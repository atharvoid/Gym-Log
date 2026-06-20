import 'package:flutter/material.dart';

/// [app_colors.dart]
/// GymLog Design System — AMOLED-first, indigo as the single source of energy.
///
/// TOKEN DISCIPLINE: this file is the single source of truth for color. Never
/// hardcode a color anywhere else. Token NAMES are preserved from the previous
/// (purple) system so no call site breaks; VALUES are re-pointed. Text and
/// borders are WHITE AT OPACITY (expressed as const ARGB) so they darken
/// consistently across surfaces — never hardcoded grey.
abstract class AppColors {
  // ── Background & surface hierarchy (AMOLED, build upward in steps) ───────
  static const bgBase    = Color(0xFF000000); // Background — pure void
  static const bgSurface = Color(0xFF0D0D0D); // Surface 1 — default card (most used)
  static const surface2  = Color(0xFF141414); // Surface 2 — elevated cards, charts, modals
  static const surface3  = Color(0xFF1C1C1C); // Surface 3 — inputs, +Add Set, secondary buttons
  static const surface4  = Color(0xFF242424); // Surface 4 — menus, action sheets, tooltips

  // Legacy surface aliases re-pointed onto the hierarchy.
  static const surfaceCard   = Color(0xFF0D0D0D); // == Surface 1
  static const surfaceRaised = Color(0xFF141414); // == Surface 2
  static const bgSheet       = Color(0xFF141414); // == Surface 2 (rest timer / dialog bg)
  static const elevated      = Color(0xFF242424); // == Surface 4

  // ── Card surface gradient — the shipped "felt-not-seen" near-black fill ──
  // Single source of truth for card chrome (see AppCard). Promoted here so no
  // feature reaches into another feature's style class for a surface.
  static const cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E0E11), Color(0xFF09090B)],
  );

  // ── Borders — white at low opacity (never solid/opaque), + indigo focus ──
  static const borderSubtle   = Color(0x0FFFFFFF); // white 6% — default card border
  static const borderDefault  = Color(0x1AFFFFFF); // white 10% — interactive element border
  static const borderEmphasis = Color(0x2EFFFFFF); // white 18% — focused/selected
  static const borderActive   = Color(0xFF7C3AED); // indigo    — focused inputs, selected cards
  static const thumbBorder    = Color(0x14FFFFFF); // white 8%  — exercise thumbnail frame
  // Light exercise-thumbnail tile (Hevy-style). Exercise GIFs are baked on
  // white, so a uniform light tile keeps GIF + icon-fallback thumbnails
  // consistent on the dark feed (instead of "white block vs dark block").
  static const thumbTile      = Color(0xFFF5F5F5); // light tile background
  static const thumbIcon      = Color(0xFF9E9E9E); // neutral icon on light tile

  // ── Indigo — the only accent for UI chrome ──────────────────────────────
  static const indigo400 = Color(0xFFA78BFA); // labels, secondary indigo text, chart line
  static const indigo500 = Color(0xFF7C3AED); // primary CTA, active states, selected
  static const indigo600 = Color(0xFF6D28D9); // pressed/active state of indigo buttons
  static const indigoTint = Color(0x1F7C3AED); // indigo 12% — selected-row / active-tab bg
  static const indigoTrack = Color(0x337C3AED); // indigo 20% — rest-timer ring track
  static const chartAreaFill = Color(0x147C3AED); // indigo 8% — chart area fill (subtle)

  // Legacy accent aliases.
  static const accentPrimary = Color(0xFF7C3AED); // == indigo500
  static const accentText    = Color(0xFFA78BFA); // == indigo400 (accent text on black)

  // ── Semantic — each has exactly one job ─────────────────────────────────
  static const success = Color(0xFF10B981); // Completion green — completed-set check + left border ONLY
  static const completionTint = Color(0x0F10B981); // green 6% — completed-set row bg
  static const warning = Color(0xFFF59E0B); // Achievement amber — PR badges / trophy ONLY
  static const prBadgeBg = Color(0x26F59E0B); // amber 15% — PR badge background
  static const prBadgeBorder = Color(0x4DF59E0B); // amber 30% — PR badge border
  static const error = Color(0xFFEF4444); // Destructive red — delete / errors ONLY
  static const errorBorder = Color(0x99EF4444); // red 60% — destructive button border

  // ── Text — white at controlled opacity (NOT hardcoded grey) ─────────────
  static const textPrimary   = Color(0xFFFFFFFF); // headings, key numbers, exercise names
  static const textSecondary = Color(0x99FFFFFF); // white 60% — dates, subtitles, secondary
  static const textTertiary  = Color(0x59FFFFFF); // white 35% — placeholders, column headers
  static const textDisabled  = Color(0x33FFFFFF); // white 20% — inactive states

  // ── Charts ──────────────────────────────────────────────────────────────
  static const chartAxisLabel = Color(0x59FFFFFF); // == textTertiary

  // Profile analytics bar chart — cyan is intentionally distinct from indigo
  // upsells so the graph reads as data, not a premium CTA.
  static const profileGraphActiveBar = Color(0xFF00C9FF);
  static const profileGraphActiveBarBright = Color(0xFF33D4FF);
  static const profileGraphPreviousBar = Color(0xFF3A3A5C);
  static const profileGraphInactiveBar = Color(0xFF2A2A3A);
  static const profileGraphGhostBar = Color(0xFF1E1E2E);
  static const profileGraphGridLine = Color(0xFF1E1E2E);
  static const profileGraphAxisLabel = Color(0xFF8E8E93);
  static const profileGraphTooltipBg = Color(0xFF1C1C24);
  static const profileGraphTooltipShadow = Color(0x33000000); // 20% black

  // Muscle-split data-viz palette — an ORDERED violet ramp, light→dark. The
  // dominant (largest) muscle is leftmost and lightest (most visible on the
  // AMOLED card); each subsequent step darkens. Monotonic ordering is the fix:
  // the old ramp was the same violets in a RANDOM order (500/400/600/300),
  // which read as a muddy smear. Same hue family = on-brand single-accent.
  static const muscleSplitPalette = [
    Color(0xFFC4B5FD), // violet 300 — dominant / largest share
    Color(0xFFA78BFA), // violet 400
    Color(0xFF8B5CF6), // violet 500
    Color(0xFF7C3AED), // violet 600
    Color(0xFF6D28D9), // violet 700
    Color(0xFF5B21B6), // violet 800 — smallest share
  ];
}
