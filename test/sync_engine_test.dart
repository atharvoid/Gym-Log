// SyncEngine behaviour without a live backend — a fake SyncRemote stands in
// for Supabase, and an in-memory Drift DB provides the local source of truth.
// Covers: outbox drain + batching, offline requeue/retry, the session
// round-trip (enqueue → push → pull → rehydrate), pending count, and the
// compression codec.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/services/sync_codec.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/core/services/sync_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

/// In-memory fake backend with controllable failure.
class FakeRemote implements SyncRemote {
  final Map<String, SyncObject> store = {};
  bool failNext = false;
  int pushBatches = 0;
  int pushedObjects = 0;

  @override
  Future<void> pushBatch(List<SyncObject> objects) async {
    if (failNext) throw Exception('offline');
    pushBatches++;
    pushedObjects += objects.length;
    for (final o in objects) {
      store[o.id] = o; // upsert (LWW handled server-side in prod)
    }
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    if (failNext) throw Exception('offline');
    return store.values.where((o) => o.userId == userId).toList();
  }
}

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late SyncEngine engine;
  const userId = 'user-1';

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeRemote();
    engine = SyncEngine(db: db, remote: remote);
  });

  tearDown(() {
    engine.dispose();
    return db.close();
  });

  Future<int> insertExercise(String name) async {
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
        name: name, bodyPart: 'chest', equipment: 'barbell', target: 'pecs'));
    return (await db.exercisesDao.getAllExercises())
        .firstWhere((e) => e.name == name)
        .id;
  }

  /// Finishes a session locally (session + 1 exercise + [setCount] sets).
  Future<String> seedSession(String id, int setCount) async {
    final exId = await insertExercise('Bench-$id');
    await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
          id: Value(id),
          userId: userId,
          name: const Value('Day'),
          startedAt: DateTime(2026, 1, 1, 8),
          endedAt: Value(DateTime(2026, 1, 1, 9)),
          totalVolumeKg: const Value(1000),
        ));
    final weId = '$id-we';
    await db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
        id: Value(weId), sessionId: id, exerciseId: exId, orderIndex: 0));
    for (var i = 0; i < setCount; i++) {
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            workoutExerciseId: weId,
            exerciseId: exId,
            orderIndex: i,
            weightKg: 80.0 + i,
            reps: 10,
          ));
    }
    return id;
  }

  test('codec round-trips and actually compresses repetitive JSON', () {
    final data = {
      'sets': [for (var i = 0; i < 50; i++) {'weightKg': 80.0, 'reps': 10}]
    };
    final encoded = SyncCodec.encode(data);
    expect(SyncCodec.decode(encoded), data);
  });

  test('enqueueSession queues one row; syncNow uploads and clears it',
      () async {
    await seedSession('s1', 3);
    await engine.enqueueSession(userId, 's1');
    expect(await db.syncOutboxDao.pendingCount(userId), 1);

    await engine.syncNow(userId);

    expect(await db.syncOutboxDao.pendingCount(userId), 0);
    expect(remote.store.containsKey('session:s1'), isTrue);
    expect(engine.status.value.phase, SyncPhase.synced);
  });

  test('offline keeps the queue; a later retry delivers it', () async {
    await seedSession('s1', 2);
    await engine.enqueueSession(userId, 's1');

    remote.failNext = true;
    await engine.syncNow(userId);
    expect(await db.syncOutboxDao.pendingCount(userId), 1); // still queued
    expect(engine.status.value.phase, SyncPhase.offline);

    remote.failNext = false;
    await engine.syncNow(userId);
    expect(await db.syncOutboxDao.pendingCount(userId), 0); // delivered
    expect(remote.store.containsKey('session:s1'), isTrue);
  });

  test('re-enqueuing the same session coalesces to one queued row', () async {
    await seedSession('s1', 1);
    await engine.enqueueSession(userId, 's1');
    await engine.enqueueSession(userId, 's1');
    expect(await db.syncOutboxDao.pendingCount(userId), 1);
  });

  test('session round-trip: push, wipe local, pull, rehydrate', () async {
    await seedSession('s1', 4);
    await engine.enqueueSession(userId, 's1');
    await engine.syncNow(userId);

    // Simulate a reinstall: drop the local session + children.
    await db.workoutsDao.deleteSession('s1');
    expect(await db.workoutsDao.getSessionOrNull('s1'), isNull);

    await engine.pull(userId);

    final restored = await db.workoutsDao.getHydratedWorkout('s1');
    expect(restored, isNotNull);
    expect(restored!.session.totalVolumeKg, 1000);
    expect(restored.exercises.first.sets.length, 4);
  });

  test('batches large queues across multiple push calls', () async {
    // 250 sessions > the 200 batch size → at least 2 push calls.
    for (var i = 0; i < 250; i++) {
      await seedSession('s$i', 1);
      await engine.enqueueSession(userId, 's$i');
    }
    expect(await db.syncOutboxDao.pendingCount(userId), 250);

    await engine.syncNow(userId);

    expect(await db.syncOutboxDao.pendingCount(userId), 0);
    expect(remote.pushedObjects, 250);
    expect(remote.pushBatches, greaterThanOrEqualTo(2));
  });
}
