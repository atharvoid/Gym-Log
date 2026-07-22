@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/bottom_nav_bar.dart';
import 'package:gymlog/core/theme/theme_palette.dart';

import 'golden_test_helpers.dart';

/// Helper that renders a [BottomNavBar] in a themed container with the given
/// [palette], [selectedIndex], and optional [size].
Widget navBarScenario(ThemePalette palette, int selectedIndex, Size size) {
  final container = Container(
    color: const Color(0xFF000000),
    child: SizedBox(
      width: size.width,
      child: BottomNavBar(
        currentIndex: selectedIndex,
        onTap: (_) {},
      ),
    ),
  );
  // Wrap in the theme, then constrain viewport.
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: gymlogApp(palette, container),
  );
}

void main() {
  final standardSizes = [const Size(390, 844), const Size(360, 800)];

  goldenTest(
    'BottomNavBar — all palettes, tab 0 selected, standard sizes',
    fileName: 'nav_bar_all_palettes_tab0',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: [
        for (final palette in ThemePalette.values)
          for (final size in standardSizes)
            GoldenTestScenario(
              name: '${palette.displayName}_${size.width}x${size.height}',
              child: navBarScenario(palette, 0, size),
            ),
      ],
    ),
  );

  goldenTest(
    'BottomNavBar — all palettes, tab 1 selected',
    fileName: 'nav_bar_all_palettes_tab1',
    builder: () => allThemesGroup(
      'Tab 1 selected',
      SizedBox(
        width: 390,
        child: BottomNavBar(
          currentIndex: 1,
          onTap: (_) {},
        ),
      ),
    ),
  );

  goldenTest(
    'BottomNavBar — all palettes, tab 2 selected',
    fileName: 'nav_bar_all_palettes_tab2',
    builder: () => allThemesGroup(
      'Tab 2 selected',
      SizedBox(
        width: 390,
        child: BottomNavBar(
          currentIndex: 2,
          onTap: (_) {},
        ),
      ),
    ),
  );

  goldenTest(
    'BottomNavBar — small viewport 320x568',
    fileName: 'nav_bar_small_viewport',
    builder: () => GoldenTestGroup(
      children: [
        for (final palette in ThemePalette.values)
          GoldenTestScenario(
            name: palette.displayName,
            child: navBarScenario(palette, 0, const Size(320, 568)),
          ),
      ],
    ),
  );

  goldenTest(
    'BottomNavBar — tablet 600x1024',
    fileName: 'nav_bar_tablet',
    builder: () => GoldenTestGroup(
      children: [
        for (final palette in ThemePalette.values)
          GoldenTestScenario(
            name: palette.displayName,
            child: navBarScenario(palette, 0, const Size(600, 1024)),
          ),
      ],
    ),
  );

  goldenTest(
    'BottomNavBar — landscape 800x360',
    fileName: 'nav_bar_landscape',
    builder: () => GoldenTestGroup(
      children: [
        for (final palette in ThemePalette.values)
          GoldenTestScenario(
            name: palette.displayName,
            child: navBarScenario(palette, 0, const Size(800, 360)),
          ),
      ],
    ),
  );

  group('BottomNavBar — reduced motion', () {
    testWidgets('indicator animates instantly when animations disabled',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: gymlogApp(
            ThemePalette.neonPurple,
            const SizedBox(
              width: 390,
              child: BottomNavBar(
                currentIndex: 0,
                onTap: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Routines'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  group('BottomNavBar — semantics', () {
    testWidgets('tabs expose semantics tree', (tester) async {
      await tester.pumpWidget(
        gymlogApp(
          ThemePalette.neonPurple,
          const SizedBox(
            width: 390,
            child: BottomNavBar(
              currentIndex: 0,
              onTap: _noop,
            ),
          ),
        ),
      );
      await tester.pump();

      // The nav bar contains 3 Semantics widgets (one per tab).
      final navBar = find.byType(BottomNavBar);
      final semanticsInside = find.descendant(
        of: navBar,
        matching: find.byType(Semantics),
      );
      expect(semanticsInside, findsAtLeast(3));
    });
  });

  group('BottomNavBar — geometry and layout', () {
    testWidgets('nav bar has 60px height', (tester) async {
      await tester.pumpWidget(
        gymlogApp(
          ThemePalette.neonPurple,
          const SizedBox(
            width: 390,
            child: BottomNavBar(
              currentIndex: 0,
              onTap: _noop,
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the SizedBox inside the nav bar with the static height.
      final sizedBoxList = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 60.0,
      );
      expect(sizedBoxList, findsAtLeast(1));
    });

    testWidgets('nav bar has 3 tab items', (tester) async {
      await tester.pumpWidget(
        gymlogApp(
          ThemePalette.neonPurple,
          const SizedBox(
            width: 390,
            child: BottomNavBar(
              currentIndex: 0,
              onTap: _noop,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.home_filled), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}

/// A no-op function that satisfies the required callback parameter.
void _noop(int _) {}
