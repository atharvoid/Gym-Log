import 'package:flutter/material.dart';

/// [app_colors.dart]
/// Purpose: Dark Neo Brutalism color tokens
/// Dependencies: flutter/material.dart
/// Last modified: Track 0, Step 0.2

abstract class AppColors {
  // Surfaces
  static const bgBase       = Color(0xFF0A0A0A); // true black
  static const bgSurface    = Color(0xFF141414); // cards
  static const bgElevated   = Color(0xFF1E1E1E); // inputs, elevated
  static const border       = Color(0xFFFFFFFF); // white borders — neo brutalism
  static const borderMuted  = Color(0xFF333333); // subtle dividers

  // Text
  static const textPrimary  = Color(0xFFFAFAFA);
  static const textSecondary= Color(0xFFA0A0A0);
  static const textMuted    = Color(0xFF606060);

  // Accent — primary interactive color
  static const accent       = Color(0xFFFFE500); // brutal yellow
  static const accentFg     = Color(0xFF0A0A0A); // text ON accent bg

  // Secondary accents
  static const accentGreen  = Color(0xFF00FF87); // set completed
  static const accentRed    = Color(0xFFFF3B3B); // danger/delete
  static const accentPurple = Color(0xFFB14EFF); // PR highlight

  // Semantic
  static const success      = Color(0xFF00FF87);
  static const danger       = Color(0xFFFF3B3B);
  static const warning      = Color(0xFFFFE500);
  static const pr           = Color(0xFFB14EFF);
}
