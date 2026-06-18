import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Single-line proportional muscle-split bar + legend. Segment widths are ∝ the
/// session's logged set counts; the dominant muscle gets the accent and the
/// rest descending white-opacity steps (see [AppColors.muscleSplitPalette]).
class MuscleSplitSection extends StatelessWidget {
  /// target muscle name → set count for this session.
  final Map<String, int> muscleSetCounts;

  const MuscleSplitSection({super.key, required this.muscleSetCounts});

  @override
  Widget build(BuildContext context) {
    if (muscleSetCounts.isEmpty) return const SizedBox.shrink();

    final sorted = muscleSetCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSets = sorted.fold<int>(0, (s, e) => s + e.value);
    if (totalSets == 0) return const SizedBox.shrink();

    Color colorFor(int rank) => AppColors.muscleSplitPalette[
        rank.clamp(0, AppColors.muscleSplitPalette.length - 1)];

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
              for (var i = 0; i < sorted.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorFor(i),
                        borderRadius: AppRadius.badgeAll,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${sorted[i].key}  ${((sorted[i].value / totalSets) * 100).round()}%',
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
                '${sorted.map((e) => '${e.key} ${((e.value / totalSets) * 100).round()} percent').join(', ')}',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: AppRadius.badgeAll,
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      for (var i = 0; i < sorted.length; i++)
                        Expanded(
                          flex: sorted[i].value < 1 ? 1 : sorted[i].value,
                          child: Container(
                            margin: i < sorted.length - 1
                                ? const EdgeInsets.only(right: 1)
                                : EdgeInsets.zero,
                            color: colorFor(i),
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
