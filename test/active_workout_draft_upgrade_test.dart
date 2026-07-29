import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> mockStorage;
  late WorkoutDraftStore store;
  late AppDatabase db;

  setUp(() {
    mockStorage = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(mockStorage);
    SharedPreferences.setMockInitialValues({});
    store = WorkoutDraftStore(const FlutterSecureStorage());
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ATOMIC-RC3-05 Workout Draft and Routine Upgrades', () {
    test(
        '1. WorkoutDraftStore upgrades legacy exercises via name inference on parse',
        () async {
      const v2Key = 'active_workout_draft_v2';
      final draftJson = jsonEncode({
        'version': 2,
        'userId': 'user-123',
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'workout': {
          'id': 'w-123',
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'name': 'Test Workout',
          'exercises': [
            {
              'id': 'ex-pushup',
              'exerciseId': 10,
              'name': 'Push-up',
              'measurementType': 'weight_and_reps', // legacy default
              'sets': [
                {
                  'id': 's-1',
                  'setType': 'normal',
                  'weightKg': 20.0,
                  'reps': 10,
                  'isCompleted': false,
                }
              ]
            },
            {
              'id': 'ex-bench',
              'exerciseId': 11,
              'name': 'Bench Press (Barbell)',
              'measurementType': 'weight_and_reps',
              'sets': [
                {
                  'id': 's-2',
                  'setType': 'normal',
                  'weightKg': 80.0,
                  'reps': 5,
                  'isCompleted': false,
                }
              ]
            }
          ]
        }
      });

      mockStorage[v2Key] = draftJson;

      final snapshot = await store.loadSnapshot(currentUserId: 'user-123');
      expect(snapshot, isNotNull);

      final pushup =
          snapshot!.workout.exercises.firstWhere((e) => e.id == 'ex-pushup');
      // Should resolve to reps_only via name inference because Push-up is an exception
      expect(pushup.measurementType, 'reps_only');
      expect(pushup.sets.first.weightKg, isNull);

      final bench =
          snapshot.workout.exercises.firstWhere((e) => e.id == 'ex-bench');
      // Should remain weight_and_reps
      expect(bench.measurementType, 'weight_and_reps');
      expect(bench.sets.first.weightKg, 80.0);
    });

    test(
        '2. ActiveWorkoutNotifier resumeDraft upgrades draft against database metadata',
        () async {
      // Seed the database with target exercises having explicit measurement types
      await db.exercisesDao.insertExercises([
        ExercisesCompanion.insert(
          id: const drift.Value(101),
          name: 'Custom Bodyweight Exercise',
          bodyPart: 'chest',
          equipment: 'bodyweight',
          target: 'pectorals',
          measurementType: const drift.Value('reps_only'),
        ),
        ExercisesCompanion.insert(
          id: const drift.Value(102),
          name: 'Custom Weighted Exercise',
          bodyPart: 'chest',
          equipment: 'barbell',
          target: 'pectorals',
          measurementType: const drift.Value('weight_and_reps'),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);

      final draft = ActiveWorkoutState(
        id: 'w-draft-456',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'we-101',
            exerciseId: 101,
            name: 'Custom Bodyweight Exercise',
            measurementType: 'weight_and_reps', // incorrect legacy draft value
            sets: [
              WorkoutSetState(id: 's-101', weightKg: 15.0, reps: 12),
            ],
          ),
          const WorkoutExerciseState(
            id: 'we-102',
            exerciseId: 102,
            name: 'Custom Weighted Exercise',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(id: 's-102', weightKg: 40.0, reps: 8),
            ],
          ),
        ],
      );

      await notifier.resumeDraft(draft);

      final state = container.read(activeWorkoutProvider);
      expect(state, isNotNull);

      final bwEx = state!.exercises.firstWhere((e) => e.exerciseId == 101);
      // Database metadata says reps_only, so it must be upgraded!
      expect(bwEx.measurementType, 'reps_only');
      expect(bwEx.sets.first.weightKg, isNull);

      final wEx = state.exercises.firstWhere((e) => e.exerciseId == 102);
      expect(wEx.measurementType, 'weight_and_reps');
      expect(wEx.sets.first.weightKg, 40.0);
    });
  });
}
