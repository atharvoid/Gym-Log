import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// [app_theme.dart]
/// Purpose: High-Density Tracker - OLED-First, Data over Decoration
/// Dependencies: flutter/material.dart, google_fonts, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.inter().fontFamily,
  
  colorScheme: const ColorScheme.dark(
    surface: AppColors.bgBase,
    surfaceContainerHighest: AppColors.bgSurface,
    primary: AppColors.accentPrimary,
    onPrimary: AppColors.textPrimary,
    secondary: AppColors.bgSurface,
    onSecondary: AppColors.textPrimary,
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
    // Kill M3's scroll-under tint: on OLED black it renders as a faint
    // purple-grey band behind the title the moment content scrolls under.
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    titleTextStyle: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
  ),
  
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
  ),
  
  cardTheme: const CardThemeData(
    elevation: 0,
    color: AppColors.bgSurface,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgSurface,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.accentPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentPrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.accentPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
    ),
  ),
  
  textTheme: TextTheme(
    // Headers: Bold, high-tracking
    displayLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    
    // Data points: Semi-bold
    titleMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    
    // Body text
    bodyLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    
    // Subtext: Regular, smaller
    bodySmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    labelMedium: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelSmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    ),
  ),
);
