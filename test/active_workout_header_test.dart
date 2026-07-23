import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/workout/presentation/widgets/active_workout_header.dart';

Widget buildHeader({
  bool isEditing = false,
  String workoutName = 'Active Workout',
  String elapsedTime = '00:12:34',
  double volumeKg = 1250.0,
  int completedSets = 8,
  String weightUnit = 'kg',
  bool finishEnabled = true,
  VoidCallback? onMinimize,
  VoidCallback? onClose,
  VoidCallback? onFinish,
  double textScale = 1.0,
  double width = 390,
  double height = 844,
}) {
  if (finishEnabled && onFinish == null) {
    onFinish = () {};
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(
      ThemePalette.values.first.tokens,
      palette: ThemePalette.values.first,
    ),
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Material(
        color: Colors.black,
        child: SizedBox(
          width: width,
          child: ActiveWorkoutHeader(
            isEditing: isEditing,
            workoutName: workoutName,
            elapsedTime: elapsedTime,
            volumeKg: volumeKg,
            completedSets: completedSets,
            weightUnit: weightUnit,
            finishEnabled: finishEnabled,
            onMinimize: onMinimize ?? () {},
            onClose: onClose ?? () {},
            onFinish: onFinish,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ActiveWorkoutHeader normal layout', () {
    testWidgets('renders elapsed time once at 1.0x', (tester) async {
      await tester.pumpWidget(buildHeader());

      expect(find.text('00:12:34'), findsOneWidget);
      expect(find.textContaining('1,250 kg · 8 sets'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('renders elapsed time once at 1.6x', (tester) async {
      await tester.pumpWidget(buildHeader(textScale: 1.6));

      expect(find.text('00:12:34'), findsOneWidget);
      expect(find.textContaining('1,250 kg · 8 sets'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('renders at 2.0x without overflow', (tester) async {
      await tester.pumpWidget(buildHeader(textScale: 2.0));

      expect(find.text('00:12:34'), findsOneWidget);
      expect(find.textContaining('1,250 kg · 8 sets'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('reflowed shows workout name as title', (tester) async {
      await tester.pumpWidget(buildHeader(
        workoutName: 'Morning Push',
        textScale: 1.6,
      ));

      expect(find.text('Morning Push'), findsOneWidget);
      expect(find.text('00:12:34'), findsOneWidget);
    });

    testWidgets('compact triggers reflow at 320px showing workout name',
        (tester) async {
      await tester.pumpWidget(buildHeader(
        workoutName: 'Quick Session',
        width: 320,
        height: 568,
      ));

      expect(find.text('Quick Session'), findsOneWidget);
      expect(find.text('00:12:34'), findsOneWidget);
      expect(find.textContaining('1,250 kg · 8 sets'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('renders long elapsed time', (tester) async {
      await tester.pumpWidget(buildHeader(elapsedTime: '99:59:59'));

      expect(find.text('99:59:59'), findsOneWidget);
    });

    testWidgets('renders large volume and sets', (tester) async {
      await tester.pumpWidget(buildHeader(
        volumeKg: 99999,
        completedSets: 999,
      ));

      expect(find.textContaining('99,999 kg · 999 sets'), findsOneWidget);
    });
  });

  group('ActiveWorkoutHeader behavior', () {
    testWidgets('Finish is present when finishEnabled is true', (tester) async {
      await tester.pumpWidget(buildHeader(
        completedSets: 2,
        finishEnabled: true,
      ));

      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('Finish is present when finishEnabled is false',
        (tester) async {
      await tester.pumpWidget(buildHeader(
        completedSets: 0,
        finishEnabled: false,
      ));

      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('assertion throws when finishEnabled=true and onFinish=null',
        (tester) async {
      expect(
        () => ActiveWorkoutHeader(
          isEditing: false,
          workoutName: 'Test',
          elapsedTime: '00:00:00',
          volumeKg: 0,
          completedSets: 0,
          weightUnit: 'kg',
          finishEnabled: true,
          onMinimize: () {},
          onClose: () {},
          onFinish: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('editing mode shows Save and elapsed time', (tester) async {
      await tester.pumpWidget(buildHeader(isEditing: true));

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('00:12:34'), findsOneWidget);
    });

    testWidgets('minimize semantic label is tappable', (tester) async {
      int calls = 0;
      await tester.pumpWidget(buildHeader(onMinimize: () => calls++));

      await tester.tap(find.bySemanticsLabel('Minimize workout'));
      expect(calls, 1);
    });

    testWidgets('close button fires onClose on tap', (tester) async {
      int calls = 0;
      await tester.pumpWidget(buildHeader(onClose: () => calls++));

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(calls, 1);
    });

    testWidgets('finish callback fires on tap', (tester) async {
      int calls = 0;
      await tester.pumpWidget(buildHeader(
        onFinish: () => calls++,
        finishEnabled: true,
      ));

      await tester.tap(find.text('Finish'));
      expect(calls, 1);
    });

    testWidgets('close button has minimum 48x48 tap target', (tester) async {
      await tester.pumpWidget(buildHeader());

      final iconButton = find.byType(IconButton);
      final size = tester.getSize(iconButton);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });
}
