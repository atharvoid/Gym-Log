import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstRunTourNotifier extends StateNotifier<int> {
  static const _key = 'first_run_tour_step';

  /// Single source of truth for tour length.
  /// Tasks A–C keep this at 5: Explore → Add → View/Start → Rest → Stats.
  static const int totalSteps = 5;

  /// Sentinel value meaning "the user chose 'Take the tour' but the app is
  /// still empty, so the masked walkthrough is deferred until real content
  /// (a routine or workout) exists." Stored under the same prefs key as step.
  static const int deferredStep = -2;

  FirstRunTourNotifier() : super(-1) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? -1;
  }

  Future<void> setStep(int step) async {
    state = step;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, step);
  }

  Future<void> reset() async {
    await setStep(0);
  }

  Future<void> nextStep() async {
    if (state == -1 || state == deferredStep) return;
    if (state >= totalSteps - 1) {
      await setStep(-1); // Tour completed!
    } else {
      await setStep(state + 1);
    }
  }

  Future<void> skipOrEnd() async {
    await setStep(-1);
  }
}

final firstRunTourProvider =
    StateNotifierProvider<FirstRunTourNotifier, int>((ref) {
  return FirstRunTourNotifier();
});
