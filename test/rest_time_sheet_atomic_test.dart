import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/features/workout/presentation/widgets/rest_time_sheet.dart';
import 'package:gymlog/shared/widgets/ui/duration_slider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableSheet({
    required String exerciseName,
    required RestPreference currentPreference,
    required int globalSeconds,
    double textScaleFactor = 1.0,
    double screenHeight = 800.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(400, screenHeight),
          textScaler: TextScaler.linear(textScaleFactor),
          padding: const EdgeInsets.only(bottom: 20),
          viewPadding: const EdgeInsets.only(bottom: 20),
        ),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showRestTimeSheet(
                    context: context,
                    exerciseName: exerciseName,
                    currentPreference: currentPreference,
                    globalSeconds: globalSeconds,
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('ATOMIC-02 RestTimeSheet Suite', () {
    testWidgets('1. no None or Matches default in sheet', (tester) async {
      await tester.pumpWidget(buildTestableSheet(
        exerciseName: 'Deadlift',
        currentPreference: const RestPreference.useDefault(),
        globalSeconds: 90,
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Rest time'), findsOneWidget);
      expect(find.text('Deadlift · This workout only'), findsOneWidget);

      expect(find.text('None'), findsNothing);
      expect(find.text('Matches default'), findsNothing);
      expect(find.text('Rest Timer Override'), findsNothing);
    });

    testWidgets(
        '2. option buttons replace preset chips; steppers + slider used',
        (tester) async {
      await tester.pumpWidget(buildTestableSheet(
        exerciseName: 'Squat',
        currentPreference: const RestPreference.custom(60),
        globalSeconds: 90,
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Preset chips are gone (ship-readiness #9): one Default·global option,
      // one Off option, and the shared DurationSlider with ±15s steppers.
      expect(find.text('Default · 1:30'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('−15s'), findsOneWidget);
      expect(find.text('+15s'), findsOneWidget);
      expect(find.byType(DurationSlider), findsOneWidget);

      // No preset chips: '1:00' appears only as the slider readout (60s draft),
      // and the global 1:30 exists solely inside the Default option label.
      expect(find.text('1:00'), findsOneWidget);
      expect(find.textContaining('1:30'), findsOneWidget);
    });

    testWidgets('3. sheet below 72% height at normal scale', (tester) async {
      const screenHeight = 800.0;
      await tester.pumpWidget(buildTestableSheet(
        exerciseName: 'Bench Press',
        currentPreference: const RestPreference.useDefault(),
        globalSeconds: 90,
        screenHeight: screenHeight,
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sheetSize = tester.getSize(
        find
            .ancestor(
              of: find.text('Rest time'),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(sheetSize.height, lessThanOrEqualTo(screenHeight * 0.72));
    });

    testWidgets('4. 200% text scale remains scrollable and does not overflow',
        (tester) async {
      await tester.pumpWidget(buildTestableSheet(
        exerciseName: 'Incline Bench Press with Long Name',
        currentPreference: const RestPreference.custom(120),
        globalSeconds: 90,
        textScaleFactor: 2.0,
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('5. Cancel returns null', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RestPreference? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showRestTimeSheet(
                    context: context,
                    exerciseName: 'Deadlift',
                    currentPreference: const RestPreference.custom(60),
                    globalSeconds: 90,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('6. Save returns normalized preference', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RestPreference? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showRestTimeSheet(
                    context: context,
                    exerciseName: 'Deadlift',
                    currentPreference: const RestPreference.useDefault(),
                    globalSeconds: 90,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Draft starts at Default → 90s (global). Step down twice to 60s.
      await tester.tap(find.text('−15s'));
      await tester.pump();
      await tester.tap(find.text('−15s'));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, equals(const RestPreference.custom(60)));
    });

    testWidgets('7. Custom equal to global normalizes to Default on Save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RestPreference? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showRestTimeSheet(
                    context: context,
                    exerciseName: 'Deadlift',
                    currentPreference: const RestPreference.custom(60),
                    globalSeconds: 90,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Custom 60s is not the global 90s, so the slider starts at 60s.
      // Step up twice to 90s — equal to global → normalizes to Default.
      await tester.tap(find.text('+15s'));
      await tester.pump();
      await tester.tap(find.text('+15s'));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, equals(const RestPreference.useDefault()));
    });
  });
}
