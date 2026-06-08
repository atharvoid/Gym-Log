import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui/secondary_button.dart';
import '../../../../shared/widgets/ui/tracker_card.dart';
import '../../../routines/presentation/widgets/routine_card.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../../domain/active_workout_state.dart';
import '../providers/active_workout_provider.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';

/// [workout_screen.dart]
/// Purpose: Routines tab — shows user's saved routines from Drift in real-time.
/// State: hydratedRoutinesProvider (StreamProvider) — auto-refreshes on DB writes.

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _routinesExpanded = true;

  void _startRoutine(HydratedRoutine routine) {
    if (routine.exerciseIds.isEmpty) return;

    final exercises = routine.exerciseIds.asMap().entries.map((e) {
      return WorkoutExerciseState(
        exerciseId: e.value,
        name: routine.exerciseNames[e.key],
        sets: [WorkoutSetState.create()],
      );
    }).toList();

    ref.read(activeWorkoutProvider.notifier).startWorkout(
          routineId: routine.routine.id,
          initialExercises: exercises,
        );
    context.push('/workout/active');
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(hydratedRoutinesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Routines',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Row
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'New Routine',
                    onPressed: () => context.push('/routines/edit'),
                    isFullWidth: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: 'Explore',
                    onPressed: () {},
                    isFullWidth: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Collapsible header
            GestureDetector(
              onTap: () =>
                  setState(() => _routinesExpanded = !_routinesExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _routinesExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    routinesAsync.when(
                      data: (routines) => Text(
                        'My Routines (${routines.length})',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      loading: () => Text(
                        'My Routines',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Routine list from DB
            if (_routinesExpanded)
              routinesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                        color: AppColors.accentPrimary),
                  ),
                ),
                error: (e, _) => TrackerCard(
                  child: Text(
                    'Failed to load routines',
                    style: GoogleFonts.inter(color: AppColors.error),
                  ),
                ),
                data: (routines) {
                  if (routines.isEmpty) {
                    return TrackerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No routines yet',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save a workout as a routine, or create one above.',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: routines.map((routine) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoutineCard(
                          routineId: routine.routine.id,
                          routineName: routine.routine.name,
                          exerciseNames: routine.exerciseNames,
                          onStartTap: () => _startRoutine(routine),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
