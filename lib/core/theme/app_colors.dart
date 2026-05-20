import 'package:flutter/material.dart';

/// [app_colors.dart]
/// Purpose: High-Density Tracker - OLED-First Dark Mode
/// Dependencies: flutter/material.dart
/// Last modified: High-Density Tracker Overhaul

abstract class AppColors {
  // Base Layers (OLED-First)
  static const bgBase         = Color(0xFF000000); // Pure Black
  static const bgSurface      = Color(0xFF1C1C1E); // Dark Grey - cards, inputs, sheets

  // Primary Accent (Electric Purple - High Visibility)
  static const accentPrimary  = Color(0xFF8A2BE2); // Electric Purple

  // Text Hierarchy
  static const textPrimary    = Color(0xFFFFFFFF); // Pure White
  static const textSecondary  = Color(0xFF8E8E93); // Muted Grey - labels, timestamps

  // Divider/Border
  static const borderSubtle   = Color(0xFF2C2C2E); // Internal card dividers

  // Semantic (kept minimal)
  static const error          = Color(0xFFFF5449);
  static const success        = Color(0xFF34C759); // iOS green
  static const warning        = Color(0xFFFFCC00); // iOS yellow
}
