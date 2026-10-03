import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/providers/bottom_chrome_provider.dart';
import 'package:gymlog/shared/widgets/active_workout_bar.dart';
import 'package:gymlog/shared/widgets/app_shell.dart';
import 'package:gymlog/shared/widgets/bottom_nav_bar.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'active_bar_large_text_test.dart' show FixedWorkoutTimer;
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';

class InsetReader extends ConsumerWidget {
  const InsetReader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      body: Text(ref.watch(bottomChromeInsetProvider).toStringAsFixed(1),
          key: const ValueKey('inset')));
}

void main() {
  setUpAll(loadSessionFonts);
  for (final scale in [1.0, 1.6, 2.0]) {
    testWidgets(
        'actual shell reserves scaled resume height at $scale without moving nav',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final router = GoRouter(routes: [
        StatefulShellRoute.indexedStack(
            builder: (_, state, shell) => AppShell(navigationShell: shell),
            branches: [
              for (final path in ['/', '/workout', '/profile'])
                StatefulShellBranch(routes: [
                  GoRoute(
                      path: path, builder: (_, state) => const InsetReader())
                ])
            ])
      ]);
      addTearDown(router.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(launchFixtureApp(
          child: const SizedBox.shrink(),
          router: router,
          palette: ThemePalette.higgsfield,
          scale: scale,
          screen: 'home',
          fixtureState: LaunchState.returning,
          activeWorkout: true,
          overrides: [workoutTimerProvider.overrideWith(FixedWorkoutTimer.new)],
          captureKey: const ValueKey('shell')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final height = tester.getSize(find.byType(ActiveWorkoutBar)).height;
      expect(tester.widget<Text>(find.byKey(const ValueKey('inset'))).data,
          (BottomNavBar.height + height + kActiveBarGap).toStringAsFixed(1));
      final nav = tester.getRect(find.byType(BottomNavBar));
      await tester.tap(find.text('Routines'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getRect(find.byType(BottomNavBar)), nav);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
