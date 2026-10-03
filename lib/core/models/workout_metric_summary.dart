import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

class WorkoutMetricSummary {
  final double weightedVolumeKg;
  final int totalReps;
  final int totalDurationSeconds;
  final double totalDistanceMeters;
  final int completedSets;

  const WorkoutMetricSummary({
    required this.weightedVolumeKg,
    required this.totalReps,
    required this.totalDurationSeconds,
    required this.totalDistanceMeters,
    this.completedSets = 0,
  });

  factory WorkoutMetricSummary.fromWorkout(ActiveWorkoutState? workout) {
    double volume = 0, distance = 0;
    int reps = 0, seconds = 0, completed = 0;
    for (final exercise in workout?.exercises ?? <WorkoutExerciseState>[]) {
      for (final set in exercise.sets.where((s) => s.isCompleted)) {
        completed++;
        switch (exercise.resolvedMeasurementType) {
          case MeasurementType.weightAndReps:
            volume += (set.weightKg ?? 0) * set.reps;
            reps += set.reps;
          case MeasurementType.repsOnly:
            reps += set.reps;
          case MeasurementType.duration:
            seconds += set.reps;
          case MeasurementType.distance:
            distance += set.weightKg ?? 0;
            seconds += set.reps;
          case MeasurementType.unknown:
            break;
        }
      }
    }
    return WorkoutMetricSummary(
        weightedVolumeKg: volume,
        totalReps: reps,
        totalDurationSeconds: seconds,
        totalDistanceMeters: distance,
        completedSets: completed);
  }

  static const empty = WorkoutMetricSummary(
    weightedVolumeKg: 0.0,
    totalReps: 0,
    totalDurationSeconds: 0,
    totalDistanceMeters: 0.0,
  );

  /// Returns true if this summary contains weighted volume.
  bool get hasWeightedVolume => weightedVolumeKg > 0;

  /// Returns the primary metric label for display in summary projections.
  /// Weighted workouts project 'VOLUME', reps-only workouts project 'REPS',
  /// distance workouts project 'DISTANCE', and duration workouts project 'DURATION'.
  String primaryMetricLabel() {
    if (hasWeightedVolume) {
      return 'VOLUME';
    } else if (totalReps > 0) {
      return 'REPS';
    } else if (totalDistanceMeters > 0) {
      return 'DISTANCE';
    } else {
      return 'DURATION';
    }
  }

  /// Returns the formatted primary metric value.
  String primaryMetricValue({String unit = 'kg'}) {
    if (hasWeightedVolume) {
      return formatVolume(weightedVolumeKg, unit);
    } else if (totalReps > 0) {
      return '$totalReps reps';
    } else if (totalDistanceMeters > 0) {
      if (totalDistanceMeters < 1000) {
        final metres = totalDistanceMeters;
        return '${metres == metres.truncateToDouble() ? metres.toInt() : metres.toStringAsFixed(1)} m';
      }
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    } else {
      final m = totalDurationSeconds ~/ 60;
      final s = totalDurationSeconds % 60;
      return s == 0 && m > 0
          ? '${m}m'
          : m > 0
              ? '${m}m ${s}s'
              : '${s}s';
    }
  }
}
