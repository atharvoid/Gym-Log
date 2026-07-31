import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/exercises/body_map.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/body/muscle_summary.dart';
import 'package:gymlog/shared/widgets/exercise_hero_thumb.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import '../providers/exercise_history_provider.dart';
import '../widgets/exercise_history_chart.dart';
import '../widgets/exercise_pr_strip.dart';

/// Detail screen for a single exercise: hero image, muscles-worked summary,
/// and (if the exercise has history) a volume trend + recent-session log.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  String _selectedTimeRange = '6M';

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final surface = context.surface;
    final historyAsync = ref
        .watch(exerciseHistoryProvider((exercise.id, _selectedTimeRange)));
    final isPremium = ref.watch(isPremiumProvider);
    final unit = ref.watch(weightUnitProvider);
    final gender =
        ref.watch(currentUserProfileProvider).valueOrNull?.gender ?? 'male';

    final secondary =
        (jsonDecode(exercise.secondaryMuscles ?? '[]') as List).cast<String>();
    final groups =
        workedGroupsFor(target: exercise.bodyPart, secondary: secondary);

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: surface.bgBase,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back_rounded,
                  size: 24, color: surface.textPrimary),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ExerciseHeroThumb(
                      exercise: exercise,
                      size: 140,
                      enableHero: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(exercise.name,
                      style: AppText.pageTitle(
                          color: surface.textPrimary,
                          shadows: AppText.depthFor(context))),
                  const SizedBox(height: 4),
                  Text('${exercise.bodyPart} • ${exercise.equipment}',
                      style: AppText.body(color: surface.textSecondary)),
                  const SizedBox(height: 16),
                  MuscleSummaryStrip(
                    primaryGroups: groups.primary,
                    secondaryGroups: groups.secondary,
                    gender: gender,
                  ),
                  const SizedBox(height: 28),
                  historyAsync.when(
                    loading: () => _wrapPulse(
                      label: 'Loading exercise history',
                      child: const _HistorySkeleton(),
                    ),
                    error: (_, __) => AsyncErrorState(
                      message: "Couldn't load exercise history.",
                      onRetry: () => ref.invalidate(
                          exerciseHistoryProvider(
                              (exercise.id, _selectedTimeRange))),
                    ),
                    data: (history) => history.sessions.isEmpty
                        ? const _NoHistoryState()
                        : _HistoryContent(
                            history: history,
                            isPremium: isPremium,
                            unit: unit,
                            selectedTimeRange: _selectedTimeRange,
                            onTimeRangeChanged: (r) =>
                                setState(() => _selectedTimeRange = r),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapPulse({required Widget child, String label = 'Loading'}) =>
      SkeletonPulse(label: label, child: child);
}

class _HistoryContent extends StatelessWidget {
  final ExerciseHistory history;
  final bool isPremium;
  final String unit;
  final String selectedTimeRange;
  final ValueChanged<String> onTimeRangeChanged;

  const _HistoryContent({
    required this.history,
    required this.isPremium,
    required this.unit,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSamples = gateChartSamples(history.volumeSamples, isPremium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExercisePrStrip(pr: history.pr, unit: unit),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Volume Trend', style: AppText.cardTitle()),
            Row(
              children: [
                if (!isPremium && history.volumeSamples.length > 3)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: ProLockPill(label: 'FULL HISTORY'),
                  ),
                TimeRangeFilter(
                  value: selectedTimeRange,
                  onChanged: onTimeRangeChanged,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ExerciseHistoryChart(samples: visibleSamples, unit: unit),
        const SizedBox(height: 28),
        Text('Recent Sessions', style: AppText.cardTitle()),
        const SizedBox(height: 12),
        for (final session in history.sessions.take(10))
          _SessionRow(session: session, unit: unit),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final ExerciseSessionEntry session;
  final String unit;

  const _SessionRow({required this.session, required this.unit});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                session.dateLabel,
                style: AppText.body(color: surface.textPrimary),
              ),
            ),
            Text(
              session.setsSummary(unit),
              style: AppText.caption(color: surface.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoHistoryState extends StatelessWidget {
  const _NoHistoryState();

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 28, color: surface.textTertiary),
            const SizedBox(height: 10),
            Text('No history yet',
                style: AppText.rowLabel(color: surface.textPrimary)),
            const SizedBox(height: 4),
            Text('Log a set with this exercise to see your progress.',
                textAlign: TextAlign.center,
                style: AppText.caption(color: surface.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 160, height: 56, radius: AppRadius.card),
        SizedBox(height: 24),
        SkeletonBox(width: 120, height: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 160, radius: AppRadius.card),
        SizedBox(height: 24),
        SkeletonBox(width: 130, height: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 52, radius: AppRadius.card),
        SizedBox(height: 10),
        SkeletonBox(height: 52, radius: AppRadius.card),
      ],
    );
  }
}
