import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/widgets/ui/app_action_chip.dart';
import 'package:gymlog/shared/widgets/ui/app_info_text.dart';
import 'package:gymlog/shared/widgets/ui/app_status_tag.dart';

Widget _wrapWithTheme(Widget child, {ThemePalette palette = ThemePalette.neonPurple}) {
  return MaterialApp(
    theme: buildAppTheme(palette.tokens, palette: palette),
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  group('Three-Tier Visual Grammar Affordance Tests', () {
    testWidgets('AppStatusTag strictly renders NO border under any configuration', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AppStatusTag(
            label: 'Verified Match',
            leadingIcon: Icons.check_circle_rounded,
            isAccented: true,
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(AppStatusTag),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // STRICT INVARIANT: AppStatusTag MUST NEVER HAVE A BORDER
      expect(decoration.border, isNull, reason: 'Status tags must never have a border (Border = Clickable invariant)');
      expect(find.text('Verified Match'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('AppActionChip always renders a border and fires onTap with haptics', (tester) async {
      var tapped = false;
      var hapticCalled = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          AppActionChip(
            label: 'Rest 1:30',
            leadingIcon: Icons.timer_rounded,
            signifier: ActionSignifier.sheet,
            customHaptic: () => hapticCalled = true,
            onTap: () => tapped = true,
          ),
        ),
      );

      // Verify Material shape has a non-null border side
      final materialFinder = find.descendant(
        of: find.byType(AppActionChip),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsOneWidget);

      final material = tester.widget<Material>(materialFinder);
      final shape = material.shape as RoundedRectangleBorder;
      expect(shape.side, isNotNull);
      expect(shape.side.color, isNot(Colors.transparent));

      // Verify signifier icon is rendered
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
      expect(find.text('Rest 1:30'), findsOneWidget);

      // Verify tap works and triggers haptic
      await tester.tap(find.byType(AppActionChip));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(hapticCalled, isTrue);
    });

    testWidgets('AppActionChip disabled state renders muted styling and disables interaction', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AppActionChip(
            label: 'Disabled Chip',
            onTap: null,
          ),
        ),
      );

      // Verify Semantics has enabled = false
      final semanticsFinder = find.descendant(
        of: find.byType(AppActionChip),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      );
      expect(semanticsFinder, findsOneWidget);
      final semantics = tester.widget<Semantics>(semanticsFinder);
      expect(semantics.properties.enabled, isFalse);

      // Verify AnimatedOpacity is at 0.40
      final opacityFinder = find.descendant(
        of: find.byType(AppActionChip),
        matching: find.byType(AnimatedOpacity),
      );
      expect(opacityFinder, findsOneWidget);
      final animatedOpacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(animatedOpacity.opacity, equals(0.40));
    });

    testWidgets('AppActionChip.compactSquare maintains 28x28 visual size and touch target', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          AppActionChip.compactSquare(
            label: 'W',
            onTap: () => tapped = true,
          ),
        ),
      );

      // Visual container size is 28x28
      final sizedBoxFinder = find.descendant(
        of: find.byType(AppActionChip),
        matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 28 && w.height == 28),
      );
      expect(sizedBoxFinder, findsOneWidget);

      // Touch target constraint is at least 44x44
      final constrainedBoxFinder = find.descendant(
        of: find.byType(AppActionChip),
        matching: find.byWidgetPredicate((w) => w is ConstrainedBox && w.constraints.minWidth >= 44 && w.constraints.minHeight >= 44),
      );
      expect(constrainedBoxFinder, findsOneWidget);

      expect(find.text('W'), findsOneWidget);

      await tester.tap(find.byType(AppActionChip));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AppInfoText formats multiple items with typographic separator', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AppInfoText(
            items: ['4 exercises', '45 mins', 'Leg Day'],
          ),
        ),
      );

      expect(find.text('4 exercises · 45 mins · Leg Day'), findsOneWidget);
    });

    testWidgets('AppInfoText filters empty or whitespace strings', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AppInfoText(
            items: ['4 exercises', '', '   ', 'Leg Day'],
          ),
        ),
      );

      expect(find.text('4 exercises · Leg Day'), findsOneWidget);
    });
  });
}
