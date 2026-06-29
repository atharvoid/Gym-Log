import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/app_refresh_indicator.dart';
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
import '../../../../shared/widgets/motion/entrance_fade.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _findProgramKey = GlobalKey();
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

    final routines = ref.watch(hydratedRoutinesProvider).valueOrNull ?? [];
    final tourStep = ref.watch(firstRunTourProvider);
    final hasNoRoutines = routines.isEmpty;
    final showFindProgram = hasNoRoutines || tourStep == 0;

    // ── Initial load: skeleton feed (no spinner, no layout jump) ───────────
    if (historyState.isInitialLoad) {
      return Scaffold(
        backgroundColor: surface.bgBase,
        body: SafeArea(
          child: SkeletonPulse(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                SkeletonBox(height: 96, radius: AppRadius.card),
                SizedBox(height: 20),
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
        ),
      );
    }

    // itemCount: [HeaderBand] + [FindProgram]? + [QuickStart] + [Header] + [N cards] + [footer]
    final int baseCount = showFindProgram ? 4 : 3;
    final itemCount = baseCount + totalItems + 1;

    final seenSessionIds = <String>{};

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            AppRefreshIndicator(
              onRefresh: () =>
                  ref.read(workoutHistoryProvider.notifier).refresh(),
              child: EntranceFade(
                child: ListView.builder(
                  key: const PageStorageKey('home_feed'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == 0) return const _HomeHeaderBand();
                    if (showFindProgram) {
                      if (index == 1) return _findProgramCard();
                      if (index == 2) return _quickStart();
                      if (index == 3) return _header();
                    } else {
                      if (index == 1) return _quickStart();
                      if (index == 2) return _header();
                    }

                    final historyIndex = index - baseCount;
                    if (historyIndex < totalItems) {
                      final preview = historyState.items[historyIndex];
                      final enableHero = seenSessionIds.add(preview.session.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WorkoutHistoryCard(
                          key: ValueKey(preview.session.id),
                          preview: preview,
                          enableHero: enableHero,
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
            ),
            if (tourStep == 0)
              SpotlightTourOverlay(
                targetKey: _findProgramKey,
                title: 'Find a training program',
                description:
                    'Choose a trainer-built routine. Tap "Explore Programs" to browse workouts tailored for your experience level.',
                step: 0,
              ),
          ],
        ),
      ),
    );
  }

  Widget _findProgramCard() {
    final tourStep = ref.read(firstRunTourProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AppCard(
        key: _findProgramKey,
        radius: AppRadius.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find a training program', style: AppText.exerciseName()),
            const SizedBox(height: 3),
            Text(
              'Choose from our curated programs designed for your experience level.',
              style: AppText.meta(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (tourStep == 0) {
                  ref.read(firstRunTourProvider.notifier).setStep(1);
                }
                context.push('/routines/explore');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Explore Programs →',
                style: AppText.label(color: context.accent.base),
              ),
            ),
          ],
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

  // ── Section header ──────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        header: true,
        child: Text(
          'Workout History',
          style: AppText.sectionHeading(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
              'Your history lives here.',
              style: AppText.meta(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (ref.read(activeWorkoutProvider) != null) return;
                ref.read(activeWorkoutProvider.notifier).startWorkout();
                context.push('/workout/active');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Start your first workout →',
                style: AppText.label(color: context.accent.base),
              ),
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

class _HomeHeaderBand extends ConsumerWidget {
  const _HomeHeaderBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakStatsProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final surface = context.surface;
    final accent = context.accent;

    final hasActivity = streak.currentStreak > 0 || streak.workoutsThisWeek > 0;
    final goalMet = streak.workoutsThisWeek >= goal;
    final progress =
        goal > 0 ? (streak.workoutsThisWeek / goal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity (always present — top is never empty)
          Text(_greeting(DateTime.now().hour),
              style: AppText.screenTitle(color: surface.textPrimary)
                  .copyWith(letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Ready to train?',
              style: AppText.body(color: surface.textSecondary)),

          // Promoted week stats (only once there's activity)
          if (hasActivity) ...[
            const SizedBox(height: 20),
            AppCard(
              radius: AppRadius.card,
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label: 'This week: ${streak.workoutsThisWeek} of $goal workouts'
                    '${goalMet ? ', goal met' : ''}'
                    '${streak.currentStreak > 0 ? '. ${streak.currentStreak} day streak' : ''}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This week',
                                  style: AppText.meta(
                                      color: surface.textSecondary)),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('${streak.workoutsThisWeek}',
                                      style: AppText.heroStat(
                                          color: goalMet
                                              ? accent.base
                                              : surface.textPrimary)),
                                  Text(' / $goal',
                                      style: AppText.statLabel(
                                          color: surface.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (streak.currentStreak > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: AppColors.warning), // allow-listed
                              const SizedBox(width: 4),
                              Text('${streak.currentStreak}',
                                  style: AppText.statLabel(
                                      color: surface.textPrimary)),
                              const SizedBox(width: 4),
                              Text('day streak',
                                  style: AppText.meta(
                                      color: surface.textSecondary)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: surface.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(accent.base),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
