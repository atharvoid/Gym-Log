import 'package:flutter/material.dart';

/// [theme_palette.dart]
/// User-selectable BRAND ACCENT palettes — the Apple Watch Neon system.
///
/// DESIGN DISCIPLINE: only the ACCENT hue is user-controlled. Surfaces
/// (bgBase, surface2/3/4), text, borders, and the FIXED semantic accents
/// (success/info/warning/reward in [AppColors]) never shift with the palette.
/// This keeps the app one coherent product in every accent and — critically —
/// keeps semantic color (done = lime, rest = cyan, PR = magenta) legible no
/// matter which brand accent is active. That is why Neon Lime is a semantic
/// token and NOT a pickable accent: a lime brand accent would collide with the
/// lime 'completed set' signal on the workout screen.
///
/// Each palette exposes six tokens with exactly one job each:
///   base     — primary action color (CTA fill, active states, selected borders)
///   light    — accent text, hairlines, chart date header (WCAG-safer on black)
///   dark     — pressed / active-depressed states
///   muted    — selected-row / tinted card / chart-fill background (~14% alpha)
///   glow     — atmospheric effects (sheet glow, celebration backdrop, ~12%)
///   onAccent — text/icon that sits ON the full-saturation base (CTA label)
///
/// SATURATION RULE: `base` (full saturation) appears only on elements that must
/// demand attention — the primary CTA, the active nav indicator, selected-card
/// borders. Everywhere else the accent appears via `muted`/`glow` so it reads
/// as depth, not noise.

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

  /// Hover / pressed backgrounds and selected-row tints (~14% alpha).
  final Color muted;

  /// Atmospheric glow — top-sheet glow, PR celebration backdrop (~12% alpha).
  final Color glow;

  /// Text / icon color that sits on top of the full-saturation [base] (e.g. a
  /// CTA label). White for the deeper palettes; near-black for the bright
  /// neon cyan where white-on-cyan would wash out.
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
  neonPurple,
  neonCyan,
  neonMagenta,
  electricIndigo,
  white,
  higgsfield;

  /// Stable key persisted to SharedPreferences. Decoupled from the index so
  /// reordering the enum never corrupts a saved choice.
  String get storageKey => name;

  /// Human-facing name shown under the swatch in the Appearance screen.
  String get displayName => switch (this) {
        ThemePalette.neonPurple => 'Purple',
        ThemePalette.neonCyan => 'Cyan',
        ThemePalette.neonMagenta => 'Magenta',
        ThemePalette.electricIndigo => 'Electric Indigo',
        ThemePalette.white => 'White',
        ThemePalette.higgsfield => 'Higgsfield',
      };

  /// Accessibility label for the swatch.
  String get a11yName => switch (this) {
        ThemePalette.neonPurple => 'Purple',
        ThemePalette.neonCyan => 'Cyan',
        ThemePalette.neonMagenta => 'Magenta',
        ThemePalette.electricIndigo => 'Electric indigo',
        ThemePalette.white => 'White',
        ThemePalette.higgsfield => 'Higgsfield',
      };

  /// The six-token set for this palette. muted = 0x24 (~14%), glow = 0x1F
  /// (~12%) — the dark-mode saturation ladder.
  ThemePaletteTokens get tokens => switch (this) {
        // 1 — Neon Purple: the app's on-brand default identity.
        ThemePalette.neonPurple => const ThemePaletteTokens(
            base: Color(0xFFBF5AF2),
            light: Color(0xFFD9A6FF),
            dark: Color(0xFF9A3FD0),
            muted: Color(0x24BF5AF2),
            glow: Color(0x1FBF5AF2),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 2 — Neon Cyan: bright analytical cyan. Near-black on-accent so a CTA
        // label stays legible on the luminous fill.
        ThemePalette.neonCyan => const ThemePaletteTokens(
            base: Color(0xFF00D9FF),
            light: Color(0xFF7FEBFF),
            dark: Color(0xFF00A6C4),
            muted: Color(0x2400D9FF),
            glow: Color(0x1F00D9FF),
            onAccent: Color(0xFF0A0A0A),
          ),
        // 3 — Neon Magenta: high-energy magenta-red.
        ThemePalette.neonMagenta => const ThemePaletteTokens(
            base: Color(0xFFFF2D55),
            light: Color(0xFFFF8FA6),
            dark: Color(0xFFC41E3F),
            muted: Color(0x24FF2D55),
            glow: Color(0x1FFF2D55),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 4 — Electric Indigo: precise, technical blue-purple.
        ThemePalette.electricIndigo => const ThemePaletteTokens(
            base: Color(0xFF5E5CE6),
            light: Color(0xFFA6A4FF),
            dark: Color(0xFF4240B0),
            muted: Color(0x245E5CE6),
            glow: Color(0x1F5E5CE6),
            onAccent: Color(0xFFFFFFFF),
          ),
        // 5 — White: white ACCENT on the dark AMOLED canvas. Off-white base
        // (not pure #FFFFFF) reads as premium pearl, not a blank void. Near-black
        // onAccent keeps CTA labels legible on the pearl fill; bright light keeps
        // accent text/hairlines crisp against black.
        ThemePalette.white => const ThemePaletteTokens(
            base: Color(0xFFF5F5F7),   // pearl-white CTA / active / selected
            light: Color(0xFFE5E5EA),  // bright near-white for accent text on black
            dark: Color(0xFFC7C7CC),   // pressed
            muted: Color(0x24F5F5F7),  // ~14% white tinted fill
            glow: Color(0x1FF5F5F7),   // ~12% white glow
            onAccent: Color(0xFF0A0A0A),// near-black label ON the white fill
          ),
        // 6 — Higgsfield: deep saturated electric chartreuse-lime. High-luminance
        // base needs near-black onAccent so CTA labels stay crisp.
        ThemePalette.higgsfield => const ThemePaletteTokens(
            base: Color(0xFFC8FF00),
            light: Color(0xFFEAFF66),
            dark: Color(0xFF9FCC00),
            muted: Color(0x24C8FF00),
            glow: Color(0x1FC8FF00),
            onAccent: Color(0xFF0A0A0A),
          ),
      };

  /// The solid swatch color shown in the Appearance picker (== base).
  Color get swatch => tokens.base;

  /// The single default accent — the app's designed identity.
  static ThemePalette get fallback => ThemePalette.neonPurple;

  /// Whether this palette has a light base surface. The app is AMOLED-dark for
  /// EVERY palette — White is a white ACCENT on the dark canvas, not a light
  /// theme — so this is always false. Retained as a hook only.
  bool get isLightSurface => false;

  /// Resolves a persisted key back to a palette, defaulting to [fallback] when
  /// the key is absent or unrecognized. Keys from BOTH previous systems (the
  /// original purple/copper/teal/red and the 6-palette premium set) migrate
  /// forward to the nearest neon palette so an existing user never loses their
  /// choice or lands on an unrecognized default.
  static ThemePalette fromStorage(String? key) {
    if (key == null) return fallback;
    for (final p in ThemePalette.values) {
      if (p.storageKey == key) return p;
    }
    return switch (key) {
      // original 4-palette system
      'purple' => ThemePalette.neonPurple,
      'copper' => ThemePalette.neonMagenta,
      'teal' => ThemePalette.neonCyan,
      'red' => ThemePalette.neonMagenta,
      // 6-palette premium system
      'spectralViolet' => ThemePalette.neonPurple,
      'phosphorAmber' => ThemePalette.neonMagenta,
      'steelBlue' => ThemePalette.electricIndigo,
      'chromaticRose' => ThemePalette.neonMagenta,
      'tacticalGreen' => ThemePalette.higgsfield,
      // 'neutralWhite' previously mapped to neonPurple; now maps to White.
      'neutralWhite' => ThemePalette.white,
      _ => fallback,
    };
  }
}
