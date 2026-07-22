import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';

/// KPI header above the profile weekly bar chart.
/// Shows the latest-week value with a contextual "This week" caption, and
/// a delta pill vs the previous week — but only once there are ≥ 4 filled
/// weeks so the percentage is computed from enough data to be meaningful.
class GraphKpiHeader extends StatelessWidget {
  final List<WeeklyAggregate> aggregates;
  final ProfileGraphMetric metric;

  const GraphKpiHeader({
    super.key,
    required this.aggregates,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final latest = aggregates.isEmpty ? null : aggregates.last;
    final previous =
        aggregates.length >= 2 ? aggregates[aggregates.length - 2] : null;
    final filledWeeks = aggregates.where((a) => a.workoutCount > 0).length;

    // Delta pill is suppressed below n=4 — two weeks of data is too noisy
    // for a percentage change to be a meaningful signal.
    final showDelta = filledWeeks >= 4 && latest != null && previous != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                latest == null ? '0' : _formatValue(latest.valueFor(metric)),
                style: AppText.statNumber(),
              ),
              const SizedBox(height: 2),
              Text(
                'This week',
                style: AppText.caption(color: surface.textTertiary),
              ),
            ],
          ),
        ),
        if (showDelta)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _DeltaPill(
              latest: latest.valueFor(metric),
              previous: previous.valueFor(metric),
            ),
          ),
      ],
    );
  }

  String _formatValue(double value) {
    final rounded = value.round();
    return switch (metric) {
      ProfileGraphMetric.volume => '${groupThousands(rounded)} kg',
      ProfileGraphMetric.duration => '${groupThousands(rounded)} min',
      ProfileGraphMetric.reps => '${groupThousands(rounded)} reps',
    };
  }
}

class _DeltaPill extends StatelessWidget {
  final double latest;
  final double previous;

  const _DeltaPill({required this.latest, required this.previous});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    if (previous == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: surface.textSecondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        child: Text(
          'vs last week',
          style: AppText.statLabel(color: surface.textSecondary),
        ),
      );
    }

    final delta = (latest - previous) / previous;
    final isPositive = delta >= 0;
    final pct = (delta * 100).round().abs();
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$pct% vs last week',
            style: AppText.statLabel(color: color),
          ),
        ],
      ),
    );
  }
}
