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

  // Bottom-sheet / dialog background (was an inline 0xFF121212 in ~5 places)
  static const bgSheet        = Color(0xFF121212);

  // WCAG-safe accent text on pure black. accentPrimary (#8A2BE2) is only ~3.2:1
  // on #000 and FAILS AA as small text; this lighter tint is ~5.9:1 and passes.
  static const accentText     = Color(0xFFB98CFF);

  // Genuinely disabled / decorative text ONLY. At ~3:1 on black this is BELOW
  // the WCAG AA 4.5:1 floor for readable copy — never use it for error/empty
  // body text (use textSecondary). Reserved for disabled controls, which are
  // exempt from the contrast requirement.
  static const textDisabled   = Color(0xFF6A6A6A);

  // Semantic (kept minimal)
  static const error          = Color(0xFFFF5449);
  static const success        = Color(0xFF34C759); // iOS green
  static const warning        = Color(0xFFFFCC00); // iOS yellow

  // Surfaces
  static const surfaceCard    = Color(0xFF0C0C0E);
  static const surfaceRaised  = Color(0xFF141416);
  static const chartAxisLabel = Color(0xFF5A5A5F);

  // Charts
  static const muscleSplitPalette = [
    Color(0xFF8A2BE2), // Electric Purple (primary)
    Color(0xFF7B68EE), // Medium Slate Blue
    Color(0xFFB19CD9), // Light Pastel Purple
    Color(0xFF4B0082), // Indigo
    Color(0xFF9932CC), // Dark Orchid
    Color(0xFF5D3FD3), // Ultra Violet
  ];
}
