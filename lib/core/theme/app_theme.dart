import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text.dart';

/// [app_theme.dart]
/// GymLog Design System — AMOLED-first, indigo accent, data over decoration.
/// Every theme text style carries Inter tabular figures. Cards carry a 1px
/// subtle white border (no shadows — invisible on AMOLED black).

TextStyle _ct({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? letterSpacing,
}) =>
    GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: kTabular,
    );

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.inter().fontFamily,

  colorScheme: const ColorScheme.dark(
    surface: AppColors.bgBase,
    surfaceContainerHighest: AppColors.bgSurface,
    primary: AppColors.indigo500,
    onPrimary: AppColors.textPrimary, // white on indigo (spec) ~4.5:1
    secondary: AppColors.indigo400,
    onSecondary: AppColors.bgBase,
    error: AppColors.error,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderSubtle,
  ),

  scaffoldBackgroundColor: AppColors.bgBase,
  cardColor: AppColors.bgSurface,
  dividerColor: AppColors.borderSubtle,

  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgBase,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    // Explicit light status-bar icons on the AMOLED canvas + transparent bar
    // for edge-to-edge (targetSdk 35). Don't leave this to AppBar brightness
    // inference — screens without an AppBar would get no guarantee.
    systemOverlayStyle:
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    titleTextStyle: _ct(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  ),

  // Bottom sheets → 20px top corners, Surface 2.
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surface2,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
  ),

  // Cards → 16px radius + 1px subtle white border (no shadow).
  cardTheme: const CardThemeData(
    elevation: 0,
    color: AppColors.bgSurface,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.cardAll,
      side: BorderSide(color: AppColors.borderSubtle),
    ),
  ),

  // Inputs → 10px, Surface 3 fill, white-10% border, indigo focus ring.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface3,
    border: const OutlineInputBorder(
      borderRadius: AppRadius.inputAll,
      borderSide: BorderSide(color: AppColors.borderDefault),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppRadius.inputAll,
      borderSide: BorderSide(color: AppColors.borderDefault),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadius.inputAll,
      borderSide: BorderSide(color: AppColors.borderActive, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: _ct(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    ),
  ),

  // Primary CTA → 14px (NOT pill), indigo fill, white text, 52px tall.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.indigo500,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: const Size(0, 52),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonPrimaryAll),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      textStyle: _ct(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.indigo400,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: _ct(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
  ),

  textTheme: TextTheme(
    // Headers / titles
    displayLarge: _ct(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineLarge: _ct(
        fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineMedium: _ct(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleLarge: _ct(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),

    // Component labels / values
    titleMedium: _ct(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleSmall: _ct(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),

    // Body
    bodyLarge: _ct(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
    bodyMedium: _ct(
        fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    bodySmall: _ct(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),

    // Labels
    labelLarge: _ct(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    labelMedium: _ct(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    labelSmall: _ct(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
  ),
);

// ── High-contrast variant ───────────────────────────────────────────────────
// Selected automatically by MaterialApp when the OS "increase contrast" setting
// is on. Brightens secondary text and makes borders clearly visible.
const _hcSecondary = Color(0xFFD2D2D7);
const _hcBorder = Color(0xFF8A8A8E);

final appHighContrastTheme = appTheme.copyWith(
  dividerColor: _hcBorder,
  colorScheme: appTheme.colorScheme.copyWith(
    onSurfaceVariant: _hcSecondary,
    outline: _hcBorder,
  ),
  textTheme: appTheme.textTheme.copyWith(
    bodyMedium: appTheme.textTheme.bodyMedium?.copyWith(color: _hcSecondary),
    bodySmall: appTheme.textTheme.bodySmall?.copyWith(color: _hcSecondary),
    labelLarge: appTheme.textTheme.labelLarge?.copyWith(color: _hcSecondary),
    labelMedium: appTheme.textTheme.labelMedium?.copyWith(color: _hcSecondary),
    labelSmall: appTheme.textTheme.labelSmall?.copyWith(color: _hcSecondary),
  ),
);
