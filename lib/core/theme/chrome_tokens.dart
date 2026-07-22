import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Chrome-specific surface tokens for the navigation shell.
///
/// Bundles the backgrounds, sheet surface, and text colors used by the
/// bottom chrome (nav bar, active-workout bar, resume-draft sheet) so
/// they are tuned as one coherent system rather than individual widgets
/// picking different surface depths.
@immutable
class ChromeTokens {
  /// Scaffold body background (currently [SurfaceTokens.bgBase]).
  final Color background;

  /// Navigation-bar background (currently [SurfaceTokens.bgBase]).
  final Color navBackground;

  /// Active-workout-bar background (currently [SurfaceTokens.surface2]).
  final Color activeBarBg;

  /// Resume-draft sheet background (currently [SurfaceTokens.surface2]).
  final Color sheetBg;

  /// 1 px separator between chrome sections.
  final Color separator;

  /// Secondary text colour for labels and descriptions in chrome surfaces.
  final Color textSecondary;

  const ChromeTokens({
    required this.background,
    required this.navBackground,
    required this.activeBarBg,
    required this.sheetBg,
    required this.separator,
    required this.textSecondary,
  });
}

extension ChromeContextX on BuildContext {
  /// Access chrome tokens from any build context.
  ChromeTokens get chrome {
    final s = surface;
    return ChromeTokens(
      background: s.bgBase,
      navBackground: s.bgBase,
      activeBarBg: s.surface2,
      sheetBg: s.surface2,
      separator: s.borderSubtle,
      textSecondary: s.textSecondary,
    );
  }
}
