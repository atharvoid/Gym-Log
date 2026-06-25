import 'package:flutter/material.dart';
import 'dynamic_accent_theme.dart';

/// [app_colors.dart]
/// GymLog Design System — AMOLED-first, Apple Watch Neon palette.
///
/// TOKEN DISCIPLINE: this file is the single source of truth for FIXED color.
/// Never hardcode a color anywhere else. There are two color layers in this app
/// and they must never be confused:
///
///   LAYER 1 — BRAND ACCENT (personalizable, REACTIVE). One hue the user picks
///   in Appearance. It propagates to CTAs, the active nav indicator, selected
///   borders, and the primary chart series. It lives in [ThemePalette] /
///   [AccentColors] and is read via `context.accent.*` — NOT from this file.
///   The accent statics below (accentPrimary/accentText/indigo*) are only the
///   DEFAULT fallback values used before the reactive theme is available.
///
///   LAYER 2 — SEMANTIC ACCENTS (FIXED, never change with the brand accent).
///   success/info/warning/reward carry meaning, so the eye decodes them without
///   thinking. Making them reactive would collapse the signal into brand noise,
///   so they are const here and never pickable.
///
/// DARK-MODE SATURATION LADDER — the one opacity policy for accent-derived
/// color on the AMOLED canvas. Full saturation is a moment, not a wash:
///   small marks (check, dot, ring) ... 100%
///   primary CTA fill ................. 100%  (the single focal hit per view)
///   standard/secondary buttons ....... 80%
///   large tinted surfaces / fills .... 14%
///   selected borders ................. 35%
///   atmospheric glows ................ 12%
/// The reactive helpers live on [AccentColors] (tint/selectionBorder/glow);
/// the fixed-token tints below mirror the same ladder for semantic color.
abstract class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // DARK SURFACE HIERARCHY (AMOLED, build upward in steps)
  // ═══════════════════════════════════════════════════════════════════════════
  static const bgBase    = Color(0xFF000000); // Background — pure void
  static const bgSurface = Color(0xFF0D0D0D); // Surface 1 — default card (most used)
  static const surface2  = Color(0xFF141414); // Surface 2 — elevated cards, charts, modals
  static const surface3  = Color(0xFF1C1C1C); // Surface 3 — inputs, +Add Set, secondary buttons
  static const surface4  = Color(0xFF242424); // Surface 4 — menus, action sheets, tooltips

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT SURFACE HIERARCHY (White palette — inverted luminance ladder)
  // Build DOWNWARD in steps from a near-white base toward darker surfaces.
  // This mirrors the dark hierarchy so the same visual depth layering works.
  // ═══════════════════════════════════════════════════════════════════════════
  static const bgBaseLight    = Color(0xFFF5F5F7); // Background — premium pearl white
  static const bgSurfaceLight = Color(0xFFEBEBEE); // Surface 1 — default card
  static const surface2Light  = Color(0xFFE0E0E3); // Surface 2 — elevated cards, charts, modals
  static const surface3Light  = Color(0xFFD6D6D9); // Surface 3 — inputs, +Add Set, secondary buttons
  static const surface4Light  = Color(0xFFCCCCCF); // Surface 4 — menus, action sheets, tooltips

  // ── Light borders — black at low opacity (mirror of dark white-opacity) ──
  static const borderSubtleLight   = Color(0x1A000000); // black 10% — default card border
  static const borderDefaultLight  = Color(0x33000000); // black 20% — interactive element border
  static const borderEmphasisLight = Color(0x4D000000); // black 30% — focused/selected

  // ── Light text — black at controlled opacity ────────────────────────────
  static const textPrimaryLight   = Color(0xFF1C1C1E); // headings, key numbers
  static const textSecondaryLight = Color(0x66000000); // black 40% — dates, subtitles
  static const textTertiaryLight  = Color(0x40000000); // black 25% — placeholders, column headers
  static const textDisabledLight  = Color(0x26000000); // black 15% — inactive states

  // Legacy surface aliases re-pointed onto the hierarchy.
  static const surfaceCard   = Color(0xFF0D0D0D); // == Surface 1 (dark)
  static const surfaceRaised = Color(0xFF141414); // == Surface 2 (dark)
  static const bgSheet       = Color(0xFF141414); // == Surface 2 (dark)
  static const elevated      = Color(0xFF242424); // == Surface 4 (dark)

  // ── Card surface gradient — the shipped "felt-not-seen" near-black fill ──
  static const cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E0E11), Color(0xFF09090B)],
  );

  // ── Card surface gradient — LIGHT variant ──────────────────────────────
  static const cardGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEFEFF2), Color(0xFFE8E8EB)],
  );

  // ── Borders — white at low opacity (never solid/opaque), + accent focus ──
  static const borderSubtle   = Color(0x0FFFFFFF); // white 6% — default card border
  static const borderDefault  = Color(0x1AFFFFFF); // white 10% — interactive element border
  static const borderEmphasis = Color(0x2EFFFFFF); // white 18% — focused/selected
  static const borderActive   = Color(0xFFBF5AF2); // neon purple — DEFAULT focus (reactive: context.accent.base)
  static const thumbBorder    = Color(0x14FFFFFF); // white 8%  — exercise thumbnail frame
  static const thumbTile      = Color(0xFFF5F5F5); // light tile background
  static const thumbIcon      = Color(0xFF9E9E9E); // neutral icon on light tile

  // ── Brand accent DEFAULT fallback (reactive truth is context.accent.*) ───
  // Apple Watch Neon Purple. These statics exist only for the pre-theme path;
  // every live surface reads the chosen palette via context.accent.
  static const accentPrimary = Color(0xFFBF5AF2); // neon purple — default CTA/active/selected
  static const accentText    = Color(0xFFD9A6FF); // neon purple LIGHT — default accent text on black
  static const accentDark    = Color(0xFF9A3FD0); // neon purple pressed/depressed
  static const accentTint    = Color(0x24BF5AF2); // neon purple 14% — default tinted fill
  static const accentBorder  = Color(0x59BF5AF2); // neon purple 35% — default selected border
  static const accentGlow    = Color(0x1FBF5AF2); // neon purple 12% — default atmospheric glow
  static const canvas        = Color(0xFF0A0A0A); // High-contrast black for CTA background/text

  // Legacy indigo aliases — re-pointed onto the neon-purple default so any
  // straggler call site stays on-brand until migrated to context.accent.
  static const indigo400 = accentText;    // light accent text
  static const indigo500 = accentPrimary; // primary CTA / active / selected
  static const indigo600 = accentDark;    // pressed
  static const indigoTint = accentTint;   // tinted fill
  static const indigoTrack = Color(0x33BF5AF2); // neon purple 20% — generic ring track default
  static const chartAreaFill = Color(0x14BF5AF2); // neon purple 8% — chart area fill (subtle)

  // ── LAYER 2 — semantic accents (FIXED — never follow the brand accent) ──
  static const accentSuccess = Color(0xFF34C759); // iOS system green — completed sets / success
  static const accentInfo    = Color(0xFF00D9FF); // (now unused by timer — see Task 3) kept for any info chips
  static const accentWarning = Color(0xFFFF9F0A); // amber — warm-up sets / warnings
  static const accentReward  = Color(0xFFE6C84A); // PR celebration → GOLD (was magenta #FF2D55)
  static const rewardGold    = Color(0xFFE6C84A); // IMMUTABLE — PR medal / trophy gold
  static const error         = Color(0xFFFF3B30); // iOS system red — delete / errors ONLY

  // Semantic tints — same saturation ladder, fixed hues.
  static const successMark   = accentSuccess;
  static const successTint   = Color(0x2434C759);   // green 14% — completed-set row bg
  static const infoMark      = accentInfo;          // 100% — rest-timer ring
  static const infoTint      = Color(0x2400D9FF);   // cyan 14% — rest-timer track / chip bg
  static const infoTrack     = Color(0x3300D9FF);   // cyan 20% — rest-timer ring track
  static const warningMark   = accentWarning;
  static const warningTint   = Color(0x24FF9F0A);   // amber 14%
  static const rewardMark    = accentReward;        // gold
  static const rewardTint    = Color(0x24E6C84A);   // gold 14% — PR backdrop
  static const errorBorder   = Color(0x99FF3B30);   // red 60% — destructive button border

  // Legacy aliases re-pointed onto the standardized layer.
  static const success        = accentSuccess; // standard green
  static const completionTint = successTint;   // green 14%
  static const warning        = accentWarning;
  static const prBadgeBg     = Color(0x26E6C84A); // gold 15%
  static const prBadgeBorder = Color(0x4DE6C84A); // gold 30%

  // ── Text — white at controlled opacity (NOT hardcoded grey) ─────────────
  static const textPrimary   = Color(0xFFFFFFFF); // headings, key numbers, exercise names
  static const textSecondary = Color(0x99FFFFFF); // white 60% — dates, subtitles, secondary
  static const textTertiary  = Color(0x59FFFFFF); // white 35% — placeholders, column headers
  static const textDisabled  = Color(0x33FFFFFF); // white 20% — inactive states

  // ── Charts ──────────────────────────────────────────────────────────────
  static const chartAxisLabel = Color(0x59FFFFFF); // == textTertiary

  // Profile analytics bar chart.
  // Semantic rule: current week = brand accent (reactive at call site), historical = neutral gray.
  static const profileGraphCurrentBar     = Color(0xFFBF5AF2); // == accentPrimary default — current/latest week
  static const profileGraphCurrentBarBright = Color(0xFFD9A6FF); // == accentText default — touch highlight
  static const profileGraphHistoricalBar  = Color(0xFF2C2C3A); // neutral cool-gray — previous weeks
  static const profileGraphInactiveBar    = Color(0xFF2A2A3A); // in-progress week (mid-week, muted)
  static const profileGraphGhostBar       = Color(0xFF1A1A26); // zero-value slot — barely visible
  static const profileGraphGridLine       = Color(0x14FFFFFF); // white 8% — barely-there guides
  static const profileGraphAxisLabel      = Color(0x59FFFFFF); // == textTertiary
  static const profileGraphTooltipBg      = Color(0xFF242424); // == surface4
  static const profileGraphTooltipShadow  = Color(0x33000000); // 20% black

  // Keep old names as aliases so any future references don't break.
  static const profileGraphActiveBar       = profileGraphCurrentBar;
  static const profileGraphActiveBarBright = profileGraphCurrentBarBright;
  static const profileGraphPreviousBar     = profileGraphHistoricalBar;

  // Muscle-split data-viz fallback palette. Matches the live Purple ramp
  // (index 0 = dominant, index 5 = smallest) for widgets that run before the
  // reactive theme is available.
  static const muscleSplitPalette = [
    Color(0xFF7F00FF), Color(0xFF9329FF), Color(0xFFA852FF),
    Color(0xFFBC7AFF), Color(0xFFD1A3FF), Color(0xFFE5CCFF),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// SurfaceContextX — context-aware surface tokens that switch between dark
// and light hierarchies based on the active palette.
// ═══════════════════════════════════════════════════════════════════════════

/// A bundle of surface tokens for the current brightness mode.
/// Access via `context.surface` — returns [SurfaceTokensDark] for dark
/// palettes and [SurfaceTokensLight] for the White palette.
@immutable
class SurfaceTokens {
  final Color bgBase;
  final Color bgSurface;
  final Color surface2;
  final Color surface3;
  final Color surface4;
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderEmphasis;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final bool isLight;

  const SurfaceTokens({
    required this.bgBase,
    required this.bgSurface,
    required this.surface2,
    required this.surface3,
    required this.surface4,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderEmphasis,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.isLight,
  });

  /// Dark surface tokens (AMOLED hierarchy).
  static const dark = SurfaceTokens(
    bgBase: AppColors.bgBase,
    bgSurface: AppColors.bgSurface,
    surface2: AppColors.surface2,
    surface3: AppColors.surface3,
    surface4: AppColors.surface4,
    borderSubtle: AppColors.borderSubtle,
    borderDefault: AppColors.borderDefault,
    borderEmphasis: AppColors.borderEmphasis,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textDisabled: AppColors.textDisabled,
    isLight: false,
  );

  /// Light surface tokens (White palette hierarchy).
  static const light = SurfaceTokens(
    bgBase: AppColors.bgBaseLight,
    bgSurface: AppColors.bgSurfaceLight,
    surface2: AppColors.surface2Light,
    surface3: AppColors.surface3Light,
    surface4: AppColors.surface4Light,
    borderSubtle: AppColors.borderSubtleLight,
    borderDefault: AppColors.borderDefaultLight,
    borderEmphasis: AppColors.borderEmphasisLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textTertiary: AppColors.textTertiaryLight,
    textDisabled: AppColors.textDisabledLight,
    isLight: true,
  );
}

/// Context extension: `context.surface.bgBase` returns the right surface token
/// for the active palette — dark AMOLED tokens for colored palettes, light
/// tokens for the White palette.
extension SurfaceContextX on BuildContext {
  SurfaceTokens get surface {
    final accent = Theme.of(this).extension<AccentColors>();
    if (accent != null && accent.isLightSurface) return SurfaceTokens.light;
    return SurfaceTokens.dark;
  }
}
