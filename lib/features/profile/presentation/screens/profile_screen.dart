import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/premium_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/tap_guard.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/premium_paywall.dart';
import '../../../../shared/widgets/ui/app_action_row.dart';
import '../../../../shared/widgets/ui/app_card.dart';
import '../../../../shared/widgets/ui/goal_ring.dart';
import '../../../../shared/widgets/ui/segmented_control.dart';
import '../../../../shared/widgets/ui/skeleton.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_stats_provider.dart';
import '../widgets/graph_kpi_header.dart';
import '../widgets/profile_graph_empty_state.dart';

import '../widgets/weekly_bar_chart.dart';
import 'settings_screen.dart';


/// Athlete dashboard — identity, streak, weekly goal ring, training chart,
/// and quick links. Designed to feel personal, immediate, and scannable.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    // Defer the entrance animation until the first paint so the screen is
    // already laid out when the stagger begins — prevents a flash of offset.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _entrance({
    required Widget child,
    required int index,
    bool slide = true,
  }) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;

    final delay = index * 0.06;
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay.clamp(0.0, 0.82), 1.0, curve: Curves.easeOutCubic),
    );

    final Widget fadeChild = FadeTransition(
      opacity: animation,
      child: child,
    );

    if (slide) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: fadeChild,
      );
    }

    return fadeChild;
  }

  void _openSettings() {
    if (!tapGuard()) return;
    HapticFeedback.selectionClick();
    context.push('/settings');
  }

  void _openExerciseLibrary() {
    if (!tapGuard()) return;
    HapticFeedback.selectionClick();
    context.push('/exercises/library');
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(workoutCountProvider);
    ref.invalidate(sessionStatsProvider);
    ref.invalidate(streakStatsProvider);
    // Give the reactive streams one frame to re-emit.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _openPremium(BuildContext context, {required bool isPremium}) {
    if (!tapGuard()) return;
    if (isPremium) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'You are on GymLog Pro. Thanks for the support!',
          style: AppText.button(),
        ),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      showPremiumPaywall(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutCount = ref.watch(workoutCountProvider).valueOrNull ?? 0;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final streak = ref.watch(streakStatsProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final bottomClearance = BottomNavBar.height +
        MediaQuery.viewPaddingOf(context).bottom +
        24;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: AppBar(
          backgroundColor: AppColors.bgBase,
          scrolledUnderElevation: 0,
          title: Text('Profile', style: AppText.screenTitle()),
          actions: [
            IconButton(
              tooltip: 'Settings',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.settings_outlined,
                  size: 22, color: AppColors.textPrimary),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: profileAsync.when(
          loading: () => _LoadingBody(bottomClearance: bottomClearance),
          error: (e, _) => _ErrorBody(
            bottomClearance: bottomClearance,
            onRetry: () => ref.invalidate(currentUserProfileProvider),
          ),
          data: (profile) {
            final displayName = profile?.displayName ?? 'Athlete';
            final email = profile?.email ?? '';

            return RefreshIndicator(
              color: AppColors.textPrimary,
              backgroundColor: AppColors.bgSurface,
              onRefresh: _onRefresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomClearance),
                children: [
                _entrance(
                  index: 0,
                  child: Semantics(
                    container: true,
                    label: 'Profile, $displayName, $email',
                    child: _IdentityHeader(
                      displayName: displayName,
                      email: email,
                      isPremium: isPremium,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _entrance(
                  index: 1,
                  child: AppCard(
                    radius: 6.0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x1, vertical: AppSpacing.x4),
                    child: _StatsStrip(
                      streak: streak,
                      goal: goal,
                      workoutCount: workoutCount,
                      onGoalTap: () => showWeeklyGoalSheet(context, ref),
                    ),
                  ),
                ),
                if (goal > 0 && streak.workoutsThisWeek >= goal) ...[
                  const SizedBox(height: 10),
                  _entrance(
                    index: 2,
                    slide: false,
                    child: const _GoalReachedBanner(),
                  ),
                ] else if (!streak.trainedToday) ...[
                  const SizedBox(height: 10),
                  _entrance(
                    index: 2,
                    slide: false,
                    child: _StreakReminder(streak: streak),
                  ),
                ],
                const SizedBox(height: 28),
                _entrance(
                  index: 3,
                  child: const _TrainingChartSection(),
                ),
                const SizedBox(height: 28),
                _entrance(
                  index: 4,
                  child: _QuickLinks(
                    isPremium: isPremium,
                    onPremiumTap: () => _openPremium(context, isPremium: isPremium),
                    onExerciseLibraryTap: _openExerciseLibrary,
                    onSettingsTap: _openSettings,
                  ),
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final bool isPremium;

  const _IdentityHeader({
    required this.displayName,
    required this.email,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.profileName(),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.profileEmail(),
                ),
              ],
            ],
          ),
        ),
        if (isPremium)
          Semantics(
            label: 'Pro status active',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'PRO',
                style: AppText.badge(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final StreakStats streak;
  final int goal;
  final int workoutCount;
  final VoidCallback onGoalTap;

  const _StatsStrip({
    required this.streak,
    required this.goal,
    required this.workoutCount,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    const iconSize = 18.0;

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: '${streak.currentStreak}',
            label: 'DAY STREAK',
            leading: Icon(
              Icons.local_fire_department_rounded,
              size: iconSize,
              color: streak.currentStreak > 0
                  ? AppColors.warning
                  : AppColors.textTertiary,
            ),
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: Semantics(
            button: true,
            label:
                'Weekly goal: ${streak.workoutsThisWeek} of $goal workouts. Tap to change goal.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onGoalTap,
              child: _StatCell(
                value: streak.workoutsThisWeek >= goal
                    ? '${streak.workoutsThisWeek}'
                    : '${streak.workoutsThisWeek}/$goal',
                label: 'THIS WEEK',
                leading: GoalRing(
                  progress: goal == 0
                      ? 0
                      : (streak.workoutsThisWeek / goal).clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: _StatCell(
            value: '$workoutCount',
            label: 'WORKOUTS',
            leading: const Icon(
              Icons.fitness_center_rounded,
              size: iconSize,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Widget leading;

  const _StatCell({
    required this.value,
    required this.label,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 6),
              Text(value, style: AppText.statValue()),
            ],
          ),
          const SizedBox(height: 5),
          Text(label, style: AppText.statCellLabel()),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.borderSubtle,
    );
  }
}

class _StreakReminder extends StatelessWidget {
  final StreakStats streak;

  const _StreakReminder({required this.streak});

  @override
  Widget build(BuildContext context) {
    final message = streak.currentStreak > 0
        ? 'Train today to keep your ${streak.currentStreak}-day streak alive.'
        : 'Train today to start a streak.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        message,
        style: AppText.caption(),
      ),
    );
  }
}

class _GoalReachedBanner extends StatelessWidget {
  const _GoalReachedBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events_rounded,
            size: 14, color: AppColors.warning),
        const SizedBox(width: 6),
        Text(
          'Weekly goal reached — great work!',
          style: AppText.caption(color: AppColors.warning),
        ),
      ],
    );
  }
}

class _TrainingChartSection extends ConsumerStatefulWidget {
  const _TrainingChartSection();

  @override
  ConsumerState<_TrainingChartSection> createState() =>
      _TrainingChartSectionState();
}

class _TrainingChartSectionState extends ConsumerState<_TrainingChartSection> {
  // Bumps on every metric change so AnimatedSwitcher never sees duplicate keys
  // when the user rapidly toggles Volume/Duration/Reps.
  int _switchVersion = 0;

  @override
  Widget build(BuildContext context) {
    final metric = ref.watch(profileChartMetricProvider);
    final aggregates = ref.watch(weeklyAggregatesProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final filledWeeks = aggregates.where((a) => a.workoutCount > 0).length;
    final isEmpty = filledWeeks == 0;

    void onStartWorkout() {
      if (!tapGuard()) return;
      HapticFeedback.mediumImpact();
      context.push('/workout/active');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Training', style: AppText.sectionHeading()),
        ),
        const SizedBox(height: 24),
        if (isEmpty)
          ProfileGraphEmptyState(onStartWorkout: onStartWorkout)
        else ...[
          // KPI header: shows latest-week value + caption.
          GraphKpiHeader(aggregates: aggregates, metric: metric),
          const SizedBox(height: 24),
          // WeeklyBarChart owns its low-data render path:
          //   < 4 filled weeks → honest comparison stat view
          //   ≥ 4 filled weeks → full bar chart with linear axis
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: WeeklyBarChart(
              key: ValueKey('${metric.name}_$_switchVersion'),
              aggregates: aggregates,
              metric: metric,
              isPremium: isPremium,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Semantics(
          label: 'Chart metric selector',
          child: SegmentedControl(
            segments: const ['Volume', 'Duration', 'Reps'],
            selected: metric.label,
            onChanged: (label) {
              final next = ProfileGraphMetric.values.firstWhere(
                (m) => m.label == label,
              );
              if (next == metric) return;
              HapticFeedback.selectionClick();
              setState(() => _switchVersion++);
              ref.read(profileChartMetricProvider.notifier).setMetric(next);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onPremiumTap;
  final VoidCallback onExerciseLibraryTap;
  final VoidCallback onSettingsTap;

  const _QuickLinks({
    required this.isPremium,
    required this.onPremiumTap,
    required this.onExerciseLibraryTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 6.0,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          AppActionRow(
            icon: Icons.workspace_premium_rounded,
            iconColor: AppColors.indigo400,
            title: isPremium ? 'GymLog Pro' : 'Upgrade to Pro',
            subtitle: isPremium
                ? 'Active — full history unlocked'
                : 'Full analytics history & more',
            onTap: onPremiumTap,
          ),
          const AppActionDivider(),
          AppActionRow(
            icon: Icons.fitness_center_rounded,
            title: 'Exercise Library',
            subtitle: 'Browse exercises, form guides & records',
            onTap: onExerciseLibraryTap,
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final double bottomClearance;

  const _LoadingBody({required this.bottomClearance});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomClearance),
        children: [
          const Row(
            children: [
              SkeletonBox(width: 52, height: 52, radius: 26),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 19, radius: 0),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 13, radius: 0),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            radius: 6.0,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  const Expanded(
                    child: Column(
                      children: [
                        SkeletonBox(width: 50, height: 17, radius: 0),
                        SizedBox(height: 5),
                        SkeletonBox(width: 56, height: 10, radius: 0),
                      ],
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const AppCard(
            radius: 6.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 16, radius: 0),
                SizedBox(height: 12),
                SkeletonBox(width: double.infinity, height: 150, radius: 6),
                SizedBox(height: 14),
                SkeletonBox(width: double.infinity, height: 36, radius: 0),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AppCard(
            radius: 6.0,
            child: Column(
              children: [
                for (var i = 0; i < 2; i++) ...[
                  const SkeletonBox(width: double.infinity, height: 48, radius: 0),
                  if (i < 1) const SizedBox(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final double bottomClearance;
  final VoidCallback onRetry;

  const _ErrorBody({required this.bottomClearance, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomClearance),
      children: [
        AppCard(
          radius: 6.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 28),
              const SizedBox(height: 12),
              Text('Could not load profile',
                  style: AppText.sheetTitle()),
              const SizedBox(height: 6),
              Text(
                'We had trouble reading your local profile. Your workouts are safe.',
                style: AppText.body(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.buttonPrimary)),
                  ),
                  child: Text('Retry', style: AppText.button()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
