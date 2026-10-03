import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/hold_timer_state.dart';
import 'active_workout_provider.dart';
import 'rest_timer_provider.dart';

class HoldTimerNotifier extends StateNotifier<HoldTimerState?>
    with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _ticker;

  HoldTimerNotifier(this._ref) : super(null) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  void start({
    required String workoutId,
    required int exerciseIndex,
    required int setIndex,
    required String setId,
    required String exerciseName,
    int? targetSeconds,
    bool enablePrep = true,
  }) {
    // Cancel any running rest timer when starting a hold
    _ref.read(restTimerProvider.notifier).skip();
    _ticker?.cancel();

    final mode = (targetSeconds != null && targetSeconds > 0)
        ? HoldTimerMode.countdown
        : HoldTimerMode.stopwatch;

    final initialPhase =
        enablePrep ? HoldTimerPhase.prep : HoldTimerPhase.holding;
    final now = DateTime.now();

    state = HoldTimerState(
      workoutId: workoutId,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      setId: setId,
      exerciseName: exerciseName,
      mode: mode,
      phase: initialPhase,
      targetSeconds: targetSeconds,
      elapsedSeconds: 0,
      prepSecondsRemaining: enablePrep ? 3 : 0,
      startTime: now,
    );

    if (enablePrep) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    final current = state;
    if (current == null) {
      _ticker?.cancel();
      return;
    }

    if (current.phase == HoldTimerPhase.prep) {
      final nextPrep = current.prepSecondsRemaining - 1;
      if (nextPrep > 0) {
        state = current.copyWith(prepSecondsRemaining: nextPrep);
        HapticFeedback.lightImpact();
      } else {
        // Prep finished -> Begin holding!
        state = current.copyWith(
          phase: HoldTimerPhase.holding,
          prepSecondsRemaining: 0,
          startTime: DateTime.now(),
          elapsedSeconds: 0,
        );
        HapticFeedback.heavyImpact();
        try {
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
      return;
    }

    if (current.phase == HoldTimerPhase.holding) {
      final now = DateTime.now();
      final wallElapsed =
          now.difference(current.startTime) - current.totalPausedDuration;
      final elapsed = math.max(0, wallElapsed.inSeconds);

      // Check if just reached target in countdown mode
      final wasBelowTarget = current.targetSeconds != null &&
          current.elapsedSeconds < current.targetSeconds!;
      final nowReachedTarget =
          current.targetSeconds != null && elapsed >= current.targetSeconds!;

      state = current.copyWith(elapsedSeconds: elapsed);

      if (wasBelowTarget && nowReachedTarget) {
        // Cue lifter that target time was hit!
        HapticFeedback.heavyImpact();
        try {
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    }
  }

  void skipPrep() {
    final current = state;
    if (current == null || current.phase != HoldTimerPhase.prep) return;

    state = current.copyWith(
      phase: HoldTimerPhase.holding,
      prepSecondsRemaining: 0,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
    );
    HapticFeedback.heavyImpact();
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  void pause() {
    final current = state;
    if (current == null || current.phase != HoldTimerPhase.holding) return;

    state = current.copyWith(
      phase: HoldTimerPhase.paused,
      pausedAt: DateTime.now(),
    );
    HapticFeedback.selectionClick();
  }

  void resume() {
    final current = state;
    if (current == null || current.phase != HoldTimerPhase.paused) return;

    final pauseDuration = current.pausedAt != null
        ? DateTime.now().difference(current.pausedAt!)
        : Duration.zero;

    state = current.copyWith(
      phase: HoldTimerPhase.holding,
      pausedAt: null,
      totalPausedDuration: current.totalPausedDuration + pauseDuration,
    );
    HapticFeedback.selectionClick();
  }

  void addSeconds(int delta) {
    final current = state;
    if (current == null) return;

    if (current.mode == HoldTimerMode.countdown) {
      final nextTarget = ((current.targetSeconds ?? 30) + delta).clamp(5, 3600);
      state = current.copyWith(targetSeconds: nextTarget);
    } else {
      // Stopwatch mode: shifting elapsed seconds shifts effective startTime
      final nextElapsed = (current.elapsedSeconds + delta).clamp(0, 3600);
      final newStartTime = DateTime.now()
          .subtract(Duration(seconds: nextElapsed))
          .subtract(current.totalPausedDuration);
      state = current.copyWith(
        elapsedSeconds: nextElapsed,
        startTime: newStartTime,
      );
    }
    HapticFeedback.selectionClick();
  }

  void finishAndLog() {
    final s = state;
    if (s == null) return;
    _ticker?.cancel();

    // Log at least 1 second if stopped early
    final loggedSeconds = math.max(1, s.elapsedSeconds);
    final workout = _ref.read(activeWorkoutProvider);

    if (workout != null && s.exerciseIndex < workout.exercises.length) {
      final ex = workout.exercises[s.exerciseIndex];
      if (s.setIndex < ex.sets.length) {
        final currentSet = ex.sets[s.setIndex];

        // Commit elapsed seconds into reps
        _ref.read(activeWorkoutProvider.notifier).replaceSet(
              ex.id,
              s.setId,
              currentSet.copyWith(reps: loggedSeconds),
            );

        // Mark set completed if not already completed
        if (!currentSet.isCompleted) {
          _ref
              .read(activeWorkoutProvider.notifier)
              .toggleSetCompletion(s.exerciseIndex, s.setIndex);
        }

        // Start rest timer if rest interval is configured
        final int restSecs =
            ex.restSecondsOverride ?? _ref.read(defaultRestSecondsProvider);
        if (restSecs > 0) {
          _ref.read(restTimerProvider.notifier).start(
                seconds: restSecs,
                workoutId: workout.id,
                exerciseId: ex.exerciseId,
                setId: s.setId,
                exerciseName: ex.name,
              );
        }
      }
    }

    HapticFeedback.heavyImpact();
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    state = null;
  }

  void cancel() {
    _ticker?.cancel();
    state = null;
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Resumed from background or lock screen -> re-sync wall clock
      final current = this.state;
      if (current != null && current.phase == HoldTimerPhase.holding) {
        final now = DateTime.now();
        final wallElapsed =
            now.difference(current.startTime) - current.totalPausedDuration;
        this.state = current.copyWith(
          elapsedSeconds: math.max(0, wallElapsed.inSeconds),
        );
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

final holdTimerProvider =
    StateNotifierProvider<HoldTimerNotifier, HoldTimerState?>(
  (ref) => HoldTimerNotifier(ref),
);
