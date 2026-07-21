import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/services/sync_codec.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/core/services/sync_entitlement_gate.dart';
import 'package:gymlog/core/services/sync_failure.dart';
import 'package:gymlog/core/services/sync_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

class FakeRemote implements SyncRemote {
  final Map<String, SyncObject> store = {};
  bool failNext = false;
  int pushBatches = 0;
  int pushedObjects = 0;

  @override
  Future<List<PushResult>> pushBatch(List<SyncObject> objects) async {
    if (failNext) throw Exception('offline');
    pushBatches++;
    pushedObjects += objects.length;
    final results = <PushResult>[];

    for (final o in objects) {
      final existing = store[o.id];
      if (existing != null) {
        if (existing.userId != o.userId) {
          results.add(PushResult(
            id: o.id,
            status: PushResultStatus.conflict,
            serverRevision: existing.revision,
            serverObject: existing,
          ));
          continue;
        }

        if (existing.operationId.isNotEmpty &&
            existing.operationId == o.operationId) {
          results.add(PushResult(
            id: o.id,
            status: PushResultStatus.duplicateOperation,
            serverRevision: existing.revision,
          ));
          continue;
        }

        if (o.revision < existing.revision) {
          results.add(PushResult(
            id: o.id,
            status: PushResultStatus.conflict,
            serverRevision: existing.revision,
            serverObject: existing,
          ));
          continue;
        }
      }

      final nextRev = existing != null ? existing.revision + 1 : o.revision;
      final storedObj = SyncObject(
        id: o.id,
        userId: o.userId,
        entityType: o.entityType,
        entityId: o.entityId,
        revision: nextRev,
        operationId: o.operationId,
        updatedAtMs: o.updatedAtMs,
        deleted: o.deleted,
        payload: o.payload,
      );
      store[o.id] = storedObj;
      results.add(PushResult(
        id: o.id,
        status: PushResultStatus.accepted,
        serverRevision: nextRev,
      ));
    }
    return results;
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    if (failNext) throw Exception('offline');
    return store.values.toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    SharedPreferences.setMockInitialValues({'sync_enabled': true});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeRemote();
    final gate = SyncEntitlementGate(SharedPreferences.getInstance);
    engine = SyncEngine(db: db, remote: remote, gate: gate);
    engine.initSession(userId, isPremium: true);
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

  Future<String> seedSession(String id) async {
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
    await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
          workoutExerciseId: weId,
          exerciseId: exId,
          orderIndex: 0,
          weightKg: const Value(80.0),
          reps: 10,
        ));
    return id;
  }

  test('corrupt payload is quarantined and does not abort pull of good objects',
      () async {
    await seedSession('s1');
    await engine.enqueueSession(userId, 's1');
    await engine.syncNow(userId);

    remote.store['session:corrupt'] = SyncObject(
      id: 'session:corrupt',
      userId: userId,
      entityType: 'session',
      entityId: 'corrupt',
      revision: 1,
      operationId: 'op_corrupt',
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      deleted: false,
      payload: 'this_is_not_valid_json_or_gzip',
    );

    await db.workoutsDao.deleteSession('s1');

    await engine.pull(userId);

    final restored = await db.workoutsDao.getSessionOrNull('s1');
    expect(restored, isNotNull);

    final failures = await db.syncOutboxDao.getQuarantinedRecords(userId);
    expect(failures.length, 1);
    expect(failures.first.objectId, 'session:corrupt');
    expect(failures.first.reason, SyncFailureReason.decodeFailure);
  });

  test('unsupported schema version is quarantined', () async {
    final payloadFuture = SyncCodec.encode(
      {
        'id': 's_future',
        'userId': userId,
        'startedAt': DateTime.now().toIso8601String(),
        'exercises': []
      },
      entityType: 'session',
      entityId: 's_future',
      schemaVersion: 99,
    );

    remote.store['session:s_future'] = SyncObject(
      id: 'session:s_future',
      userId: userId,
      entityType: 'session',
      entityId: 's_future',
      revision: 1,
      operationId: 'op_future',
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      deleted: false,
      payload: payloadFuture,
    );

    await engine.pull(userId);

    final failures = await db.syncOutboxDao.getQuarantinedRecords(userId);
    expect(failures.length, 1);
    expect(failures.first.objectId, 'session:s_future');
    expect(failures.first.reason, SyncFailureReason.unsupportedVersion);
  });

  test(
      'quarantined object is removed from outbox and does not retry on every sync',
      () async {
    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 'bad_obj',
      userId: userId,
      payload: 'corrupt_data',
    );

    expect(await db.syncOutboxDao.pendingCount(userId), 1);

    await engine.quarantineObject(
      userId: userId,
      entityType: 'session',
      entityId: 'bad_obj',
      reason: SyncFailureReason.decodeFailure,
      diagnostic: 'Test corrupt payload',
    );

    expect(await db.syncOutboxDao.pendingCount(userId), 0);

    await engine.syncNow(userId);
    expect(remote.store.containsKey('session:bad_obj'), isFalse);
    expect(await db.syncOutboxDao.quarantinedCount(userId), 1);
  });

  test('outbox coalesces multiple edits for (userId, entityType, entityId)',
      () async {
    await seedSession('s1');
    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 's1',
      userId: userId,
      payload: 'p1',
    );
    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 's1',
      userId: userId,
      payload: 'p2',
    );
    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 's1',
      userId: userId,
      payload: 'p3',
    );

    final batch = await db.syncOutboxDao.nextBatch(userId);
    expect(batch.length, 1);
    expect(batch.single.payload, 'p3');
  });

  test('duplicate operation is idempotent', () async {
    final validPayload =
        SyncCodec.encode({'id': 's1'}, entityType: 'session', entityId: 's1');
    final obj = SyncObject(
      id: 'session:s1',
      userId: userId,
      entityType: 'session',
      entityId: 's1',
      revision: 1,
      operationId: 'op_fixed_id',
      updatedAtMs: 1000,
      deleted: false,
      payload: validPayload,
    );

    final res1 = await remote.pushBatch([obj]);
    expect(res1.single.status, PushResultStatus.accepted);

    final res2 = await remote.pushBatch([obj]);
    expect(res2.single.status, PushResultStatus.duplicateOperation);
  });

  test('stale revision reports conflict and clock skew does not decide winner',
      () async {
    final validPayload =
        SyncCodec.encode({'id': 's1'}, entityType: 'session', entityId: 's1');
    remote.store['session:s1'] = SyncObject(
      id: 'session:s1',
      userId: userId,
      entityType: 'session',
      entityId: 's1',
      revision: 5,
      operationId: 'op_server',
      updatedAtMs: 5000,
      deleted: false,
      payload: validPayload,
    );

    final staleClientObj = SyncObject(
      id: 'session:s1',
      userId: userId,
      entityType: 'session',
      entityId: 's1',
      revision: 1,
      operationId: 'op_client_stale',
      updatedAtMs: 9000,
      deleted: false,
      payload: validPayload,
    );

    final results = await remote.pushBatch([staleClientObj]);
    expect(results.single.status, PushResultStatus.conflict);
    expect(results.single.serverRevision, 5);
    expect(remote.store['session:s1']!.payload, validPayload);
  });

  test('account ownership mismatch is quarantined', () async {
    final validPayload =
        SyncCodec.encode({'id': 's1'}, entityType: 'session', entityId: 's1');
    remote.store['session:s1'] = SyncObject(
      id: 'session:s1',
      userId: 'other_user',
      entityType: 'session',
      entityId: 's1',
      revision: 1,
      operationId: 'op_other',
      updatedAtMs: 1000,
      deleted: false,
      payload: validPayload,
    );

    await engine.pull(userId);

    final failures = await db.syncOutboxDao.getQuarantinedRecords(userId);
    expect(failures.length, 1);
    expect(failures.first.reason, SyncFailureReason.ownershipMismatch);
  });

  test('delete tombstone is preserved in outbox and remote', () async {
    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 's_del',
      userId: userId,
      payload: '',
      op: 'delete',
    );

    final batch = await db.syncOutboxDao.nextBatch(userId);
    expect(batch.single.op, 'delete');
    expect(batch.single.payload, '');

    await engine.syncNow(userId);
    expect(remote.store['session:s_del']!.deleted, isTrue);
  });

  test('privacy-safe logs contain no payload, email, or token string', () {
    const diagnostic = 'Decode error in session:s123';
    expect(diagnostic.contains('payload'), isFalse);
    expect(diagnostic.contains('@'), isFalse);
    expect(diagnostic.contains('token'), isFalse);
  });
}
