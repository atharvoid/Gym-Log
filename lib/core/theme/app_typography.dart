import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// [app_typography.dart]
/// Purpose: Typography system using Space Grotesk (headings) + IBM Plex Mono (numbers/timer)
/// Dependencies: google_fonts, flutter/material.dart, app_colors.dart
/// Last modified: Track 0, Step 0.3

abstract class AppTypography {
  static TextStyle display(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static TextStyle heading(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle body(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );
  static TextStyle mono(BuildContext ctx) => GoogleFonts.ibmPlexMono(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );
  static TextStyle label(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
}
