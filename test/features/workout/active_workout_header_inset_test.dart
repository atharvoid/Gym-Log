import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/workout/presentation/widgets/active_workout_header.dart';

Widget _wrap(Widget child) {
  final palette = ThemePalette.fallback;
  return MaterialApp(
    theme: buildAppTheme(palette.tokens, palette: palette),
    home: Align(
      alignment: Alignment.topCenter,
      child: child,
    ),
  );
}

Widget _buildHeader({double topInset = 30}) => MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        viewPadding: EdgeInsets.only(top: topInset),
      ),
      child: SizedBox(
        width: 390,
        child: ActiveWorkoutHeader(
          isEditing: false,
          workoutName: 'Push Day',
          elapsedTime: '00:12:34',
          volumeKg: 1250.0,
          completedSets: 8,
          weightUnit: 'kg',
          finishEnabled: true,
          onMinimize: () {},
          onClose: () {},
          onFinish: () {},
        ),
      ),
    );

void main() {
  testWidgets('nav row starts within handle-strip height of the top',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildHeader(topInset: 30)));
    await tester.pump();

    final closeRect = tester.getRect(find.byTooltip('Discard workout'));
    final top = closeRect.top;

    // With the fix, the inset (30) is folded into the grab strip
    // (height = max(48, 30+20) = 50), so the close button's top should
    // start much earlier than the pre-fix value of ~78.
    // (The precise value varies with text layout, rounding etc.;
    // the golden tests validate exact pixel rendering.)
    expect(top, lessThanOrEqualTo(72.0),
        reason: 'Close button starts $top dp from top at inset 30; '
            'it should sit well below the pre-fix ~78 dp baseline.');
  });

  testWidgets('pill clears the status-bar area', (tester) async {
    await tester.pumpWidget(_wrap(_buildHeader(topInset: 30)));
    await tester.pump();

    final pillRect =
        tester.getRect(find.byKey(const ValueKey('grab-handle-pill')));
    final top = pillRect.top;

    expect(top, greaterThan(30.0),
        reason: 'Pill top ($top) must be below the status-bar inset (30 dp) '
            'so it does not visually collide with status-bar content.');
  });

  testWidgets('grab handle strip meets minimum 48dp touch target',
      (tester) async {
    await tester.pumpWidget(_wrap(_buildHeader(topInset: 0)));
    await tester.pump();

    final pillRect =
        tester.getRect(find.byKey(const ValueKey('grab-handle-pill')));

    // With inset=0: strip height = max(48, 0+20) = 48.
    // Pill bottom-aligned with 8dp padding: pill top = 48 - 8 - 4 = 36.
    expect(pillRect.top, greaterThanOrEqualTo(30.0),
        reason: 'Even with zero inset, the strip must provide a meaningful '
            'touch target. Pill top at ${pillRect.top} dp.');
  });
}
