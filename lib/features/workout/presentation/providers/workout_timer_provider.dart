import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'active_workout_provider.dart';

part 'workout_timer_provider.g.dart';

@riverpod
class WorkoutTimer extends _$WorkoutTimer {
  Timer? _timer;

  @override
  String build() {
    final workout = ref.watch(activeWorkoutProvider);

    // Cleanup timer when provider is disposed
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    if (workout == null) {
      _timer?.cancel();
      _timer = null;
      return '00:00:00';
    }

    // Timer suppression for historical workout edits
    if (workout.originalSessionId != null &&
        workout.historicalDuration != null) {
      _timer?.cancel();
      _timer = null;
      return _formatDuration(workout.historicalDuration!);
    }

    _timer?.cancel();
    _updateElapsed(workout.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed(workout.startTime);
    });

    return state;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _updateElapsed(DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    state = '$h:$m:$s';
  }
}
