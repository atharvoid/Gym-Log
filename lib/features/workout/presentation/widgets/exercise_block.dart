import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/database/database.dart';
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
      return (ex.exerciseId, ex.name, ex.sets.map((s) => s.id).toList());
    }));

    if (exerciseMeta == null) return const SizedBox.shrink();

    final exerciseId = exerciseMeta.$1;
    final exerciseName = exerciseMeta.$2;
    final setIds = exerciseMeta.$3;

    final catalogById = ref.watch(exerciseCatalogByIdProvider).valueOrNull ??
        const <int, Exercise>{};
    final de = catalogById[exerciseId];

    final unit = ref.watch(exerciseUnitProvider(exerciseId));
    final previousSets =
        ref.watch(previousSessionSetsProvider(exerciseId)).valueOrNull ??
            const [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: AppCard.decoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 4, 0),
            child: Row(
              children: [
                de != null
                    ? ExerciseHeroThumb(
                        exercise: de,
                        size: 44,
                        enableHero: enableHero,
                      )
                    : const ExerciseThumbnail(gifUrl: null, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: de != null
                        ? () =>
                            context.push('/exercise/detail/${de.id}', extra: de)
                        : null,
                    child: Text(
                      exerciseName,
                      // S3: text-depth shadow on exercise card title
                      style:
                          AppText.cardTitle(shadows: AppText.depthFor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                      style:
                          AppText.columnHeader(color: AppColors.textSecondary)),
                ),
                Expanded(
                  flex: kPrevFlex,
                  child: Text('PREVIOUS',
                      style:
                          AppText.columnHeader(color: AppColors.textSecondary)),
                ),
                Expanded(
                  flex: kWeightFlex,
                  child: Center(
                    child: Semantics(
                      button: onUnitTap != null,
                      label: 'Weight unit ${unit.toUpperCase()}, tap to change',
                      child: GestureDetector(
                        onTap: onUnitTap == null
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onUnitTap!();
                              },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fitness_center_rounded,
                                size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(unit.toUpperCase(),
                                style: AppText.columnHeader(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: kRepsFlex,
                  child: Center(
                    child: Text('REPS',
                        style: AppText.columnHeader(
                            color: AppColors.textSecondary)),
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

          // ── Sets — swipe left to delete (locked once completed) ──
          ...setIds.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final setId = entry.value;
            return Consumer(
              key: ValueKey(setId),
              builder: (context, ref, child) {
                final setData = ref.watch(activeWorkoutProvider.select((state) {
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
    );
  }
}
