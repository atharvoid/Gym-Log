import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';
import 'set_row.dart';

class ExerciseBlock extends StatelessWidget {
  final int exerciseIndex;
  final WorkoutExerciseState exercise;
  final Exercise? driftExercise;
  final VoidCallback onRemove;
  final VoidCallback onReplace;
  final VoidCallback onAddNote;
  final VoidCallback onAddSet;
  final ValueChanged<WorkoutSetState> onSetChanged;
  final VoidCallback onToggleSetCompletion;

  const ExerciseBlock({
    super.key,
    required this.exerciseIndex,
    required this.exercise,
    this.driftExercise,
    required this.onRemove,
    required this.onReplace,
    required this.onAddNote,
    required this.onAddSet,
    required this.onSetChanged,
    required this.onToggleSetCompletion,
  });

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.textSecondary, size: 22),
              title: Text(
                'Replace Exercise',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReplace();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error, size: 22),
              title: Text(
                'Remove Exercise',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Exercise Name + 3-dot menu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: driftExercise != null
                        ? () => context.push('/exercise/detail',
                            extra: driftExercise)
                        : null,
                    child: Text(
                      exercise.name,
                      style: GoogleFonts.inter(
                        color: AppColors.accentPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showMenu(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Rest Timer Row (temporarily removed)
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          //   child: Row(
          //     children: [
          //       const Icon(Icons.timer, size: 14, color: AppColors.accentPrimary),
          //       const SizedBox(width: 6),
          //       Text(
          //         'Rest Timer: 1min 0s',
          //         style: GoogleFonts.inter(
          //           color: AppColors.accentPrimary,
          //           fontSize: 12,
          //           fontWeight: FontWeight.w400,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 12),

          // Column Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text('SET', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('PREVIOUS', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: Text('KG', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                SizedBox(width: 50, child: Text('REPS', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Spacer(),
                const SizedBox(width: 32, child: Icon(Icons.check, size: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Sets List
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final setData = entry.value;
            return SetRow(
              setIndex: setIndex,
              setData: setData,
              previousWeight: null,
              previousReps: null,
              onChanged: (updated) => onSetChanged(updated),
              onToggleComplete: onToggleSetCompletion,
            );
          }),

          // Footer: Add Set
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SecondaryButton(
              label: '+ Add Set',
              onPressed: onAddSet,
            ),
          ),
        ],
      ),
    );
  }
}
