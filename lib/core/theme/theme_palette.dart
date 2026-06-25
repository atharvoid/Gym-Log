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
  /// CTA label). Near-black (#0A0A0A) on EVERY palette — a dark label on a
  /// saturated fill reads as the crisp, high-end "vibrant control" language
  /// (Apple's tinted-button treatment) and stays uniform across the picker.
  final Color onAccent;

  /// 6-step data-viz ramp for the muscle-split bar, index 0 = dominant
  /// (largest share), index 5 = smallest share. Hand-tuned per accent so the
  /// bar shows clearly distinct tints instead of one flat color.
  final List<Color> muscleSplitRamp;

  const ThemePaletteTokens({
    required this.base,
    required this.light,
    required this.dark,
    required this.muted,
    required this.glow,
    required this.onAccent,
    required this.muscleSplitRamp,
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
        ThemePalette.higgsfield => 'Volt',
      };

  /// Accessibility label for the swatch.
  String get a11yName => switch (this) {
        ThemePalette.neonPurple => 'Purple',
        ThemePalette.neonCyan => 'Cyan',
        ThemePalette.neonMagenta => 'Magenta',
        ThemePalette.electricIndigo => 'Electric indigo',
        ThemePalette.white => 'White',
        ThemePalette.higgsfield => 'Volt',
      };

  /// The six-token set for this palette. muted = 0x24 (~14%), glow = 0x1F
  /// (~12%) — the dark-mode saturation ladder.
  ThemePaletteTokens get tokens => switch (this) {
        // 1 — Neon Purple: the app's on-brand default identity. Pure violet
        // #7F00FF for a deeper, more premium CTA presence than orchid.
        ThemePalette.neonPurple => const ThemePaletteTokens(
            base: Color(0xFF7F00FF),
            light: Color(0xFFB973FF),
            dark: Color(0xFF6300C7),
            muted: Color(0x247F00FF),
            glow: Color(0x1F7F00FF),
            onAccent:
                Color(0xFF0A0A0A), // near-black on every palette — uniform rule
            muscleSplitRamp: [
              Color(0xFF7F00FF),
              Color(0xFF9329FF),
              Color(0xFFA852FF),
              Color(0xFFBC7AFF),
              Color(0xFFD1A3FF),
              Color(0xFFE5CCFF),
            ],
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
            muscleSplitRamp: [
              Color(0xFF00D9FF),
              Color(0xFF29DFFF),
              Color(0xFF52E5FF),
              Color(0xFF7AEBFF),
              Color(0xFFA3F1FF),
              Color(0xFFCCF7FF),
            ],
          ),
        // 3 — Neon Magenta: high-energy magenta-red.
        ThemePalette.neonMagenta => const ThemePaletteTokens(
            base: Color(0xFFFF2D55),
            light: Color(0xFFFF8FA6),
            dark: Color(0xFFC41E3F),
            muted: Color(0x24FF2D55),
            glow: Color(0x1FFF2D55),
            onAccent:
                Color(0xFF0A0A0A), // near-black on every palette — uniform rule
            muscleSplitRamp: [
              Color(0xFFFF2D55),
              Color(0xFFFF4F70),
              Color(0xFFFF708B),
              Color(0xFFFF92A7),
              Color(0xFFFFB3C2),
              Color(0xFFFFD5DD),
            ],
          ),
        // 4 — Electric Indigo: precise, technical blue-purple.
        ThemePalette.electricIndigo => const ThemePaletteTokens(
            base: Color(
                0xFF7C7AFF), // lightened from 0xFF5E5CE6 — black-on-indigo
            // at the original base was ~3.0:1 (tight). At 0xFF7C7AFF it's ~4.0:1,
            // comfortably above the large-text AA threshold while keeping the
            // uniform near-black onAccent rule.
            light: Color(0xFFA6A4FF),
            dark: Color(
                0xFF5E5CE6), // original base becomes the pressed/dark tone
            muted: Color(0x247C7AFF),
            glow: Color(0x1F7C7AFF),
            onAccent:
                Color(0xFF0A0A0A), // near-black on every palette — uniform rule
            muscleSplitRamp: [
              Color(0xFF7C7AFF),
              Color(0xFF918FFF),
              Color(0xFFA6A5FF),
              Color(0xFFBBBAFF),
              Color(0xFFD0CFFF),
              Color(0xFFE5E4FF),
            ],
          ),
        // 5 — White: white ACCENT on the dark AMOLED canvas. Off-white base
        // (not pure #FFFFFF) reads as premium pearl, not a blank void. Near-black
        // onAccent keeps CTA labels legible on the pearl fill; bright light keeps
        // accent text/hairlines crisp against black.
        ThemePalette.white => const ThemePaletteTokens(
            base: Color(0xFFF5F5F7), // pearl-white CTA / active / selected
            light:
                Color(0xFFE5E5EA), // bright near-white for accent text on black
            dark: Color(0xFFC7C7CC), // pressed
            muted: Color(0x24F5F5F7), // ~14% white tinted fill
            glow: Color(0x1FF5F5F7), // ~12% white glow
            onAccent: Color(0xFF0A0A0A), // near-black label ON the white fill
            muscleSplitRamp: [
              Color(0xFFF5F5F7),
              Color(0xFFD2D2D4),
              Color(0xFFB0B0B1),
              Color(0xFF8D8D8E),
              Color(0xFF6A6A6B),
              Color(0xFF474748),
            ],
          ),
        // 6 — Volt: deep saturated electric chartreuse-lime. High-luminance
        // base needs near-black onAccent so CTA labels stay crisp.
        ThemePalette.higgsfield => const ThemePaletteTokens(
            base: Color(0xFFC8FF00),
            light: Color(0xFFEAFF66),
            dark: Color(0xFF9FCC00),
            muted: Color(0x24C8FF00),
            glow: Color(0x1FC8FF00),
            onAccent: Color(0xFF0A0A0A),
            muscleSplitRamp: [
              Color(0xFFC8FF00),
              Color(0xFFD1FF29),
              Color(0xFFDAFF52),
              Color(0xFFE2FF7A),
              Color(0xFFEBFFA3),
              Color(0xFFF4FFCC),
            ],
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
