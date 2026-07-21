import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';
import 'package:gymlog/shared/widgets/exercise_hero_thumb.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/previous_session_provider.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import 'rest_time_sheet.dart';
import 'set_row.dart';

/// One exercise inside the active workout. Shared card surface (gradient +
/// hairline via AppCard), white heading (accent is for actions, not titles),
/// swipe-to-delete sets, and the branded three-dot sheet.
class ExerciseBlock extends ConsumerWidget {
  final int exerciseIndex;

  /// Opens the focus-safe reorder sheet. Null when there's only one exercise.
  final VoidCallback? onReorderExercises;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  /// Toggles kg/lbs for this exercise — invoked from the tappable column header.
  final VoidCallback? onUnitTap;
  final VoidCallback onAddSet;
  final void Function(int setIndex) onRemoveSet;
  final ValueChanged<WorkoutSetState> onSetChanged;
  final void Function(int setIndex) onToggleSetCompletion;
  final bool enableHero;

  const ExerciseBlock({
    super.key,
    required this.exerciseIndex,
    this.onReorderExercises,
    required this.onRemove,
    required this.onReplace,
    this.onUnitTap,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onSetChanged,
    required this.onToggleSetCompletion,
    this.enableHero = true,
  });

  void _showMenu(BuildContext context, String exerciseName) {
    showActionBottomSheet(
      context: context,
      title: exerciseName,
      items: [
        ActionSheetItem(
          icon: Icons.swap_horiz_rounded,
          iconColor: AppColors.textSecondary,
          iconBackground: AppColors.bgBase,
          title: 'Replace Exercise',
          onTap: (sheetContext) {
            Navigator.pop(sheetContext);
            onReplace();
          },
        ),
        if (onReorderExercises != null)
          ActionSheetItem(
            icon: Icons.swap_vert_rounded,
            iconColor: AppColors.textSecondary,
            iconBackground: AppColors.bgBase,
            title: 'Reorder Exercises',
            onTap: (sheetContext) {
              Navigator.pop(sheetContext);
              onReorderExercises!();
            },
          ),
        ActionSheetItem(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.error.withValues(alpha: 0.12),
          title: 'Remove Exercise',
          titleColor: AppColors.error,
          onTap: (sheetContext) {
            Navigator.pop(sheetContext);
            HapticFeedback.heavyImpact();
            onRemove();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseMeta = ref.watch(activeWorkoutProvider.select((state) {
      if (state == null || exerciseIndex >= state.exercises.length) return null;
      final ex = state.exercises[exerciseIndex];
      // Include measurementType in the tuple so the column headers are always
      // accurate even before the catalog resolves (de == null).
      return (
        ex.exerciseId,
        ex.name,
        ex.sets.map((s) => s.id).join(','),
        ex.measurementType, // $4 — authoritative source
      );
    }));

    if (exerciseMeta == null) return const SizedBox.shrink();

    final exerciseId = exerciseMeta.$1;
    final exerciseName = exerciseMeta.$2;
    final setIds =
        exerciseMeta.$3.isEmpty ? const <String>[] : exerciseMeta.$3.split(',');
    final stateMType = exerciseMeta.$4;

    final catalogById =
        ref.watch(exerciseCatalogByIdProvider).valueOrNull ?? {};
    final de = catalogById[exerciseId];
    final String? rawType =
        stateMType.isNotEmpty ? stateMType : de?.measurementType;
    final mType = (rawType != null && rawType.isNotEmpty)
        ? MeasurementType.fromString(rawType)
        : MeasurementType.inferLegacyMeasurementType(
            equipment: de?.equipment, exerciseName: de?.name);

    final unit = ref.watch(exerciseUnitProvider(exerciseId));
    final previousSets =
        ref.watch(previousSessionSetsProvider(exerciseId)).valueOrNull ??
            const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Container(
        decoration: AppCard.decoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  de != null
                      ? ExerciseHeroThumb(
                          exercise: de,
                          size: 48,
                          enableHero: enableHero,
                        )
                      : const ExerciseThumbnail(gifUrl: null, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: de != null
                              ? () => context.push('/exercise/detail/${de.id}',
                                  extra: de)
                              : null,
                          child: Text(
                            exerciseName,
                            style: AppText.cardTitle(
                                shadows: AppText.depthFor(context)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _RestOverrideChip(
                          exerciseIndex: exerciseIndex,
                          exerciseName: exerciseName,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Exercise options',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.more_horiz_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => _showMenu(context, exerciseName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Column labels — share SetRow's exact column geometry ─────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: kSetColW,
                    child: Text('SET',
                        style: AppText.columnHeader(
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    flex: kPrevFlex,
                    child: Text('PREVIOUS',
                        style: AppText.columnHeader(
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    flex: kWeightFlex,
                    child: !mType.showsWeightColumn
                        ? const SizedBox.shrink()
                        : Center(
                            child: Semantics(
                              button: onUnitTap != null && mType.requiresWeight,
                              label: mType.requiresWeight
                                  ? 'Weight unit ${unit.toUpperCase()}, tap to change'
                                  : 'Distance column',
                              child: GestureDetector(
                                onTap:
                                    (mType.requiresWeight && onUnitTap != null)
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            onUnitTap!();
                                          }
                                        : null,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        mType.isDistance
                                            ? Icons.straighten_rounded
                                            : Icons.fitness_center_rounded,
                                        size: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        mType.fixedWeightColumnLabel ??
                                            unit.toUpperCase(),
                                        style: AppText.columnHeader(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    flex: kRepsFlex,
                    child: Center(
                      child: Text(
                        mType.repsColumnLabel,
                        style: AppText.columnHeader(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: kCheckColW,
                    child: Center(
                      child: Icon(Icons.check_rounded,
                          size: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── Sets ──
            ...setIds.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final setId = entry.value;
              return Consumer(
                key: ValueKey(setId),
                builder: (context, ref, child) {
                  final setData =
                      ref.watch(activeWorkoutProvider.select((state) {
                    if (state == null ||
                        exerciseIndex >= state.exercises.length) {
                      return null;
                    }
                    final ex = state.exercises[exerciseIndex];
                    if (setIndex >= ex.sets.length) return null;
                    return ex.sets[setIndex];
                  }));
                  if (setData == null) return const SizedBox.shrink();

                  final prevSet = setIndex < previousSets.length
                      ? previousSets[setIndex]
                      : null;

                  final row = SetRow(
                    key: ValueKey(setData.id),
                    setIndex: setIndex,
                    setData: setData,
                    measurementType: mType,
                    previousWeight: prevSet?.weightKg,
                    previousReps: prevSet?.reps,
                    unit: unit,
                    onChanged: onSetChanged,
                    onToggleComplete: () => onToggleSetCompletion(setIndex),
                  );

                  return Dismissible(
                    key: ValueKey(setData.id),
                    direction: setData.isCompleted
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    dismissThresholds: const {
                      DismissDirection.endToStart: 0.55,
                    },
                    confirmDismiss: (_) async {
                      HapticFeedback.heavyImpact(); // feel the danger first
                      return true;
                    },
                    onDismissed: (_) => onRemoveSet(setIndex),
                    background: Container(
                      color: AppColors.error.withValues(alpha: 0.85),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    child: row,
                  );
                },
              );
            }),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SecondaryButton(
                label: '+ Add Set',
                accent: true,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAddSet();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestOverrideChip extends ConsumerWidget {
  final int exerciseIndex;
  final String exerciseName;

  const _RestOverrideChip({
    required this.exerciseIndex,
    required this.exerciseName,
  });

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return 'Off';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    RestPreference currentPreference,
    int defaultRest,
  ) async {
    final result = await showRestTimeSheet(
      context: context,
      exerciseName: exerciseName,
      currentPreference: currentPreference,
      globalSeconds: defaultRest,
    );

    if (result != null) {
      ref
          .read(activeWorkoutProvider.notifier)
          .setRestPreference(exerciseIndex, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null || exerciseIndex >= workout.exercises.length) {
      return const SizedBox.shrink();
    }
    final exercise = workout.exercises[exerciseIndex];
    final defaultRest = ref.watch(defaultRestSecondsProvider);
    final preference = normalizeRestPreference(
      preference: exercise.restPreference,
      globalSeconds: defaultRest,
    );

    final accent = context.accent;
    final isCustom = preference is RestPreferenceCustomDuration;
    final isDisabled = isOff(preference);

    String labelText;
    if (isDisabled) {
      labelText = 'Rest Off';
    } else if (preference is RestPreferenceCustomDuration) {
      labelText = 'Rest ${_formatDuration(preference.seconds)} · Custom';
    } else {
      labelText = 'Rest ${_formatDuration(defaultRest)}';
    }

    return Semantics(
      button: true,
      label: 'Set rest duration override. Currently $labelText',
      child: Material(
        color: isDisabled
            ? AppColors.surface3.withValues(alpha: 0.5)
            : (isCustom
                ? accent.base.withValues(alpha: 0.16)
                : AppColors.surface3),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleTap(context, ref, preference, defaultRest),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDisabled ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 14,
                  color: isCustom && !isDisabled
                      ? accent.light
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  labelText,
                  style: AppText.columnHeader(
                    color: isCustom && !isDisabled
                        ? accent.light
                        : AppColors.textSecondary,
                  ).copyWith(fontWeight: isCustom ? FontWeight.bold : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
