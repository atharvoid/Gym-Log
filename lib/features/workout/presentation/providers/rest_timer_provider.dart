import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final end = _endTime;
    if (current == null || end == null) return;
    final remaining = (current.remainingSeconds + delta).clamp(1, 600);
    final total =
        delta > 0 && remaining > _totalSeconds ? remaining : _totalSeconds;
    _totalSeconds = total;
    _endTime = DateTime.now().add(Duration(seconds: remaining));
    state = RestTimerState(totalSeconds: total, remainingSeconds: remaining);
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

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState?>(
        (ref) => RestTimerNotifier());
