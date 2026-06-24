import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_palette.dart';

/// [dynamic_accent_theme.dart]
/// Runtime accent-palette state + the plumbing that lets any widget read the
/// live accent.
///
/// ARCHITECTURE: the active palette is held in a Riverpod notifier. The root
/// [MaterialApp] watches it and rebuilds [ThemeData] (see app_theme.dart),
/// registering an [AccentColors] ThemeExtension. Leaf widgets read the live
/// accent via `context.accent.base` etc. — no per-widget provider wiring, and
/// it works in both StatelessWidget and ConsumerWidget. Switching the palette
/// rebuilds the theme once and every screen updates consistently.

/// SharedPreferences key for the persisted palette choice.
const String kAccentPaletteKey = 'accent_palette';

/// Seeded by [Bootstrap] (overridden in main.dart) with the palette read from
/// disk BEFORE the first frame, so the app never flashes the default purple
/// for a user who picked another accent. Defaults to purple when not
/// overridden (e.g. tests).
final initialAccentPaletteProvider = Provider<ThemePalette>(
  (_) => ThemePalette.purple,
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

/// Convenience: the active palette's five color tokens.
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

  const AccentColors({
    required this.base,
    required this.light,
    required this.dark,
    required this.muted,
    required this.glow,
  });

  factory AccentColors.fromTokens(ThemePaletteTokens t) => AccentColors(
        base: t.base,
        light: t.light,
        dark: t.dark,
        muted: t.muted,
        glow: t.glow,
      );

  @override
  AccentColors copyWith({
    Color? base,
    Color? light,
    Color? dark,
    Color? muted,
    Color? glow,
  }) =>
      AccentColors(
        base: base ?? this.base,
        light: light ?? this.light,
        dark: dark ?? this.dark,
        muted: muted ?? this.muted,
        glow: glow ?? this.glow,
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
    );
  }
}

/// Ergonomic access to the live accent from any widget: `context.accent.base`.
extension AccentColorsContextX on BuildContext {
  AccentColors get accent =>
      Theme.of(this).extension<AccentColors>() ??
      AccentColors.fromTokens(ThemePalette.purple.tokens);
}
