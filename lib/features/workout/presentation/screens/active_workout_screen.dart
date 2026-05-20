import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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
            onPressed: () => Navigator.pop(context, true),
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
    await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final timer = ref.watch(workoutTimerProvider);
    final exercisesAsync = ref.watch(exerciseListProvider);

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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  // Timer
                  Text(
                    timer,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Finish
                  PrimaryButton(
                    label: 'Finish',
                    onPressed: _finish,
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
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: workout.exercises.length + 1,
                    itemBuilder: (context, index) {
                      if (index == workout.exercises.length) {
                        // Footer
                        return Padding(
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
                        onToggleSetCompletion: () {
                          // Toggle the first uncompleted set, or last set if all done
                          final targetIdx = exercise.sets.indexWhere((s) => !s.isCompleted);
                          notifier.toggleSetCompletion(
                            index,
                            targetIdx == -1 ? exercise.sets.length - 1 : targetIdx,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
