import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'dynamic_accent_theme.dart';
import 'theme_palette.dart';

/// [app_text.dart]
/// GymLog Design System tokens: typography, radius, and spacing. Together with
/// app_colors, this is the single source of truth — never hardcode a size,
/// weight, radius, or spacing value outside these classes.
///
/// Weights: only 300 / 400 / 600 / 700 exist in this app.
/// `FontFeature` resolves via material (used the same way elsewhere), so no
/// `dart:ui` import is needed. Numbers carry tabular figures.

const List<FontFeature> kTabular = <FontFeature>[FontFeature.tabularFigures()];

// ── Text depth / shadow system ──────────────────────────────────────────────
// Premium text-depth shadows. Applied to headings, stat numbers, and exercise
// names across all themes. The shadow is theme-aware:
// - On dark themes (Purple/Cyan/Magenta/Indigo/Higgsfield): a subtle accent-
//   tinted glow at ~8% alpha, 0.5px y-offset, 4px blur.
// - On the White theme: a darker shadow (~18% black) because the base surface
//   is light and an accent-tinted shadow would be invisible.
//
// Usage: pass `shadows: TextDepth.forAccent(context.accent)` to any AppText
// style method. The methods accept an optional `shadows` parameter for
// backward compatibility — when null, no shadow is applied.

abstract class TextDepth {
  /// Accent-tinted etched shadow for dark themes. Returns an empty list when
  /// [accent] is null (backward compatible — no visual change).
  static List<Shadow> forAccent(AccentColors? accent) {
    if (accent == null) return const [];
    return [
      Shadow(
        color: accent.base.withValues(alpha: 0.08),
        offset: const Offset(0, 0.5),
        blurRadius: 4,
      ),
    ];
  }

  /// High-contrast shadow for the White theme — deep grey, not accent-tinted.
  static List<Shadow> forLightSurface() => [
        Shadow(
          color: Colors.black.withValues(alpha: 0.18),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];

  /// For on-accent text placed on high-luminance accent fills (Cyan,
  /// Higgsfield, White), add a dark halo so the text edges stay crisp.
  /// For Magenta, use a dark-magenta halo to deepen the edge without
  /// introducing a different hue. For other palettes, no halo needed.
  static List<Shadow> onAccentHalo(ThemePalette? palette) {
    if (palette == null) return const [];
    if (palette == ThemePalette.neonCyan ||
        palette == ThemePalette.higgsfield ||
        palette == ThemePalette.white) {
      return [
        Shadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 0.5),
          blurRadius: 1.5,
        ),
      ];
    }
    if (palette == ThemePalette.neonMagenta) {
      return [
        Shadow(
          color: const Color(0xFFC41E3F).withValues(alpha: 0.30),
          offset: const Offset(0, 0.5),
          blurRadius: 1.5,
        ),
      ];
    }
    return const [];
  }
}

abstract class AppText {
  /// Screen title (Home, Profile, Routines): 32 / 700.
  static TextStyle screenTitle({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, color: color, shadows: shadows);

  /// Section heading: 20 / 700.
  static TextStyle sectionHeading({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: color, shadows: shadows);

  /// Sheet title (bottom-sheet headings): 18 / 700.
  static TextStyle sheetTitle({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: color, shadows: shadows);

  /// Profile display name: 19 / 700.
  static TextStyle profileName({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.3,
          shadows: shadows);

  /// Profile email / secondary identity: 13 / 400.
  static TextStyle profileEmail({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: color, shadows: shadows);

  /// Stat number (duration, volume, sets): 28 / 700, tabular.
  static TextStyle statNumber({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular,
          shadows: shadows);

  /// Rest-timer display: 48 / 700, tabular.
  static TextStyle timer({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular,
          shadows: shadows);

  /// Hero metric value (collapsing workout-detail header): 22 / 700, tabular.
  static TextStyle heroStat({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular,
          shadows: shadows);

  /// Exercise name: 16 / 600.
  static TextStyle exerciseName({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: color, shadows: shadows);

  /// Set/rep/weight value in the logging table: 16 / 600, tabular.
  static TextStyle value({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: kTabular,
          shadows: shadows);

  /// Body / description: 15 / 400.
  static TextStyle body({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: color, shadows: shadows);

  /// Button label: 16 / 600.
  static TextStyle button({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: color, shadows: shadows);

  /// Column header (SET / REPS / KG): 11 / 600, +0.8 tracking. The ONLY
  /// all-caps text in the app — uppercase the string at the call site.
  static TextStyle columnHeader({
    Color color = AppColors.textTertiary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: color,
          shadows: shadows);

  /// Caption / timestamp: 12 / 400.
  static TextStyle caption({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: color, shadows: shadows);

  /// Badge (PR): 11 / 600, amber.
  static TextStyle badge({
    Color color = AppColors.warning,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: color, shadows: shadows);

  /// Card title (workout / routine card heading): 16 / 700.
  static TextStyle cardTitle({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, color: color, shadows: shadows);

  /// Group header (SETTINGS, ACCOUNT): 11 / 600, +0.8 tracking, textSecondary.
  static TextStyle groupHeader({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: color,
          shadows: shadows);

  /// Stat cell value (stats strip): 17 / 700, tabular.
  static TextStyle statValue({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular,
          shadows: shadows);

  /// List-row label (exercise name inside a feed card): 14 / 600.
  static TextStyle rowLabel({
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: color, shadows: shadows);

  /// Compact stat value (history-card chips): 13 / 600, tabular.
  static TextStyle statLabel({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: kTabular,
          shadows: shadows);

  /// Stat cell label (DAY STREAK, THIS WEEK): 10 / 600, +0.7 tracking.
  static TextStyle statCellLabel({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: color,
          shadows: shadows);

  /// Secondary meta (counts like "3 sets"): 13 / 400.
  static TextStyle meta({
    Color color = AppColors.textSecondary,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: color, shadows: shadows);

  /// Label / badge style (uppercase subheadlines/badges): 12 / 500.
  static TextStyle label({
    Color color = AppColors.textSecondary,
    double letterSpacing = 0.0,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
      );
}

/// Border-radius scale. The premium "sweet spot" curvature: cards and
/// thumbnails 10px, primary CTAs 14px, secondary actions 14px, badges 8px,
/// sheets 12px. Data-entry fields stay sharp at 0px — this is intentional
/// per the design system.
abstract class AppRadius {
  static const double card = 10;
  static const double buttonPrimary = 14;
  static const double buttonSecondary = 14;
  static const double input = 0;
  static const double badge = 8;
  static const double thumbnail = 10;
  static const double sheet = 12;
  static const double segmentedOuter = 14;
  static const double segmentedInner = 12;
  static const double nav = 0;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonPrimaryAll =
      BorderRadius.all(Radius.circular(buttonPrimary));
  static const BorderRadius buttonSecondaryAll =
      BorderRadius.all(Radius.circular(buttonSecondary));
  static const BorderRadius inputAll = BorderRadius.all(Radius.circular(input));
  static const BorderRadius badgeAll = BorderRadius.all(Radius.circular(badge));
  static const BorderRadius thumbnailAll =
      BorderRadius.all(Radius.circular(thumbnail));
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Spacing scale. Base unit 4 — every value is a multiple of 4.
abstract class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;

  static const double screenH = 16;
  static const double cardPad = 16;
  static const double sectionGap = 12;
  static const double elementGap = 12;
  static const double iconText = 10;
  static const double statGap = 8;
}
