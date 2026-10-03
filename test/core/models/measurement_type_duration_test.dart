import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';

void main() {
  group('MeasurementType Duration Taxonomy & Resolver', () {
    test('resolves isometric and duration exercises to duration', () {
      final durationNames = [
        'Plank',
        'Front Plank',
        'Side Plank',
        'Reverse Plank',
        'Copenhagen Plank',
        'Dead Hang',
        'dead hang',
        'Deadhang',
        'deadhang',
        'Passive Hang',
        'Active Hang',
        'Bar Hang',
        'Scapular Hang',
        'Pec Stretch',
        'pec stretch',
        'Chest Stretch',
        'Lat Stretch',
        'Shoulder Stretch',
        'Hamstring Stretch',
        'Quad Stretch',
        'Calf Stretch',
        'Hip Flexor Stretch',
        'Biceps Stretch',
        'Triceps Stretch',
        'Static Stretch',
        'Wall Sit',
        'L-Sit',
        'V-Sit',
        'Hollow Body Hold',
        'Hollow Hold',
        'Arch Hold',
        'Superman Hold',
        'Bridge Hold',
        'Handstand Hold',
      ];

      for (final name in durationNames) {
        final resolved = MeasurementType.resolve(
          explicitValue: null,
          equipment: 'bodyweight',
          exerciseName: name,
        );
        expect(
          resolved,
          MeasurementType.duration,
          reason: '$name should resolve to MeasurementType.duration',
        );
      }
    });

    test('preserves Olympic barbell and dumbbell lifts with hang as weighted',
        () {
      final olympicHangs = [
        'Hang Clean',
        'Dumbbell Hang Clean',
        'Hang Power Clean',
        'Hang Snatch',
        'Hang Power Snatch',
        'Hang High Pull',
      ];

      for (final name in olympicHangs) {
        final resolved = MeasurementType.resolve(
          explicitValue: null,
          equipment: 'barbell',
          exerciseName: name,
        );
        expect(
          resolved,
          MeasurementType.weightAndReps,
          reason: '$name must remain MeasurementType.weightAndReps',
        );
      }
    });

    test('explicit exceptions override default weight_and_reps', () {
      // Even if legacy explicit value defaulted to weight_and_reps in db,
      // explicit duration exercises like plank or deadhang resolve to duration
      final resolvedPlank = MeasurementType.resolve(
        explicitValue: 'weight_and_reps',
        equipment: 'bodyweight',
        exerciseName: 'Plank',
      );
      expect(resolvedPlank, MeasurementType.duration);

      final resolvedDeadHang = MeasurementType.resolve(
        explicitValue: 'weight_and_reps',
        equipment: 'bodyweight',
        exerciseName: 'Dead Hang',
      );
      expect(resolvedDeadHang, MeasurementType.duration);

      final resolvedPecStretch = MeasurementType.resolve(
        explicitValue: 'weight_and_reps',
        equipment: 'bodyweight',
        exerciseName: 'Pec Stretch',
      );
      expect(resolvedPecStretch, MeasurementType.duration);
    });

    test('repsColumnLabel is TIME for duration', () {
      expect(MeasurementType.duration.repsColumnLabel, 'TIME');
    });

    test('weighted duration shows weight column and provides +KG header', () {
      const weightedPlank = 'Weighted Front Plank';
      const bodyweightPlank = 'Front Plank';

      expect(
        MeasurementType.duration.showsWeightColumnFor(weightedPlank),
        isTrue,
      );
      expect(
        MeasurementType.duration.showsWeightColumnFor(bodyweightPlank),
        isFalse,
      );
      expect(
        MeasurementType.duration.fixedWeightColumnLabelFor(weightedPlank, 'kg'),
        '+KG',
      );
      expect(
        MeasurementType.duration
            .fixedWeightColumnLabelFor(weightedPlank, 'lbs'),
        '+LBS',
      );
    });

    test('dynamic hanging exercises resolve to reps, not duration', () {
      final dynamicHangingExercises = [
        'Hanging Leg Raise',
        'hanging leg raise',
        'Hanging Knee Raise',
        'Hanging Windshield Wipers',
      ];

      for (final name in dynamicHangingExercises) {
        final resolved = MeasurementType.resolve(
          explicitValue: null,
          equipment: 'bodyweight',
          exerciseName: name,
        );
        expect(
          resolved,
          isNot(MeasurementType.duration),
          reason: '$name must not resolve to duration',
        );
      }
    });
  });
}
