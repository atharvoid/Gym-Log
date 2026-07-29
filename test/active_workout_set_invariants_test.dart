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

  group('ATOMIC-RC3-02 Set State Invariants Suite', () {
    test('1. Clearing weight sets it to null, clearing reps sets it to 0',
        () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Bench Press',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(id: 's-1', weightKg: 80, reps: 8),
            ],
          ),
        ],
      );

      // Verify initial setup
      var currentState = container.read(activeWorkoutProvider)!;
      expect(currentState.exercises.first.sets.first.weightKg, 80.0);
      expect(currentState.exercises.first.sets.first.reps, 8);

      // Clear weight via replaceSet
      notifier.replaceSet(
        'ex-1',
        's-1',
        currentState.exercises.first.sets.first.copyWith(weightKg: null),
      );

      currentState = container.read(activeWorkoutProvider)!;
      expect(currentState.exercises.first.sets.first.weightKg, isNull);
      expect(currentState.exercises.first.sets.first.reps, 8);

      // Clear reps via replaceSet
      notifier.replaceSet(
        'ex-1',
        's-1',
        currentState.exercises.first.sets.first.copyWith(reps: 0),
      );

      currentState = container.read(activeWorkoutProvider)!;
      expect(currentState.exercises.first.sets.first.weightKg, isNull);
      expect(currentState.exercises.first.sets.first.reps, 0);
    });

    test('2. Direct notifier cannot complete invalid set', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Bench Press',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(id: 's-1', weightKg: null, reps: 0),
            ],
          ),
        ],
      );

      // Attempt to toggle set completion
      notifier.toggleSetCompletion(0, 0);

      final currentState = container.read(activeWorkoutProvider)!;
      // Should remain not completed because set data is empty / invalid
      expect(currentState.exercises.first.sets.first.isCompleted, isFalse);
    });

    test('3. Untouched weighted placeholder is not meaningful', () {
      const exerciseWithPlaceholder = WorkoutExerciseState(
        id: 'ex-1',
        exerciseId: 101,
        name: 'Bench Press',
        sets: [
          WorkoutSetState(id: 's-1', weightKg: 0.0, reps: 0),
        ],
      );

      // hasMeaningfulSetData should be false for 0.0 weight and 0 reps
      expect(hasMeaningfulSetData(exerciseWithPlaceholder), isFalse);

      const exerciseWithData = WorkoutExerciseState(
        id: 'ex-2',
        exerciseId: 102,
        name: 'Bench Press',
        sets: [
          WorkoutSetState(id: 's-2', weightKg: 80.0, reps: 5),
        ],
      );

      // hasMeaningfulSetData should be true for real data
      expect(hasMeaningfulSetData(exerciseWithData), isTrue);
    });

    test(
        '4. Reps-only / duration sets normalize weight to null, distance normalizes reps to 0',
        () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-reps',
            exerciseId: 101,
            name: 'Pushup',
            measurementType: 'reps_only',
            sets: [
              WorkoutSetState(id: 's-1', weightKg: 10, reps: 15),
            ],
          ),
          const WorkoutExerciseState(
            id: 'ex-dist',
            exerciseId: 102,
            name: 'Running',
            measurementType: 'distance',
            sets: [
              WorkoutSetState(id: 's-2', weightKg: 5000, reps: 10),
            ],
          ),
        ],
      );

      // Trigger update/replace on reps-only exercise set
      notifier.replaceSet(
        'ex-reps',
        's-1',
        container
            .read(activeWorkoutProvider)!
            .exercises[0]
            .sets
            .first
            .copyWith(weightKg: 10, reps: 15),
      );

      // Weight should be normalized to null for reps-only
      var state = container.read(activeWorkoutProvider)!;
      expect(state.exercises[0].sets.first.weightKg, isNull);
      expect(state.exercises[0].sets.first.reps, 15);

      // Trigger update/replace on distance exercise set
      notifier.replaceSet(
        'ex-dist',
        's-2',
        container
            .read(activeWorkoutProvider)!
            .exercises[1]
            .sets
            .first
            .copyWith(weightKg: 5000, reps: 10),
      );

      // Reps should be normalized to 0 for distance
      state = container.read(activeWorkoutProvider)!;
      expect(state.exercises[1].sets.first.weightKg, 5000.0);
      expect(state.exercises[1].sets.first.reps, 0);
    });
  });
}
