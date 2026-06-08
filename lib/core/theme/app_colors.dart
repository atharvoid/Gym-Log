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

  // Charts
  static const muscleSplitPalette = [
    Color(0xFF8A2BE2), // Electric Purple (primary)
    Color(0xFF7B68EE), // Medium Slate Blue
    Color(0xFFB19CD9), // Light Pastel Purple
    Color(0xFF4B0082), // Indigo
    Color(0xFF9932CC), // Dark Orchid
    Color(0xFF5D3FD3), // Ultra Violet
  ];

  // --- Premium routine-detail surfaces (added 2026-06) ---
  static const Color surfaceCard    = Color(0xFF0C0C0E); // chart/empty card base
  static const Color surfaceRaised  = Color(0xFF141416); // ghost buttons, pills, add-exercise
  static const Color chartAxisLabel = Color(0xFF5A5A5F); // chart axis + table header text
}
