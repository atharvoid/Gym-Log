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
/// lightest / most-prominent violet ([AppColors.muscleSplitPalette] index 0);
/// each lesser share steps one shade darker. So the dominant data point is the
/// brightest — the eye lands on what matters most.
abstract class MuscleColorService {
  /// Ranks [muscleSetCounts] (muscle name -> logged set count) by descending
  /// volume and returns ordered slices. The dominant muscle is first and gets
  /// the lightest palette color. Entries with a non-positive count are dropped;
  /// an empty/zero-total input yields an empty list.
  static List<MuscleSplitSlice> rankedSplit(Map<String, int> muscleSetCounts) {
    final entries = muscleSetCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) return const <MuscleSplitSlice>[];
    return [
      for (var i = 0; i < entries.length; i++)
        MuscleSplitSlice(
          muscle: entries[i].key,
          setCount: entries[i].value,
          share: entries[i].value / total,
          color: colorForRank(i),
        ),
    ];
  }

  /// Color for a given volume rank (0 = dominant / largest = lightest). Ranks
  /// beyond the palette length clamp to the darkest shade.
  static Color colorForRank(int rank) {
    final palette = AppColors.muscleSplitPalette;
    return palette[rank.clamp(0, palette.length - 1)];
  }

  /// Accent for a SINGLE dominant-muscle glyph (e.g. a routine card), where the
  /// volume rank is implicitly 0. By the dominant=brightest rule this is the
  /// lightest palette entry, lifted slightly toward white for legibility on the
  /// dark tinted tile. [dominantMuscle] is accepted for call-site clarity and
  /// future per-group theming; the brand is intentionally single-accent today.
  static Color glyphColorFor(String? dominantMuscle) {
    final base = AppColors.muscleSplitPalette.first; // lightest = dominant
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
