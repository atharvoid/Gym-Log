import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Single source of truth for set-type presentation (normal / warm-up / drop
/// set / failure).
///
/// Before this, every surface hardcoded its own colors — set_row used amber
/// `#E0A422` / red `#FF6B70`, while the workout-detail pills used the design
/// tokens `#F59E0B` / `#EF4444` — so the SAME warm-up set looked different on
/// the logging screen vs the history screen. Everything now resolves through
/// this enum so set types are identical everywhere and on-token.
enum SetType {
  normal(
    raw: 'normal',
    label: 'Normal',
    subtitle: 'Working set',
    short: '', // normal shows the set number, not a letter
    color: AppColors.textPrimary,
    icon: Icons.fitness_center_rounded,
  ),
  warmup(
    raw: 'warmup',
    label: 'Warm-up',
    subtitle: 'Lighter prep work',
    short: 'W',
    color: AppColors.warning,
    icon: Icons.local_fire_department_rounded,
  ),
  dropset(
    raw: 'dropset',
    label: 'Drop set',
    subtitle: 'Reduced weight, no rest',
    short: 'D',
    color: AppColors.accentText,
    icon: Icons.trending_down_rounded,
  ),
  failure(
    raw: 'failure',
    label: 'Failure',
    subtitle: 'Taken to the limit',
    short: 'F',
    color: AppColors.error,
    icon: Icons.warning_amber_rounded,
  );

  const SetType({
    required this.raw,
    required this.label,
    required this.subtitle,
    required this.short,
    required this.color,
    required this.icon,
  });

  /// Storage value ('normal' | 'warmup' | 'dropset' | 'failure').
  final String raw;

  /// Full name for pickers / screen readers ("Warm-up").
  final String label;
  final String subtitle;

  /// One-letter badge for the SET column ('W'/'D'/'F'); empty for normal.
  final String short;
  final Color color;
  final IconData icon;

  /// Resolve a stored string to a [SetType]. Tolerates the legacy 'drop' alias.
  static SetType of(String? value) {
    switch (value) {
      case 'warmup':
        return SetType.warmup;
      case 'dropset':
      case 'drop':
        return SetType.dropset;
      case 'failure':
        return SetType.failure;
      default:
        return SetType.normal;
    }
  }
}
