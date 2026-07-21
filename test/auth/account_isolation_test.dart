import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/sign_out_coordinator.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/core/services/sync_remote.dart';
import 'package:gymlog/core/services/sync_entitlement_gate.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

class FakeSyncRemote implements SyncRemote {
  List<SyncObject> pushed = [];

  @override
  Future<List<PushResult>> pushBatch(List<SyncObject> objects) async {
    pushed.addAll(objects);
    return objects
        .map((o) => PushResult(id: o.id, status: PushResultStatus.accepted))
        .toList();
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late WorkoutDraftStore draftStore;
  late FakeSyncRemote remote;

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
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    draftStore = WorkoutDraftStore();
    remote = FakeSyncRemote();
  });

  tearDown(() async {
    await db.close();
  });

  test('account A workouts hidden from account B', () async {
    await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            id: const Value('session-a'),
            userId: 'user-a',
            startedAt: DateTime.now(),
          ),
        );

    final sessionForA =
        await db.workoutsDao.getHydratedWorkout('session-a', userId: 'user-a');
    expect(sessionForA, isNotNull);

    final sessionForB =
        await db.workoutsDao.getHydratedWorkout('session-a', userId: 'user-b');
    expect(sessionForB, isNull);
  });

  test('account A drafts hidden from B', () async {
    final activeState = ActiveWorkoutState(
      id: 'draft-a',
      startTime: DateTime.now(),
    );

    await draftStore.save(activeState, userId: 'user-a');

    // A can load A's draft
    final loadedForA = await draftStore.loadSnapshot(currentUserId: 'user-a');
    expect(loadedForA, isNotNull);
    expect(loadedForA!.workout.id, 'draft-a');

    // B cannot load A's draft
    final loadedForB = await draftStore.loadSnapshot(currentUserId: 'user-b');
    expect(loadedForB, isNull);
  });

  test('account A sync queue not uploaded as B', () async {
    final gate = SyncEntitlementGate(SharedPreferences.getInstance);
    final engine = SyncEngine(db: db, remote: remote, gate: gate);
    await engine.initSession('user-a', isPremium: true);

    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 'session-a',
      userId: 'user-a',
      payload: 'data-a',
    );

    // B runs syncNow, should not upload A's queue
    await engine.syncNow('user-b');
    expect(remote.pushed, isEmpty);

    // A runs syncNow, uploads A's queue
    await engine.syncNow('user-a');
    expect(remote.pushed.length, 1);
    expect(remote.pushed.first.entityId, 'session-a');
  });

  test('custom exercises isolation policy', () async {
    // 1. Insert standard exercise
    await db.exercisesDao.insertExercise(
      ExercisesCompanion.insert(
        name: 'Standard Bench',
        bodyPart: 'chest',
        equipment: 'barbell',
        target: 'pecs',
        isCustom: const Value(false),
      ),
    );

    // 2. Insert custom exercise for user A
    await db.exercisesDao.insertExercise(
      ExercisesCompanion.insert(
        name: 'Custom User A Press',
        bodyPart: 'chest',
        equipment: 'dumbbell',
        target: 'pecs',
        isCustom: const Value(true),
        createdBy: const Value('user-a'),
      ),
    );

    // User A can see both
    final listA = await db.exercisesDao.getAllExercises(userId: 'user-a');
    expect(listA.length, 2);

    // User B only sees standard one
    final listB = await db.exercisesDao.getAllExercises(userId: 'user-b');
    expect(listB.length, 1);
    expect(listB.first.name, 'Standard Bench');
  });

  test('pending sync warning and offline sign-out / restart flow', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWithValue(draftStore),
        syncRemoteProvider.overrideWithValue(remote),
      ],
    );

    final coordinator = container.read(signOutCoordinatorProvider);

    // Scenario: No pending sync
    final prep1 = await coordinator.prepare('user-a');
    expect(prep1, SignOutResult.ready);

    // Scenario: Unsynced work exists
    await db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: 'session-unsynced',
      userId: 'user-a',
      payload: 'data',
    );
    final prep2 = await coordinator.prepare('user-a');
    expect(prep2, SignOutResult.unsyncedWork);
  });
}
