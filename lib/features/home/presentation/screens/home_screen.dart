import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/shared/widgets/ui/tracker_card.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_actions_provider.dart';
import 'package:gymlog/features/home/presentation/providers/home_provider.dart';
import 'package:gymlog/features/home/presentation/providers/recent_workouts_provider.dart';
import 'package:gymlog/features/home/presentation/widgets/workout_history_card.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(workoutHistoryProvider);
    final notifier = ref.read(workoutHistoryProvider.notifier);
    final totalItems = historyState.items.length;

    // itemCount: [QuickStart] + [Header] + [N cards] + [1 footer slot]
    final itemCount = 2 + totalItems + 1;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // ── 0: Quick Start card ──────────────────────────────────────────
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TrackerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Start',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Start Empty Workout',
                      onPressed: () {
                        ref.read(activeWorkoutProvider.notifier).startWorkout();
                        context.push('/workout/active');
                      },
                      icon: Icons.add_circle_outline,
                    ),
                  ],
                ),
              ),
            );
          }

          // ── 1: Section header ────────────────────────────────────────────
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Workout History',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          final historyIndex = index - 2;

          // ── 2..N+1: History cards ────────────────────────────────────────
          if (historyIndex < totalItems) {
            // Trigger next-page fetch when within 3 items of the end
            if (historyIndex >= totalItems - 3 &&
                historyState.hasMore &&
                !historyState.isLoadingMore) {
              Future.microtask(() => notifier.fetchNextPage());
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WorkoutHistoryCard(
                key: ValueKey(historyState.items[historyIndex].session.id),
                preview: historyState.items[historyIndex],
                onMenuPressed: () => _showWorkoutCardMenu(
                  context,
                  ref,
                  historyState.items[historyIndex].session,
                ),
              ),
            );
          }

          // ── N+2: Footer (loading | empty | all caught up) ─────────────────
          if (historyState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            );
          }

          if (totalItems == 0) {
            return TrackerCard(
              child: Text(
                'No workouts yet. Start your first workout!',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'All caught up',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWorkoutCardMenu(
    BuildContext context,
    WidgetRef ref,
    WorkoutSession session,
  ) {
    final name = getWorkoutNameFallback(session.startedAt, session.name);

    showActionBottomSheet(
      context: context,
      title: name,
      items: [
        ActionSheetItem(
          icon: Icons.edit_outlined,
          iconColor: AppColors.textSecondary,
          iconBackground: AppColors.bgBase,
          title: 'Edit Workout',
          onTap: (sheetContext) async {
            Navigator.of(sheetContext).pop();
            final db = ref.read(databaseProvider);
            final hydrated = await db.workoutsDao.getHydratedWorkout(session.id);
            if (hydrated == null) return;
            if (!context.mounted) return;
            HapticFeedback.lightImpact();
            ref.read(activeWorkoutProvider.notifier).loadForEdit(hydrated);
            context.push('/workout/active');
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.error.withValues(alpha: 0.12),
          title: 'Delete Workout',
          titleColor: AppColors.error,
          subtitle: 'This cannot be undone',
          subtitleColor: AppColors.error.withValues(alpha: 0.7),
          onTap: (sheetContext) {
            Navigator.of(sheetContext).pop();
            _confirmDeleteWorkout(context, ref, session.id);
          },
        ),
      ],
    );
  }

  void _confirmDeleteWorkout(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Workout?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This workout will be permanently removed from your history.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref
                  .read(workoutActionsProvider.notifier)
                  .deleteSession(sessionId);
              ref.invalidate(recentWorkoutsProvider);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


