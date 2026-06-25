import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';

/// [muscle_color_service.dart]
/// Single source of truth for mapping muscle groups to data-viz colors.
///
/// This logic used to be duplicated inline inside presentation widgets
/// (the muscle-split bar) and re-invented ad-hoc elsewhere (a hashCode-based
/// tint in the routine card). Color assignment is one decision; it lives here.
///
/// PERCEPTUAL HIERARCHY (the fix): the mapping is VOLUME-RANKED and
/// luminance-INVERTED. The muscle with the largest logged share gets the
/// darkest / most-prominent color (ramp index 0); each lesser share steps
/// one shade lighter. So the dominant data point is the deepest — the eye
/// lands on what matters most.
///
/// When a reactive `ramp` is passed (e.g. `context.accent.muscleSplitRamp`),
/// the colors follow the live accent palette. When null, the old static
/// `AppColors.muscleSplitPalette` is used (backward compatible).
abstract class MuscleColorService {
  /// Ranks [muscleSetCounts] (muscle name -> logged set count) by descending
  /// volume and returns ordered slices. The dominant muscle is first and gets
  /// the deepest ramp color. Entries with a non-positive count are dropped;
  /// an empty/zero-total input yields an empty list.
  static List<MuscleSplitSlice> rankedSplit(
    Map<String, int> muscleSetCounts, {
    List<Color>? ramp,
  }) {
    final entries = muscleSetCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) return const <MuscleSplitSlice>[];
    final palette = ramp ?? AppColors.muscleSplitPalette;
    final n = entries.length;
    final lastIdx = palette.length - 1;
    return [
      for (var i = 0; i < n; i++)
        MuscleSplitSlice(
          muscle: entries[i].key,
          setCount: entries[i].value,
          share: entries[i].value / total,
          // Spread N slices across the full ramp so even 2 groups get a
          // clearly dark-vs-light pair. rank 0 = deepest (dominant).
          color: palette[(n == 1 ? 0 : (i * lastIdx / (n - 1)).round())
              .clamp(0, lastIdx)],
        ),
    ];
  }

  /// Color for a given volume rank (0 = dominant / largest = deepest). Ranks
  /// beyond the ramp length clamp to the lightest shade.
  static Color colorForRank(int rank, {List<Color>? ramp}) {
    final palette = ramp ?? AppColors.muscleSplitPalette;
    final lastIdx = palette.length - 1;
    // Map rank into the full ramp, distributing lesser ranks toward the light
    // end the same way rankedSplit does for N slices.
    final idx = rank <= 0
        ? 0
        : rank >= lastIdx
            ? lastIdx
            : (rank * lastIdx / (rank + 1)).round();
    return palette[idx.clamp(0, lastIdx)];
  }

  /// Accent for a SINGLE dominant-muscle glyph (e.g. a routine card), where the
  /// volume rank is implicitly 0. By the dominant=deepest rule this is the
  /// deepest ramp entry, lifted slightly toward white for legibility on the
  /// dark tinted tile. [dominantMuscle] is accepted for call-site clarity and
  /// future per-group theming; the brand is intentionally single-accent today.
  static Color glyphColorFor(String? dominantMuscle, {List<Color>? ramp}) {
    final palette = ramp ?? AppColors.muscleSplitPalette;
    final base = palette.first; // deepest = dominant
    return Color.lerp(base, Colors.white, 0.2) ?? base;
  }
}

/// One ranked muscle slice of a session's split: who, how much, and the color
/// the hierarchy assigns it.
class MuscleSplitSlice {
  final String muscle;
  final int setCount;

  /// Fraction of the session's total sets, 0..1.
  final double share;
  final Color color;

  const MuscleSplitSlice({
    required this.muscle,
    required this.setCount,
    required this.share,
    required this.color,
  });

  /// Whole-percent share for display (e.g. 42).
  int get percent => (share * 100).round();
}
