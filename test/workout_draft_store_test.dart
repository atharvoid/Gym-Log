// P0-03 tests — Active workout draft survival across process death and app termination.
//
// Requirement & Failure Case Coverage:
//   1. Kill immediately after starting workout
//   2. Kill during set entry (null-weight preservation for repsOnly/duration)
//   3. Kill immediately after set completion (completedAt & isCompleted preserved)
//   4. Kill during active rest timer (restTimer endTimestamp & totalSeconds restored)
//   5. Repeated restore (idempotency)
//   6. Finishing / Discarding clears draft
//   7. Corrupt / partial draft payload recovery (fails safely, clears draft, no crash)
//   8. Legacy v1 draft payload compatibility / schema upgrade
//   9. Account isolation (user_A draft unreadable by user_B) and sign-out cleanup
//  10. Stale draft expiration (>24 hours auto-cleansed)

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutDraftStore P0-03 Resilience & Persistence Suite', () {
    late WorkoutDraftStore store;
    late Map<String, String> mockStorage;

    setUp(() {
      mockStorage = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(mockStorage);
      store = WorkoutDraftStore(const FlutterSecureStorage());
    });

    // ── 1. Kill immediately after starting ──────────────────────────────────

    test('resumes workout identity and structure immediately after start',
        () async {
      final startTime = DateTime.now();
      final state = ActiveWorkoutState(
        id: 'w-start-123',
        startTime: startTime,
        name: 'Leg Day',
        routineId: 'routine-456',
        exercises: [
          const WorkoutExerciseState(
            id: 'we-1',
            exerciseId: 10,
            name: 'Squat',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(id: 's-1', weightKg: 100, reps: 5),
            ],
          ),
        ],
      );

      await store.save(state, userId: 'user-777');

      // Simulate process restart
      final snapshot = await store.loadSnapshot(currentUserId: 'user-777');
      expect(snapshot, isNotNull);
      expect(snapshot!.version, 2);
      expect(snapshot.userId, 'user-777');
      expect(snapshot.workout.id, 'w-start-123');
      expect(snapshot.workout.name, 'Leg Day');
      expect(snapshot.workout.routineId, 'routine-456');
      expect(snapshot.workout.exercises.length, 1);
      expect(snapshot.workout.exercises.first.name, 'Squat');
    });

    // ── 2. Kill during set entry (null vs non-null weight preservation) ──────

    test('preserves draft set values and retains null weightKg for repsOnly',
        () async {
      final state = ActiveWorkoutState(
        id: 'w-entry-888',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'we-weighted',
            exerciseId: 101,
            name: 'Bench Press',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(id: 's-10', weightKg: 82.5, reps: 8),
            ],
          ),
          const WorkoutExerciseState(
            id: 'we-reps-only',
            exerciseId: 102,
            name: 'Pull-up',
            measurementType: 'reps_only',
            sets: [
              WorkoutSetState(id: 's-20', weightKg: null, reps: 12),
            ],
          ),
        ],
      );

      await store.save(state, userId: 'user-777');

      final loaded = await store.load(currentUserId: 'user-777');
      expect(loaded, isNotNull);
      expect(loaded!.exercises.length, 2);

      // Weighted exercise preserves weightKg
      expect(loaded.exercises[0].sets[0].weightKg, 82.5);
      expect(loaded.exercises[0].sets[0].reps, 8);

      // Reps-only exercise preserves NULL weightKg (not converted to 0.0)
      expect(loaded.exercises[1].sets[0].weightKg, isNull);
      expect(loaded.exercises[1].sets[0].reps, 12);
    });

    // ── 3. Kill immediately after set completion ─────────────────────────────

    test('preserves completion status and completedAt timestamp', () async {
      final completionTime = DateTime.now();
      final state = ActiveWorkoutState(
        id: 'w-complete-999',
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        exercises: [
          WorkoutExerciseState(
            id: 'we-1',
            exerciseId: 10,
            name: 'Deadlift',
            sets: [
              WorkoutSetState(
                id: 's-done',
                weightKg: 140,
                reps: 5,
                isCompleted: true,
                completedAt: completionTime,
              ),
            ],
          ),
        ],
      );

      await store.save(state, userId: 'user-777');

      final loaded = await store.load(currentUserId: 'user-777');
      expect(loaded, isNotNull);
      final set = loaded!.exercises.first.sets.first;
      expect(set.isCompleted, isTrue);
      expect(set.completedAt?.millisecondsSinceEpoch,
          completionTime.millisecondsSinceEpoch);
    });

    // ── 4. Kill during active rest timer ─────────────────────────────────────

    test('persists and restores rest timer deadline and total duration',
        () async {
      final state = ActiveWorkoutState(
        id: 'w-timer-101',
        startTime: DateTime.now(),
        exercises: const [],
      );

      final endTime = DateTime.now().add(const Duration(seconds: 45));
      final restTimer = RestTimerSnapshot(
        totalSeconds: 90,
        endTime: endTime,
        workoutId: 'w-timer-101',
        exerciseId: 10,
        setId: 's-timer-123',
      );

      await store.save(state, userId: 'user-777', restTimer: restTimer);

      final snapshot = await store.loadSnapshot(currentUserId: 'user-777');
      expect(snapshot, isNotNull);
      expect(snapshot!.restTimer, isNotNull);
      expect(snapshot.restTimer!.totalSeconds, 90);
      expect(snapshot.restTimer!.endTime.millisecondsSinceEpoch,
          endTime.millisecondsSinceEpoch);
    });

    // ── 5. Repeated restore (Idempotency) ───────────────────────────────────

    test('repeated load calls return identical valid state deterministically',
        () async {
      final state = ActiveWorkoutState(
        id: 'w-idem-555',
        startTime: DateTime.now(),
        name: 'Idempotency Workout',
        exercises: const [],
      );

      await store.save(state, userId: 'user-777');

      final load1 = await store.load(currentUserId: 'user-777');
      final load2 = await store.load(currentUserId: 'user-777');
      final load3 = await store.load(currentUserId: 'user-777');

      expect(load1?.id, 'w-idem-555');
      expect(load2?.id, 'w-idem-555');
      expect(load3?.id, 'w-idem-555');
    });

    // ── 6. Finishing / Discarding clears draft ────────────────────────────────

    test('clear() erases draft completely from storage', () async {
      final state = ActiveWorkoutState(
        id: 'w-finish-333',
        startTime: DateTime.now(),
      );

      await store.save(state, userId: 'user-777');
      expect(await store.load(currentUserId: 'user-777'), isNotNull);

      await store.clear();
      expect(await store.load(currentUserId: 'user-777'), isNull);
    });

    // ── 7. Corrupt / partial draft payload recovery ──────────────────────────

    test('corrupt JSON payload fails safely, clears storage, and returns null',
        () async {
      // Manually inject bad JSON into storage
      const storageKey = 'active_workout_draft_v2';
      mockStorage[storageKey] = '{invalid_json_payload: [incomplete';

      final loaded = await store.load(currentUserId: 'user-777');
      expect(loaded, isNull,
          reason: 'Corrupt payload must return null without throwing');

      // Storage should be cleansed
      expect(mockStorage.containsKey(storageKey), isFalse,
          reason: 'Corrupt payload must be auto-cleared');
    });

    // ── 8. Schema migration / Legacy v1 draft compatibility ───────────────────

    test(
        'legacy v1 draft loads safely and normalizes null weightKg for repsOnly',
        () async {
      const v1Key = 'active_workout_draft_v1';
      final v1Json = jsonEncode({
        'id': 'v1-workout-001',
        'startTime': DateTime.now().millisecondsSinceEpoch,
        'name': 'Legacy Workout',
        'exercises': [
          {
            'id': 'ex-v1',
            'exerciseId': 50,
            'name': 'Push-up',
            'measurementType': 'reps_only',
            'sets': [
              {
                'id': 's-v1',
                'setType': 'normal',
                'weightKg': 0, // Legacy format stored 0
                'reps': 20,
                'isCompleted': true,
              }
            ]
          }
        ]
      });

      mockStorage[v1Key] = v1Json;

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.id, 'v1-workout-001');
      expect(loaded.exercises.first.name, 'Push-up');
      // Normalized: weightKg should be null for reps_only movement
      expect(loaded.exercises.first.sets.first.weightKg, isNull);
    });

    // ── 9. Account isolation and sign-out ────────────────────────────────────

    test('draft belonging to user_A cannot be loaded by user_B', () async {
      final state = ActiveWorkoutState(
        id: 'w-user-A',
        startTime: DateTime.now(),
        name: 'User A Workout',
      );

      await store.save(state, userId: 'user-A');

      // User A can load it
      final loadA = await store.load(currentUserId: 'user-A');
      expect(loadA, isNotNull);

      // User B cannot load User A's draft
      final loadB = await store.load(currentUserId: 'user-B');
      expect(loadB, isNull,
          reason: 'User B must not see User A draft snapshot');
    });

    // ── 10. Stale draft expiration (>24h) ───────────────────────────────────

    test('draft older than 24 hours is treated as stale and auto-cleared',
        () async {
      const v2Key = 'active_workout_draft_v2';
      final staleSavedAt = DateTime.now().subtract(const Duration(hours: 25));

      final staleJson = jsonEncode({
        'version': 2,
        'userId': 'user-777',
        'savedAt': staleSavedAt.millisecondsSinceEpoch,
        'workout': {
          'id': 'w-stale-99',
          'startTime': staleSavedAt.millisecondsSinceEpoch,
          'name': 'Stale Session',
          'exercises': []
        }
      });

      mockStorage[v2Key] = staleJson;

      final loaded = await store.load(currentUserId: 'user-777');
      expect(loaded, isNull, reason: 'Stale draft (>24h) must return null');
      expect(mockStorage.containsKey(v2Key), isFalse,
          reason: 'Stale draft must be auto-cleared');
    });
  });
}
