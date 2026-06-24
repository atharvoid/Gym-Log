import 'package:flutter/material.dart';

/// [theme_palette.dart]
/// User-selectable accent palettes for the Dynamic Accent Theme system.
///
/// DESIGN DISCIPLINE: only the ACCENT hue is user-controlled. Surfaces
/// (bgBase, surface2/3/4), text, and borders are fixed in [AppColors] and
/// never shift with the palette. This keeps the app feeling like one coherent
/// product in every accent.
///
/// Each palette exposes five tokens with exactly one job each:
///   base  — primary action color (CTA fill, active states, chart active pts)
///   light — accent text, hairlines, focus rings (WCAG-safer on AMOLED black)
///   dark  — pressed / active-depressed states
///   muted — selected-row / hover background tint (~15% alpha)
///   glow  — atmospheric effects (sheet glow, celebration backdrop, ~18% alpha)

/// Reward gold — the achievement color. IMMUTABLE across every palette: PR
/// badges, the streak flame, and celebration gold are emotional anchors that
/// must never change with the accent choice.
const Color kRewardGold = Color(0xFFE6C84A);

@immutable
class ThemePaletteTokens {
  /// Primary action color — CTA fill, active states, chart active points.
  final Color base;

  /// Accent text, hairlines, and focus rings.
  final Color light;

  /// Pressed / depressed states.
  final Color dark;

  /// Hover / pressed backgrounds and selected-row tints (~15% alpha).
  final Color muted;

  /// Atmospheric glow — top-sheet glow, PR celebration backdrop (~18% alpha).
  final Color glow;

  const ThemePaletteTokens({
    required this.base,
    required this.light,
    required this.dark,
    required this.muted,
    required this.glow,
  });
}

enum ThemePalette {
  purple,
  copper,
  teal,
  red;

  /// Stable key persisted to SharedPreferences. Decoupled from the index so
  /// reordering the enum never corrupts a saved choice.
  String get storageKey => name;

  /// Human-facing name shown under the swatch row in Settings.
  String get displayName => switch (this) {
        ThemePalette.purple => 'Premium Purple',
        ThemePalette.copper => 'Copper Ember',
        ThemePalette.teal => 'Clinical Teal',
        ThemePalette.red => 'Signal Red',
      };

  /// Accessibility label for the swatch, e.g. "Purple accent".
  String get a11yName => switch (this) {
        ThemePalette.purple => 'Purple',
        ThemePalette.copper => 'Copper',
        ThemePalette.teal => 'Teal',
        ThemePalette.red => 'Red',
      };

  /// The five-token set for this palette. Alpha values: muted = 0x26 (~15%),
  /// glow = 0x2E (~18%).
  ThemePaletteTokens get tokens => switch (this) {
        ThemePalette.purple => const ThemePaletteTokens(
            base: Color(0xFF8B5CF6),
            light: Color(0xFFA78BFA),
            dark: Color(0xFF6D28D9),
            muted: Color(0x268B5CF6),
            glow: Color(0x2E8B5CF6),
          ),
        ThemePalette.copper => const ThemePaletteTokens(
            base: Color(0xFFC67C3B),
            light: Color(0xFFE8A87C),
            dark: Color(0xFF8B5A2B),
            muted: Color(0x26C67C3B),
            glow: Color(0x2EC67C3B),
          ),
        ThemePalette.teal => const ThemePaletteTokens(
            base: Color(0xFF00C4A0),
            light: Color(0xFF5EEAD4),
            dark: Color(0xFF0F766E),
            muted: Color(0x2600C4A0),
            glow: Color(0x2E00C4A0),
          ),
        ThemePalette.red => const ThemePaletteTokens(
            base: Color(0xFFF85149),
            light: Color(0xFFFCA5A5),
            dark: Color(0xFF991B1B),
            muted: Color(0x26F85149),
            glow: Color(0x2EF85149),
          ),
      };

  /// The solid swatch color shown in the Settings picker (== base).
  Color get swatch => tokens.base;

  /// Resolves a persisted key back to a palette, defaulting to [purple] when
  /// the key is absent or unrecognized (fresh install / migrated user).
  static ThemePalette fromStorage(String? key) {
    if (key == null) return ThemePalette.purple;
    for (final p in ThemePalette.values) {
      if (p.storageKey == key) return p;
    }
    return ThemePalette.purple;
  }
}
