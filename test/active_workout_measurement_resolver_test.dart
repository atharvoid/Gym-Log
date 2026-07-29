import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

void main() {
  group('ATOMIC-RC3-03 Measurement Resolver Invariants', () {
    test('1. MeasurementType.tryParse basic and malformed inputs', () {
      expect(MeasurementType.tryParse('weight_and_reps'),
          MeasurementType.weightAndReps);
      expect(MeasurementType.tryParse('reps_only'), MeasurementType.repsOnly);
      expect(MeasurementType.tryParse('duration'), MeasurementType.duration);
      expect(MeasurementType.tryParse('distance'), MeasurementType.distance);
      expect(MeasurementType.tryParse('unknown'), MeasurementType.unknown);

      // case insensitivity and whitespace stripping
      expect(MeasurementType.tryParse('  Weight_And_Reps  '),
          MeasurementType.weightAndReps);
      expect(MeasurementType.tryParse('RepsOnly'), MeasurementType.repsOnly);

      // missing, null, empty, unknown
      expect(MeasurementType.tryParse(null), isNull);
      expect(MeasurementType.tryParse(''), isNull);
      expect(MeasurementType.tryParse('garbage'), isNull);
    });

    test('2. MeasurementType.fromString throws on invalid input', () {
      expect(() => MeasurementType.fromString('garbage'), throwsArgumentError);
      expect(() => MeasurementType.fromString(null), throwsArgumentError);
      expect(() => MeasurementType.fromString(''), throwsArgumentError);
      expect(MeasurementType.fromString('reps_only'), MeasurementType.repsOnly);
    });

    test('3. MeasurementType.resolve explicit value resolution', () {
      // Explicit overrides legacy inference
      expect(
        MeasurementType.resolve(
          explicitValue: 'duration',
          equipment: 'barbell',
          exerciseName: 'Bench Press',
        ),
        MeasurementType.duration,
      );

      expect(
        MeasurementType.resolve(
          explicitValue: 'reps_only',
          equipment: 'machine',
          exerciseName: 'Leg Press',
        ),
        MeasurementType.repsOnly,
      );
    });

    test('4. Legacy inference rules', () {
      // Planks, wall sits, holds are duration
      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'bodyweight',
          exerciseName: 'Plank Hold',
        ),
        MeasurementType.duration,
      );

      // Pushups, pullups, chin-ups, situps, crunches, jumping jacks are repsOnly
      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'bodyweight',
          exerciseName: 'Wide Grip Pull-up',
        ),
        MeasurementType.repsOnly,
      );

      // Dips default to repsOnly
      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'bodyweight',
          exerciseName: 'Chest Dip',
        ),
        MeasurementType.repsOnly,
      );

      // Assisted / counterweight exercises remain weighted
      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'bodyweight',
          exerciseName: 'Assisted Pull-up',
        ),
        MeasurementType.weightAndReps,
      );

      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'assisted',
          exerciseName: 'Dips',
        ),
        MeasurementType.weightAndReps,
      );

      // Barbells, dumbbells, cables, machines, kettlebells, smith, plate, band are weighted
      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'dumbbell',
          exerciseName: 'Bicep Curl',
        ),
        MeasurementType.weightAndReps,
      );

      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: 'kettlebell',
          exerciseName: 'Swing',
        ),
        MeasurementType.weightAndReps,
      );

      // Missing metadata completely defaults to unknown
      expect(
        MeasurementType.resolve(
          explicitValue: null,
          equipment: null,
          exerciseName: 'Custom Exercise',
        ),
        MeasurementType.unknown,
      );
    });

    test('5. WorkoutExerciseState resolvedMeasurementType and defaults', () {
      // Exposes resolvedMeasurementType and defaults to unknown
      const ex1 = WorkoutExerciseState(
        id: 'we1',
        exerciseId: 1,
        name: 'Bench Press',
      );
      expect(ex1.measurementType, 'unknown');
      expect(ex1.resolvedMeasurementType, MeasurementType.unknown);

      // Resolves explicitly stored types
      const ex2 = WorkoutExerciseState(
        id: 'we2',
        exerciseId: 2,
        name: 'Bench Press',
        measurementType: 'weight_and_reps',
      );
      expect(ex2.resolvedMeasurementType, MeasurementType.weightAndReps);

      // Resolves empty type using legacy inference on name
      const ex3 = WorkoutExerciseState(
        id: 'we3',
        exerciseId: 3,
        name: 'Pushup',
        measurementType: '',
      );
      expect(ex3.resolvedMeasurementType, MeasurementType.repsOnly);
    });
  });
}
