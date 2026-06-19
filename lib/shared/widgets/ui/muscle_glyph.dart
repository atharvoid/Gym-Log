import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymlog/core/theme/app_colors.dart';

/// [muscle_glyph.dart]
/// Renders a muscle-group icon for a routine's DOMINANT muscle, tinted via
/// srcIn. SVGs live at `assets/icons/muscles/<group>.svg`.
///
/// Sourcing: simple, original (license-free) glyphs ship by default so the
/// build is green and every group is distinct immediately. To upgrade to a
/// polished pack (e.g. a purchased Flaticon "muscles" set), drop the SVGs at
/// the SAME paths/filenames — zero code change. Do NOT commit a licensed pack
/// into the repo; keep it under your own license.
class MuscleGlyph extends StatelessWidget {
  /// Raw bodyPart / muscle string (any case) — normalized to a group below.
  final String muscle;
  final double size;
  final Color color;

  const MuscleGlyph({
    super.key,
    required this.muscle,
    this.size = 24,
    this.color = AppColors.accentText,
  });

  /// Every group here MUST have a matching asset (and pubspec declaration).
  static const _groups = {
    'arms',
    'back',
    'chest',
    'core',
    'legs',
    'shoulders',
    'fullbody',
  };

  /// Normalizes the app's bodyPart vocabulary (and common synonyms) to one of
  /// [_groups]. Defaults to 'fullbody' so there is always a valid asset.
  static String groupFor(String raw) {
    final m = raw.toLowerCase();
    bool has(List<String> keys) => keys.any((k) => m.contains(k));
    if (has(['chest', 'pec'])) return 'chest';
    if (has(['back', 'lat', 'trap', 'spine'])) return 'back';
    if (has(['shoulder', 'delt'])) return 'shoulders';
    if (has(['arm', 'bicep', 'tricep', 'forearm'])) return 'arms';
    if (has(['core', 'abs', 'abdom', 'waist', 'obliqu'])) return 'core';
    if (has([
      'leg',
      'quad',
      'hamstring',
      'calf',
      'calves',
      'glute',
      'adduct',
      'abduct',
    ])) {
      return 'legs';
    }
    return 'fullbody';
  }

  @override
  Widget build(BuildContext context) {
    final group = groupFor(muscle);
    final name = _groups.contains(group) ? group : 'fullbody';
    return SvgPicture.asset(
      'assets/icons/muscles/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      // Neutral fallback if a file is ever missing — never throws on screen.
      placeholderBuilder: (_) =>
          Icon(Icons.fitness_center_rounded, size: size, color: color),
    );
  }
}
