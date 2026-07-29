import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/workout_metric_summary.dart';

void main() {
  group('ATOMIC-RC3-14: WorkoutMetricSummary Projection Suite', () {
    test(
        'weighted workout projects VOLUME as primary metric label and formatted kg',
        () {
      const summary = WorkoutMetricSummary(
        weightedVolumeKg: 1250.0,
        totalReps: 50,
        totalDurationSeconds: 1800,
        totalDistanceMeters: 0.0,
      );

      expect(summary.hasWeightedVolume, isTrue);
      expect(summary.primaryMetricLabel(), equals('VOLUME'));
      expect(summary.primaryMetricValue(unit: 'kg'), equals('1250 kg'));
    });

    test(
        'reps-only / bodyweight workout projects REPS instead of volume default',
        () {
      const summary = WorkoutMetricSummary(
        weightedVolumeKg: 0.0,
        totalReps: 75,
        totalDurationSeconds: 1200,
        totalDistanceMeters: 0.0,
      );

      expect(summary.hasWeightedVolume, isFalse);
      expect(summary.primaryMetricLabel(), equals('REPS'));
      expect(summary.primaryMetricValue(), equals('75 reps'));
    });

    test('distance workout projects DISTANCE instead of volume default', () {
      const summary = WorkoutMetricSummary(
        weightedVolumeKg: 0.0,
        totalReps: 0,
        totalDurationSeconds: 2400,
        totalDistanceMeters: 5000.0,
      );

      expect(summary.hasWeightedVolume, isFalse);
      expect(summary.primaryMetricLabel(), equals('DISTANCE'));
      expect(summary.primaryMetricValue(), equals('5.0 km'));
    });

    test('duration-only workout projects DURATION instead of volume default',
        () {
      const summary = WorkoutMetricSummary(
        weightedVolumeKg: 0.0,
        totalReps: 0,
        totalDurationSeconds: 900,
        totalDistanceMeters: 0.0,
      );

      expect(summary.hasWeightedVolume, isFalse);
      expect(summary.primaryMetricLabel(), equals('DURATION'));
      expect(summary.primaryMetricValue(), equals('15m'));
    });
  });
}
