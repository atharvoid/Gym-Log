import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/start_button.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_actions_provider.dart';
import 'package:gymlog/features/home/presentation/providers/home_provider.dart';
import 'package:gymlog/features/home/presentation/widgets/workout_history_card.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Pagination is driven from real scroll position — NOT scheduled as a
  // side-effect inside itemBuilder (which fired a microtask on every rebuild).
  final ScrollController _scrollController = ScrollController();

  /// Prefetch when within this many logical pixels of the end.
  static const _prefetchThreshold = 600.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final st = ref.read(workoutHistoryProvider);
    if (!st.hasMore || st.isLoadingMore || st.hasError) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _prefetchThreshold) {
      ref.read(workoutHistoryProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(workoutHistoryProvider);
    final totalItems = historyState.items.length;
    final surface = context.surface;
    final accent = context.accent;

    // ── Initial load: skeleton feed (no spinner, no layout jump) ───────────
    if (historyState.isInitialLoad) {
      return Scaffold(
        backgroundColor: surface.bgBase,
        appBar: _appBar(),
        body: SkeletonPulse(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: const [
              SkeletonBox(height: 124, radius: AppRadius.card),
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

    // itemCount: [QuickStart] + [Header+WeekStrip] + [N cards] + [footer]
    final itemCount = 2 + totalItems + 1;

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: _appBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(workoutHistoryProvider.notifier).refresh(),
        color: accent.base,
        backgroundColor: surface.surface2,
        child: ListView.builder(
          key: const PageStorageKey('home_feed'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) return _quickStart();
            if (index == 1) return _header();

            final historyIndex = index - 2;
            if (historyIndex < totalItems) {
              final preview = historyState.items[historyIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WorkoutHistoryCard(
                  key: ValueKey(preview.session.id),
                  preview: preview,
                  onMenuPressed: () {
                    HapticFeedback.selectionClick();
                    _showWorkoutCardMenu(preview.session);
                  },
                ),
              );
            }

            return _footer(historyState);
          },
        ),
      ),
    );
  }

  // ── Quick Start ────────────────────────────────────────────────
  Widget _quickStart() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AppCard(
        radius: AppRadius.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('Quick Start', style: AppText.sectionHeading()),
            ),
            const SizedBox(height: 16),
            StartButton(
              label: 'Start Empty Workout',
              icon: Icons.add_circle_outline,
              expand: true,
              onPressed: () {
                // Guard against a double-tap pushing two active-workout
                // screens (startWorkout sets state synchronously).
                if (ref.read(activeWorkoutProvider) != null) return;
                ref.read(activeWorkoutProvider.notifier).startWorkout();
                context.push('/workout/active');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header + week-at-a-glance ──────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Workout History',
                style: AppText.sectionHeading(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const _WeekStrip(),
        ],
      ),
    );
  }

  // ── Footer: loading | error | empty | all-caught-up ─────────────────────
  Widget _footer(WorkoutHistoryState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: SkeletonPulse(child: WorkoutHistoryCardSkeleton()),
      );
    }

    // Error WITH existing items → compact inline retry (keep the feed).
    if (state.hasError && state.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AsyncErrorState(
          message: "Couldn't load more workouts.",
          onRetry: () => ref.read(workoutHistoryProvider.notifier).retry(),
        ),
      );
    }

    // Empty feed: error state (with retry) or the calm empty card.
    if (state.items.isEmpty) {
      if (state.hasError) {
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: AsyncErrorState(
            onRetry: () => ref.read(workoutHistoryProvider.notifier).retry(),
          ),
        );
      }
      return AppCard(
        radius: AppRadius.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No workouts yet', style: AppText.exerciseName()),
            const SizedBox(height: 3),
            Text(
              'Your history lives here. Start your first workout above.',
              style: AppText.meta(),
            ),
          ],
        ),
      );
    }

    // Has items, nothing more to load.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('All caught up', style: AppText.meta()),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: Semantics(
          header: true,
          child: Text('Home', style: AppText.screenTitle()),
        ),
      );

  void _showWorkoutCardMenu(WorkoutSession session) {
    final surface = context.surface;
    final name = getWorkoutNameFallback(session.startedAt, session.name);

    showActionBottomSheet(
      context: context,
      title: name,
      items: [
        ActionSheetItem(
          icon: Icons.edit_outlined,
          iconColor: surface.textSecondary,
          iconBackground: surface.bgBase,
          title: 'Edit Workout',
          onTap: (sheetContext) async {
            Navigator.of(sheetContext).pop();
            final db = ref.read(databaseProvider);
            final hydrated =
                await db.workoutsDao.getHydratedWorkout(session.id);
            if (hydrated == null) return;
            // State.context guarded by the State's own `mounted` (not
            // context.mounted) — required by use_build_context_synchronously.
            if (!mounted) return;
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
            if (!tapGuard()) return;
            Navigator.of(sheetContext).pop();
            final db = ref.read(databaseProvider);
            final actions = ref.read(workoutActionsProvider.notifier);
            final messenger = ScaffoldMessenger.of(context);

            final data = await db.workoutsDao.exportSessionJson(session.id);
            if (data == null) return;

            if (!mounted) return;

            final confirmed = await showAppConfirmDialog(
              context: context,
              title: 'Delete Workout?',
              message:
                  'This workout will be permanently removed from your history.',
              confirmLabel: 'Delete',
              isDestructive: true,
            );
            if (confirmed) {
              HapticFeedback.mediumImpact();
              await actions.deleteSession(session.id);
              showUndoableDelete(
                messenger: messenger,
                label: 'Workout deleted',
                onUndo: () async {
                  await actions.restoreSession(data);
                },
              );
            }
          },
        ),
      ],
    );
  }
}

/// Week-at-a-glance chip living inside the Workout History header — clear
/// hierarchy, no orphaned strips. Hidden until the first completed workout.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakStatsProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final surface = context.surface;

    if (streak.currentStreak == 0 && streak.workoutsThisWeek == 0) {
      return const SizedBox.shrink();
    }

    final goalMet = streak.workoutsThisWeek >= goal;

    // Goal-met is shown on screen by icon shape + color; give screen readers a
    // single spoken summary and hide the fragmented row pieces.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'This week: ${streak.workoutsThisWeek} of $goal workouts'
          '${goalMet ? ', goal met' : ''}'
          '${streak.currentStreak > 0 ? '. ${streak.currentStreak} day streak' : ''}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (streak.currentStreak > 0) ...[
            const Icon(
              Icons.local_fire_department_rounded,
              size: 14,
              color: AppColors.warning,
            ),
            const SizedBox(width: 3),
            Text('${streak.currentStreak}',
                style: AppText.statLabel(color: surface.textPrimary)),
            Text('  ·  ', style: AppText.caption()),
          ],
          Icon(
            goalMet ? Icons.check_circle_rounded : Icons.flag_rounded,
            size: 13,
            color: goalMet ? AppColors.success : surface.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${streak.workoutsThisWeek}/$goal',
            style: AppText.statLabel(
              color: goalMet ? AppColors.success : surface.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
