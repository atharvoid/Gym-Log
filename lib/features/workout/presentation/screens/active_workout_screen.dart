import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import '../widgets/exercise_block.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Discard Workout?',
            style: GoogleFonts.inter(color: AppColors.textPrimary)),
        content: Text('All progress will be lost.',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, true);
            },
            child: Text('Discard',
                style: GoogleFonts.inter(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(activeWorkoutProvider.notifier).discardWorkout();
      Navigator.pop(context);
    }
  }

  Future<void> _finish() async {
    HapticFeedback.heavyImpact();
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;

    final durationMinutes =
        DateTime.now().difference(workout.startTime).inMinutes;
    final completedSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.isCompleted).length,
    );

    // Spec: warn when 10+ completed sets were logged in under 5 minutes.
    // This is physically implausible and usually means the timer wasn't started.
    if (completedSets >= 10 && durationMinutes < 5) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          title: Text(
            'Short Workout',
            style: GoogleFonts.inter(color: AppColors.textPrimary),
          ),
          content: Text(
            'This workout was very short. Are you sure ?',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Go Back',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Finish Anyway',
                style: GoogleFonts.inter(color: AppColors.accentPrimary),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (mounted) context.go('/');
  }

  Future<void> _saveChanges() async {
    HapticFeedback.heavyImpact();
    await ref.read(activeWorkoutProvider.notifier).saveEditedWorkout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final timer = ref.watch(workoutTimerProvider);
    final exercisesAsync = ref.watch(exerciseListProvider);
    final isEditing = workout?.originalSessionId != null;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Discard
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: _confirmDiscard,
                  ),
                  const Spacer(),
                  // Timer / Edit Title
                  if (isEditing)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Workout',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timer,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      timer,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  // Finish / Save Changes
                  PrimaryButton(
                    label: isEditing ? 'Save Changes' : 'Finish',
                    onPressed: isEditing ? _saveChanges : _finish,
                    isFullWidth: false,
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: workout == null
                ? const Center(child: SizedBox.shrink())
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 120.0),
                    itemCount: workout.exercises.length + 1,
                    itemBuilder: (context, index) {
                      if (index == workout.exercises.length) {
                        // Footer
                        return Padding(
                          key: const ValueKey('footer'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: SecondaryButton(
                            label: '+ Add Exercise',
                            onPressed: () async {
                              final selected =
                                  await Navigator.push<Exercise>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ExerciseSelectionScreen(),
                                ),
                              );
                              if (selected != null && mounted) {
                                notifier.addExercise(
                                  selected.id,
                                  selected.name,
                                );
                              }
                            },
                          ),
                        );
                      }

                      final exercise = workout.exercises[index];
                      final driftEx = exercisesAsync.maybeWhen(
                        data: (list) => list.firstWhere(
                          (e) => e.id == exercise.exerciseId,
                          orElse: () => Exercise(
                            id: exercise.exerciseId,
                            name: exercise.name,
                            bodyPart: '',
                            equipment: '',
                            target: '',
                            isCustom: false,
                          ),
                        ),
                        orElse: () => Exercise(
                          id: exercise.exerciseId,
                          name: exercise.name,
                          bodyPart: '',
                          equipment: '',
                          target: '',
                          isCustom: false,
                        ),
                      );
                      return ExerciseBlock(
                        key: ValueKey(exercise.id),
                        exerciseIndex: index,
                        exercise: exercise,
                        driftExercise: driftEx,
                        onRemove: () => notifier.removeExercise(index),
                        onReplace: () async {
                          final selected = await Navigator.push<Exercise>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ExerciseSelectionScreen(),
                            ),
                          );
                          if (selected != null && mounted) {
                            notifier.replaceExercise(
                              index,
                              selected.id,
                              selected.name,
                            );
                          }
                        },
                        onAddNote: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add note')),
                          );
                        },
                        onAddSet: () => notifier.addSet(index),
                        onSetChanged: (updatedSet) {
                          final setIdx =
                              exercise.sets.indexWhere((s) => s.id == updatedSet.id);
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
                            notifier.toggleSetCompletion(index, setIdx),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
