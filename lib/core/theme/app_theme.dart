import 'package:flutter/material.dart';
import 'app_colors.dart';

final appTheme = ThemeData(
  useMaterial3: true,
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
  dividerColor: AppColors.border,
  cardTheme: const CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  ),
);
