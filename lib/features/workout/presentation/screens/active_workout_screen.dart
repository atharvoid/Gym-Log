import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/previous_session_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import '../widgets/exercise_block.dart';
import '../widgets/pr_celebration_overlay.dart';
import '../widgets/rest_timer_bar.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Future<void> _confirmDiscard() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Discard Workout?',
      message: 'All progress from this session will be lost.',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      ref.read(restTimerProvider.notifier).skip();
      ref.read(activeWorkoutProvider.notifier).discardWorkout();
      Navigator.pop(context);
    }
  }

  Future<void> _finish() async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;

    final durationMinutes =
        DateTime.now().difference(workout.startTime).inMinutes;
    final completedSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.isCompleted).length,
    );

    // Warn when 10+ completed sets were logged in under 5 minutes —
    // physically implausible, usually means the timer wasn't started.
    if (completedSets >= 10 && durationMinutes < 5) {
      final confirmed = await showAppConfirmDialog(
        context: context,
        title: 'Short Workout',
        message:
            'This workout lasted under 5 minutes. Finish and save it anyway?',
        confirmLabel: 'Finish Anyway',
        cancelLabel: 'Go Back',
      );
      if (!confirmed) return;
    }

    ref.read(restTimerProvider.notifier).skip();
    final prs = await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (!mounted) return;

    // Celebrate before navigating — the dopamine hit lands while the
    // accomplishment is still on screen.
    if (prs.isNotEmpty) {
      await showPrCelebration(context, prs);
      if (!mounted) return;
    }
    context.go('/');
  }

  Future<void> _saveChanges() async {
    await ref.read(activeWorkoutProvider.notifier).saveEditedWorkout();
    if (mounted) context.go('/');
  }

  /// Toggle completion; when a set flips TO complete in a live session,
  /// auto-start the rest countdown.
  void _toggleSet(int exerciseIndex, int setIndex, {required bool isEditing}) {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    final wasCompleted =
        workout.exercises[exerciseIndex].sets[setIndex].isCompleted;

    ref
        .read(activeWorkoutProvider.notifier)
        .toggleSetCompletion(exerciseIndex, setIndex);

    if (!wasCompleted && !isEditing) {
      final seconds = ref.read(defaultRestSecondsProvider);
      if (seconds > 0) {
        ref.read(restTimerProvider.notifier).start(seconds);
      }
    }
  }

  /// Focus-safe reorder: a dedicated sheet of plain exercise-name tiles.
  /// Because it contains NO text fields, ReorderableListView is safe here —
  /// dragging can't steal focus from a weight/reps input.
  void _showReorderSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A6A6A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reorder Exercises',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag to change the order',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  // Consumer so the list reflects live order as it changes.
                  child: Consumer(
                    builder: (context, ref, _) {
                      final exercises =
                          ref.watch(activeWorkoutProvider)?.exercises ??
                              const [];
                      return ReorderableListView.builder(
                        scrollController: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        buildDefaultDragHandles: false,
                        onReorderStart: (_) => HapticFeedback.selectionClick(),
                        onReorderItem: (oldIndex, newIndex) => ref
                            .read(activeWorkoutProvider.notifier)
                            .reorderExercise(oldIndex, newIndex),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          return Padding(
                            key: ValueKey('reorder_${ex.id}'),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentPrimary
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFCBB2FF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      ex.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        size: 22,
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickUnit(int exerciseId) async {
    final globalUnit = ref.read(weightUnitProvider);
    final current = ref.read(exerciseUnitProvider(exerciseId));
    final selected = await showBrandedPickerSheet<String>(
      context: context,
      title: 'Weight Unit',
      selected: current,
      options: [
        const PickerOption(
          value: 'kg',
          label: 'Kilograms',
          subtitle: 'kg',
          icon: Icons.fitness_center_rounded,
          color: AppColors.textPrimary,
        ),
        const PickerOption(
          value: 'lbs',
          label: 'Pounds',
          subtitle: 'lbs',
          icon: Icons.fitness_center_rounded,
          color: Color(0xFFB98CFF),
        ),
        PickerOption(
          value: '_default',
          label: 'Use app default',
          subtitle: 'Currently $globalUnit — change in Settings',
          icon: Icons.settings_backup_restore_rounded,
          color: AppColors.textSecondary,
        ),
      ],
    );
    if (selected == null) return;
    await ref
        .read(unitOverridesProvider.notifier)
        .setOverride(exerciseId, selected == '_default' ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final timer = ref.watch(workoutTimerProvider);
    final exercisesAsync = ref.watch(exerciseListProvider);
    final restTimer = ref.watch(restTimerProvider);
    final globalUnit = ref.watch(weightUnitProvider);
    final isEditing = workout?.originalSessionId != null;

    // Live investment readout — the session gets visibly more valuable
    // with every completed set.
    final (volumeKg, completedSets) = notifier.sessionTotals;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgBase,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Discard workout',
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: _confirmDiscard,
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Edit Workout' : timer,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: isEditing ? 16 : 19,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isEditing
                            ? timer
                            : completedSets == 0
                                ? 'Log your first set'
                                : '${groupThousands(kgToDisplay(volumeKg, globalUnit))} $globalUnit · $completedSets set${completedSets != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: isEditing ? 'Save' : 'Finish',
                    onPressed: isEditing ? _saveChanges : _finish,
                    isFullWidth: false,
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          // Plain ListView (NOT ReorderableListView): the latter assigns
          // internal per-item GlobalKeys, and a keystroke → updateSet →
          // provider rebuild made those keys collide, throwing
          // "Multiple widgets used the same GlobalKey" and stealing focus
          // from the weight/reps field (keyboard dismissed every tap).
          // A keyed StatefulWidget SetRow inside a plain ListView keeps its
          // FocusNode across rebuilds. Reordering moved to a focus-safe
          // sheet (no live text fields) — see _showReorderSheet.
          Expanded(
            child: workout == null
                ? const SizedBox.shrink()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 140.0),
                    itemCount: workout.exercises.length + 1,
                    itemBuilder: (context, index) {
                      if (index == workout.exercises.length) {
                        return Padding(
                          key: const ValueKey('footer'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: SecondaryButton(
                            label: '+ Add Exercise',
                            onPressed: () async {
                              final selected = await Navigator.push<Exercise>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ExerciseSelectionScreen(),
                                ),
                              );
                              if (selected != null && mounted) {
                                notifier.addExercise(
                                    selected.id, selected.name);
                              }
                            },
                          ),
                        );
                      }

                      final exercise = workout.exercises[index];
                      final driftEx = exercisesAsync.maybeWhen(
                        data: (list) => list
                            .where((e) => e.id == exercise.exerciseId)
                            .firstOrNull,
                        orElse: () => null,
                      );
                      final unit =
                          ref.watch(exerciseUnitProvider(exercise.exerciseId));
                      // Read-only last-session sets for the PREVIOUS column.
                      final previousSets = ref
                          .watch(previousSessionSetsProvider(
                              exercise.exerciseId))
                          .valueOrNull ??
                          const [];

                      return ExerciseBlock(
                        key: ValueKey(exercise.id),
                        exerciseIndex: index,
                        exercise: exercise,
                        driftExercise: driftEx,
                        unit: unit,
                        previousSets: previousSets,
                        onReorderExercises: workout.exercises.length > 1
                            ? _showReorderSheet
                            : null,
                        onRemove: () => notifier.removeExercise(index),
                        onUnitTap: () => _pickUnit(exercise.exerciseId),
                        onReplace: () async {
                          final selected = await Navigator.push<Exercise>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExerciseSelectionScreen(),
                            ),
                          );
                          if (selected != null && mounted) {
                            notifier.replaceExercise(
                                index, selected.id, selected.name);
                          }
                        },
                        onAddSet: () => notifier.addSet(index),
                        onRemoveSet: (setIdx) =>
                            notifier.removeSet(index, setIdx),
                        onSetChanged: (updatedSet) {
                          final setIdx = exercise.sets
                              .indexWhere((s) => s.id == updatedSet.id);
                          if (setIdx != -1) {
                            notifier.updateSet(
                              index,
                              setIdx,
                              weight: updatedSet.weightKg,
                              reps: updatedSet.reps,
                              type: updatedSet.setType,
                            );
                          }
                        },
                        onToggleSetCompletion: (setIdx) =>
                            _toggleSet(index, setIdx, isEditing: isEditing),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Rest timer — the 90-second heartbeat of the session ───────────
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: restTimer == null
            ? const SizedBox.shrink(key: ValueKey('noRest'))
            : RestTimerBar(key: const ValueKey('rest'), state: restTimer),
      ),
    );
  }
}
