import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/features/workout/presentation/widgets/rest_time_sheet.dart';

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

    testWidgets('2. only one selection active and presets wrap used',
        (tester) async {
      await tester.pumpWidget(buildTestableSheet(
        exerciseName: 'Squat',
        currentPreference: const RestPreference.custom(60),
        globalSeconds: 90,
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(Wrap), findsWidgets);

      expect(find.text('1:00'), findsNWidgets(2));
      expect(find.text('1:30'), findsOneWidget);
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

      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('1:30'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, equals(const RestPreference.useDefault()));
    });
  });
}
