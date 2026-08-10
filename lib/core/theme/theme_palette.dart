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
  higgsfield,
  neonPurple,
  white,
  neonCyan,
  neonMagenta,
  blazeOrange;

  /// Stable key persisted to SharedPreferences. Decoupled from the index so
  /// reordering the enum never corrupts a saved choice.
  String get storageKey => name;

  /// Human-facing name shown under the swatch in the Appearance screen.
  String get displayName => switch (this) {
        ThemePalette.higgsfield => 'Volt',
        ThemePalette.neonPurple => 'Purple',
        ThemePalette.white => 'White',
        ThemePalette.neonCyan => 'Cyan',
        ThemePalette.neonMagenta => 'Magenta',
        ThemePalette.blazeOrange => 'Orange',
      };

  /// Accessibility label for the swatch.
  String get a11yName => switch (this) {
        ThemePalette.higgsfield => 'Volt',
        ThemePalette.neonPurple => 'Purple',
        ThemePalette.white => 'White',
        ThemePalette.neonCyan => 'Cyan',
        ThemePalette.neonMagenta => 'Magenta',
        ThemePalette.blazeOrange => 'Orange',
      };

  /// The six-token set for this palette. muted = 0x24 (~14%), glow = 0x1F
  /// (~12%) — the dark-mode saturation ladder.
  ThemePaletteTokens get tokens => switch (this) {
        // 1 — Volt: deep saturated electric chartreuse-lime. High-luminance
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
        // 2 — Neon Purple: the app's on-brand purple identity.
        ThemePalette.neonPurple => const ThemePaletteTokens(
            base: Color(0xFFBF00FF),
            light: Color(0xFFD966FF),
            dark: Color(0xFF9900CC),
            muted: Color(0x24BF00FF),
            glow: Color(0x1FBF00FF),
            onAccent:
                Color(0xFF0A0A0A), // near-black on every palette — uniform rule
            muscleSplitRamp: [
              Color(0xFFBF00FF),
              Color(0xFFCC29FF),
              Color(0xFFD952FF),
              Color(0xFFE67AFF),
              Color(0xFFF2A3FF),
              Color(0xFFFECCFF),
            ],
          ),
        // 3 — White: a cool "ice-chrome" accent, not a flat neutral gray. A
        // faint blue undertone (not pure #FFFFFF, not warm gray) puts it in
        // the same cool family as Cyan/Purple instead of reading as "no
        // theme" next to the other five. Near-black onAccent keeps CTA
        // labels legible on the light fill; pure white keeps accent text/
        // hairlines crisp against black.
        ThemePalette.white => const ThemePaletteTokens(
            base: Color(0xFFEAF2FF), // ice-chrome CTA / active / selected
            light: Color(0xFFFFFFFF), // pure white for accent text on black
            dark: Color(0xFFB9C9E0), // pressed — cool steel-blue
            muted: Color(0x24EAF2FF), // ~14% ice-chrome tinted fill
            glow: Color(0x1FEAF2FF), // ~12% ice-chrome glow
            onAccent: Color(0xFF0A0A0A), // near-black label ON the light fill
            muscleSplitRamp: [
              Color(0xFFEAF2FF),
              Color(0xFFCBD9EF),
              Color(0xFFACC0DE),
              Color(0xFF8DA7CE),
              Color(0xFF6E8EBD),
              Color(0xFF4F75AD),
            ],
          ),
        // 4 — Neon Cyan: bright analytical cyan. Near-black on-accent so a CTA
        // label stays legible on the luminous fill.
        ThemePalette.neonCyan => const ThemePaletteTokens(
            base: Color(0xFF00F0FF),
            light: Color(0xFF7FF7FF),
            dark: Color(0xFF00C0CC),
            muted: Color(0x2400F0FF),
            glow: Color(0x1F00F0FF),
            onAccent: Color(0xFF0A0A0A),
            muscleSplitRamp: [
              Color(0xFF00F0FF),
              Color(0xFF29F3FF),
              Color(0xFF52F5FF),
              Color(0xFF7AF8FF),
              Color(0xFFA3FAFF),
              Color(0xFFCCFDFF),
            ],
          ),
        // 5 — Neon Magenta: high-energy magenta-red.
        ThemePalette.neonMagenta => const ThemePaletteTokens(
            base: Color(0xFFFF006E),
            light: Color(0xFFFF66AA),
            dark: Color(0xFFCC0058),
            muted: Color(0x24FF006E),
            glow: Color(0x1FFF006E),
            onAccent:
                Color(0xFF0A0A0A), // near-black on every palette — uniform rule
            muscleSplitRamp: [
              Color(0xFFFF006E),
              Color(0xFFFF338A),
              Color(0xFFFF66A7),
              Color(0xFFFF99C3),
              Color(0xFFFFB3D1),
              Color(0xFFFFCCE0),
            ],
          ),
        // 6 — Blaze Orange: shifted off pure red-orange (which read as
        // hazard-sign, not neon-sign) toward a brighter amber-tangerine —
        // the same full-saturation, mid-lightness "electric" formula as
        // Purple/Cyan/Magenta/Volt — so it glows instead of just warning.
        ThemePalette.blazeOrange => const ThemePaletteTokens(
            base: Color(0xFFFF6600),
            light: Color(0xFFFFA366),
            dark: Color(0xFFCC5200),
            muted: Color(0x24FF6600),
            glow: Color(0x1FFF6600),
            onAccent:
                Color(0xFF0A0A0A), // near-black on every palette — uniform rule
            muscleSplitRamp: [
              Color(0xFFFF6600),
              Color(0xFFFF8533),
              Color(0xFFFFA366),
              Color(0xFFFFC299),
              Color(0xFFFFE0CC),
              Color(0xFFFFF0E6),
            ],
          ),
      };

  /// The solid swatch color shown in the Appearance picker (== base).
  Color get swatch => tokens.base;

  /// The single default accent — the app's designed identity.
  static ThemePalette get fallback => ThemePalette.higgsfield;

  /// Whether this palette has a light base surface. The app is AMOLED-dark for
  /// EVERY palette — White is a white ACCENT on the dark canvas, not a light
  /// theme — so this is always false. Retained as a hook only.
  ///
  /// C29 audit note: this hook has never been flipped to true in production,
  /// and [SurfaceTokens.light] (app_colors.dart) has never been contrast-
  /// verified against [SurfaceTokens.dark] as a result — a spot check found
  /// its text/border alpha values do NOT preserve the dark ladder's contrast
  /// ratios (e.g. textSecondary ≈7.4:1 on dark vs ≈2.8:1 on light, which
  /// fails WCAG's 3:1 floor). Re-derive and re-verify every SurfaceTokens.light
  /// value against WCAG 1.4.3/1.4.11 before ever wiring this to true.
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
      'phosphorAmber' => ThemePalette.blazeOrange,
      'steelBlue' => ThemePalette.neonCyan,
      'chromaticRose' => ThemePalette.neonMagenta,
      'tacticalGreen' => ThemePalette.higgsfield,
      // 'neutralWhite' previously mapped to neonPurple; now maps to White.
      'neutralWhite' => ThemePalette.white,
      // renamed electric indigo -> blaze orange
      'electricIndigo' => ThemePalette.blazeOrange,
      _ => fallback,
    };
  }
}
