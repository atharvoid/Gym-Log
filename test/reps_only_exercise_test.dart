import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';

void main() {
  group('MeasurementType Domain Model', () {
    test('parses raw string values correctly', () {
      expect(MeasurementType.fromString('weight_and_reps'),
          MeasurementType.weightAndReps);
      expect(MeasurementType.fromString('reps_only'), MeasurementType.repsOnly);
      expect(MeasurementType.fromString('duration'), MeasurementType.duration);
      expect(MeasurementType.fromString('distance'), MeasurementType.distance);
    });

    test('falls back to equipment when raw value is null or empty', () {
      expect(MeasurementType.fromString(null, equipment: 'Bodyweight'),
          MeasurementType.repsOnly);
      expect(MeasurementType.fromString(null, equipment: 'body weight'),
          MeasurementType.repsOnly);
      expect(MeasurementType.fromString(null, equipment: 'Assisted'),
          MeasurementType.repsOnly);
      expect(MeasurementType.fromString(null, equipment: 'Barbell'),
          MeasurementType.weightAndReps);
      expect(MeasurementType.fromString(null, equipment: 'Dumbbell'),
          MeasurementType.weightAndReps);
    });

    test(
        'defaults to weightAndReps when both raw and equipment are unrecognised',
        () {
      expect(MeasurementType.fromString(null, equipment: null),
          MeasurementType.weightAndReps);
      expect(MeasurementType.fromString('unknown_type'),
          MeasurementType.weightAndReps);
    });

    test('boolean flags match enum value', () {
      expect(MeasurementType.repsOnly.isRepsOnly, isTrue);
      expect(MeasurementType.repsOnly.requiresWeight, isFalse);

      expect(MeasurementType.weightAndReps.isRepsOnly, isFalse);
      expect(MeasurementType.weightAndReps.requiresWeight, isTrue);
    });
  });

  group('WorkoutSetState & WorkoutExerciseState Reps-Only Defaults', () {
    test('WorkoutSetState weightKg defaults to null when specified', () {
      final setState = WorkoutSetState.create(weightKg: null);
      expect(setState.weightKg, isNull);
    });

    test('WorkoutExerciseState holds measurementType string', () {
      const exState = WorkoutExerciseState(
        id: 'ex-1',
        exerciseId: 10,
        name: 'Push-up',
        measurementType: 'reps_only',
      );
      expect(exState.measurementType, 'reps_only');
    });
  });

  group('ActiveWorkoutNotifier Reps-Only & Switching Logic', () {
    test('adding reps-only exercise initializes weightKg to null', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Test Workout');
      notifier.addExercise(100, 'Pull-up', measurementType: 'reps_only');

      final state = container.read(activeWorkoutProvider);
      expect(state, isNotNull);
      expect(state!.exercises.length, 1);
      expect(state.exercises.first.measurementType, 'reps_only');
      expect(state.exercises.first.sets.first.weightKg, isNull);
    });

    test('adding weighted exercise initializes weightKg to 0.0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Test Workout');
      notifier.addExercise(101, 'Bench Press',
          measurementType: 'weight_and_reps');

      final state = container.read(activeWorkoutProvider);
      expect(state, isNotNull);
      expect(state!.exercises.first.measurementType, 'weight_and_reps');
      expect(state.exercises.first.sets.first.weightKg, 0.0);
    });

    test(
        'switching between weighted and reps-only respects target measurementType',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Test Workout');
      notifier.addExercise(101, 'Bench Press',
          measurementType: 'weight_and_reps');

      // Replace with reps-only exercise
      notifier.replaceExercise(0, 102, 'Push-up', measurementType: 'reps_only');
      final state1 = container.read(activeWorkoutProvider);
      expect(state1!.exercises.first.name, 'Push-up');
      expect(state1.exercises.first.measurementType, 'reps_only');
      expect(state1.exercises.first.sets.first.weightKg, isNull);

      // Replace back with weighted exercise
      notifier.replaceExercise(0, 103, 'Squat',
          measurementType: 'weight_and_reps');
      final state2 = container.read(activeWorkoutProvider);
      expect(state2!.exercises.first.name, 'Squat');
      expect(state2.exercises.first.measurementType, 'weight_and_reps');
      expect(state2.exercises.first.sets.first.weightKg, 0.0);
    });

    test('sessionTotals volume calculation ignores null weights', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Test Workout');
      notifier.addExercise(100, 'Pull-up', measurementType: 'reps_only');
      notifier.updateSet(0, 0, reps: 15);
      notifier.toggleSetCompletion(0, 0);

      notifier.addExercise(101, 'Bench Press',
          measurementType: 'weight_and_reps');
      notifier.updateSet(1, 0, weight: 80.0, reps: 5);
      notifier.toggleSetCompletion(1, 0);

      final (volume, completedSets) = notifier.sessionTotals;
      expect(completedSets, 2);
      expect(volume, 400.0); // (0 * 15) + (80 * 5)
    });
  });
}
