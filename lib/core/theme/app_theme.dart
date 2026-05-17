import 'package:flutter/material.dart';
import 'app_colors.dart';

/// [app_theme.dart]
/// Purpose: Global ThemeData for Dark Neo Brutalism
/// Dependencies: flutter/material.dart, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.5

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: AppColors.bgBase,
    surfaceVariant: AppColors.bgSurface,
    primary: AppColors.accent,
    secondary: AppColors.pr,
    error: AppColors.danger,
    onSurface: AppColors.textPrimary,
    outline: AppColors.border,
  ),
  scaffoldBackgroundColor: AppColors.bgBase,
  cardColor: AppColors.bgSurface,
  dividerColor: AppColors.borderMuted,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bgBase,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bgBase,
    shape: RoundedRectangleBorder(),
  ),
  cardTheme: const CardTheme(
    elevation: 0,
    color: AppColors.bgSurface,
    shape: RoundedRectangleBorder(),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgElevated,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.border, width: 2),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.border, width: 2),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.accent, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.accentFg,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textPrimary),
    bodySmall: TextStyle(color: AppColors.textSecondary),
    titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
    titleSmall: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
    labelLarge: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
  ),
);
