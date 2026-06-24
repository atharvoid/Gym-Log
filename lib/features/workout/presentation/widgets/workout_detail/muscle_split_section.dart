import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/services/muscle_color_service.dart';

/// Single-line proportional muscle-split bar + legend. Segment widths are ∝ the
/// session's logged set counts. Color assignment is delegated to
/// [MuscleColorService]: the dominant muscle gets the deepest ramp color and
/// each lesser share steps lighter (see [AccentColors.muscleSplitRamp]).
class MuscleSplitSection extends StatelessWidget {
  /// target muscle name → set count for this session.
  final Map<String, int> muscleSetCounts;

  const MuscleSplitSection({super.key, required this.muscleSetCounts});

  @override
  Widget build(BuildContext context) {
    final slices = MuscleColorService.rankedSplit(
      muscleSetCounts,
      ramp: context.accent.muscleSplitRamp,
    );
    if (slices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('MUSCLE SPLIT',
                style: AppText.columnHeader(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),

          // Legend: dot · muscle · % of total sets (Wrap never overflows).
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final s in slices)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: AppRadius.badgeAll,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${s.muscle}  ${s.percent}%',
                      style: AppText.caption(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Proportional bar. Color-only on screen → spoken summary attached,
          // decorative segments hidden (the text legend carries the breakdown).
          Semantics(
            label: 'Muscle split: '
                '${slices.map((s) => '${s.muscle} ${s.percent} percent').join(', ')}',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: AppRadius.badgeAll,
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      for (var i = 0; i < slices.length; i++)
                        Expanded(
                          flex: slices[i].setCount < 1 ? 1 : slices[i].setCount,
                          child: Container(
                            margin: i < slices.length - 1
                                ? const EdgeInsets.only(right: 1)
                                : EdgeInsets.zero,
                            color: slices[i].color,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
