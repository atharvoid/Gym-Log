import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// [muscle_glyph.dart]
/// Renders a muscle-group icon for a routine's DOMINANT muscle, tinted via
/// srcIn. SVGs live at `assets/icons/muscles/<group>.svg`.
///
/// S16: Theme-reactive SVG system. All glyphs now respect the active accent
/// palette by default. The `color` parameter is optional — when omitted, the
/// glyph reads `context.accent.light` (which lerps nicely between dark and
/// light across all 6 palettes). Detailed SVGs (chest, back, etc.) are also
/// tinted via srcIn so they follow the accent — previously they used their
/// raw embedded colors which broke the dynamic-accent system.
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

  /// Tint applied via `BlendMode.srcIn`. When null, reads the live accent from
  /// the theme (S16: theme-reactive default).
  final Color? color;

  const MuscleGlyph({
    super.key,
    required this.muscle,
    this.size = 24,
    this.color,
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

    // S16: All glyphs are tinted via srcIn — no more raw SVG colors.
    // The default tint reads context.accent.light (theme-reactive).
    final tint = color ?? context.accent.light;

    return SvgPicture.asset(
      'assets/icons/muscles/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      // Neutral fallback if a file is ever missing — never throws on screen.
      placeholderBuilder: (_) =>
          Icon(Icons.fitness_center_rounded, size: size, color: tint),
    );
  }
}
