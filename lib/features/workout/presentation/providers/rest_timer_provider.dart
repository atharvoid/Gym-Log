import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_event_provider.dart';
import 'active_workout_provider.dart';
import '../../../../core/services/notification_service.dart';

/// Shortest rest a running timer may hold. Zero means "no rest", which is
/// represented by a null state rather than a 0-second countdown.
const int kRestMinRunningSeconds = 1;

/// Longest rest the app allows. The rest slider and every +/- control clamp to
/// this, so the UI can never offer a value this notifier would reject.
const int kRestMaxSeconds = 600;

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final DateTime endTime;

  // Timer Context Identity
  final String workoutId;
  final int exerciseId;
  final String setId;
  final String? exerciseName;

  const RestTimerState({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.endTime,
    required this.workoutId,
    required this.exerciseId,
    required this.setId,
    this.exerciseName,
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
  String? _currentExerciseName;

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
    String? exerciseName,
  }) {
    if (seconds <= 0) return; // "Off" — never spin up a 0-second countdown
    _ticker?.cancel();
    _finished = false;
    _totalSeconds = seconds;
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    _currentWorkoutId = workoutId;
    _currentExerciseId = exerciseId;
    _currentSetId = setId;
    _currentExerciseName = exerciseName;

    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      endTime: _endTime!,
      workoutId: workoutId,
      exerciseId: exerciseId,
      setId: setId,
      exerciseName: exerciseName,
    );

    // Fire TimerStartedEvent
    _ref.read(workoutEventBusProvider).fire(TimerStartedEvent(
          seconds: seconds,
          workoutId: workoutId,
          exerciseId: exerciseId,
          setId: setId,
          exerciseName: exerciseName,
        ));

    // D42: ask for notification permission here — the first moment the user
    // is actually experiencing the feature the permission is for ("notify me
    // when rest is over") — instead of at cold start (see bootstrap.dart).
    // Cold start had no context for the OS prompt: a user who had not yet
    // started a single set, let alone backgrounded the app mid-rest, could
    // permanently lose the ability to be re-prompted (both platforms suppress
    // the native dialog after one decision) for a feature they had not yet
    // seen. hasPermission() is checked first so this is a no-op once already
    // resolved, rather than a platform-channel round trip on every set.
    unawaited(_ensureNotificationPermission());

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
      // The timer expired while the app was suspended. Take the exact same
      // completion path as the live ticker would have — TimerExpiredEvent,
      // haptic buzz, and sound — instead of silently dropping the rest.
      _currentWorkoutId = workoutId;
      _currentExerciseId = exerciseId;
      _currentSetId = setId;
      _finish();
      return;
    }
    _ticker?.cancel();
    _finished = false;
    _totalSeconds = totalSeconds;
    _endTime = endTime;
    _currentWorkoutId = workoutId;
    _currentExerciseId = exerciseId;
    _currentSetId = setId;

    // Clamp for the same reason as _sync(): a clock that moved backward
    // between persisting endTime and resuming must not resurrect more time
    // than the timer originally had.
    final clampedRemaining = math.min(remaining, totalSeconds);
    state = RestTimerState(
      totalSeconds: totalSeconds,
      remainingSeconds: clampedRemaining,
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
      // Clamp to _totalSeconds: a backward clock jump (DST fall-back, manual
      // clock change) must never make the countdown appear to grow past its
      // starting value.
      final clampedRemaining = math.min(remaining, _totalSeconds);
      state = RestTimerState(
        totalSeconds: _totalSeconds,
        remainingSeconds: clampedRemaining,
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
          exerciseName: _currentExerciseName,
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
    if (current == null) return;
    setRemaining(current.remainingSeconds + delta);
  }

  /// Sets the remaining rest to an ABSOLUTE value.
  ///
  /// Scrubbing used to be expressed as repeated [addSeconds] deltas, which
  /// recomputed `_totalSeconds` on every step and made the ring progress drift
  /// (the denominator kept growing as you dragged). Setting an absolute value
  /// keeps the ring honest: the total only ever grows to accommodate a longer
  /// remaining time, never as a side effect of many small nudges.
  void setRemaining(int seconds) {
    final current = state;
    final end = _endTime;
    if (current == null || end == null) return;
    final remaining = seconds.clamp(kRestMinRunningSeconds, kRestMaxSeconds);
    _totalSeconds = math.max(remaining, _totalSeconds);
    _endTime = DateTime.now().add(Duration(seconds: remaining));
    state = RestTimerState(
      totalSeconds: _totalSeconds,
      remainingSeconds: remaining,
      endTime: _endTime!,
      workoutId: current.workoutId,
      exerciseId: current.exerciseId,
      setId: current.setId,
      exerciseName: current.exerciseName,
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
          unawaited(_scheduleNotificationIfPermitted(
            exerciseName: exerciseName,
            endTime: end,
          ));
        }
      }
    }
  }

  Future<void> _scheduleNotificationIfPermitted({
    required String exerciseName,
    required DateTime endTime,
  }) async {
    final notifService = _ref.read(notificationServiceProvider);
    final permitted = await notifService.hasPermission();
    if (permitted) {
      notifService.scheduleRestTimerNotification(
        exerciseName: exerciseName,
        endTime: endTime,
      );
    }
  }

  /// Requests notification permission if not already granted. Called from
  /// [start] — see the D42 comment there for why this replaced the
  /// unconditional cold-start request in bootstrap.dart.
  Future<void> _ensureNotificationPermission() async {
    final notifService = _ref.read(notificationServiceProvider);
    final already = await notifService.hasPermission();
    if (already) return;
    await notifService.requestPermissions();
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
