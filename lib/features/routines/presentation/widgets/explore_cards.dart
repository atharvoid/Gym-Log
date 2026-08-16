// [explore_cards.dart]
// 10/10 Routine and Program cards for GymLog Explore.
//
// DESIGN PRINCIPLES:
// - AMOLED-first surface depth (surface2 base, surface3 raised accents).
// - Clear typography hierarchy: focus kicker -> card title -> program subtitle -> facts.
// - Clean muscle group tag chips instead of crude block glyphs.
// - Dedicated 44pt tap targets with haptics and instant checkmark states.
// - De-loaded program cards with weekly cadence pips and clean metrics (no wall of text).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';

const double _kCardRadius = 16;
const double _kMinTapTarget = 44;

/// One training day. The unit a user can actually do tomorrow.
/// Tapping the card opens deep routine preview; tapping the plus icon adds it.
class ExploreRoutineCard extends StatelessWidget {
  const ExploreRoutineCard({
    super.key,
    required this.routine,
    required this.onAdd,
    this.onTap,
    this.onOpenProgram,
    this.primaryGroups = const <String>{},
    this.secondaryGroups = const <String>{},
    this.isOwned = false,
    this.showProgramLine = true,
  });

  final ExploreRoutine routine;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final VoidCallback? onOpenProgram;
  final Set<String> primaryGroups;
  final Set<String> secondaryGroups;
  final bool isOwned;

  /// Hidden inside program detail, where the program is already the context.
  final bool showProgramLine;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    final targetMuscles = primaryGroups.isNotEmpty
        ? primaryGroups.toList()
        : routine.focus.split(' · ').where((s) => s.isNotEmpty).toList();

    return Semantics(
      button: true,
      label: '${routine.name}, ${routine.estMinutes} minutes, '
          '${routine.exerciseCount} exercises',
      child: Material(
        color: surface.surface2,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kCardRadius),
          onTap: onTap ?? onOpenProgram,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(color: surface.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Focus Kicker / Program Subtitle + Quick-Add Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (routine.focus.isNotEmpty) ...[
                            Text(
                              routine.focus.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: surface.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Text(
                            routine.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: surface.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          if (showProgramLine) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Day ${routine.dayNumber} of ${routine.programLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: surface.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _AddControl(isOwned: isOwned, onAdd: onAdd),
                  ],
                ),

                // Muscle Group Tag Chips
                if (targetMuscles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final muscle in targetMuscles.take(4))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: surface.surface3,
                            borderRadius: AppRadius.badgeAll,
                            border: Border.all(color: surface.borderSubtle),
                          ),
                          child: Text(
                            muscle,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: surface.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Key Facts Line
                _FactLine(
                  facts: [
                    '~${routine.estMinutes} min',
                    '${routine.exerciseCount} exercises',
                    routine.levelLabel,
                    routine.equipmentLabel,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A multi-week commitment. Clean, de-loaded catalog card with 7-day cadence pips.
class ExploreProgramCard extends StatelessWidget {
  const ExploreProgramCard({
    super.key,
    required this.template,
    required this.routines,
    required this.onOpen,
    this.importedCount = 0,
  });

  final RoutineTemplate template;
  final List<ExploreRoutine> routines;
  final VoidCallback onOpen;

  /// How many of this program's routines the user already has.
  final int importedCount;

  bool get _isFullyImported =>
      routines.isNotEmpty && importedCount >= routines.length;

  /// An honest duration range. A program spanning 45 to 80 minute days must
  /// never advertise a single averaged number.
  String get _durationLabel {
    if (routines.isEmpty) return '';
    var min = routines.first.estMinutes;
    var max = min;
    for (final r in routines) {
      if (r.estMinutes < min) min = r.estMinutes;
      if (r.estMinutes > max) max = r.estMinutes;
    }
    return min == max ? '$min min' : '$min-$max min';
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    final kicker =
        '${template.daysPerWeek}-DAY SPLIT \u00b7 ${template.category.toUpperCase()}';

    return Material(
      color: surface.surface2,
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kCardRadius),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(color: surface.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Kicker & Status Pill
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kicker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: surface.textTertiary,
                      ),
                    ),
                  ),
                  if (importedCount > 0)
                    _StatusPill(
                      label: _isFullyImported
                          ? 'Imported'
                          : '$importedCount of ${routines.length} Added',
                      color: accent.base,
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Program Title
              Text(
                template.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: surface.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Cadence & Metrics Row
              Row(
                children: [
                  _WeeklyCadencePips(daysPerWeek: template.daysPerWeek),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FactLine(
                      facts: [
                        '${template.daysPerWeek} days/week',
                        _durationLabel,
                        template.levelLabel,
                        template.equipmentLabel,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimalist 7-dot weekly cadence indicator
class _WeeklyCadencePips extends StatelessWidget {
  const _WeeklyCadencePips({required this.daysPerWeek});

  final int daysPerWeek;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 3.5),
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: i < daysPerWeek ? accent.base : surface.surface4,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

/// Up to four facts on one line, separated by middots.
class _FactLine extends StatelessWidget {
  const _FactLine({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final visible = [
      for (final f in facts)
        if (f.trim().isNotEmpty) f,
    ].take(4).toList();

    return Text(
      visible.join('  \u00b7  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        color: surface.textSecondary,
        height: 1.1,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(0x24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(0x44)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// One-tap add, or a settled "Added" checkmark state.
class _AddControl extends StatelessWidget {
  const _AddControl({required this.isOwned, required this.onAdd});

  final bool isOwned;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final surface = context.surface;

    if (isOwned) {
      return Container(
        width: _kMinTapTarget,
        height: _kMinTapTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withAlpha(0x18),
          borderRadius: AppRadius.badgeAll,
          border: Border.all(color: accent.withAlpha(0x33)),
        ),
        child: Semantics(
          label: 'Already in your routines',
          child: Icon(Icons.check_rounded, size: 20, color: accent),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Add to my routines',
      child: Material(
        color: surface.surface3,
        borderRadius: AppRadius.badgeAll,
        child: InkWell(
          borderRadius: AppRadius.badgeAll,
          onTap: () {
            HapticFeedback.mediumImpact();
            onAdd();
          },
          child: Container(
            width: _kMinTapTarget,
            height: _kMinTapTarget,
            decoration: BoxDecoration(
              borderRadius: AppRadius.badgeAll,
              border: Border.all(color: surface.borderDefault),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 22,
              color: surface.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared filter chip with a real 44pt target and dropdown chevron.
class ExploreFilterChip extends StatelessWidget {
  const ExploreFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showChevron = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? accent.muted : surface.surface2,
        borderRadius: BorderRadius.circular(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? accent.selectionBorder : surface.borderSubtle,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 38,
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent.base,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? accent.base : surface.textSecondary,
                    ),
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: selected ? accent.base : surface.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
