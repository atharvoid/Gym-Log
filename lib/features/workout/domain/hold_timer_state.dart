import 'package:flutter/foundation.dart';

enum HoldTimerMode {
  countdown,
  stopwatch,
}

enum HoldTimerPhase {
  prep,
  holding,
  paused,
}

@immutable
class HoldTimerState {
  final String workoutId;
  final int exerciseIndex;
  final int setIndex;
  final String setId;
  final String exerciseName;
  final HoldTimerMode mode;
  final HoldTimerPhase phase;
  final int? targetSeconds;
  final int elapsedSeconds;
  final int prepSecondsRemaining;
  final DateTime startTime;
  final DateTime? pausedAt;
  final Duration totalPausedDuration;

  const HoldTimerState({
    required this.workoutId,
    required this.exerciseIndex,
    required this.setIndex,
    required this.setId,
    required this.exerciseName,
    required this.mode,
    required this.phase,
    this.targetSeconds,
    required this.elapsedSeconds,
    this.prepSecondsRemaining = 0,
    required this.startTime,
    this.pausedAt,
    this.totalPausedDuration = Duration.zero,
  });

  bool get isPrep => phase == HoldTimerPhase.prep;
  bool get isHolding => phase == HoldTimerPhase.holding;
  bool get isPaused => phase == HoldTimerPhase.paused;

  /// In countdown mode, remaining seconds to target. Can be negative in overtime.
  int? get remainingSeconds {
    if (targetSeconds == null) return null;
    return targetSeconds! - elapsedSeconds;
  }

  /// True when a countdown has elapsed past its target.
  bool get isOvertime =>
      mode == HoldTimerMode.countdown &&
      targetSeconds != null &&
      elapsedSeconds > targetSeconds!;

  /// The active number shown in the timer display.
  int get displaySeconds {
    if (isPrep) return prepSecondsRemaining;
    if (mode == HoldTimerMode.countdown && targetSeconds != null) {
      if (elapsedSeconds <= targetSeconds!) {
        return targetSeconds! - elapsedSeconds;
      } else {
        return elapsedSeconds - targetSeconds!; // overtime seconds
      }
    }
    return elapsedSeconds;
  }

  /// Formatted label, e.g. "0:45", "1:20", "+0:05", or "3s" during prep.
  String get formattedTime {
    if (isPrep) return '${prepSecondsRemaining}s';
    final secs = displaySeconds;
    final m = secs ~/ 60;
    final s = secs % 60;
    final timeStr = '$m:${s.toString().padLeft(2, '0')}';
    return isOvertime ? '+$timeStr' : timeStr;
  }

  /// Progress from 1.0 (start) down to 0.0 (reached target).
  double get progress {
    if (mode == HoldTimerMode.countdown &&
        targetSeconds != null &&
        targetSeconds! > 0) {
      final ratio = 1.0 - (elapsedSeconds / targetSeconds!);
      return ratio.clamp(0.0, 1.0);
    }
    return 1.0;
  }

  HoldTimerState copyWith({
    String? workoutId,
    int? exerciseIndex,
    int? setIndex,
    String? setId,
    String? exerciseName,
    HoldTimerMode? mode,
    HoldTimerPhase? phase,
    int? targetSeconds,
    int? elapsedSeconds,
    int? prepSecondsRemaining,
    DateTime? startTime,
    DateTime? pausedAt,
    Duration? totalPausedDuration,
  }) {
    return HoldTimerState(
      workoutId: workoutId ?? this.workoutId,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      setIndex: setIndex ?? this.setIndex,
      setId: setId ?? this.setId,
      exerciseName: exerciseName ?? this.exerciseName,
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      prepSecondsRemaining: prepSecondsRemaining ?? this.prepSecondsRemaining,
      startTime: startTime ?? this.startTime,
      pausedAt: pausedAt ?? this.pausedAt,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
    );
  }
}
