import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';

/// KPI header above the profile weekly bar chart.
/// Shows the latest-week value and a delta pill vs the previous week.
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
    final latest = aggregates.isEmpty ? null : aggregates.last;
    final previous =
        aggregates.length >= 2 ? aggregates[aggregates.length - 2] : null;
    final filledWeeks = aggregates.where((a) => a.workoutCount > 0).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            latest == null ? '—' : _formatValue(latest.valueFor(metric)),
            style: AppText.statNumber(),
          ),
        ),
        if (filledWeeks >= 2 && latest != null && previous != null)
          _DeltaPill(
            latest: latest.valueFor(metric),
            previous: previous.valueFor(metric),
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
    if (previous == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '—',
          style: AppText.statLabel(color: AppColors.textSecondary),
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
        borderRadius: BorderRadius.circular(999),
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
            '$pct%',
            style: AppText.statLabel(color: color),
          ),
        ],
      ),
    );
  }
}
