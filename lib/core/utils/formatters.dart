String formatWorkoutDuration(DateTime start, DateTime? end) {
  final duration = end != null ? end.difference(start) : DateTime.now().difference(start);
  
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
  if (existingName != null && existingName.isNotEmpty && existingName != 'Workout') {
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
