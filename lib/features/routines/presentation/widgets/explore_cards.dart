// [explore_cards.dart]
// 10/10 Routine and Program cards for GymLog Explore.
//
// DESIGN PRINCIPLES:
// - AMOLED-first surface depth (surface2 base, surface3 raised accents).
// - Clear typography hierarchy: focus kicker -> card title -> program subtitle -> facts.
// - Clean muscle group tag chips instead of crude block glyphs.
// - Dedicated 44pt tap targets with haptics and instant checkmark states.
// - De-loaded program cards with weekly cadence pips and clean metrics (no wall of text).
// - A card never silently drops information: facts reflow, never ellipsize,
//   and a trimmed list says how much it trimmed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';

const double _kCardRadius = 16;
const double _kMinTapTarget = 44;

/// How many muscle chips render before the rest collapse into a "+N" chip.
/// Four chips filled the row edge to edge on a 360dp phone, which is how the
/// old `.take(4)` managed to hide the overflow it was creating.
const int _kMaxMuscleChips = 3;

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
          '${routine.exerciseCount} exercises'
          '${isOwned ? ", already in your routines" : ""}',
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
                            // Was maxLines: 1 here and 2 on the program card,
                            // so the same length of name clipped on one shelf
                            // and not the other.
                            maxLines: 2,
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
                  _MuscleChips(muscles: targetMuscles),
                ],

                const SizedBox(height: 12),

                // Key Facts
                _FactStrip(
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

    // The card had no Semantics node of its own: a screen reader received a
    // loose pile of texts plus seven unlabelled dots, and nothing said the
    // card was a button.
    return Semantics(
      button: true,
      label: '${template.displayName}, '
          '${template.daysPerWeek} days a week, '
          '${routines.length} training days'
          '${importedCount > 0 ? ", $importedCount already added" : ""}',
      child: Material(
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

                // Cadence + "opens" affordance. The pips used to sit in the
                // same row as the facts and eat ~51dp of it, which guaranteed
                // the duration range and level were ellipsized away.
                Row(
                  children: [
                    _WeeklyCadencePips(daysPerWeek: template.daysPerWeek),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: surface.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Metrics, now with the full width of the card
                _FactStrip(
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
      ),
    );
  }
}

/// Minimalist 7-dot weekly cadence indicator.
///
/// Announced as a sentence: seven unlabelled dots are meaningless to a screen
/// reader, and "4 of 7 dots filled" would be barely better.
class _WeeklyCadencePips extends StatelessWidget {
  const _WeeklyCadencePips({required this.daysPerWeek});

  final int daysPerWeek;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    return Semantics(
      label: 'Trains $daysPerWeek day${daysPerWeek == 1 ? '' : 's'} a week',
      excludeSemantics: true,
      child: Row(
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
      ),
    );
  }
}

/// The facts a user filters on, none of which may be silently dropped.
///
/// Was a single `maxLines: 1` Text of up to four middot-joined facts at
/// 12.5px. Four facts need roughly 330dp; a routine card gives the strip about
/// 300dp on a 360dp phone and a program card gave it ~250dp because the
/// cadence pips shared the row. So `levelLabel` and `equipmentLabel` -- the
/// exact two fields the filter bar exists to filter on -- were ellipsized off
/// almost every card, and at larger text scales even the duration went.
///
/// A reflowing strip fixes the whole class of bug: separators are painted
/// between items instead of being characters inside one ellipsized string, so
/// the strip drops to a second line rather than eating information.
class _FactStrip extends StatelessWidget {
  const _FactStrip({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final visible = [
      for (final f in facts)
        if (f.trim().isNotEmpty) f.trim(),
    ].take(4).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    final style = TextStyle(
      fontSize: 12.5,
      color: surface.textSecondary,
      height: 1.1,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0)
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: surface.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          Text(visible[i], style: style),
        ],
      ],
    );
  }
}

/// Muscle tags, with an honest overflow count.
class _MuscleChips extends StatelessWidget {
  const _MuscleChips({required this.muscles});

  final List<String> muscles;

  @override
  Widget build(BuildContext context) {
    final shown = muscles.take(_kMaxMuscleChips).toList();
    final hidden = muscles.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final muscle in shown) _MuscleChip(label: muscle),
        // `.take(4)` used to discard the remainder in silence, so a pull day
        // hitting six groups advertised four and misrepresented itself.
        if (hidden > 0)
          _MuscleChip(
            label: '+$hidden',
            semanticsLabel: 'and $hidden more muscle groups',
          ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label, this.semanticsLabel});

  final String label;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: surface.surface3,
        borderRadius: AppRadius.badgeAll,
        border: Border.all(color: surface.borderSubtle),
      ),
      child: Text(
        label,
        semanticsLabel: semanticsLabel,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: surface.textSecondary,
        ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
    // Was Theme.of(context).colorScheme.primary while every other widget in
    // this file reads the accent tokens, so this control drifted away from the
    // user's chosen accent.
    final accent = context.accent.base;
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
        // Exactly one of shape/borderRadius, forever: shape carries the radius
        // AND the side, so adding borderRadius here would trip the
        // '!(shape != null && borderRadius != null)' assertion in Material.
        color: selected ? accent.muted : surface.surface2,
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
            // The doc comment promised "a real 44pt target" and then set 38.
            height: _kMinTapTarget,
            constraints: const BoxConstraints(minHeight: _kMinTapTarget),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    softWrap: false,
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
