// test/tour_orchestration_test.dart
//
// Task E — Verify the central tour orchestrator, overlay auto-advance,
// and the complete 5-step replay flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymlog/core/router/router.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';
import 'package:gymlog/shared/widgets/tour/tour_navigation_orchestrator.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TourNavigationOrchestrator', () {
    test('step route map covers 0, 1, 3, 4 and leaves 2 dynamic', () {
      expect(TourNavigationOrchestrator.stepRoutes[0], equals('/'));
      expect(TourNavigationOrchestrator.stepRoutes[1],
          equals('/routines/explore'));
      expect(TourNavigationOrchestrator.stepRoutes[2], isNull);
      expect(TourNavigationOrchestrator.stepRoutes[3], equals('/settings'));
      expect(TourNavigationOrchestrator.stepRoutes[4], equals('/'));
    });

    testWidgets('navigates each routed step to the correct screen',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _Placeholder('Home')),
          GoRoute(
              path: '/routines/explore',
              builder: (_, __) => const _Placeholder('Explore')),
          GoRoute(
              path: '/settings',
              builder: (_, __) => const _Placeholder('Settings')),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                TourNavigationOrchestrator(child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final notifier = container.read(firstRunTourProvider.notifier);

      Future<void> expectRoute(int step, String path) async {
        await notifier.setStep(step);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, equals(path),
            reason: 'Step $step should navigate to $path');
      }

      await expectRoute(0, '/');
      await expectRoute(1, '/routines/explore');
      await expectRoute(3, '/settings');
      await expectRoute(4, '/');

      // Completing the tour leaves the user on Home.
      await notifier.nextStep(); // 4 → -1
      await tester.pumpAndSettle();
      expect(container.read(firstRunTourProvider), equals(-1));
      expect(router.routeInformationProvider.value.uri.path, equals('/'));
    });
  });

  group('SpotlightTourOverlay auto-advance', () {
    testWidgets('advances past a target that never mounts', (tester) async {
      SharedPreferences.setMockInitialValues({'first_run_tour_step': 2});

      final targetKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpotlightTourOverlay(
              targetKey: targetKey, // intentionally unattached
              title: 'Test',
              description: 'Test',
              step: 2,
            ),
          ),
        ),
      );

      // Overlay should start retrying but never paint a mask.
      expect(find.byType(SpotlightTourOverlay), findsOneWidget);

      // Wait long enough for the retry cap to expire.
      await tester.pump(const Duration(seconds: 3));

      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      expect(container.read(firstRunTourProvider), equals(3),
          reason: 'Tour should auto-advance from step 2 when target is absent');
    });
  });

  group('Tour replay', () {
    test('reset from Settings replays all 5 steps', () async {
      final notifier = FirstRunTourNotifier();
      await notifier.setStep(-1); // Simulate a completed tour.
      await notifier.reset();
      expect(notifier.state, equals(0));

      for (int i = 0; i < FirstRunTourNotifier.totalSteps; i++) {
        await notifier.nextStep();
      }
      expect(notifier.state, equals(-1));
    });
  });

  group('Start Routine during tour', () {
    test('skipOrEnd from step 2 exits the tour cleanly', () async {
      final notifier = FirstRunTourNotifier();
      await notifier.setStep(2);
      await notifier.skipOrEnd();
      expect(notifier.state, equals(-1));
    });
  });
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder(this.label);

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}
