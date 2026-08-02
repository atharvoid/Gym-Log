import 'dart:async';

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
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/shared/providers/bottom_chrome_provider.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';

/// Whether the weekly-stats card should be rendered.
///
/// Normally it is shown only once the user has logged at least one workout;
/// during the step-4 spotlight we force it so the tour always anchors on a
/// real, personalized card (showing "0 / {goal}" if necessary) rather than a
/// placeholder band.
///
/// [statsPending] forces it as well, in a skeleton/error form. Without that
/// the card was absent while the stats stream was still loading — because a
/// loading stream reported zero activity — and then appeared a moment later,
/// shifting the whole feed. Reserving the space from the first frame is the
/// entire point. It is optional and defaulted so this function's existing
/// call sites and tests keep compiling.
@visibleForTesting
bool showWeeklyStatsCard({
  required bool hasActivity,
  required int tourStep,
  bool statsPending = false,
}) =>
    hasActivity || tourStep == 4 || statsPending;

/// Time-of-day greeting. Pure and top-level so it can be tested directly
/// instead of by pumping the header at a mocked wall-clock time.
@visibleForTesting
String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// The next instant at which [greetingForHour] would return something
/// different: noon, 5pm, or the following midnight.
///
/// Deliberately boundary-based rather than a periodic tick — Home is kept
/// alive for the whole session by the indexed-stack shell, so a repeating
/// timer would burn frames all day to change two words twice.
///
/// Local-time arithmetic is intentional. On a DST transition the boundary can
/// land an hour early or late; the greeting is then briefly wrong and
/// self-corrects at the next boundary, which is an acceptable trade against
/// carrying a timezone database for this.
@visibleForTesting
DateTime nextGreetingBoundary(DateTime now) {
  final startOfDay = DateTime(now.year, now.month, now.day);
  for (final hour in const [12, 17]) {
    final boundary = DateTime(now.year, now.month, now.day, hour);
    if (boundary.isAfter(now)) return boundary;
  }
  // Past 5pm — next change is midnight, back to "Good morning".
  return startOfDay.add(const Duration(days: 1));
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _findProgramKey = GlobalKey();

  /// Used by the step-4 tour spotlight — attached to the weekly-stats card
  /// inside [_HomeHeaderBand]. Hoisted here so the overlay (mounted in this
  /// State's Stack) can reference the same key.
  final GlobalKey _weeklyStatsKey = GlobalKey();

  /// Target for the step-0 tour spotlight when the user already has routines
  /// (deferred tour start) and the "Find a program" card is not shown.
  final GlobalKey _quickStartKey = GlobalKey();

  /// Latch for the deferred-tour kickoff. Without it, build scheduled a fresh
  /// post-frame callback on every rebuild while the deferred condition held.
  bool _tourKickoffScheduled = false;

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

  /// Starts the first-run tour that was deferred because the user had no
  /// content to point at yet.
  ///
  /// Latched, and the callback re-reads the step before acting: a callback
  /// queued one frame ago must not force the user back to step 0 if the
  /// notifier has moved on in the meantime.
  void _scheduleDeferredTourStart() {
    if (_tourKickoffScheduled) return;
    _tourKickoffScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(firstRunTourProvider) != FirstRunTourNotifier.deferredStep) {
        return;
      }
      ref.read(firstRunTourProvider.notifier).setStep(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(workoutHistoryProvider);
    final totalItems = historyState.items.length;
    final surface = context.surface;
    // Reserve room for the floating active-workout mini player, same as the
    // Routines tab. Without this the last card / footer sits behind the bar
    // whenever a session is live.
    final bottomInset = ref.watch(bottomChromeInsetProvider);

    // Display unit for every aggregate figure in the feed. Watched once here
    // and threaded down; the cards themselves stay provider-free.
    final unit = ref.watch(weightUnitProvider);

    // Home only ever asks "does this user have any routines at all?", so it
    // selects that one boolean. Watching the whole hydrated list rebuilt the
    // entire screen — every visible history card included — whenever any
    // routine, exercise or set anywhere in the library changed.
    final hasNoRoutines = ref.watch(
      hydratedRoutinesProvider
          .select((async) => (async.valueOrNull ?? const []).isEmpty),
    );
    final tourStep = ref.watch(firstRunTourProvider);
    final streak = ref.watch(streakStatsProvider);

    // Only ever true once the stats have actually resolved. A loading or
    // failed stream reports zeroes, and treating those as "no activity" is
    // what used to hide the card and then pop it back in.
    final hasActivity = streak.isResolved &&
        (streak.currentStreak > 0 || streak.workoutsThisWeek > 0);
    final showStats = showWeeklyStatsCard(
      hasActivity: hasActivity,
      tourStep: tourStep,
      statsPending: !streak.isResolved,
    );
    final showFindProgram = hasNoRoutines ||
        tourStep == 0 ||
        tourStep == FirstRunTourNotifier.deferredStep;

    // If the tour is deferred and the user now has real content, kick it off.
    if (tourStep == FirstRunTourNotifier.deferredStep &&
        (!hasNoRoutines || hasActivity)) {
      _scheduleDeferredTourStart();
    }

    // ── Initial load: skeleton feed (no spinner, no layout jump) ───────
    if (historyState.isInitialLoad) {
      return Scaffold(
        backgroundColor: surface.bgBase,
        body: SafeArea(
          child: SkeletonPulse(
            label: 'Loading your workouts',
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
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

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            AppRefreshIndicator(
              onRefresh: () =>
                  ref.read(workoutHistoryProvider.notifier).refresh(),
              child: ListView.builder(
                key: const PageStorageKey('home_feed'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _HomeHeaderBand(
                      weeklyStatsKey: _weeklyStatsKey,
                      showWeeklyStats: showStats,
                    );
                  }
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: WorkoutHistoryCard(
                        key: ValueKey(preview.session.id),
                        preview: preview,
                        unit: unit,
                        // RC3-09: Hero flying-title animation removed.
                        enableHero: false,
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
            // Step 0 — Find a program spotlight (or Quick Start if the user
            // already has routines and the tour was deferred).
            // Guard: only render when Home is the active top route so the
            // mask cannot leak through to another screen during transitions.
            //
            // The description must name the control the spotlight is actually
            // highlighting. The card's action reads "Browse programs"; the
            // word "Explore" belongs to a different button on the Routines
            // tab, so naming it here sent the user looking for a control that
            // is not on the screen — and the mask hid everything else.
            if (tourStep == 0 && (ModalRoute.of(context)?.isCurrent ?? false))
              SpotlightTourOverlay(
                targetKey: hasNoRoutines ? _findProgramKey : _quickStartKey,
                title: hasNoRoutines
                    ? 'Find a training program'
                    : 'Ready to train?',
                description: hasNoRoutines
                    ? 'Choose a trainer-built routine. Tap "Browse programs" to see workouts tailored for your experience level.'
                    : 'Tap "Start Empty Workout" to log a session, or browse your routine library for a structured program.',
                step: 0,
                borderRadius: AppRadius.card,
              ),

            // Step 4 — Weekly stats spotlight. The card is forced to render
            // while step 4 is active (even with zero activity) so the spotlight
            // always lands on a real, personalized weekly-goal card.
            // Guard: only render when Home is the active top route so the
            // mask cannot leak through to another screen.
            if (tourStep == 4 && (ModalRoute.of(context)?.isCurrent ?? false))
              SpotlightTourOverlay(
                targetKey: _weeklyStatsKey,
                title: 'Your weekly progress',
                description: hasActivity
                    ? 'This card tracks your workouts toward your weekly goal and your current streak. Keep it up to grow that streak!'
                    : 'This is where your weekly progress lives. Log your first workout to start filling the ring toward your goal.',
                step: 4,
                borderRadius: AppRadius.card,
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
            Text('Import your first program', style: AppText.exerciseName()),
            const SizedBox(height: 3),
            Text(
              'Browse trainer-built routines and add one to your library to get started.',
              style: AppText.meta(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (tourStep == 0 ||
                    tourStep == FirstRunTourNotifier.deferredStep) {
                  ref.read(firstRunTourProvider.notifier).setStep(1);
                }
                context.push('/routines/explore');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              // The arrow is decoration. Left inside the Text it was read out
              // as "right arrow" by TalkBack.
              child: Text(
                'Browse programs →',
                semanticsLabel: 'Browse programs',
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
        key: _quickStartKey,
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

  // ── Section header ─────────────────────────────────────────────
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

  // ── Footer: loading | error | empty | all-caught-up ───────────────────
  Widget _footer(WorkoutHistoryState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: SkeletonPulse(
          label: 'Loading more workouts',
          child: WorkoutHistoryCardSkeleton(),
        ),
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
                semanticsLabel: 'Start your first workout',
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
          subtitle: 'Remove from history',
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
              message: 'This workout will be removed from your history.',
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

class _HomeHeaderBand extends ConsumerStatefulWidget {
  /// Key attached to the weekly-stats AppCard so the step-4 tour spotlight
  /// can locate its position on screen. Exactly one of the three mutually
  /// exclusive card states below carries it, so it always resolves to a
  /// single element.
  final GlobalKey? weeklyStatsKey;

  /// When true, force the weekly-stats card to render even if the user has
  /// not yet logged a workout. Used so the step-4 spotlight has a real
  /// target (showing "0 / {goal}"), and so the card's space is reserved
  /// while the stats are still loading.
  final bool showWeeklyStats;

  const _HomeHeaderBand({
    this.weeklyStatsKey,
    this.showWeeklyStats = false,
  });

  @override
  ConsumerState<_HomeHeaderBand> createState() => _HomeHeaderBandState();
}

class _HomeHeaderBandState extends ConsumerState<_HomeHeaderBand> {
  late String _greeting;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _greeting = greetingForHour(DateTime.now().hour);
    _scheduleGreetingRefresh();
  }

  /// One-shot timer aimed at the next greeting boundary, rescheduled each
  /// time it fires. Home is never disposed while the app is foregrounded
  /// (indexed-stack shell), so without this the greeting is frozen at
  /// whatever it was when the app launched.
  void _scheduleGreetingRefresh() {
    _greetingTimer?.cancel();
    final now = DateTime.now();
    // One second past the boundary, so the hour has definitely rolled over.
    final delay =
        nextGreetingBoundary(now).difference(now) + const Duration(seconds: 1);
    _greetingTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _greeting = greetingForHour(DateTime.now().hour));
      _scheduleGreetingRefresh();
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakStatsProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final surface = context.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity (always present — top is never empty)
          Text(_greeting,
              style: AppText.screenTitle(color: surface.textPrimary)
                  .copyWith(letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Ready to train?',
              style: AppText.body(color: surface.textSecondary)),

          // Promoted week stats. Three mutually exclusive states, matching
          // the rigour the history feed below already had.
          if (widget.showWeeklyStats) ...[
            const SizedBox(height: 20),
            if (streak.isLoading)
              _statsSkeleton()
            else if (streak.hasError)
              _statsError()
            else
              _statsCard(context, streak, goal),
          ],
        ],
      ),
    );
  }

  /// Placeholder with the same internal geometry as the real card, so the
  /// feed does not shift when the numbers arrive.
  Widget _statsSkeleton() => AppCard(
        key: widget.weeklyStatsKey,
        radius: AppRadius.card,
        child: const SkeletonPulse(
          label: 'Loading your weekly progress',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 72, height: 12),
              SizedBox(height: 6),
              SkeletonBox(width: 96, height: 28),
              SizedBox(height: 12),
              SkeletonBox(height: 6, radius: AppRadius.badge),
            ],
          ),
        ),
      );

  /// An honest failure with a real retry, rather than a confident "0".
  Widget _statsError() => AppCard(
        key: widget.weeklyStatsKey,
        radius: AppRadius.card,
        child: AsyncErrorState(
          message: "Couldn't load your weekly progress.",
          onRetry: () => ref.invalidate(trainingDatesProvider),
        ),
      );

  Widget _statsCard(BuildContext context, StreakStats streak, int goal) {
    final surface = context.surface;
    final accent = context.accent;

    final goalMet = streak.workoutsThisWeek >= goal;
    final progress =
        goal > 0 ? (streak.workoutsThisWeek / goal).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      key: widget.weeklyStatsKey,
      radius: AppRadius.card,
      child: Semantics(
        // Merge-and-relabel: safe here because the subtree is presentational
        // only — Text plus a LinearProgressIndicator, no actions and no
        // focusable descendants — so nothing operable is being hidden. This
        // is the same shape that caused the C30 regression, where it DID
        // wrap tappable children; the distinction is the reason it stays.
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
                          style: AppText.meta(color: surface.textSecondary)),
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
                          size: 18, color: AppColors.warning), // allow-listed
                      const SizedBox(width: 4),
                      Text('${streak.currentStreak}',
                          style: AppText.statLabel(color: surface.textPrimary)),
                      const SizedBox(width: 4),
                      Text('day streak',
                          style: AppText.meta(color: surface.textSecondary)),
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
    );
  }
}
