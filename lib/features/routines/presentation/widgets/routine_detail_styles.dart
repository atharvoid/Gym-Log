import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';

/// Single source of truth for the Routine Detail screen's typography and
/// surface tokens. Every component pulls from here so the screen stays
/// pixel-consistent with the approved mockup. Inter only.
class RDStyles {
  // ── Header / AppBar ──────────────────────────────────────────────────────
  static TextStyle title = GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.15,
      letterSpacing: -0.2);
  static TextStyle subtitle =
      GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary);

  // ── Buttons ──────────────────────────────────────────────────────────────
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

  // ── Section header + range pill ──────────────────────────────────────────
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

  // ── Chart ────────────────────────────────────────────────────────────────
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
      color: const Color(0xFFA78BFA));

  // ── Exercise block ─────────────────────────────────────────────────────────
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

  // ── Empty state ────────────────────────────────────────────────────────────
  static TextStyle emptyTitle = GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary);
  static TextStyle emptySub =
      GoogleFonts.inter(fontSize: 12, color: AppColors.chartAxisLabel);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const cardGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0E0E11), Color(0xFF09090B)]);
  static Border hairlineBorder =
      Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1);
  static Color hairline = Colors.white.withValues(alpha: 0.06);
}
