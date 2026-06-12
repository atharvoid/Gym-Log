import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/shared/widgets/ui/tracker_card.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_actions_provider.dart';
import 'package:gymlog/features/home/presentation/providers/home_provider.dart';
import 'package:gymlog/features/home/presentation/widgets/workout_history_card.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
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

    // ── Initial load: skeleton feed (no spinner, no layout jump) ─────────
    if (historyState.isInitialLoad) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _appBar(),
        body: SkeletonPulse(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: const [
              SkeletonBox(height: 124, radius: 12),
              SizedBox(height: 16),
              SkeletonBox(width: 150, height: 18),
              SizedBox(height: 12),
              WorkoutHistoryCardSkeleton(),
              SizedBox(height: 8),
              WorkoutHistoryCardSkeleton(),
              SizedBox(height: 8),
              WorkoutHistoryCardSkeleton(),
            ],
          ),
        ),
      );
    }

    // itemCount: [QuickStart] + [WeekStrip] + [Header] + [N cards] + [footer]
    final itemCount = 3 + totalItems + 1;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _appBar(),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // ── 0: Quick Start card ──────────────────────────────────────────
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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

          // ── 1: Streak / weekly strip ─────────────────────────────────────
          if (index == 1) {
            return const _WeekStrip();
          }

          // ── 2: Section header ────────────────────────────────────────────
          if (index == 2) {
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

          final historyIndex = index - 3;

          // ── 3..N+2: History cards ────────────────────────────────────────
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

          // ── Footer (loading | empty | all caught up) ─────────────────────
          if (historyState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SkeletonPulse(child: WorkoutHistoryCardSkeleton()),
            );
          }

          if (totalItems == 0) {
            return TrackerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No workouts yet',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your history lives here. Start your first workout above.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
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

  AppBar _appBar() => AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      );

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
            HapticFeedback.selectionClick();
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
          onTap: (sheetContext) async {
            Navigator.of(sheetContext).pop();
            final confirmed = await showAppConfirmDialog(
              context: context,
              title: 'Delete Workout?',
              message:
                  'This workout will be permanently removed from your history.',
              confirmLabel: 'Delete',
              isDestructive: true,
            );
            if (confirmed) {
              await ref
                  .read(workoutActionsProvider.notifier)
                  .deleteSession(session.id);
            }
          },
        ),
      ],
    );
  }
}

/// Slim streak + weekly-goal line between Quick Start and the feed.
/// Renders nothing until there is at least one completed workout —
/// no dead gray blocks for brand-new users.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakStatsProvider);
    final goal = ref.watch(weeklyGoalProvider);

    if (streak.currentStreak == 0 && streak.workoutsThisWeek == 0) {
      return const SizedBox(height: 8);
    }

    final goalMet = streak.workoutsThisWeek >= goal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 4, right: 4, top: 2),
      child: Row(
        children: [
          if (streak.currentStreak > 0) ...[
            const Icon(Icons.local_fire_department_rounded,
                size: 15, color: Color(0xFFFF9F0A)),
            const SizedBox(width: 5),
            Text(
              '${streak.currentStreak}-day streak',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '  ·  ',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          Text(
            '${streak.workoutsThisWeek}/$goal this week',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: goalMet ? FontWeight.w600 : FontWeight.w400,
              color: goalMet ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          if (goalMet) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.success),
          ],
        ],
      ),
    );
  }
}
