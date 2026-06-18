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
}

/// Border-radius scale. Pill is deliberately NOT in the system — the largest
/// button radius is 14 on a ~52px control (professional proportion).
abstract class AppRadius {
  static const double card = 16; // workout/routine/exercise cards
  static const double buttonPrimary = 14; // Start, Finish — NOT pill, NOT square
  static const double buttonSecondary = 12; // Add Set, secondary actions
  static const double input = 10; // weight/reps fields
  static const double badge = 6; // PR badge, muscle tags, chips
  static const double thumbnail = 14; // exercise thumbnail container
  static const double sheet = 20; // bottom-sheet / rest-timer top corners
  static const double segmentedOuter = 10;
  static const double segmentedInner = 8;
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
