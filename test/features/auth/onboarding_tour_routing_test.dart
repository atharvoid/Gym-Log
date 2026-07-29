import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'notifier.setStep(0) updates both provider state and persisted prefs',
    () async {
      // This is the FIX behaviour (onboarding_screen.dart _handleStartTour
      // now calls notifier.setStep(0) instead of raw prefs.write).
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(firstRunTourProvider.notifier).setStep(0);

      // Provider state reflects the change
      expect(container.read(firstRunTourProvider), 0);

      // Prefs also reflect the change (persistence round-trip)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('first_run_tour_step'), 0);
    },
  );

  test('raw SharedPreferences write does NOT update provider state', () async {
    // The BUG: onboarding_screen.dart used to write raw prefs (via
    // SharedPreferences.setInt), which is invisible to the live notifier
    // because it reads prefs only once at construction.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('first_run_tour_step', 0);

    // State stays at the default -1 — the notifier never re-reads prefs.
    // This is why pre-fix the FTUE tour never started.
    expect(container.read(firstRunTourProvider), -1);
  });

  test(
    'notifier.setStep(-1) marks tour permanently skipped',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start at step 0, then skip
      await container.read(firstRunTourProvider.notifier).setStep(0);
      await container.read(firstRunTourProvider.notifier).setStep(-1);

      expect(container.read(firstRunTourProvider), -1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('first_run_tour_step'), -1);
    },
  );
}
