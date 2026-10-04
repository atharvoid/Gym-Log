import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';

void main() {
  setUpAll(loadSessionFonts);
  Future<void> render(WidgetTester tester, String screen,
      {double scale = 1}) async {
    SharedPreferences.setMockInitialValues({
      'first_run_tour_step': -1,
      'training_routine:local': 'sample-0',
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(launchFixtureApp(
      child: currentLaunchScreen(screen),
      palette: ThemePalette.higgsfield,
      scale: scale,
      screen: screen,
      fixtureState: LaunchState.returning,
      captureKey: const ValueKey('correction'),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Home advances the chosen program after a completed Pull A',
      (tester) async {
    await render(tester, 'home');
    expect(find.text('Start Legs A'), findsOneWidget);
    expect(find.text('Last workout'), findsOneWidget);
    expect(find.text('After Pull A in your saved order'), findsOneWidget);
  });

  testWidgets('Library has substantial utility buttons and one next marker',
      (tester) async {
    await render(tester, 'library');
    expect(find.text('HOME ROUTINE'), findsNothing);
    expect(find.text('Following on Home'), findsOneWidget);
    for (final label in ['New routine', 'Explore']) {
      expect(tester.getSize(find.text(label)).height, greaterThan(0));
      final button = find.byKey(ValueKey('library-$label'));
      expect(button, findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(52));
    }
    expect(find.text('View next'), findsOneWidget);
  });

  testWidgets('one-session override is separate from persistent plan choice',
      (tester) async {
    await render(tester, 'home');
    await tester.tap(find.text('Train something else'));
    await tester.pumpAndSettle();
    expect(find.text('For this session'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Outdoor');
    await tester.pumpAndSettle();
    expect(find.text('Outdoor walk'), findsOneWidget);
    expect(find.text('Push A'), findsNothing);
    expect(
        (await SharedPreferences.getInstance())
            .getString('training_routine:local'),
        'sample-0');
  });
}
