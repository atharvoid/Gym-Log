import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/import/presentation/screens/import_screen.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

void main() {
  testWidgets('_Banner renders with AppRadius.cardAll and semantic label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportTestHelper.buildBanner(
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            text: 'Test Warning Text',
          ),
        ),
      ),
    );

    // Verify Semantics wrapper
    final semanticsFinder = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.label == 'Notification: Test Warning Text',
    );
    expect(semanticsFinder, findsOneWidget);

    // Verify BorderRadius of Container is AppRadius.cardAll
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, AppRadius.cardAll);
  });

  testWidgets('_StatRow renders with semantic label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportTestHelper.buildStatRow(
            label: 'Total workouts',
            value: '42',
          ),
        ),
      ),
    );

    final semanticsFinder = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Total workouts: 42',
    );
    expect(semanticsFinder, findsOneWidget);
  });

  testWidgets(
      '_UnitChooser renders with custom height, color tokens, and semantics',
      (tester) async {
    var selectedUnit = 'kg';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportTestHelper.buildUnitChooser(
            unit: selectedUnit,
            onChanged: (u) => selectedUnit = u,
          ),
        ),
      ),
    );

    // Verify overall Unit Selection semantics
    final chooserSemanticsFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label ==
              'Unit Selection. This file has no unit — what was it logged in?',
    );
    expect(chooserSemanticsFinder, findsOneWidget);

    // Verify unit selector chips semantics
    final kgSemanticsFinder = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == 'Kilograms',
    );
    expect(kgSemanticsFinder, findsOneWidget);
    final kgSemantics = tester.widget<Semantics>(kgSemanticsFinder);
    expect(kgSemantics.properties.button, true);
    expect(kgSemantics.properties.selected, true);

    // Verify height of animated containers is 48
    final animatedContainers =
        tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(animatedContainers.length, 2);
    for (final container in animatedContainers) {
      expect(container.constraints?.minHeight, 48.0);
      expect(container.constraints?.maxHeight, 48.0);
    }

    // Verify inner container background color uses surface3 (from fallback context theme)
    final selectorContainerFinder = find
        .ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        )
        .first;
    final selectorContainer = tester.widget<Container>(selectorContainerFinder);
    final decoration = selectorContainer.decoration as BoxDecoration;
    expect(decoration.color, AppColors.surface3); // fallback tokenized value
  });
}
