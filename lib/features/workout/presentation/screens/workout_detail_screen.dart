import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import '../providers/workout_detail_provider.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String sessionId;

  const WorkoutDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutDetailProvider(sessionId));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          workoutAsync.valueOrNull?.session.name != null 
              ? getWorkoutNameFallback(workoutAsync.valueOrNull!.session.startedAt, workoutAsync.valueOrNull!.session.name)
              : 'Workout',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.bgSurface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            onPressed: () => _showWorkoutActions(context, ref, workoutAsync.valueOrNull),
          ),
        ],
      ),
      body: SafeArea(
        child: workoutAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary),
          ),
          error: (err, _) => Center(
            child: Text(
              'Failed to load workout',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
          data: (workout) {
            if (workout == null) {
              return Center(
                child: Text(
                  'Workout not found',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              );
            }

            final durationStr = formatWorkoutDuration(
              workout.session.startedAt,
              workout.session.endedAt,
            );

            final totalSets = workout.exercises.fold<int>(
              0,
              (sum, ex) => sum + ex.sets.length,
            );

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: workout.exercises.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      // Header Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statColumn('Time', durationStr),
                            _statColumn(
                              'Volume',
                              '${workout.session.totalVolumeKg.toStringAsFixed(0)} kg',
                            ),
                            _statColumn('Sets', '$totalSets'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }

                final exercise = workout.exercises[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => context.push('/exercise/detail', extra: exercise.exerciseMetadata),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accentPrimary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.accentPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.exerciseMetadata.name,
                                      style: GoogleFonts.inter(
                                        color: AppColors.accentPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (exercise.exerciseMetadata.equipment
                                        .isNotEmpty)
                                      Text(
                                        exercise.exerciseMetadata.equipment,
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Set Table Header
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  'SET',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'WEIGHT & REPS',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Set Rows
                        ...exercise.sets.asMap().entries.map((entry) {
                          final setIndex = entry.key;
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${setIndex + 1}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${set.weightKg.toStringAsFixed(1)} kg x ${set.reps}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
            );
          },
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showWorkoutActions(BuildContext context, WidgetRef ref, HydratedWorkout? workout) {
    if (workout == null) return;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _sheetTile(Icons.download, 'Save as Routine', () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              final exerciseIds = workout.exercises.map((e) => e.exerciseMetadata.id).toList();
              final defaultName = '${workout.session.name ?? 'Custom'} Routine';
              await db.routinesDao.saveWorkoutAsRoutine(workout.session.userId, defaultName, exerciseIds);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to Routines')),
                );
              }
            }),
            _sheetTile(Icons.edit, 'Edit Workout', () {
              Navigator.pop(ctx);
            }),
            _sheetTile(Icons.delete, 'Delete Workout', () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              await db.workoutsDao.deleteSession(sessionId);
              if (context.mounted) {
                context.go('/');
              }
            }, isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? AppColors.error : AppColors.textSecondary,
          size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
