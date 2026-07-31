import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/domain/workout_save_result.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_event_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import '../widgets/active_workout_header.dart';
import '../widgets/exercise_block.dart';
import '../widgets/pr_celebration_overlay.dart';
import '../widgets/rest_timer_bar.dart';
import '../widgets/finish_summary_sheet.dart';
import 'package:gymlog/shared/widgets/motion/entrance_fade.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';

const double _bottomListPadding = 100.0;
const double _reorderSheetHeightRatio = 0.7;

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  StreamSubscription<ActiveWorkoutEvent>? _eventSubscription;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(activeWorkoutProvider) == null) {
        ref.read(activeWorkoutProvider.notifier).startWorkout();
      }
      _eventSubscription =
          ref.read(workoutEventBusProvider).stream.listen(_handleWorkoutEvent);
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _handleWorkoutEvent(ActiveWorkoutEvent event) {
    if (!mounted) return;
    switch (event) {
      case SetRemovedEvent(
          exerciseIndex: final exIdx,
          setIndex: final setIdx,
          removedSet: final set,
          snapshot: final snapshot,
        ):
        if (snapshot != null) {
          _showSetRemovedSnackbar(snapshot);
        } else {
          final workout = ref.read(activeWorkoutProvider);
          final exId = (workout != null && exIdx < workout.exercises.length)
              ? workout.exercises[exIdx].id
              : '';
          _showSetRemovedSnackbar(RemovedSetSnapshot(
            exerciseInstanceId: exId,
            set: set,
            originalIndex: setIdx,
          ));
        }
        break;
      case TimerStartedEvent(seconds: final secs, exerciseName: final name):
        SemanticsService.sendAnnouncement(
          View.of(context),
          name != null && name.isNotEmpty
              ? 'Rest timer started for $name, $secs seconds.'
              : 'Rest timer started, $secs seconds.',
          TextDirection.ltr,
        );
        break;
      case TimerCancelledEvent():
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Rest timer skipped',
          TextDirection.ltr,
        );
        break;
      case TimerExpiredEvent(exerciseName: final name):
        SemanticsService.sendAnnouncement(
          View.of(context),
          name != null && name.isNotEmpty
              ? 'Rest complete for $name.'
              : 'Rest complete.',
          TextDirection.ltr,
        );
        break;
      default:
        break;
    }
  }

  void _showSetRemovedSnackbar(RemovedSetSnapshot snapshot) {
    final restTimer = ref.read(restTimerProvider);
    final restBarVisible = restTimer != null;

    showAppSnackBar(
      context,
      message: 'Set removed',
      actionLabel: 'Undo',
      duration: const Duration(seconds: 5),
      additionalBottomOffset: restBarVisible ? kRestTileHeight + 18 : 0,
      onAction: () {
        ref.read(activeWorkoutProvider.notifier).restoreRemovedSet(snapshot);
      },
    );
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Discard workout?',
      message:
          'Your sets from this workout will be deleted. This cannot be undone.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep workout',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      ref.read(restTimerProvider.notifier).skip();
      ref.read(activeWorkoutProvider.notifier).discardWorkout();
      Navigator.pop(context);
    }
  }

  Future<void> _finish() async {
    if (!tapGuard() || _isSaving) return;
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;

    final durationMinutes =
        DateTime.now().difference(workout.startTime).inMinutes;
    final completedSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.isCompleted).length,
    );

    if (completedSets > 0 && durationMinutes < 5) {
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

    final preFill = (workout.name != null && workout.name!.trim().isNotEmpty)
        ? workout.name!.trim()
        : getWorkoutNameFallback(workout.startTime, null);
    final (volumeKg, sets) =
        ref.read(activeWorkoutProvider.notifier).sessionTotals;

    final name = await showFinishSummarySheet(
      context: context,
      duration: DateTime.now().difference(workout.startTime),
      volumeKg: volumeKg,
      sets: sets,
      unit: ref.read(weightUnitProvider),
      initialName: preFill,
    );
    if (name == null || !mounted) return;

    await _retryFinish(name);
  }

  Future<void> _retryFinish(String? name) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    ref.read(restTimerProvider.notifier).skip();
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    final result = await ref
        .read(activeWorkoutProvider.notifier)
        .finishWorkout(name: name);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (result is WorkoutSaveSuccess) {
      HapticFeedback.heavyImpact();
      context.go('/');
      if (result.prs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPrCelebration(rootNavigator.context, result.prs);
        });
      }
    } else if (result is WorkoutSaveFailure) {
      _showSaveErrorSnackBar(
        context,
        isEditing: false,
        name: name,
        reason: result.reason,
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final result =
        await ref.read(activeWorkoutProvider.notifier).saveEditedWorkout();

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (result is WorkoutSaveSuccess) {
      context.go('/');
    } else if (result is WorkoutSaveFailure) {
      _showSaveErrorSnackBar(
        context,
        isEditing: true,
        reason: result.reason,
      );
    }
  }

  void _showSaveErrorSnackBar(
    BuildContext context, {
    required bool isEditing,
    String? name,
    required String reason,
  }) {
    final bottomMargin = ref.read(restTimerProvider) != null ? 80.0 : 16.0;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? "Failed to save changes. Try again."
              : "Failed to finish workout. Try again.",
          style: AppText.body(color: context.surface.textPrimary),
        ),
        backgroundColor: AppColors.error.withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomMargin),
        action: SnackBarAction(
          label: 'Retry',
          textColor: context.surface.textPrimary,
          onPressed: () {
            if (isEditing) {
              _saveChanges();
            } else {
              _retryFinish(name);
            }
          },
        ),
      ),
    );
  }

  void _toggleSet(int exerciseIndex, int setIndex, {required bool isEditing}) {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    final wasCompleted =
        workout.exercises[exerciseIndex].sets[setIndex].isCompleted;

    ref
        .read(activeWorkoutProvider.notifier)
        .toggleSetCompletion(exerciseIndex, setIndex);

    if (!wasCompleted && !isEditing) {
      final exercise = workout.exercises[exerciseIndex];
      final int seconds =
          exercise.restSecondsOverride ?? ref.read(defaultRestSecondsProvider);
      if (seconds > 0) {
        ref.read(restTimerProvider.notifier).start(
              seconds: seconds,
              workoutId: workout.id,
              exerciseId: exercise.exerciseId,
              setId: exercise.sets[setIndex].id,
              exerciseName: exercise.name,
            );
      }
    }
  }

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
    final surface = context.surface;
    final selected = await showBrandedPickerSheet<String>(
      context: context,
      title: 'Weight Unit',
      selected: current,
      options: [
        PickerOption(
          value: 'kg',
          label: 'Kilograms',
          subtitle: 'kg',
          icon: Icons.fitness_center_rounded,
          color: surface.textPrimary,
        ),
        PickerOption(
          value: 'lbs',
          label: 'Pounds',
          subtitle: 'lbs',
          icon: Icons.fitness_center_rounded,
          color: surface.textPrimary,
        ),
        PickerOption(
          value: '_default',
          label: 'Use app default',
          subtitle: 'Currently $globalUnit, change in Settings',
          icon: Icons.settings_backup_restore_rounded,
          color: surface.textSecondary,
        ),
      ],
    );
    if (selected == null) return;
    await ref
        .read(unitOverridesProvider.notifier)
        .setOverride(exerciseId, selected == '_default' ? null : selected);
  }

  Widget _buildAddExerciseButton(ActiveWorkoutNotifier notifier) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Material(
        color: surface.surface3,
        borderRadius: AppRadius.buttonSecondaryAll,
        child: InkWell(
          borderRadius: AppRadius.buttonSecondaryAll,
          onTap: () async {
            final selected = await context.push<Exercise>('/exercises/select');
            if (selected != null && mounted) {
              notifier.addExerciseFromEntity(selected);
            }
          },
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: surface.borderSubtle),
              borderRadius: AppRadius.buttonSecondaryAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: surface.textPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Exercise',
                  style: AppText.button(color: surface.textPrimary),
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
    final workoutExists =
        ref.watch(activeWorkoutProvider.select((state) => state != null));
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final restTimer = ref.watch(restTimerProvider);
    final globalUnit = ref.watch(weightUnitProvider);
    final isEditing = ref.watch(activeWorkoutProvider
        .select((state) => state?.originalSessionId != null));

    final exerciseIds = ref.watch(activeWorkoutProvider.select((state) =>
        state?.exercises.map((e) => e.id).toList() ?? const <String>[]));

    final exerciseTemplateIds = ref.watch(activeWorkoutProvider.select(
        (state) =>
            state?.exercises.map((e) => e.exerciseId).toList() ??
            const <int>[]));

    final seen = <int>{};
    final heroEnabledList = <bool>[];
    for (final id in exerciseTemplateIds) {
      heroEnabledList.add(seen.add(id));
    }

    final surface = context.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: AdaptiveContent(
            child: Column(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final timer = ref.watch(workoutTimerProvider);
                final totals = ref.watch(sessionTotalsProvider);
                final volumeKg = totals.$1;
                final completedSets = totals.$2;
                final workoutName = ref.watch(
                  activeWorkoutProvider.select(
                    (state) => state == null
                        ? 'Active Workout'
                        : getWorkoutNameFallback(state.startTime, state.name),
                  ),
                );
                return ActiveWorkoutHeader(
                  isEditing: isEditing,
                  workoutName: workoutName,
                  elapsedTime: timer,
                  volumeKg: volumeKg,
                  completedSets: completedSets,
                  weightUnit: globalUnit,
                  finishEnabled: completedSets > 0 && !_isSaving,
                  onMinimize: () => context.pop(),
                  onClose: isEditing ? () => context.pop() : _confirmDiscard,
                  onFinish:
                      _isSaving ? null : (isEditing ? _saveChanges : _finish),
                );
              },
            ),
            Expanded(
              child: !workoutExists
                  ? const SizedBox.shrink()
                  : exerciseIds.isEmpty
                      ? EntranceFade(
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 48,
                                    color: surface.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add your first exercise',
                                    style: AppText.sheetTitle(
                                        color: surface.textPrimary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Choose from our library or build a custom move.',
                                    style: AppText.body(
                                        color: surface.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: 200,
                                    child: _buildAddExerciseButton(notifier),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            top: 8,
                            bottom: MediaQuery.viewPaddingOf(context).bottom +
                                _bottomListPadding,
                          ),
                          itemCount: exerciseIds.length + 1,
                          itemBuilder: (context, index) {
                            if (index == exerciseIds.length) {
                              return _buildAddExerciseButton(notifier);
                            }
                            return ExerciseBlock(
                              key: ValueKey(exerciseIds[index]),
                              exerciseIndex: index,
                              enableHero: heroEnabledList[index],
                              onReorderExercises: exerciseIds.length > 1
                                  ? _showReorderSheet
                                  : null,
                              onRemove: () {
                                final messenger = ScaffoldMessenger.of(context);
                                final exercise = ref
                                    .read(activeWorkoutProvider)
                                    ?.exercises[index];
                                if (exercise == null) return;
                                final snapshot =
                                    notifier.removeExerciseWithSnapshot(index);
                                if (snapshot == null) return;
                                showUndoableDelete(
                                  messenger: messenger,
                                  label: '"${snapshot.name}" removed',
                                  onUndo: () => notifier.insertExerciseAt(
                                      index, snapshot),
                                );
                              },
                              onUnitTap: () => _pickUnit(index),
                              onReplace: () async {
                                final selected = await context
                                    .push<Exercise>('/exercises/select');
                                if (selected == null || !context.mounted) {
                                  return;
                                }
                                final workout = ref.read(activeWorkoutProvider);
                                if (workout != null &&
                                    index < workout.exercises.length) {
                                  final oldExercise = workout.exercises[index];
                                  if (hasMeaningfulSetData(oldExercise)) {
                                    if (!context.mounted) return;
                                    final choice =
                                        await _showReplaceExerciseDialog(
                                            context);
                                    if (choice ==
                                        ReplacementChoice.keepValues) {
                                      notifier.replaceExerciseWithPolicy(
                                        index,
                                        selected.id,
                                        selected.name,
                                        keepCompatibleValues: true,
                                        measurementType:
                                            selected.measurementType,
                                      );
                                    } else if (choice ==
                                        ReplacementChoice.clearSets) {
                                      notifier.replaceExerciseWithPolicy(
                                        index,
                                        selected.id,
                                        selected.name,
                                        keepCompatibleValues: false,
                                        measurementType:
                                            selected.measurementType,
                                      );
                                    }
                                  } else {
                                    notifier.replaceExerciseWithPolicy(
                                      index,
                                      selected.id,
                                      selected.name,
                                      keepCompatibleValues: false,
                                      measurementType: selected.measurementType,
                                    );
                                  }
                                }
                              },
                              onAddSet: () => notifier.addSet(index),
                              onRemoveSet: (setIdx) {
                                notifier.removeSet(index, setIdx);
                              },
                              onSetChanged: (updatedSet) {
                                final workout = ref.read(activeWorkoutProvider);
                                if (workout == null ||
                                    index >= workout.exercises.length) {
                                  return;
                                }
                                final exercise = workout.exercises[index];
                                notifier.replaceSet(
                                    exercise.id, updatedSet.id, updatedSet);
                              },
                              onToggleSetCompletion: (setIdx) => _toggleSet(
                                  index, setIdx,
                                  isEditing: isEditing),
                            );
                          },
                        ),
            ),
          ],
        )),
        bottomNavigationBar: !workoutExists || restTimer == null
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: surface.bgBase,
                  border: Border(
                    top: BorderSide(color: surface.borderSubtle, width: 0.5),
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
                    child: RestTimerBar(
                        key: const ValueKey('rest'), state: restTimer),
                  ),
                ),
              ),
      ),
    );
  }
}

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
    final maxHeight =
        MediaQuery.of(context).size.height * _reorderSheetHeightRatio;
    final surface = context.surface;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: surface.surface2,
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
              color: surface.borderEmphasis,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reorder Exercises',
            style: AppText.cardTitle(color: surface.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Drag to change the order',
            style: AppText.meta(color: surface.textSecondary),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              buildDefaultDragHandles: false,
              onReorderStart: (_) => HapticFeedback.selectionClick(),
              onReorder: (oldIndex, newIndex) {
                // Flutter's onReorder reports newIndex against the
                // pre-removal list — without this adjustment every
                // downward drag (to any position but the very last slot)
                // lands one slot past where the user dropped it (B25).
                // Adjust once here so both the local preview list and the
                // persisted provider state (via widget.onReorder) agree.
                if (newIndex > oldIndex) newIndex -= 1;
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
                      color: surface.surface3,
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
                            color: surface.surface3,
                            borderRadius: AppRadius.badgeAll,
                          ),
                          child: Text(
                            '${index + 1}',
                            style:
                                AppText.statLabel(color: surface.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ex.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.exerciseName(
                                color: surface.textPrimary),
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
                              color: surface.textSecondary,
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

enum ReplacementChoice {
  clearSets,
  keepValues,
  cancel,
}

Future<ReplacementChoice?> _showReplaceExerciseDialog(BuildContext context) {
  final surface = context.surface;
  final accent = context.accent;

  return showDialog<ReplacementChoice>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: surface.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: surface.borderSubtle, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Replace exercise?',
                style: AppText.sheetTitle(color: surface.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'This exercise has logged data. Choose how to handle your existing sets.',
                style: AppText.meta(color: surface.textSecondary),
              ),
              const SizedBox(height: 20),
              Material(
                color: surface.surface3,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      Navigator.pop(dialogContext, ReplacementChoice.clearSets),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Replace and clear sets',
                        style: AppText.button(color: surface.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: accent.base.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(
                      dialogContext, ReplacementChoice.keepValues),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Replace and keep compatible values',
                        style: AppText.button(color: accent.light),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, ReplacementChoice.cancel),
                child: Text(
                  'Cancel',
                  style: AppText.button(color: surface.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
