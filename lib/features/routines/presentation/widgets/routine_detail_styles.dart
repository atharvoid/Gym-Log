import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';

/// Single source of truth for the Routine Detail screen's typography and
/// surface tokens. Every component pulls from here so the screen stays
/// pixel-consistent with the approved mockup. Inter only.
///
/// NOTE: This class is retained because the shared [BrandedLineChart]
/// (used by Profile and Exercise Detail, outside the routines feature) still
/// depends on its chart typography. The color/surface members below now alias
/// [AppColors] tokens; migrating the remaining GoogleFonts text styles onto
/// [AppText] is a cross-cutting change tracked for a shared-widget pass.
class RDStyles {
  // ── Header / AppBar ──────────────────────────────────────────
  static TextStyle title = GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.15,
      letterSpacing: -0.2);
  static TextStyle subtitle =
      GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary);

  // ── Buttons ──────────────────────────────────────────────
  static TextStyle startBtn = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle editBtn = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.86));
  static TextStyle addBtn = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.90));

  // ── Section header + range pill ───────────────────────────────
  static TextStyle sectionLabel = GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle sectionUnit = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary);
  static TextStyle rangePill = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.86));

  // ── Chart ───────────────────────────────────────────────
  static TextStyle chartValue = GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white);
  static TextStyle chartDate = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.accentPrimary);
  static TextStyle axis = GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.chartAxisLabel,
      fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle deltaPill = GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.accentText);

  // ── Exercise block ──────────────────────────────────────────
  static TextStyle exName = GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2);
  static TextStyle exLast =
      GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary);
  static TextStyle tableHeader = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.chartAxisLabel,
      letterSpacing: 0.6);
  static TextStyle setNo = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.90),
      fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle numCell = GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.92),
      fontFeatures: const [FontFeature.tabularFigures()]);

  // ── Empty state ────────────────────────────────────────────
  static TextStyle emptyTitle = GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary);
  static TextStyle emptySub =
      GoogleFonts.inter(fontSize: 12, color: AppColors.chartAxisLabel);

  // ── Surfaces (tokenized: alias AppColors so no feature owns a private surface) ──
  static const cardGradient = AppColors.cardGradient;
  static Border hairlineBorder =
      Border.all(color: AppColors.borderSubtle, width: 1);
  static Color hairline = AppColors.borderSubtle;
}
