import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Single source of truth for the Routine Detail screen's typography and
/// surface tokens. Every component pulls from here so the screen stays
/// pixel-consistent with the approved mockup. Inter only.
///
/// NOTE: This class is retained because the shared [BrandedLineChart]
/// (used by Profile and Exercise Detail, outside the routines feature) still
/// depends on its chart typography. The color/surface members below now alias
/// [AppColors] tokens; migrating the remaining GoogleFonts text styles onto
/// [AppText] is a cross-cutting change tracked for a shared-widget pass.
///
/// ACCENT RULE: nothing in this file may bake in an accent color. A static
/// const TextStyle cannot react to the runtime palette, so accent-colored text
/// (e.g. the chart's selected-date header) starts from a NEUTRAL style here and
/// has the live accent applied at the call site with
/// `style.copyWith(color: context.accent.light)`.
class RDStyles {
  // ── Header / AppBar ────────────────────────────
  static TextStyle title =
      AppText.heroStat(color: AppColors.textPrimary).copyWith(
    height: 1.15,
    letterSpacing: -0.2,
  );
  static TextStyle subtitle = AppText.meta(color: AppColors.textSecondary);

  // ── Buttons ─────────────────────────
  static TextStyle startBtn = AppText.button(color: Colors.white);
  static TextStyle editBtn = AppText.rowLabel(
    color: Colors.white.withValues(alpha: 0.86),
  );
  static TextStyle addBtn = AppText.body(
    color: Colors.white.withValues(alpha: 0.90),
  ).copyWith(
    fontWeight: FontWeight.w600,
  );

  // ── Section header + range pill ────────────────────
  static TextStyle sectionLabel = AppText.body(
    color: AppColors.textPrimary,
  ).copyWith(
    fontWeight: FontWeight.w600,
  );
  static TextStyle sectionUnit = AppText.meta(
    color: AppColors.textSecondary,
  );
  static TextStyle rangePill = AppText.meta(
    color: Colors.white.withValues(alpha: 0.86),
  );

  // ── Chart ────────────────────────
  static TextStyle chartValue = AppText.heroStat(
    color: Colors.white,
  );
  // NEUTRAL base — the chart's selected-date header is accent-colored, so the
  // consumer applies `chartDate.copyWith(color: context.accent.light)`. Never
  // bake an accent here: a static style is frozen at first load and was the
  // exact cause of the hardcoded-purple date axis.
  static TextStyle chartDate = AppText.body(
    color: AppColors.textSecondary,
  ).copyWith(
    fontWeight: FontWeight.w600,
  );
  static TextStyle axis = AppText.statCellLabel(
    color: AppColors.chartAxisLabel,
  ).copyWith(
    letterSpacing: 0.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  // NEUTRAL base — apply the live accent at the call site if an accent-colored
  // delta is desired (`deltaPill.copyWith(color: context.accent.light)`).
  static TextStyle deltaPill = AppText.caption(
    color: AppColors.textSecondary,
  ).copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );

  // ── Exercise block ───────────────────────────
  static TextStyle exName = AppText.exerciseName(
    color: AppColors.textPrimary,
  ).copyWith(
    fontSize: 17,
    letterSpacing: -0.2,
  );
  static TextStyle exLast = AppText.meta(color: AppColors.textSecondary);
  static TextStyle tableHeader = AppText.columnHeader(
    color: AppColors.chartAxisLabel,
  ).copyWith(
    letterSpacing: 0.6,
  );
  static TextStyle setNo = AppText.body(
    color: Colors.white.withValues(alpha: 0.90),
  ).copyWith(
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle numCell = AppText.statValue(
    color: Colors.white.withValues(alpha: 0.92),
  ).copyWith(
    fontWeight: FontWeight.w600,
  );

  // ── Empty state ─────────────────────────
  static TextStyle emptyTitle = AppText.meta(
    color: AppColors.textSecondary,
  ).copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
  );
  static TextStyle emptySub = AppText.caption(color: AppColors.chartAxisLabel);

  // ── Surfaces (tokenized: alias AppColors so no feature owns a private surface) ──
  static const cardGradient = AppColors.cardGradient;
  static Border hairlineBorder =
      Border.all(color: AppColors.borderSubtle, width: 1);
  static Color hairline = AppColors.borderSubtle;
}
