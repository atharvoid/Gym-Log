/// Golden test harness for GymLog.
///
/// Wraps any widget in the full GymLog theme (OLED dark canvas, AccentColors
/// ThemeExtension) for a given [ThemePalette]. Use [themedScenario] to generate
/// one golden scenario per palette, and [gymlogApp] for ad-hoc widget tests.
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';

/// Wraps [child] in a full GymLog MaterialApp configured for [palette].
/// Use this in golden tests when you need a fully themed BuildContext.
Widget gymlogApp(ThemePalette palette, Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(palette.tokens, palette: palette),
    home: Material(
      color: Colors.black,
      child: Center(child: child),
    ),
  );
}

/// Creates one [GoldenTestScenario] for a given palette. Use inside a
/// [GoldenTestGroup.children] list to render the same widget under every accent.
GoldenTestScenario themedScenario(ThemePalette palette, Widget child) {
  return GoldenTestScenario(
    name: palette.displayName,
    child: gymlogApp(palette, child),
  );
}

/// Convenience: generates a [GoldenTestGroup] with one scenario per palette.
GoldenTestGroup allThemesGroup(String label, Widget child) {
  return GoldenTestGroup(
    scenarioConstraints: const BoxConstraints(maxWidth: 400),
    children: [
      for (final palette in ThemePalette.values) themedScenario(palette, child),
    ],
  );
}
