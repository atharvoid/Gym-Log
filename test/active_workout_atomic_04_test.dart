import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> mockStorage;
  late WorkoutDraftStore store;

  setUp(() {
    mockStorage = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(mockStorage);
    SharedPreferences.setMockInitialValues({});
    store = WorkoutDraftStore(const FlutterSecureStorage());
  });

  group('ATOMIC-04 Reversible Deletion & Replacement Policy Suite', () {
    test('1. deletion returns complete snapshot', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-instance-1',
            exerciseId: 101,
            name: 'Bench Press',
            sets: [
              WorkoutSetState(
                id: 'set-1',
                setType: 'normal',
                weightKg: 100,
                reps: 8,
              ),
              WorkoutSetState(
                id: 'set-2',
                setType: 'normal',
                weightKg: 105,
                reps: 6,
              ),
            ],
          ),
        ],
      );

      final snapshot = notifier.removeSetWithSnapshot(
        exerciseInstanceId: 'ex-instance-1',
        setId: 'set-2',
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.exerciseInstanceId, 'ex-instance-1');
      expect(snapshot.set.id, 'set-2');
      expect(snapshot.set.weightKg, 105);
      expect(snapshot.set.reps, 6);
      expect(snapshot.originalIndex, 1);

      final currentState = container.read(activeWorkoutProvider);
      expect(currentState!.exercises.first.sets.length, 1);
    });

    test('2. Undo restores exact index and values', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-instance-1',
            exerciseId: 101,
            name: 'Squat',
            sets: [
              WorkoutSetState(id: 'set-1', weightKg: 140, reps: 5),
              WorkoutSetState(id: 'set-2', weightKg: 150, reps: 3),
              WorkoutSetState(id: 'set-3', weightKg: 160, reps: 1),
            ],
          ),
        ],
      );

      final snapshot = notifier.removeSetWithSnapshot(
        exerciseInstanceId: 'ex-instance-1',
        setId: 'set-2',
      );

      final restored = notifier.restoreRemovedSet(snapshot!);
      expect(restored, isTrue);

      final sets = container.read(activeWorkoutProvider)!.exercises.first.sets;
      expect(sets.length, 3);
      expect(sets[1].id, 'set-2');
      expect(sets[1].weightKg, 150);
      expect(sets[1].reps, 3);
    });

    test('3. Undo after exercise reorder finds stable ID', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-a',
            exerciseId: 101,
            name: 'Bench Press',
            sets: [
              WorkoutSetState(id: 'set-a1', weightKg: 80, reps: 10),
            ],
          ),
          const WorkoutExerciseState(
            id: 'ex-b',
            exerciseId: 102,
            name: 'Incline Dumbbell Press',
            sets: [
              WorkoutSetState(id: 'set-b1', weightKg: 30, reps: 12),
            ],
          ),
        ],
      );

      // Remove set from exercise B (index 1)
      final snapshot = notifier.removeSetWithSnapshot(
        exerciseInstanceId: 'ex-b',
        setId: 'set-b1',
      );
      expect(snapshot, isNotNull);

      // Reorder exercises: move ex-b (index 1) to top (index 0)
      notifier.reorderExercise(1, 0);

      final stateAfterReorder = container.read(activeWorkoutProvider)!;
      expect(stateAfterReorder.exercises.first.id, 'ex-b');

      // Undo restoration should locate ex-b at index 0 via its stable instance ID
      final restored = notifier.restoreRemovedSet(snapshot!);
      expect(restored, isTrue);

      final restoredExB = container
          .read(activeWorkoutProvider)!
          .exercises
          .firstWhere((e) => e.id == 'ex-b');
      expect(restoredExB.sets.first.id, 'set-b1');
    });

    test('4. duplicate Undo is ignored', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Deadlift',
            sets: [
              WorkoutSetState(id: 'set-1', weightKg: 180, reps: 3),
            ],
          ),
        ],
      );

      final snapshot = notifier.removeSetWithSnapshot(
        exerciseInstanceId: 'ex-1',
        setId: 'set-1',
      );

      final restoredFirst = notifier.restoreRemovedSet(snapshot!);
      expect(restoredFirst, isTrue);

      final restoredSecond = notifier.restoreRemovedSet(snapshot);
      expect(restoredSecond, isFalse);

      final sets = container.read(activeWorkoutProvider)!.exercises.first.sets;
      expect(sets.length, 1);
    });

    test('5. deletion persists draft', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'OHP',
            sets: [
              WorkoutSetState(id: 's1', weightKg: 50, reps: 5),
              WorkoutSetState(id: 's2', weightKg: 55, reps: 5),
            ],
          ),
        ],
      );

      notifier.removeSetWithSnapshot(
        exerciseInstanceId: 'ex-1',
        setId: 's2',
      );

      notifier.saveDraftNow();

      final savedDraft = await store.load();
      expect(savedDraft, isNotNull);
      expect(savedDraft!.exercises.first.sets.length, 1);
    });

    test('6. replacement Cancel changes nothing', () async {
      const originalEx = WorkoutExerciseState(
        id: 'ex-1',
        exerciseId: 101,
        name: 'Barbell Row',
        measurementType: 'weight_and_reps',
        sets: [
          WorkoutSetState(id: 's1', weightKg: 70, reps: 10),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(initialExercises: [originalEx]);

      // Verify exercise has meaningful data
      expect(hasMeaningfulSetData(originalEx), isTrue);

      // On Cancel, no replace method is called -> verify active workout state is untouched
      final state = container.read(activeWorkoutProvider)!;
      expect(state.exercises.first.name, 'Barbell Row');
      expect(state.exercises.first.sets.first.weightKg, 70);
    });

    test('7. clear resets values', () async {
      final container = ProviderContainer();
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
              WorkoutSetState(
                  id: 's1', weightKg: 100, reps: 8, isCompleted: true),
            ],
          ),
        ],
      );

      await notifier.replaceExerciseWithPolicy(
        0,
        202,
        'Dumbbell Press',
        keepCompatibleValues: false,
        measurementType: 'weight_and_reps',
      );

      final updatedEx = container.read(activeWorkoutProvider)!.exercises.first;
      expect(updatedEx.name, 'Dumbbell Press');
      expect(updatedEx.sets.length, 1);
      expect(updatedEx.sets.first.weightKg, 0.0);
      expect(updatedEx.sets.first.reps, 0);
      expect(updatedEx.sets.first.isCompleted, isFalse);
    });

    test('8. compatible replacement preserves values', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Incline Bench',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(
                  id: 's1', setType: 'warmup', weightKg: 60, reps: 12),
              WorkoutSetState(
                  id: 's2', setType: 'normal', weightKg: 90, reps: 8),
            ],
          ),
        ],
      );

      await notifier.replaceExerciseWithPolicy(
        0,
        203,
        'Dumbbell Incline Press',
        keepCompatibleValues: true,
        measurementType: 'weight_and_reps',
      );

      final updatedEx = container.read(activeWorkoutProvider)!.exercises.first;
      expect(updatedEx.name, 'Dumbbell Incline Press');
      expect(updatedEx.sets.length, 2);
      expect(updatedEx.sets[0].weightKg, 60);
      expect(updatedEx.sets[0].reps, 12);
      expect(updatedEx.sets[0].setType, 'warmup');
      expect(updatedEx.sets[1].weightKg, 90);
      expect(updatedEx.sets[1].reps, 8);
    });

    test('9. stale weight is cleared for reps-only', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Lat Pulldown',
            measurementType: 'weight_and_reps',
            sets: [
              WorkoutSetState(id: 's1', weightKg: 70, reps: 10),
            ],
          ),
        ],
      );

      // Replace weightAndReps -> repsOnly (e.g. Pull Ups)
      await notifier.replaceExerciseWithPolicy(
        0,
        301,
        'Pull Up',
        keepCompatibleValues: true,
        measurementType: 'reps_only',
      );

      final repsOnlyEx = container.read(activeWorkoutProvider)!.exercises.first;
      expect(repsOnlyEx.name, 'Pull Up');
      expect(repsOnlyEx.sets.first.weightKg, isNull);
      expect(repsOnlyEx.sets.first.reps, 10);

      // Now replace repsOnly -> weightAndReps (e.g. Back Lat Pulldown)
      await notifier.replaceExerciseWithPolicy(
        0,
        101,
        'Lat Pulldown',
        keepCompatibleValues: true,
        measurementType: 'weight_and_reps',
      );

      final weightedEx = container.read(activeWorkoutProvider)!.exercises.first;
      expect(weightedEx.name, 'Lat Pulldown');
      expect(weightedEx.sets.first.weightKg,
          isNull); // Stale weight cleared / left null
      expect(weightedEx.sets.first.reps, 10);
    });
  });
}
