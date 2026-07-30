import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';
import 'muscle_map.dart';

/// [muscle_summary.dart]
/// Progressive disclosure for "what does this routine train".
///
/// LAYER 1 — [MuscleSummaryStrip]: always visible, one row, ranked chips.
/// LAYER 2 — [showMuscleMapSheet]: the anatomical figure, on demand, full size.
///
/// Rationale: the muscle map is reference information with a very low re-read
/// rate. A user opening their Push day for the 40th time already knows it hits
/// chest and triceps; what they actually came for is the exercise list and last
/// session's numbers. Reference content that is re-read rarely should not hold
/// prime vertical real estate above the primary content — it should be one tap
/// away and bigger when you get there.

/// Maximum chips rendered before collapsing the remainder into "+n".
///
/// Four is the point where the row still reads as a glanceable summary rather
/// than a list to be parsed. Everything beyond it is available in the sheet.
const int _kMaxVisibleChips = 4;

/// One row of ranked muscle-group chips. Primary groups come first, in accent;
/// secondary groups follow in neutral. Tapping anywhere opens the full map.
class MuscleSummaryStrip extends StatelessWidget {
  final Set<String> primaryGroups;
  final Set<String> secondaryGroups;
  final String gender;

  /// Optional override for the tap action. Defaults to opening the map sheet.
  final VoidCallback? onTap;

  const MuscleSummaryStrip({
    super.key,
    required this.primaryGroups,
    required this.secondaryGroups,
    required this.gender,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (primaryGroups.isEmpty && secondaryGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final accent = context.accent;
    final surface = context.surface;

    // Stable ordering: primaries alphabetically, then secondaries. Alphabetical
    // (not set-iteration order) so the strip does not reshuffle between builds
    // when the underlying set is rebuilt from a different exercise order.
    final primaries = primaryGroups.toList()..sort();
    final secondaries = secondaryGroups.toList()..sort();
    final ordered = <({String label, bool isPrimary})>[
      for (final g in primaries) (label: g, isPrimary: true),
      for (final g in secondaries) (label: g, isPrimary: false),
    ];

    final visible = ordered.take(_kMaxVisibleChips).toList();
    final overflow = ordered.length - visible.length;

    return Semantics(
      button: true,
      label: 'Muscles worked: '
          '${ordered.map((e) => _titleCase(e.label)).join(', ')}. '
          'Opens the full muscle map.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) {
            onTap!();
            return;
          }
          showMuscleMapSheet(
            context: context,
            primaryGroups: primaryGroups,
            secondaryGroups: secondaryGroups,
            gender: gender,
          );
        },
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Icon(Icons.accessibility_new_rounded,
                  size: 16, color: surface.textSecondary),
              const SizedBox(width: 8),
              // Scrollable so a many-muscle routine never wraps to a second
              // line and changes the height of the page.
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: visible.length + (overflow > 0 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    if (i >= visible.length) {
                      return _Chip(
                        label: '+$overflow',
                        fill: surface.surface3,
                        border: surface.borderSubtle,
                        textColor: surface.textSecondary,
                      );
                    }
                    final item = visible[i];
                    return _Chip(
                      label: _titleCase(item.label),
                      fill: item.isPrimary ? accent.muted : surface.surface3,
                      border: item.isPrimary
                          ? accent.base.withValues(alpha: 0.35)
                          : surface.borderSubtle,
                      textColor: item.isPrimary
                          ? accent.light
                          : surface.textSecondary,
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: surface.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fill;
  final Color border;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.fill,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.badgeAll,
        border: Border.all(color: border, width: 1),
      ),
      child: Text(label, style: AppText.statLabel(color: textColor)),
    );
  }
}

/// Full-size muscle map in a 92%-height sheet.
///
/// The map is unchanged — the win is purely that it is no longer squeezed into
/// a scroll position it has to share with a stat strip, a chart, and a list.
Future<void> showMuscleMapSheet({
  required BuildContext context,
  required Set<String> primaryGroups,
  required Set<String> secondaryGroups,
  required String gender,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final surface = sheetCtx.surface;
      return FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          decoration: BoxDecoration(
            color: surface.surface2,
            borderRadius: AppRadius.sheetTop,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: surface.borderEmphasis,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text('Muscles Worked',
                            style: AppText.sheetTitle(
                                color: surface.textPrimary)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: Icon(Icons.close_rounded,
                          size: 22, color: surface.textSecondary),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MuscleMap(
                        primaryGroups: primaryGroups,
                        secondaryGroups: secondaryGroups,
                        gender: gender,
                        showBack: true,
                        showLegend: true,
                      ),
                      const SizedBox(height: 20),
                      if (primaryGroups.isNotEmpty)
                        _GroupList(
                          title: 'PRIMARY',
                          groups: primaryGroups,
                          color: AppColors.textPrimary,
                        ),
                      if (secondaryGroups.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _GroupList(
                          title: 'SECONDARY',
                          groups: secondaryGroups,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _GroupList extends StatelessWidget {
  final String title;
  final Set<String> groups;
  final Color color;

  const _GroupList({
    required this.title,
    required this.groups,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = groups.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppText.columnHeader(color: context.surface.textTertiary)),
        const SizedBox(height: 6),
        Text(
          sorted.map(_titleCase).join('  \u00b7  '),
          style: AppText.body(color: color),
        ),
      ],
    );
  }
}

/// `'lower back' -> 'Lower Back'`. Body-map group keys are lowercase, and
/// title-casing at the presentation layer keeps the data layer canonical.
String _titleCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
