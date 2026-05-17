import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import '../widgets/exercise_block.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late TextEditingController _nameController;
  late Stopwatch _stopwatch;
  late Duration _elapsedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'My Workout');
    _stopwatch = Stopwatch()..start();
    _elapsedTime = Duration.zero;
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _elapsedTime = _stopwatch.elapsed;
        });
      }
      return mounted;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // Top bar
          Container(
            color: AppColors.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  // Timer
                  Text(
                    _formatDuration(_elapsedTime),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Editable name
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.bgSurface,
                            title: const Text(
                              'Workout Name',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            content: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.bgElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppColors.border),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Save',
                                    style:
                                        TextStyle(color: AppColors.accent)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        _nameController.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Finish button
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(activeWorkoutProvider.notifier)
                          .finishWorkout();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body - scrollable exercises
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                children: [
                  // Mock exercise data for demo
                  ExerciseBlock(
                    exerciseId: 1,
                    exerciseName: 'Bench Press',
                    muscleGroup: 'Chest',
                    numSets: 3,
                    onRemove: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercise removed')),
                      );
                    },
                    onReplace: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Replace exercise')),
                      );
                    },
                    onAddNote: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add note')),
                      );
                    },
                  ),
                  ExerciseBlock(
                    exerciseId: 2,
                    exerciseName: 'Incline Dumbbell Press',
                    muscleGroup: 'Upper Chest',
                    numSets: 3,
                    onRemove: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercise removed')),
                      );
                    },
                    onReplace: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Replace exercise')),
                      );
                    },
                    onAddNote: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add note')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add exercise')),
          );
        },
        backgroundColor: AppColors.accent,
        label: const Text('Add Exercise'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
