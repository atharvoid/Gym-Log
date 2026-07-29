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

    test(
        'inferLegacyMeasurementType classifies bodyweight vs assisted machine correctly',
        () {
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: 'Bodyweight', exerciseName: 'Push-up'),
          MeasurementType.repsOnly);
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: 'None', exerciseName: 'Air Squat'),
          MeasurementType.repsOnly);
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: 'Bodyweight', exerciseName: 'Plank Hold'),
          MeasurementType.duration);
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: 'Assisted', exerciseName: 'Assisted Pull-up'),
          MeasurementType.weightAndReps);
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: 'Assisted Machine', exerciseName: 'Assisted Dip'),
          MeasurementType.weightAndReps);
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: 'Barbell', exerciseName: 'Bench Press'),
          MeasurementType.weightAndReps);
    });

    test(
        'defaults to unknown when metadata is completely missing, and throws on unknown_type in fromString',
        () {
      expect(
          MeasurementType.inferLegacyMeasurementType(
              equipment: null, exerciseName: null),
          MeasurementType.unknown);
      expect(() => MeasurementType.fromString('unknown_type'),
          throwsArgumentError);
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
      final ex0 = container.read(activeWorkoutProvider)!.exercises[0];
      notifier.replaceSet(
          ex0.id, ex0.sets[0].id, ex0.sets[0].copyWith(reps: 15));
      notifier.toggleSetCompletion(0, 0);

      notifier.addExercise(101, 'Bench Press',
          measurementType: 'weight_and_reps');
      final ex1 = container.read(activeWorkoutProvider)!.exercises[1];
      notifier.replaceSet(ex1.id, ex1.sets[0].id,
          ex1.sets[0].copyWith(weightKg: 80.0, reps: 5));
      notifier.toggleSetCompletion(1, 0);

      final (volume, completedSets) = notifier.sessionTotals;
      expect(completedSets, 2);
      expect(volume, 400.0); // (0 * 15) + (80 * 5)
    });
  });
}
