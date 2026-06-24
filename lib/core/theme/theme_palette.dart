import 'package:flutter/material.dart';

/// [theme_palette.dart]
/// User-selectable accent palettes for the Dynamic Accent Theme system.
///
/// DESIGN DISCIPLINE: only the ACCENT hue is user-controlled. Surfaces
/// (bgBase, surface2/3/4), text, and borders are fixed in [AppColors] and
/// never shift with the palette. This keeps the app feeling like one coherent
/// product in every accent.
///
/// Each palette exposes six tokens with exactly one job each:
///   base     — primary action color (CTA fill, active nav, selected border)
///   light    — accent text, hairlines, chart date header (WCAG-safer on black)
///   dark     — pressed / active-depressed states
///   muted    — selected-row / tinted card / chart-fill background (~15% alpha)
///   glow     — atmospheric effects (sheet glow, celebration backdrop, ~18%)
///   onAccent — text/icon that sits ON the full-saturation base (CTA label)
///
/// PREMIUM DARK-MODE SATURATION RULE: `base` (full saturation) appears only on
/// elements that must demand attention — the primary CTA, the active nav
/// indicator, and selected-card borders. Everywhere else (icon fills, chart
/// bars, tinted backgrounds, badges) the accent appears via `muted`/`glow`
/// (~12–18% alpha) so it reads as depth, not noise.

/// Reward gold — the achievement color. IMMUTABLE across every palette: PR
/// badges, the streak flame, and celebration gold are emotional anchors that
/// must never change with the accent choice.
const Color kRewardGold = Color(0xFFE6C84A);

@immutable
class ThemePaletteTokens {
  /// Primary action color — CTA fill, active states, selected borders.
  final Color base;

  /// Accent text, hairlines, focus rings, chart date header.
  final Color light;

  /// Pressed / depressed states.
  final Color dark;

  /// Hover / pressed backgrounds and selected-row tints (~15% alpha).
  final Color muted;

  /// Atmospheric glow — top-sheet glow, PR celebration backdrop (~18% alpha).
  final Color glow;

  /// Text / icon color that sits on top of the full-saturation [base] (e.g. a
  /// CTA label). White for the colored palettes; near-black for the neutral
  /// (white) palette where white-on-white would be invisible.
  final Color onAccent;

  const ThemePaletteTokens({
    required this.base,
    required this.light,
    required this.dark,
    required this.muted,
    required this.glow,
    required this.onAccent,
  });
}

enum ThemePalette {
  spectralViolet,
  phosphorAmber,
  steelBlue,
  chromaticRose,
  tacticalGreen,
  neutralWhite;

  /// Stable key persisted to SharedPreferences. Decoupled from the index so
  /// reordering the enum never corrupts a saved choice.
  String get storageKey => name;

  /// Human-facing name shown under the swatch in the Appearance screen.
  String get displayName => switch (this) {
        ThemePalette.spectralViolet => 'Deep Spectral Violet',
        ThemePalette.phosphorAmber => 'Phosphor Amber',
        ThemePalette.steelBlue => 'Electric Steel Blue',
        ThemePalette.chromaticRose => 'Chromatic Rose',
        ThemePalette.tacticalGreen => 'Tactical Green',
        ThemePalette.neutralWhite => 'Pure White',
      };

  /// Accessibility label for the swatch.
  String get a11yName => switch (this) {
        ThemePalette.spectralViolet => 'Deep spectral violet',
        ThemePalette.phosphorAmber => 'Phosphor amber',
        ThemePalette.steelBlue => 'Electric steel blue',
        ThemePalette.chromaticRose => 'Chromatic rose',
        ThemePalette.tacticalGreen => 'Tactical green',
        ThemePalette.neutralWhite => 'Pure white',
      };

  /// The six-token set for this palette. Alpha values: muted = 0x26 (~15%),
  /// glow = 0x2E (~18%); the neutral palette uses white at 0x24/0x2E.
  ThemePaletteTokens get tokens => switch (this) {
        // 1 — Deep Spectral Violet: a richer, darker descendant of the
        // profile-tab indigo. The app's on-brand default.
        ThemePalette.spectralViolet => const ThemePaletteTokens(
            base: Color(0xFF7C4DFF),
            light: Color(0xFFB39DFF),
            dark: Color(0xFF5A2EB8),
            muted: Color(0x267C4DFF),
            glow: Color(0x2E7C4DFF),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 2 — Phosphor Amber: deep gold-amber (performance / PR alignment).
        // Dark text reads cleanly on the bright base.
        ThemePalette.phosphorAmber => const ThemePaletteTokens(
            base: Color(0xFFE8910C),
            light: Color(0xFFF6C064),
            dark: Color(0xFF9C5E00),
            muted: Color(0x26E8910C),
            glow: Color(0x2EE8910C),
            onAccent: Color(0xFF0A0A0A),
          ),
        // 3 — Electric Steel Blue: deep, desaturated, analytical.
        ThemePalette.steelBlue => const ThemePaletteTokens(
            base: Color(0xFF4574C4),
            light: Color(0xFF8FB2E0),
            dark: Color(0xFF2A4A7A),
            muted: Color(0x264574C4),
            glow: Color(0x2E4574C4),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 4 — Chromatic Rose: deep magenta-leaning pink, sophisticated.
        ThemePalette.chromaticRose => const ThemePaletteTokens(
            base: Color(0xFFD6418A),
            light: Color(0xFFED8FBE),
            dark: Color(0xFF8C2A5C),
            muted: Color(0x26D6418A),
            glow: Color(0x2ED6418A),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 5 — Tactical Green: deep military-influenced green (not mint/teal).
        ThemePalette.tacticalGreen => const ThemePaletteTokens(
            base: Color(0xFF4E7D3E),
            light: Color(0xFF8FB87C),
            dark: Color(0xFF2F4E24),
            muted: Color(0x264E7D3E),
            glow: Color(0x2E4E7D3E),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 6 — Pure White / Neutral: maximum contrast, no hue. Dark on-accent.
        ThemePalette.neutralWhite => const ThemePaletteTokens(
            base: Color(0xFFF2F2F5),
            light: Color(0xFFFFFFFF),
            dark: Color(0xFFC7C7CC),
            muted: Color(0x24FFFFFF),
            glow: Color(0x2EFFFFFF),
            onAccent: Color(0xFF0A0A0A),
          ),
      };

  /// The solid swatch color shown in the Appearance picker (== base).
  Color get swatch => tokens.base;

  /// The single default accent — the app's designed identity.
  static ThemePalette get fallback => ThemePalette.spectralViolet;

  /// Resolves a persisted key back to a palette, defaulting to [fallback] when
  /// the key is absent or unrecognized. Legacy keys from the previous
  /// 4-palette system (purple/copper/teal/red) migrate forward so an existing
  /// user never loses their choice or lands on an unrecognized default.
  static ThemePalette fromStorage(String? key) {
    if (key == null) return fallback;
    for (final p in ThemePalette.values) {
      if (p.storageKey == key) return p;
    }
    return switch (key) {
      'purple' => ThemePalette.spectralViolet,
      'copper' => ThemePalette.phosphorAmber,
      'teal' => ThemePalette.tacticalGreen,
      'red' => ThemePalette.chromaticRose,
      _ => fallback,
    };
  }
}
