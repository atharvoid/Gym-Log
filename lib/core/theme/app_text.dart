import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// [app_text.dart]
/// GymLog Design System tokens: typography, radius, and spacing. Together with
/// app_colors, this is the single source of truth — never hardcode a size,
/// weight, radius, or spacing value outside these classes.
///
/// Weights: only 300 / 400 / 600 / 700 exist in this app.
/// `FontFeature` resolves via material (used the same way elsewhere), so no
/// `dart:ui` import is needed. Numbers carry tabular figures.

const List<FontFeature> kTabular = <FontFeature>[FontFeature.tabularFigures()];

abstract class AppText {
  /// Screen title (Home, Profile, Routines): 32 / 700.
  static TextStyle screenTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: color);

  /// Section heading: 20 / 700.
  static TextStyle sectionHeading({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color);

  /// Sheet title (bottom-sheet headings): 18 / 700.
  static TextStyle sheetTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color);

  /// Profile display name: 19 / 700.
  static TextStyle profileName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.3);

  /// Profile email / secondary identity: 13 / 400.
  static TextStyle profileEmail({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: color);

  /// Stat number (duration, volume, sets): 28 / 700, tabular.
  static TextStyle statNumber({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular);

  /// Rest-timer display: 48 / 700, tabular.
  static TextStyle timer({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular);

  /// Hero metric value (collapsing workout-detail header): 22 / 700, tabular.
  /// Smaller than [statNumber] (28) so three pips fit across a phone width.
  static TextStyle heroStat({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular);

  /// Exercise name: 16 / 600.
  static TextStyle exerciseName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  /// Set/rep/weight value in the logging table: 16 / 600, tabular.
  static TextStyle value({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: kTabular);

  /// Body / description: 15 / 400.
  static TextStyle body({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: color);

  /// Button label: 16 / 600.
  static TextStyle button({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  /// Column header (SET / REPS / KG): 11 / 600, +0.8 tracking. The ONLY
  /// all-caps text in the app — uppercase the string at the call site.
  static TextStyle columnHeader({Color color = AppColors.textTertiary}) =>
      GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: color);

  /// Caption / timestamp: 12 / 400.
  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  /// Badge (PR): 11 / 600, amber.
  static TextStyle badge({Color color = AppColors.warning}) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color);

  /// Card title (workout / routine card heading): 16 / 700.
  static TextStyle cardTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color);

  /// Group header (SETTINGS, ACCOUNT): 11 / 600, +0.8 tracking, textSecondary.
  static TextStyle groupHeader({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: color);

  /// Stat cell value (stats strip): 17 / 700, tabular.
  static TextStyle statValue({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: kTabular);

  /// List-row label (exercise name inside a feed card): 14 / 600.
  static TextStyle rowLabel({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  /// Compact stat value (history-card chips): 13 / 600, tabular.
  static TextStyle statLabel({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: kTabular);

  /// Stat cell label (DAY STREAK, THIS WEEK): 10 / 600, +0.7 tracking.
  static TextStyle statCellLabel({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: color);

  /// Secondary meta (counts like "3 sets"): 13 / 400.
  static TextStyle meta({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: color);

  /// Label / badge style (uppercase subheadlines/badges): 12 / 500.
  static TextStyle label({
    Color color = AppColors.textSecondary,
    double letterSpacing = 0.0,
  }) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing,
      );
}

/// Border-radius scale. The premium "sweet spot" curvature: cards and
/// thumbnails 10px, primary CTAs 14px, secondary actions 14px, badges 8px,
/// sheets 12px. Not boxy (6), not pill (24+). Data-entry fields stay sharp
/// at 0px — this is intentional per the design system.
abstract class AppRadius {
  static const double card = 10; // workout/routine/exercise cards
  static const double buttonPrimary = 14; // Start, Finish, primary CTAs
  static const double buttonSecondary = 14; // Add Set, secondary actions
  static const double input = 0; // weight/reps fields (intentional sharp)
  static const double badge = 8; // PR badge, muscle tags, chips, data pills
  static const double thumbnail = 10; // exercise thumbnail container
  static const double sheet = 12; // bottom-sheet / rest-timer top corners
  static const double segmentedOuter = 14;
  static const double segmentedInner = 12;
  static const double nav = 0; // flush to bottom edge

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

  static const double screenH = 16; // screen horizontal padding
  static const double cardPad = 16; // card internal padding
  static const double sectionGap = 12; // between cards
  static const double elementGap = 12; // between rows inside a card
  static const double iconText = 10; // icon → text gap
  static const double statGap = 8; // stat columns internal gap
}
