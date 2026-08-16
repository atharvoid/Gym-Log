// [explore_cards.dart]
// Cards for the routine-first Explore screen.
//
// DESIGN RULE: at most THREE facts on list cards, crisp visual hierarchy,
// dedicated 44pt tap targets, and OLED-first surface tokens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';
import 'package:gymlog/shared/widgets/body/routine_muscle_glyph.dart';

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
    final accent = Theme.of(context).colorScheme.primary;

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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(color: surface.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoutineMuscleGlyph(
                  primaryGroups: primaryGroups,
                  secondaryGroups: secondaryGroups,
                  highlight: accent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
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
                            fontSize: 12,
                            color: surface.textTertiary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _FactLine(
                        facts: [
                          '${routine.estMinutes} min',
                          '${routine.exerciseCount} exercises',
                          routine.levelLabel,
                          routine.equipmentLabel,
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _AddControl(isOwned: isOwned, onAdd: onAdd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A multi-week commitment. Deliberately shaped differently from a routine
/// card so the two are never mistaken for the same kind of thing.
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
    final accent = Theme.of(context).colorScheme.primary;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
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
                  ),
                  if (importedCount > 0)
                    _StatusPill(
                      label: _isFullyImported
                          ? 'Imported'
                          : '$importedCount of ${routines.length}',
                      color: accent,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _WeekStrip(routines: routines, accent: accent),
              const SizedBox(height: 12),
              _FactLine(
                facts: [
                  '${template.daysPerWeek} days/week',
                  _durationLabel,
                  template.levelLabel,
                  template.equipmentLabel,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The week at a glance: one tick per training day, labelled by focus.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.routines, required this.accent});

  final List<ExploreRoutine> routines;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          for (var i = 0; i < routines.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Flexible(
              child: Container(
                height: 26,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: accent.withAlpha(0x1F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  routines[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: surface.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Up to three facts on one line, separated by middots.
class _FactLine extends StatelessWidget {
  const _FactLine({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final visible = [
      for (final f in facts)
        if (f.trim().isNotEmpty) f,
    ].take(3).toList();

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

/// One-tap add, or a settled "Added" state. Never both, never ambiguous.
class _AddControl extends StatelessWidget {
  const _AddControl({required this.isOwned, required this.onAdd});

  final bool isOwned;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    if (isOwned) {
      return SizedBox(
        width: _kMinTapTarget,
        height: _kMinTapTarget,
        child: Center(
          child: Semantics(
            label: 'Already in your routines',
            child: Icon(Icons.check_rounded, size: 20, color: accent),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Add to my routines',
      child: Material(
        color: accent.withAlpha(0x1F),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onAdd();
          },
          child: SizedBox(
            width: _kMinTapTarget,
            height: _kMinTapTarget,
            child: Icon(Icons.add_rounded, size: 22, color: accent),
          ),
        ),
      ),
    );
  }
}

/// Shared filter chip with a real 44pt target.
class ExploreFilterChip extends StatelessWidget {
  const ExploreFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? accent.withAlpha(0x24) : surface.surface2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: _kMinTapTarget,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? accent.withAlpha(0x66) : surface.borderSubtle,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? accent : surface.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
