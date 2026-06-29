// test/tour_sequencing_test.dart
//
// Task D — Verify the full 5-step tour: sequencing, skip, and replay.
// These are pure-unit tests against FirstRunTourNotifier + StateNotifier.
// No widget tree needed — SharedPreferences is faked via setMockInitialValues.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences to a clean slate before every test.
    SharedPreferences.setMockInitialValues({});
  });

  group('FirstRunTourNotifier', () {
    // ── Sequencing ───────────────────────────────────────────────────────────
    test('totalSteps constant equals 5', () {
      expect(FirstRunTourNotifier.totalSteps, equals(5));
    });

    test('nextStep advances 0→1→2→3→4 then completes tour at -1', () async {
      final notifier = FirstRunTourNotifier();
      // Wait for _load() to settle (fresh prefs → -1 initially, but we reset)
      await Future.delayed(Duration.zero);

      // Force the tour to step 0 (simulates first-run trigger).
      await notifier.setStep(0);
      expect(notifier.state, equals(0));

      for (int expected = 1; expected <= 4; expected++) {
        await notifier.nextStep();
        expect(notifier.state, equals(expected),
            reason: 'After nextStep from ${expected - 1} expected $expected');
      }

      // One more nextStep from step 4 (last) → completes.
      await notifier.nextStep();
      expect(notifier.state, equals(-1),
          reason: 'After step 4 nextStep() should complete the tour (-1)');
    });

    test('nextStep from -1 is a no-op', () async {
      final notifier = FirstRunTourNotifier();
      await Future.delayed(Duration.zero);
      // State defaults to -1 on fresh prefs.
      expect(notifier.state, equals(-1));
      await notifier.nextStep();
      expect(notifier.state, equals(-1));
    });

    // ── Skip ─────────────────────────────────────────────────────────────────
    test('skipOrEnd from step 0 exits cleanly', () async {
      final notifier = FirstRunTourNotifier();
      await notifier.setStep(0);
      await notifier.skipOrEnd();
      expect(notifier.state, equals(-1));
    });

    test('skipOrEnd from mid-tour (step 3) exits cleanly', () async {
      final notifier = FirstRunTourNotifier();
      await notifier.setStep(3);
      await notifier.skipOrEnd();
      expect(notifier.state, equals(-1));
    });

    test('skipOrEnd from last step (step 4) exits cleanly', () async {
      final notifier = FirstRunTourNotifier();
      await notifier.setStep(4);
      await notifier.skipOrEnd();
      expect(notifier.state, equals(-1));
    });

    // ── Persistence ──────────────────────────────────────────────────────────
    test('completed tour (-1) persists and does not re-trigger on reload',
        () async {
      final notifier = FirstRunTourNotifier();
      await notifier.setStep(0);
      // Advance all the way to completion.
      for (int i = 0; i < FirstRunTourNotifier.totalSteps; i++) {
        await notifier.nextStep();
      }
      expect(notifier.state, equals(-1));

      // Simulate app restart: new notifier reads from persisted SharedPrefs.
      final notifier2 = FirstRunTourNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier2.state, equals(-1),
          reason:
              'Completed tour should still be -1 after simulated app restart');
    });

    // ── Replay ───────────────────────────────────────────────────────────────
    test('reset() restarts tour at step 0 regardless of prior state', () async {
      final notifier = FirstRunTourNotifier();
      // Simulate a completed tour.
      await notifier.setStep(-1);
      await notifier.reset();
      expect(notifier.state, equals(0));
    });

    test('reset() then full advance completes cleanly', () async {
      final notifier = FirstRunTourNotifier();
      await notifier.reset();
      expect(notifier.state, equals(0));
      for (int i = 0; i < FirstRunTourNotifier.totalSteps; i++) {
        await notifier.nextStep();
      }
      expect(notifier.state, equals(-1));
    });
  });
}
