import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/exercises/muscle_split.dart';
import 'package:gymlog/core/theme/app_colors.dart';

/// Renders a session's muscle split: an optional legend (dot · group · %) above
/// a single segmented bar whose widths are proportional to set counts.
///
/// Legend, bar segments, colours, and percentages are all derived from ONE
/// sorted slice list, so they can never drift out of sync. Input is a
/// {muscle group → set count} map (already collapsed to parent groups via
/// [groupMuscleSetsByParent]). Groups beyond the colour palette are merged into
/// a single neutral "Other" slice so colours stay distinct.
class MuscleSplitBar extends StatelessWidget {
  const MuscleSplitBar({
    super.key,
    required this.setCountsByGroup,
    this.showLegend = true,
    this.dense = false,
  });

  final Map<String, int> setCountsByGroup;
  final bool showLegend;

  /// Compact sizing for the home feed card.
  final bool dense;

  static const _otherColor = Color(0xFF48484A);

  @override
  Widget build(BuildContext context) {
    final slices = _buildSlices();
    if (slices.isEmpty) return const SizedBox.shrink();

    final percents = largestRemainderPercents([for (final s in slices) s.sets]);
    final barHeight = dense ? 6.0 : 8.0;
    final dotSize = dense ? 7.0 : 8.0;
    final fontSize = dense ? 10.5 : 11.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLegend) ...[
          Wrap(
            spacing: dense ? 10 : 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < slices.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: slices[i].color,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${slices[i].group}  ${percents[i]}%',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: dense ? 7 : 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            height: barHeight,
            child: Row(
              children: [
                for (var i = 0; i < slices.length; i++)
                  Expanded(
                    flex: slices[i].sets < 1 ? 1 : slices[i].sets,
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
      ],
    );
  }

  /// Sorted (dominant first), palette-coloured slices with the long tail merged
  /// into one neutral "Other" slice.
  List<_Slice> _buildSlices() {
    final entries = setCountsByGroup.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key); // stable
      });
    if (entries.isEmpty) return const [];

    const palette = AppColors.muscleSplitPalette;
    final maxNamed = dense ? 4 : palette.length; // leaves room for "Other"

    final slices = <_Slice>[];
    if (entries.length <= maxNamed) {
      for (var i = 0; i < entries.length; i++) {
        slices.add(_Slice(entries[i].key, entries[i].value, palette[i]));
      }
    } else {
      for (var i = 0; i < maxNamed - 1; i++) {
        slices.add(_Slice(entries[i].key, entries[i].value, palette[i]));
      }
      final otherSets =
          entries.skip(maxNamed - 1).fold<int>(0, (s, e) => s + e.value);
      slices.add(_Slice('Other', otherSets, _otherColor));
    }
    return slices;
  }
}

class _Slice {
  const _Slice(this.group, this.sets, this.color);
  final String group;
  final int sets;
  final Color color;
}
