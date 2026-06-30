import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';

/// Card-ready "muscles worked" visual: a front+back [MuscleMap] on a subtly
/// accent-tinted rounded tile. Front+back is ~square, so the tile is square
/// and sized by [size]. One consistent muscle visual for Routine + Explore
/// cards (replaces the legacy single-muscle MuscleGlyph).
class MuscleMapThumb extends StatelessWidget {
  final Set<String> primaryGroups;
  final Set<String> secondaryGroups;
  final String gender;
  final double size;

  const MuscleMapThumb({
    super.key,
    required this.primaryGroups,
    this.secondaryGroups = const {},
    this.gender = 'male',
    this.size = 108,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    // Empty/unknown → light the whole figure instead of a blank body.
    final primary = primaryGroups.isEmpty ? const {'Full Body'} : primaryGroups;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.base.withValues(alpha: 0.10),
        borderRadius: AppRadius.thumbnailAll,
      ),
      child: Center(
        child: MuscleMap(
          primaryGroups: primary,
          secondaryGroups: secondaryGroups,
          gender: gender,
          showBack: true,
          showLegend: false,
        ),
      ),
    );
  }
}
