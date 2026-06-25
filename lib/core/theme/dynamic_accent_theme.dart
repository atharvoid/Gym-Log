import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_palette.dart';

/// [dynamic_accent_theme.dart]
/// Runtime accent-palette state + the plumbing that lets any widget read the
/// live accent.
///
/// ARCHITECTURE (THE SINGLE SOURCE OF TRUTH): the active palette is held in a
/// Riverpod notifier. The root [MaterialApp] watches it and rebuilds
/// [ThemeData] (see app_theme.dart), registering an [AccentColors]
/// ThemeExtension. Leaf widgets read the live accent via `context.accent.base`
/// etc. — no per-widget provider wiring, and it works in both StatelessWidget
/// and ConsumerWidget. Switching the palette rebuilds the theme once and every
/// screen updates consistently within a single frame.
///
/// RULE: any color that is semantically "the accent" — fill, tint, border, the
/// on-accent label, every chart color argument — MUST read from `context.accent`
/// (or watch [accentTokensProvider]). Static accent constants cannot react and
/// are therefore forbidden on accent-derived surfaces.

/// SharedPreferences key for the persisted palette choice.
const String kAccentPaletteKey = 'accent_palette';

/// Seeded by [Bootstrap] (overridden in main.dart) with the palette read from
/// disk BEFORE the first frame, so the app never flashes the default accent for
/// a user who picked another. Defaults to [ThemePalette.fallback] when not
/// overridden (e.g. tests).
final initialAccentPaletteProvider = Provider<ThemePalette>(
  (_) => ThemePalette.fallback,
);

class DynamicAccentNotifier extends Notifier<ThemePalette> {
  @override
  ThemePalette build() => ref.read(initialAccentPaletteProvider);

  /// Updates the active palette and persists the choice. No-op if unchanged.
  Future<void> setPalette(ThemePalette palette) async {
    if (state == palette) return;
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAccentPaletteKey, palette.storageKey);
  }
}

/// The active accent palette. Read this for the enum value (e.g. to highlight
/// the selected swatch); read [accentTokensProvider] for the color tokens.
final dynamicAccentThemeProvider =
    NotifierProvider<DynamicAccentNotifier, ThemePalette>(
  DynamicAccentNotifier.new,
);

/// Convenience: the active palette's color tokens.
final accentTokensProvider = Provider<ThemePaletteTokens>(
  (ref) => ref.watch(dynamicAccentThemeProvider).tokens,
);

/// ThemeExtension carrying the live accent tokens. Registered on [ThemeData]
/// so widgets can read `context.accent.base` without touching Riverpod.
@immutable
class AccentColors extends ThemeExtension<AccentColors> {
  final Color base;
  final Color light;
  final Color dark;
  final Color muted;
  final Color glow;

  /// Text / icon color that sits on the full-saturation [base] (e.g. a CTA
  /// label). White for colored palettes; near-black for the neutral palette.
  final Color onAccent;

  /// 6-step data-viz ramp for the muscle-split bar, index 0 = dominant.
  final List<Color> muscleSplitRamp;

  /// The palette enum that produced these tokens. Used by SurfaceContextX
  /// and TextDepth.onAccentHalo to switch between dark/light surface strategy.
  final ThemePalette palette;

  const AccentColors({
    required this.base,
    required this.light,
    required this.dark,
    required this.muted,
    required this.glow,
    required this.onAccent,
    required this.muscleSplitRamp,
    required this.palette,
  });

  factory AccentColors.fromTokens(ThemePaletteTokens t, ThemePalette p) =>
      AccentColors(
        base: t.base,
        light: t.light,
        dark: t.dark,
        muted: t.muted,
        glow: t.glow,
        onAccent: t.onAccent,
        muscleSplitRamp: t.muscleSplitRamp,
        palette: p,
      );

  /// Saturation-rule helpers — the single place the dark-mode opacity policy
  /// lives, so no widget reinvents "how much accent" with a literal alpha.

  /// Low-opacity accent fill for tinted card/icon/badge/chart backgrounds
  /// (~14%). Use this, NOT full [base], for non-CTA fills.
  Color get tint => base.withValues(alpha: 0.14);

  /// Slightly stronger accent for the border of a selected card/input (~35%).
  Color get selectionBorder => base.withValues(alpha: 0.35);

  /// Whether this palette drives a light surface hierarchy.
  bool get isLightSurface => palette.isLightSurface;

  /// The default accent, for the rare path where a widget needs an accent
  /// before the inherited theme is available (e.g. a State field initializer
  /// that runs ahead of didChangeDependencies). Matches the fallback used by
  /// [AccentColorsContextX.accent] so 'default accent' has one source of truth.
  static AccentColors get fallback => AccentColors.fromTokens(
      ThemePalette.fallback.tokens, ThemePalette.fallback);

  /// Backwards-compatible alias for [fallback]. Retained so existing callers
  /// (e.g. weekly_bar_chart) keep compiling; now resolves to the active
  /// default palette rather than a hardcoded purple.
  static AccentColors get purpleFallback => fallback;

  @override
  AccentColors copyWith({
    Color? base,
    Color? light,
    Color? dark,
    Color? muted,
    Color? glow,
    Color? onAccent,
    List<Color>? muscleSplitRamp,
    ThemePalette? palette,
  }) =>
      AccentColors(
        base: base ?? this.base,
        light: light ?? this.light,
        dark: dark ?? this.dark,
        muted: muted ?? this.muted,
        glow: glow ?? this.glow,
        onAccent: onAccent ?? this.onAccent,
        muscleSplitRamp: muscleSplitRamp ?? this.muscleSplitRamp,
        palette: palette ?? this.palette,
      );

  @override
  AccentColors lerp(ThemeExtension<AccentColors>? other, double t) {
    if (other is! AccentColors) return this;
    return AccentColors(
      base: Color.lerp(base, other.base, t)!,
      light: Color.lerp(light, other.light, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      muscleSplitRamp: t < 0.5 ? muscleSplitRamp : other.muscleSplitRamp,
      palette: t < 0.5 ? palette : other.palette,
    );
  }
}

/// Ergonomic access to the live accent from any widget: `context.accent.base`.
extension AccentColorsContextX on BuildContext {
  AccentColors get accent =>
      Theme.of(this).extension<AccentColors>() ?? AccentColors.fallback;
}
