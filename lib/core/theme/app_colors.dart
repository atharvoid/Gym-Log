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

  // ── Borders — white at low opacity (never solid/opaque), + indigo focus ──
  static const borderSubtle   = Color(0x0FFFFFFF); // white 6% — default card border
  static const borderDefault  = Color(0x1AFFFFFF); // white 10% — interactive element border
  static const borderEmphasis = Color(0x2EFFFFFF); // white 18% — focused/selected
  static const borderActive   = Color(0xFF7C3AED); // indigo    — focused inputs, selected cards
  static const thumbBorder    = Color(0x14FFFFFF); // white 8%  — exercise thumbnail frame

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

  // Provisional indigo ramp (replaces the purple palette; revisit visually).
  static const muscleSplitPalette = [
    Color(0xFF7C3AED), // indigo 500
    Color(0xFFA78BFA), // indigo 400
    Color(0xFF6D28D9), // indigo 600
    Color(0xFFC4B5FD), // indigo 300
    Color(0xFF5B21B6), // indigo 800
    Color(0x99FFFFFF), // white 60% (fallback)
  ];
}
