// WCAG AA contrast guard for the dark surface tokens the Explore screen
// relies on. The review claimed the subtitle was "borderline for
// accessibility"; the computed ratios (>= 6:1 for every secondary-text-on-
// surface pair) prove the tokens comply, so this test locks the evidence in
// instead of changing a token that is already compliant.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';

double _channel(double value) {
  final s = value / 255;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _channel(c.r * 255) +
    0.7152 * _channel(c.g * 255) +
    0.0722 * _channel(c.b * 255);

double _contrast(Color a, Color b) {
  final hi = math.max(_luminance(a), _luminance(b));
  final lo = math.min(_luminance(a), _luminance(b));
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('dark surface text tokens meet WCAG AA (4.5:1) on their surfaces', () {
    const dark = SurfaceTokens.dark;
    final checks = <String, double>{
      'subtitle on page background': _contrast(dark.textSecondary, dark.bgBase),
      'subtitle on default card': _contrast(dark.textSecondary, dark.bgSurface),
      'subtitle on elevated card': _contrast(dark.textSecondary, dark.surface2),
      'chip label on surface3': _contrast(dark.textSecondary, dark.surface3),
      'stat chip label on surface3':
          _contrast(dark.textSecondary, dark.surface3),
      'primary text on black': _contrast(dark.textPrimary, dark.bgBase),
      'on-accent (dark label on saturated fill)':
          _contrast(AppColors.canvas, AppColors.accentPrimary),
    };
    for (final entry in checks.entries) {
      expect(
        entry.value,
        greaterThanOrEqualTo(4.5),
        reason: '${entry.key}: ${entry.value.toStringAsFixed(2)}:1 '
            '(WCAG AA requires >= 4.5:1)',
      );
    }
  });

  test('intermediate levelColor is never the brand accent hue', () {
    // On every non-purple palette the intermediate dot was previously rendered
    // in AppColors.accentText (#D9A6FF, neon-purple light) — a static value
    // that accidentally matched the default palette but clashed on amber,
    // fire-red, ice-chrome, higgsfield, and white palettes.
    // Fixed: intermediate now maps to AppColors.accentInfo (#00D9FF, cyan).
    //
    // This test guards the mapping in the data layer (explore_catalog.dart)
    // independently of any widget pump or theme wiring.
    const template = RoutineTemplate(
      name: 'Guard Test Program',
      category: 'Full Body',
      levels: [TemplateLevel.intermediate],
      equipment: ProgramEquipment.fullGym,
      focus: 'Test',
      description: 'Guard test',
      days: [
        ProgramDay(
          label: 'Day 1',
          focus: 'Test',
          slots: [],
        ),
      ],
    );
    expect(template.levelColor, AppColors.accentInfo,
        reason: 'intermediate difficulty must use accentInfo (cyan), not '
            'accentText (neon-purple light) which clashes with non-purple '
            'brand accent palettes');
    expect(template.levelColor, isNot(AppColors.accentText),
        reason: 'accentText is a brand-accent-derived token — forbidden on '
            'semantic difficulty signals');
    expect(template.levelColor, isNot(AppColors.accentPrimary),
        reason: 'accentPrimary is the brand accent base — forbidden on '
            'semantic difficulty signals');
  });
}
