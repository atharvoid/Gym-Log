import '../models/measurement_type.dart';

String formatWorkoutDuration(DateTime start, DateTime? end) {
  final duration =
      end != null ? end.difference(start) : DateTime.now().difference(start);

  if (duration.inHours > 0) {
    final minutes = duration.inMinutes % 60;
    return '${duration.inHours}h ${minutes}m';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  } else {
    return '${duration.inSeconds}s';
  }
}

String getWorkoutNameFallback(DateTime start, String? existingName) {
  if (existingName != null &&
      existingName.isNotEmpty &&
      existingName != 'Workout') {
    return existingName;
  }

  final hour = start.hour;
  if (hour >= 5 && hour < 12) {
    return 'Morning Workout';
  } else if (hour >= 12 && hour < 17) {
    return 'Afternoon Workout';
  } else if (hour >= 17 && hour < 21) {
    return 'Evening Workout';
  } else {
    return 'Night Workout';
  }
}

class MeasurementFormatter {
  /// Formats a set's logged metrics based strictly on canonical [MeasurementType].
  /// Never infers from raw equipment text in presentation code.
  static String formatSet({
    required MeasurementType measurementType,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    String? equipment,
  }) {
    switch (measurementType) {
      case MeasurementType.weightAndReps:
        final w = weightKg ?? 0;
        final wStr = (w == w.truncateToDouble())
            ? '${w.toInt()} kg'
            : '${w.toStringAsFixed(1)} kg';
        final isBw = equipment?.toLowerCase() == 'body weight';
        final prefix = (isBw && w > 0) ? '+' : '';
        final r = reps ?? 0;
        return '$prefix$wStr × $r';
      case MeasurementType.repsOnly:
        final r = reps ?? 0;
        return '$r reps';
      case MeasurementType.duration:
        final secs = durationSeconds ?? reps ?? 0;
        final mins = secs ~/ 60;
        final s = secs % 60;
        return '$mins:${s.toString().padLeft(2, '0')}';
      case MeasurementType.distance:
        final dist = distanceMeters ?? weightKg ?? 0;
        final distKm = dist / 1000.0;
        final distStr = (distKm >= 1.0)
            ? '${distKm.toStringAsFixed(1)} km'
            : '${dist.toInt()} m';
        final secs = durationSeconds ?? reps ?? 0;
        if (secs > 0) {
          final mins = secs ~/ 60;
          final s = secs % 60;
          final timeStr = '$mins:${s.toString().padLeft(2, '0')}';
          return '$distStr · $timeStr';
        }
        return distStr;
    }
  }

  /// Formats pace in MM:SS /km from distance in meters and duration in seconds.
  static String formatPace(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0 || durationSeconds <= 0) return '—';
    final paceSecsPerKm = (durationSeconds / (distanceMeters / 1000.0)).round();
    final mins = paceSecsPerKm ~/ 60;
    final secs = paceSecsPerKm % 60;
    return '$mins:${secs.toString().padLeft(2, '0')} /km';
  }
}
