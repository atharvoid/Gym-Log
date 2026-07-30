import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shortest rest a running timer may hold. Zero means "no rest", which is
/// represented by a null state rather than a 0-second countdown.
const int kRestMinRunningSeconds = 1;

/// Longest rest the app allows. The rest slider and every +/- control clamp to
/// this, so the UI can never offer a value this notifier would reject.
const int kRestMaxSeconds = 600;

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;

  const RestTimerState({
    required this.totalSeconds,
    required this.remainingSeconds,
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
  Timer? _ticker;
  DateTime? _endTime;
  int _totalSeconds = 0;
  bool _finished = false;

  RestTimerNotifier() : super(null) {
    WidgetsBinding.instance.addObserver(this);
  }

  void start(int seconds) {
    if (seconds <= 0) return; // "Off" — never spin up a 0-second countdown
    _ticker?.cancel();
    _finished = false;
    _totalSeconds = seconds;
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    state = RestTimerState(totalSeconds: seconds, remainingSeconds: seconds);
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
      );
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _endTime = null;
    state = null;
    // Double buzz — felt even with the phone on the bench.
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();
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
    _totalSeconds = math_max(remaining, _totalSeconds);
    _endTime = DateTime.now().add(Duration(seconds: remaining));
    state = RestTimerState(
      totalSeconds: _totalSeconds,
      remainingSeconds: remaining,
    );
  }

  void skip() {
    _ticker?.cancel();
    _endTime = null;
    state = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _endTime != null) {
      _sync();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Local int max — avoids importing dart:math into a provider for one call.
int math_max(int a, int b) => a > b ? a : b;

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState?>(
        (ref) => RestTimerNotifier());
