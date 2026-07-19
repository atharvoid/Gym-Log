import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_event_provider.dart';
import 'active_workout_provider.dart';
import '../../../../core/services/notification_service.dart';

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final DateTime endTime;

  // Timer Context Identity
  final String workoutId;
  final int exerciseId;
  final String setId;

  const RestTimerState({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.endTime,
    required this.workoutId,
    required this.exerciseId,
    required this.setId,
  });

  double get progress =>
      totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;
}

/// Between-set rest countdown. Auto-started on set completion, dismissible,
/// extendable in ±15s steps. Buzzes twice at zero — the cue to load the bar.
///
/// The countdown is anchored to an absolute wall-clock [_endTime] rather than a
/// naive per-tick decrement, so it stays accurate across app backgrounding: the
/// 1s ticker only samples the clock, and an [AppLifecycleState.resumed] event
/// re-syncs (and fires completion if the timer expired while suspended).
class RestTimerNotifier extends StateNotifier<RestTimerState?>
    with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _ticker;
  DateTime? _endTime;
  int _totalSeconds = 0;
  bool _finished = false;

  String _currentWorkoutId = '';
  int _currentExerciseId = 0;
  String _currentSetId = '';

  RestTimerNotifier(this._ref) : super(null) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  void start({
    required int seconds,
    required String workoutId,
    required int exerciseId,
    required String setId,
  }) {
    _ticker?.cancel();
    _finished = false;
    _totalSeconds = seconds;
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    _currentWorkoutId = workoutId;
    _currentExerciseId = exerciseId;
    _currentSetId = setId;

    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      endTime: _endTime!,
      workoutId: workoutId,
      exerciseId: exerciseId,
      setId: setId,
    );

    // Fire TimerStartedEvent
    _ref.read(workoutEventBusProvider).fire(TimerStartedEvent(
          seconds: seconds,
          workoutId: workoutId,
          exerciseId: exerciseId,
          setId: setId,
        ));

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
  }

  /// Resumes an active rest timer from a persisted absolute wall-clock [_endTime].
  void resumeFromEndTime({
    required DateTime endTime,
    required int totalSeconds,
    required String workoutId,
    required int exerciseId,
    required String setId,
  }) {
    final remaining = endTime.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _finished = true;
      _ticker?.cancel();
      _endTime = null;
      state = null;
      return;
    }
    _ticker?.cancel();
    _finished = false;
    _totalSeconds = totalSeconds;
    _endTime = endTime;
    _currentWorkoutId = workoutId;
    _currentExerciseId = exerciseId;
    _currentSetId = setId;

    state = RestTimerState(
      totalSeconds: totalSeconds,
      remainingSeconds: remaining,
      endTime: endTime,
      workoutId: workoutId,
      exerciseId: exerciseId,
      setId: setId,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
  }

  /// Recomputes remaining seconds from the wall clock. Safe to call on every
  /// tick and on resume.
  void _sync() {
    final end = _endTime;
    if (end == null) {
      _ticker?.cancel();
      return;
    }
    final remaining = end.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _finish();
    } else {
      state = RestTimerState(
        totalSeconds: _totalSeconds,
        remainingSeconds: remaining,
        endTime: end,
        workoutId: _currentWorkoutId,
        exerciseId: _currentExerciseId,
        setId: _currentSetId,
      );
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _endTime = null;
    state = null;

    // Fire TimerExpiredEvent
    _ref.read(workoutEventBusProvider).fire(TimerExpiredEvent(
          workoutId: _currentWorkoutId,
          exerciseId: _currentExerciseId,
          setId: _currentSetId,
        ));

    // Double buzz — felt even with the phone on the bench.
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();

    // Respect silent mode / play foreground sound
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  void addSeconds(int delta) {
    final current = state;
    final end = _endTime;
    if (current == null || end == null) return;
    final remaining = (current.remainingSeconds + delta).clamp(1, 600);
    final total =
        delta > 0 && remaining > _totalSeconds ? remaining : _totalSeconds;
    _totalSeconds = total;
    _endTime = DateTime.now().add(Duration(seconds: remaining));
    state = RestTimerState(
      totalSeconds: total,
      remainingSeconds: remaining,
      endTime: _endTime!,
      workoutId: current.workoutId,
      exerciseId: current.exerciseId,
      setId: current.setId,
    );
  }

  void skip() {
    _ticker?.cancel();
    _endTime = null;
    _currentWorkoutId = '';
    _currentExerciseId = 0;
    _currentSetId = '';
    state = null;

    // Fire TimerCancelledEvent
    _ref.read(workoutEventBusProvider).fire(const TimerCancelledEvent());
    _ref.read(notificationServiceProvider).cancelRestTimerNotification();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Returned to foreground -> cancel background notifications to prevent duplicate sound/haptics
      _ref.read(notificationServiceProvider).cancelRestTimerNotification();
      if (_endTime != null) {
        _sync();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background -> schedule exact local notification
      final end = _endTime;
      if (end != null) {
        final remaining = end.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          final workout = _ref.read(activeWorkoutProvider);
          String exerciseName = 'Exercise';
          if (workout != null) {
            final exIndex = workout.exercises
                .indexWhere((e) => e.exerciseId == _currentExerciseId);
            if (exIndex != -1) {
              exerciseName = workout.exercises[exIndex].name;
            }
          }
          _ref.read(notificationServiceProvider).scheduleRestTimerNotification(
                exerciseName: exerciseName,
                endTime: end,
              );
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState?>(
        (ref) => RestTimerNotifier(ref));
