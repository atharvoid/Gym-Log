import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import '../widgets/exercise_block.dart';
import '../widgets/pr_celebration_overlay.dart';
import '../widgets/rest_timer_bar.dart';
import '../widgets/finish_summary_sheet.dart';

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
    if (!tapGuard()) return; // no double-tap → double sheet / double save
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
    if (!mounted) return;

    // Pre-fill with the routine name (when started from one) or a time-of-day
    // default. Cancelling the sheet backs out of finishing — nothing is saved.
    final preFill = (workout.name != null && workout.name!.trim().isNotEmpty)
        ? workout.name!.trim()
        : getWorkoutNameFallback(workout.startTime, null);
    final (volumeKg, sets) =
        ref.read(activeWorkoutProvider.notifier).sessionTotals;

    // The session recap + name in one premium sheet (replaces the bare dialog):
    // the user sees what they earned, names it, and confirms.
    final name = await showFinishSummarySheet(
      context: context,
      duration: DateTime.now().difference(workout.startTime),
      volumeKg: volumeKg,
      sets: sets,
      unit: ref.read(weightUnitProvider),
      initialName: preFill,
    );
    if (name == null || !mounted) return; // cancelled → stay in the session

    ref.read(restTimerProvider.notifier).skip();

    // The root navigator outlives this screen, so the PR celebration can land
    // over Home rather than over the (about-to-be-torn-down) active screen.
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    try {
      final prs = await ref
          .read(activeWorkoutProvider.notifier)
          .finishWorkout(name: name);
      if (!mounted) return;
      HapticFeedback.heavyImpact(); // saved — definitive success cue
      // Leave the workout screen FIRST, then celebrate over Home next frame
      // (no z-order glitch, no jump-back).
      context.go('/');
      if (prs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPrCelebration(rootNavigator.context, prs);
        });
      }
    } catch (e) {
      // Save failed — keep the user IN the session (nothing lost) + tell them.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't save the workout — your session is safe. Try again.",
            style: AppText.body(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.error.withValues(alpha: 0.92),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
  ///
  /// The sheet renders from a LOCAL snapshot (not a watched provider) and uses
  /// a fixed-height modal rather than DraggableScrollableSheet. That removes
  /// the two glitch sources of the old version: (1) the watched list rebuilding
  /// the ReorderableListView mid drop-animation, and (2) edge auto-scroll
  /// fighting the draggable sheet over a shared ScrollController.
  void _showReorderSheet() {
    final snapshot = ref.read(activeWorkoutProvider)?.exercises;
    if (snapshot == null || snapshot.length < 2) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ReorderExercisesSheet(
        initialExercises: snapshot,
        onReorder: (oldIndex, newIndex) => ref
            .read(activeWorkoutProvider.notifier)
            .reorderExercise(oldIndex, newIndex),
      ),
    );
  }

  Future<void> _pickUnit(int exerciseIndex) async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null || exerciseIndex >= workout.exercises.length) return;
    final exerciseId = workout.exercises[exerciseIndex].exerciseId;
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
          color: AppColors.textPrimary,
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

  /// Builds the "Add Exercise" button that appears at the end of the
  /// scrollable exercise list (S12.2).
  Widget _buildAddExerciseButton(ActiveWorkoutNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Material(
        color: AppColors.surface3,
        borderRadius: AppRadius.buttonSecondaryAll,
        child: InkWell(
          borderRadius: AppRadius.buttonSecondaryAll,
          onTap: () async {
            final selected =
                await context.push<Exercise>('/exercises/select');
            if (selected != null && mounted) {
              notifier.addExercise(selected.id, selected.name);
            }
          },
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: AppRadius.buttonSecondaryAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Exercise',
                  style: AppText.button(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutExists = ref.watch(activeWorkoutProvider.select((state) => state != null));
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final restTimer = ref.watch(restTimerProvider);
    final globalUnit = ref.watch(weightUnitProvider);
    final isEditing = ref.watch(activeWorkoutProvider.select((state) => state?.originalSessionId != null));

    final exerciseIds = ref.watch(activeWorkoutProvider.select((state) => state?.exercises.map((e) => e.id).toList() ?? const <String>[]));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
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
                  MergeSemantics(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final timer = ref.watch(workoutTimerProvider);
                        final totals = ref.watch(activeWorkoutProvider.select((state) {
                          if (state == null) return (0.0, 0);
                          double volume = 0;
                          int completed = 0;
                          for (final ex in state.exercises) {
                            for (final set in ex.sets) {
                              if (set.isCompleted) {
                                volume += set.weightKg * set.reps;
                                completed++;
                              }
                            }
                          }
                          return (volume, completed);
                        }));
                        final volumeKg = totals.$1;
                        final completedSets = totals.$2;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isEditing ? 'Edit Workout' : timer,
                              style: isEditing ? AppText.cardTitle() : AppText.heroStat(),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isEditing
                                  ? timer
                                  : completedSets == 0
                                      ? 'Log your first set'
                                      : '${groupThousands(kgToDisplay(volumeKg, globalUnit))} $globalUnit · $completedSets set${completedSets != 1 ? 's' : ''}',
                              style: AppText.statLabel(),
                            ),
                          ],
                        );
                      },
                    ),
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
          //
          // S12.2: The "Add Exercise" button is now the LAST item in the
          // scrollable list — it scrolls into view at the end instead of
          // being permanently fixed at the bottom. The bottomNavigationBar
          // now only hosts the rest timer bar.
          Expanded(
            child: !workoutExists
                ? const SizedBox.shrink()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 100.0,
                    ),
                    // +1 item: the last slot is the "Add Exercise" button.
                    itemCount: exerciseIds.length + 1,
                    itemBuilder: (context, index) {
                      // Last item → Add Exercise button at end of list.
                      if (index == exerciseIds.length) {
                        return _buildAddExerciseButton(notifier);
                      }
                      return ExerciseBlock(
                        key: ValueKey(exerciseIds[index]),
                        exerciseIndex: index,
                        onReorderExercises: exerciseIds.length > 1
                            ? _showReorderSheet
                            : null,
                        onRemove: () => notifier.removeExercise(index),
                        onUnitTap: () => _pickUnit(index),
                        onReplace: () async {
                          final selected =
                              await context.push<Exercise>('/exercises/select');
                          if (selected != null && mounted) {
                            notifier.replaceExercise(
                                index, selected.id, selected.name);
                          }
                        },
                        onAddSet: () => notifier.addSet(index),
                        onRemoveSet: (setIdx) =>
                            notifier.removeSet(index, setIdx),
                        onSetChanged: (updatedSet) {
                          final workout = ref.read(activeWorkoutProvider);
                          if (workout == null || index >= workout.exercises.length) return;
                          final exercise = workout.exercises[index];
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
      // S12.2: bottomNavigationBar now ONLY hosts the rest timer bar.
      // The "Add Exercise" button was moved to the end of the scrollable list.
      bottomNavigationBar: !workoutExists || restTimer == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.bgBase,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
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
                  child: RestTimerBar(key: const ValueKey('rest'), state: restTimer),
                ),
              ),
            ),
    ),
    );
  }
}

/// The reorder sheet body. Owns a LOCAL, mutable copy of the exercise order so
/// the ReorderableListView is never rebuilt by an external provider change
/// while a drop animation is settling — the single biggest cause of the old
/// reorder glitch. Each drop mutates the local list (smooth animation) and
/// forwards the same move to the provider via [onReorder] to persist it.
class _ReorderExercisesSheet extends StatefulWidget {
  final List<WorkoutExerciseState> initialExercises;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ReorderExercisesSheet({
    required this.initialExercises,
    required this.onReorder,
  });

  @override
  State<_ReorderExercisesSheet> createState() => _ReorderExercisesSheetState();
}

class _ReorderExercisesSheetState extends State<_ReorderExercisesSheet> {
  late final List<WorkoutExerciseState> _items =
      List<WorkoutExerciseState>.from(widget.initialExercises);

  @override
  Widget build(BuildContext context) {
    // Cap the sheet height so a long list scrolls INSIDE the list (its own
    // controller) instead of resizing the sheet — no controller tug-of-war.
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.sheetTop,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderEmphasis,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reorder Exercises',
            style: AppText.cardTitle(),
          ),
          const SizedBox(height: 4),
          Text(
            'Drag to change the order',
            style: AppText.meta(),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              buildDefaultDragHandles: false,
              onReorderStart: (_) => HapticFeedback.selectionClick(),
              onReorderItem: (oldIndex, newIndex) {
                // Local mutation drives the smooth drop animation; the same
                // move is forwarded to the provider to persist the order.
                setState(() {
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
                widget.onReorder(oldIndex, newIndex);
              },
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final ex = _items[index];
                return Padding(
                  key: ValueKey('reorder_${ex.id}'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      borderRadius: AppRadius.cardAll,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface3,
                            borderRadius: AppRadius.badgeAll,
                          ),
                          child: Text(
                            '${index + 1}',
                            style:
                                AppText.statLabel(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ex.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.exerciseName(),
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
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
