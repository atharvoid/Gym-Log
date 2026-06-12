import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/shared/widgets/exercise_gif_widget.dart';
import '../providers/exercises_provider.dart';

/// Exercise list with live search.
///
/// Two modes, one screen:
///  * Selection (default): tapping pops with the chosen [Exercise] —
///    used by Active Workout and the Routine editor.
///  * Browse (`browse: true`, route `/exercises/library`): tapping opens
///    the exercise detail with charts, records and form instructions.
class ExerciseSelectionScreen extends ConsumerStatefulWidget {
  final bool browse;

  const ExerciseSelectionScreen({super.key, this.browse = false});

  @override
  ConsumerState<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState
    extends ConsumerState<ExerciseSelectionScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          widget.browse ? 'Exercise Library' : 'Select Exercise',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (query) {
                ref.read(exerciseListProvider.notifier).search(query);
              },
            ),
          ),

          // Exercise List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 30,
                            color: Colors.white.withValues(alpha: 0.25)),
                        const SizedBox(height: 10),
                        Text(
                          'No exercises found',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ListTile(
                      key: ValueKey(exercise.id),
                      leading: RepaintBoundary(
                        child: ExerciseGifWidget(
                          gifUrl: exercise.gifUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          animate: false,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise.target} • ${exercise.equipment}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      trailing: widget.browse
                          ? Icon(Icons.chevron_right_rounded,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.25))
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (widget.browse) {
                          context.push('/exercise/detail/${exercise.id}',
                              extra: exercise);
                        } else {
                          Navigator.pop(context, exercise);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accentPrimary, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load exercises',
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
