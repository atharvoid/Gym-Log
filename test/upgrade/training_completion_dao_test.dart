import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
          OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    }
  });
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());
  Future<void> insert(String id, DateTime start, DateTime? end,
          {String user = 'owner', String? routine = 'push'}) =>
      db.workoutsDao.insertSession(WorkoutSessionsCompanion(
        id: Value(id),
        userId: Value(user),
        routineId: Value(routine),
        name: Value(id),
        startedAt: Value(start),
        endedAt: Value(end),
      ));
  test(
      'completed-only, account-scoped latest queries use endedAt rather than feed order',
      () async {
    await insert('long', DateTime(2026, 1), DateTime(2026, 10, 4));
    await insert('new-start', DateTime(2026, 10, 3), DateTime(2026, 10, 3, 1),
        routine: 'pull');
    await insert('unfinished', DateTime(2026, 10, 5), null);
    await insert(
        'another-account', DateTime(2026, 10, 6), DateTime(2026, 10, 6, 1),
        user: 'other');
    final rows =
        await db.workoutsDao.watchLatestCompletedPreviews('owner').first;
    expect(rows.map((p) => p.session.id), ['long', 'new-start']);
    expect(
        await db.workoutsDao
            .watchLatestCompletedPreviews('owner', routineIds: []).first,
        isEmpty);
  });
  test('program completion outside first history page remains available',
      () async {
    await insert('program', DateTime(2026, 1), DateTime(2026, 1, 1, 1),
        routine: 'pull');
    for (var i = 0; i < 15; i++) {
      await insert(
          'outside-$i', DateTime(2026, 2, i + 1), DateTime(2026, 2, i + 1, 1),
          routine: null);
    }
    final feed = await db.workoutsDao
        .getSessionPreviewsForUser('owner', limit: 10, offset: 0);
    expect(feed.any((p) => p.session.id == 'program'), isFalse);
    final selected = await db.workoutsDao.watchLatestCompletedPreviews('owner',
        routineIds: ['push', 'pull']).first;
    expect(selected.single.session.id, 'program');
    expect(
        (await db.workoutsDao.watchLatestCompletedPreviews('owner').first)
            .first
            .session
            .id,
        'outside-14');
  });
  test('persisted edit, deletion and sync import recompute the narrow stream',
      () async {
    await insert('older', DateTime(2026, 1), DateTime(2026, 1, 1, 1));
    final queue =
        StreamIterator(db.workoutsDao.watchLatestCompletedPreviews('owner'));
    addTearDown(queue.cancel);
    expect(await queue.moveNext(), isTrue);
    expect(queue.current.single.session.id, 'older');
    await insert('synced', DateTime(2025, 1), DateTime(2026, 10, 4),
        routine: 'pull');
    expect(await queue.moveNext(), isTrue);
    expect(queue.current.first.session.id, 'synced');
    await (db.update(db.workoutSessions)..where((t) => t.id.equals('older')))
        .write(WorkoutSessionsCompanion(
            endedAt: Value(DateTime(2026, 10, 5)),
            name: const Value('Renamed')));
    expect(await queue.moveNext(), isTrue);
    expect(queue.current.first.session.name, 'Renamed');
    await (db.delete(db.workoutSessions)..where((t) => t.id.equals('older')))
        .go();
    expect(await queue.moveNext(), isTrue);
    expect(queue.current.first.session.id, 'synced');
  });
  test('duplicate same-day records cannot hide an ambiguous tied program day',
      () async {
    final end = DateTime(2026, 10, 4);
    await insert('a-push', DateTime(2026, 10, 3), end);
    await insert('b-push', DateTime(2026, 10, 3), end);
    await insert('z-pull', DateTime(2026, 10, 3), end, routine: 'pull');
    final rows = await db.workoutsDao.watchLatestCompletedPreviews('owner',
        routineIds: ['push', 'pull']).first;
    expect(rows.map((p) => p.session.routineId).toSet(), {'push', 'pull'});
  });
}
