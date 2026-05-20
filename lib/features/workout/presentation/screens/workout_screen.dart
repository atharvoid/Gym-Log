import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui/secondary_button.dart';
import '../../../routines/presentation/widgets/routine_card.dart';
import '../../domain/active_workout_state.dart';
import '../providers/active_workout_provider.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _routinesExpanded = true;

  final _routines = [
    _RoutineData(
      title: 'Push Day',
      exercises: ['Bench Press', 'Overhead Press', 'Tricep Dips', 'Lateral Raises'],
    ),
    _RoutineData(
      title: 'Pull Day',
      exercises: ['Deadlift', 'Pull-ups', 'Barbell Row', 'Face Pulls'],
    ),
    _RoutineData(
      title: 'Leg Day',
      exercises: ['Squat', 'Leg Press', 'Hamstring Curl', 'Calf Raises'],
    ),
  ];

  void _startRoutine(List<String> exerciseNames) {
    final exercises = exerciseNames.asMap().entries.map((e) {
      return WorkoutExerciseState(
        exerciseId: e.key + 1,
        name: e.value,
        sets: [WorkoutSetState.create()],
      );
    }).toList();

    ref.read(activeWorkoutProvider.notifier).startWorkout(
      initialExercises: exercises,
    );
    context.push('/workout/active');
  }

  @override
  Widget build(BuildContext context) {
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
            // Section: Routines
            Text(
              'Routines',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

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

            // Collapsible Header
            GestureDetector(
              onTap: () => setState(() => _routinesExpanded = !_routinesExpanded),
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
                  Expanded(
                    child: Text(
                      'My Routines (${_routines.length})',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Routine Cards
            if (_routinesExpanded)
              ..._routines.map((routine) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RoutineCard(
                      routineName: routine.title,
                      exerciseNames: routine.exercises,
                      onStartTap: () => _startRoutine(routine.exercises),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _RoutineData {
  final String title;
  final List<String> exercises;

  _RoutineData({
    required this.title,
    required this.exercises,
  });
}
