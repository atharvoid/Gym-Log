import 'dart:async';

import 'package:flutter/services.dart';
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
class RestTimerNotifier extends StateNotifier<RestTimerState?> {
  Timer? _ticker;

  RestTimerNotifier() : super(null);

  void start(int seconds) {
    _ticker?.cancel();
    state = RestTimerState(totalSeconds: seconds, remainingSeconds: seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final current = state;
    if (current == null) {
      _ticker?.cancel();
      return;
    }
    final remaining = current.remainingSeconds - 1;
    if (remaining <= 0) {
      _finish();
    } else {
      state = RestTimerState(
        totalSeconds: current.totalSeconds,
        remainingSeconds: remaining,
      );
    }
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    state = null;
    // Double buzz — felt even with the phone on the bench.
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();
  }

  void addSeconds(int delta) {
    final current = state;
    if (current == null) return;
    final remaining = (current.remainingSeconds + delta).clamp(1, 600);
    final total = delta > 0 && remaining > current.totalSeconds
        ? remaining
        : current.totalSeconds;
    state = RestTimerState(totalSeconds: total, remainingSeconds: remaining);
  }

  void skip() {
    _ticker?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState?>(
        (ref) => RestTimerNotifier());
