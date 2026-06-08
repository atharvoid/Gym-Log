import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/widgets/exercise_gif_widget.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';
import 'package:gymlog/shared/widgets/ui/tracker_card.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
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
  final void Function(int setIndex) onToggleSetCompletion;

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
    required this.onToggleSetCompletion, // ignore: avoid_positional_boolean_parameters
  });

  void _showMenu(BuildContext context) {
    showActionBottomSheet(
      context: context,
      items: [
        ActionSheetItem(
          icon: Icons.swap_horiz,
          iconColor: AppColors.textSecondary,
          iconBackground: AppColors.bgBase,
          title: 'Replace Exercise',
          onTap: (sheetContext) {
            Navigator.pop(sheetContext);
            onReplace();
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.error.withValues(alpha: 0.12),
          title: 'Remove Exercise',
          titleColor: AppColors.error,
          onTap: (sheetContext) {
            Navigator.pop(sheetContext);
            onRemove();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final de = driftExercise;
    final gifUrl = de?.gifUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TrackerCard(
        padding: EdgeInsets.zero,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExerciseBlockHeader(
            exerciseName: exercise.name,
            gifUrl: gifUrl,
            driftExercise: de,
            onShowMenu: () => _showMenu(context),
          ),
          const SizedBox(height: 12),
          const _SetColumnHeaders(),
          const SizedBox(height: 4),
          // Sets List
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final setData = entry.value;
            return SetRow(
              key: ValueKey(setData.id),
              setIndex: setIndex,
              setData: setData,
              previousWeight: null,
              previousReps: null,
              equipment: driftExercise?.equipment,
              onChanged: (updated) => onSetChanged(updated),
              onToggleComplete: () => onToggleSetCompletion(setIndex),
            );
          }),
          _AddSetFooter(onAddSet: onAddSet),
        ],
        ),
      ),
    );
  }
}

class _ExerciseBlockHeader extends StatelessWidget {
  final String exerciseName;
  final String? gifUrl;
  final Exercise? driftExercise;
  final VoidCallback onShowMenu;

  const _ExerciseBlockHeader({
    required this.exerciseName,
    this.gifUrl,
    this.driftExercise,
    required this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          if (gifUrl != null && gifUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: ExerciseGifWidget(
                  gifUrl: gifUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  animate: false,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: driftExercise != null
                  ? () => context.push('/exercise/detail/${driftExercise!.id}',
                      extra: driftExercise)
                  : null,
              child: Text(
                exerciseName,
                style: GoogleFonts.inter(
                  color: AppColors.accentPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onShowMenu,
          ),
        ],
      ),
    );
  }
}

class _SetColumnHeaders extends StatelessWidget {
  const _SetColumnHeaders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text('SET', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('WEIGHT & REPS', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.left),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text('VS PREV', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
          const SizedBox(width: 16),
          const SizedBox(width: 44, child: Icon(Icons.check, size: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AddSetFooter extends StatelessWidget {
  final VoidCallback onAddSet;

  const _AddSetFooter({required this.onAddSet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SecondaryButton(
        label: '+ Add Set',
        onPressed: onAddSet,
      ),
    );
  }
}
