import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/widgets/active_workout_bar.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';

class FixedWorkoutTimer extends WorkoutTimer {
  @override
  String build() => '00:24:00';
}

void main() {
  setUpAll(loadSessionFonts);
  for (final scale in [1.6, 2.0]) {
    testWidgets('real resume bar fits $scale text without overflow',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(launchFixtureApp(
        child: const Scaffold(
            body: Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ActiveWorkoutBar()))),
        palette: ThemePalette.higgsfield,
        scale: scale,
        screen: 'home',
        fixtureState: LaunchState.returning,
        activeWorkout: true,
        overrides: [workoutTimerProvider.overrideWith(FixedWorkoutTimer.new)],
        captureKey: const ValueKey('large-resume'),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('00:24:00'), findsOneWidget);
      expect(tester.getSize(find.byType(ActiveWorkoutBar)).height,
          greaterThanOrEqualTo(56));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
