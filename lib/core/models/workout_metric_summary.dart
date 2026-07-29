class WorkoutMetricSummary {
  final double weightedVolumeKg;
  final int totalReps;
  final int totalDurationSeconds;
  final double totalDistanceMeters;

  const WorkoutMetricSummary({
    required this.weightedVolumeKg,
    required this.totalReps,
    required this.totalDurationSeconds,
    required this.totalDistanceMeters,
  });

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
      final formatted = weightedVolumeKg.toStringAsFixed(
          weightedVolumeKg.truncateToDouble() == weightedVolumeKg ? 0 : 1);
      return '$formatted $unit';
    } else if (totalReps > 0) {
      return '$totalReps reps';
    } else if (totalDistanceMeters > 0) {
      final km = totalDistanceMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    } else {
      final m = totalDurationSeconds ~/ 60;
      return '${m}m';
    }
  }
}
