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
}
