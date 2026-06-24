import 'dart:math' show pi, max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/shared/widgets/branded_line_chart.dart';
import 'package:intl/intl.dart';

/// Categorical weekly bar chart for the Profile "Training" section.
///
/// **Low-data path (< 4 filled weeks):** renders a [_ComparisonView] — a clear
/// stat comparison card that honestly reflects how little data exists. No chart
/// is rendered, no lock banner needed.
///
/// **Full-data path (≥ 4 filled weeks):** renders the BarChart with:
///   - Linear, evenly-spaced Y-axis (max = dataMax × 1.15 rounded to next interval)
///   - Accent current-week bar / neutral-gray historical bars (no cyan)
///   - Value labels printed above bars (when ≤ 6 bars)
///   - Horizontal X-axis labels (no rotation) when ≤ 4 bars; 30° for more
///   - White-8% gridlines (barely-there guides, not competing with bars)
class WeeklyBarChart extends StatefulWidget {
  final List<WeeklyAggregate> aggregates;
  final ProfileGraphMetric metric;
  final bool isPremium;

  const WeeklyBarChart({
    super.key,
    required this.aggregates,
    required this.metric,
    required this.isPremium,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int? _touchedIndex;
  List<BarChartGroupData> _barGroups = const [];
  double _maxY = 1;
  double _interval = 1;

  // Live accent palette — resolved from the inherited theme in
  // didChangeDependencies so bar colors track the user's chosen palette.
  // Bars are computed off the BuildContext (initState/didUpdateWidget), so the
  // accent must be cached on the State rather than read inside _buildGroup.
  AccentColors _accent = AccentColors.purpleFallback;

  // Derived counts — recomputed in _computeBars.
  int _filledWeeks = 0;
  List<WeeklyAggregate> _gatedAggregates = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fires whenever the MaterialApp theme rebuilds (i.e. the user picks a
    // new accent), so the bars recolor without an explicit listener.
    final accent = context.accent;
    final changed = accent != _accent;
    _accent = accent;
    if (changed || _barGroups.isEmpty) _computeBars();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aggregates != widget.aggregates ||
        oldWidget.metric != widget.metric ||
        oldWidget.isPremium != widget.isPremium) {
      _computeBars();
    }
  }

  void _computeBars() {
    final metric = widget.metric;
    _gatedAggregates = gateChartSamples(widget.aggregates, widget.isPremium);
    final values = _gatedAggregates.map((a) => a.valueFor(metric)).toList();

    // Count filled weeks from the FULL ungated window so free users with
    // ≥4 filled weeks across 8 weeks still unlock the full chart.
    // The gate only clips which bars render — it must not suppress the
    // threshold check that decides between chart and comparison view.
    _filledWeeks =
        widget.aggregates.where((a) => a.workoutCount > 0).length;

    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    _interval = _niceInterval(maxValue, metric);
    _maxY = _axisMax(maxValue, metric, _interval);

    final now = DateTime.now();
    final currentWeekStart = _weekStartOf(now);
    final isCurrentWeekInProgress = _gatedAggregates.isNotEmpty &&
        _gatedAggregates.last.weekStart == currentWeekStart &&
        now.weekday != DateTime.sunday;

    _barGroups = [
      for (var i = 0; i < _gatedAggregates.length; i++)
        _buildGroup(
          index: i,
          aggregate: _gatedAggregates[i],
          value: values[i],
          isLatest: i == _gatedAggregates.length - 1,
          isInProgress:
              isCurrentWeekInProgress && i == _gatedAggregates.length - 1,
        ),
    ];
  }

  BarChartGroupData _buildGroup({
    required int index,
    required WeeklyAggregate aggregate,
    required double value,
    required bool isLatest,
    required bool isInProgress,
  }) {
    final isTouched = index == _touchedIndex;
    final hasValue = value > 0;

    // ── Semantic color rule ─────────────────────────────────────────────────────
    // current week (complete)  → accent base
    // current week (in-flight) → accent base 50% (shows progress, not done)
    // previous weeks with data → neutral cool-gray (historical reference)
    // empty week slot          → ghost (barely visible placeholder)
    // touch highlight          → accent light (slightly brighter)
    final Color rodColor;
    if (isTouched) {
      rodColor = _accent.light;
    } else if (isLatest && !isInProgress) {
      rodColor = _accent.base;
    } else if (isInProgress) {
      rodColor = _accent.base.withValues(alpha: 0.50);
    } else if (hasValue) {
      rodColor = AppColors.profileGraphHistoricalBar;
    } else {
      rodColor = AppColors.profileGraphGhostBar;
    }

    // Render a ~1px ghost bar for empty weeks so the X-axis slot is not a void.
    final rodHeight = hasValue ? value : max(_maxY / 120, 0.2);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: rodHeight,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          color: rodColor,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  /// Corrected axis max: dataMax × 1.15, rounded UP to the next clean interval.
  /// This guarantees the top label is always above the tallest bar and that
  /// every tick gap is identical — fixing the non-linear axis bug.
  double _axisMax(double dataMax, ProfileGraphMetric metric, double interval) {
    if (dataMax <= 0) return interval * 4; // sensible empty-state range
    final padded = dataMax * 1.15;
    return (padded / interval).ceil() * interval;
  }

  /// Nice interval for gridlines and axis labels.
  /// Target: 4–5 ticks maximum so the chart doesn't feel cluttered.
  double _niceInterval(double dataMax, ProfileGraphMetric metric) {
    if (dataMax <= 0) {
      return switch (metric) {
        ProfileGraphMetric.duration => 30,
        ProfileGraphMetric.reps => 100,
        ProfileGraphMetric.volume => 2000,
      };
    }
    // Candidate steps — always results in 3–5 ticks
    const steps = <double>[
      1, 2, 5, 10, 20, 50, 100, 200, 500,
      1000, 2000, 5000, 10000, 20000, 50000, 100000,
    ];
    // We aim for max / step ≤ 5 ticks
    for (final step in steps) {
      if (dataMax / step <= 5) return step;
    }
    return steps.last;
  }

  DateTime _weekStartOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _yAxisLabel(double value) {
    return switch (widget.metric) {
      ProfileGraphMetric.volume => BrandedLineChart.defaultAxisFormat(value),
      ProfileGraphMetric.duration => '${value.toInt()}m',
      ProfileGraphMetric.reps => value.toInt().toString(),
    };
  }

  String _valueLabel(double value) {
    final rounded = value.round();
    return switch (widget.metric) {
      ProfileGraphMetric.volume => '${groupThousands(rounded)} kg',
      ProfileGraphMetric.duration => '${groupThousands(rounded)} min',
      ProfileGraphMetric.reps => '${groupThousands(rounded)} reps',
    };
  }

  String _weekRangeLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(start)} — ${DateFormat('MMM d').format(end)}';
  }

  // ── Low-data comparison view ─────────────────────────────────────────────────

  /// Renders when filledWeeks < 4. Shows an honest stat comparison instead of
  /// a broken/half-empty chart sitting under a "data not ready" banner.
  Widget _buildComparisonView() {
    final filledAggs = _gatedAggregates.where((a) => a.workoutCount > 0).toList();
    final latest = filledAggs.isNotEmpty ? filledAggs.last : null;
    final previous = filledAggs.length >= 2 ? filledAggs[filledAggs.length - 2] : null;

    final latestValue = latest?.valueFor(widget.metric) ?? 0;
    final prevValue = previous?.valueFor(widget.metric) ?? 0;

    final double? deltaFraction = (prevValue > 0 && latestValue > 0)
        ? (latestValue - prevValue) / prevValue
        : null;

    const neededWeeks = 4;
    final progressFraction = (_filledWeeks / neededWeeks).clamp(0.0, 1.0);

    final totalLoggedSamples = widget.aggregates.where((a) => a.workoutCount > 0).length;
    // visibleSamples: use the gated count (how many weeks are actually shown
    // to this user tier) so the banner reflects what IS visible, not total history.
    final gatedFilledWeeks = _gatedAggregates.where((a) => a.workoutCount > 0).length;
    final bannerText = chartLimitBannerCopy(
          isPremium: widget.isPremium,
          totalLoggedSamples: totalLoggedSamples,
          visibleSamples: gatedFilledWeeks,
          minSamplesForTrend: neededWeeks,
        ) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat comparison row
        Row(
          children: [
            if (previous != null) ...[
              Expanded(
                child: _StatBlock(
                  label: 'Last week',
                  value: _valueLabel(prevValue),
                  dim: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildDeltaIndicator(deltaFraction),
              ),
            ],
            Expanded(
              child: _StatBlock(
                label: 'This week',
                value: latest != null ? _valueLabel(latestValue) : '—',
                dim: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Progress toward unlocking the chart
        if (bannerText.isNotEmpty)
          _UnlockProgress(
            progressFraction: progressFraction,
            bannerText: bannerText,
          ),
      ],
    );
  }

  Widget _buildDeltaIndicator(double? fraction) {
    if (fraction == null) {
      return const Icon(Icons.arrow_forward_rounded,
          size: 18, color: AppColors.textTertiary);
    }
    final isUp = fraction >= 0;
    final pct = (fraction * 100).round().abs();
    final color = isUp ? AppColors.success : AppColors.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 16,
          color: color,
        ),
        Text(
          '$pct%',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Full bar chart ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final boldText = MediaQuery.boldTextOf(context);
    final accent = context.accent;

    if (_barGroups.isEmpty) return const SizedBox.shrink();

    // Low-data path: honest comparison view instead of a half-empty chart.
    if (_filledWeeks < 4) {
      return _buildComparisonView();
    }

    // Full chart — ≥ 4 filled weeks.
    final barCount = _gatedAggregates.length;
    final showValueLabels = barCount <= 6;
    // Rotate labels when many bars; keep horizontal for ≤ 4.
    final labelAngle = barCount <= 4 ? 0.0 : -pi / 6;
    final labelBottomPad = barCount <= 4 ? 28.0 : 44.0;

    return Semantics(
      label: _buildAccessibilitySummary(),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: AspectRatio(
          aspectRatio: 1.55,
          child: BarChart(
            BarChartData(
              maxY: _maxY,
              minY: 0,
              baselineY: 0,
              alignment: BarChartAlignment.center,
              groupsSpace: 8,
              barGroups: _barGroups,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _interval,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.profileGraphGridLine, // white 8%
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                // Value labels above bars
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showValueLabels,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _gatedAggregates.length) {
                        return const SizedBox.shrink();
                      }
                      final agg = _gatedAggregates[index];
                      final v = agg.valueFor(widget.metric);
                      if (v <= 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(
                          _yAxisLabel(v),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: index == _gatedAggregates.length - 1
                                ? accent.light
                                : AppColors.textTertiary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _interval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        _yAxisLabel(value),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              boldText ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.profileGraphAxisLabel,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: labelBottomPad,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _gatedAggregates.length) {
                        return const SizedBox.shrink();
                      }
                      final label = DateFormat('MMM d')
                          .format(_gatedAggregates[index].weekStart);
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: labelAngle == 0.0
                            ? Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: boldText
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: AppColors.profileGraphAxisLabel,
                                ),
                              )
                            : Transform.rotate(
                                angle: labelAngle,
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: boldText
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: AppColors.profileGraphAxisLabel,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: AppRadius.badge.toDouble(),
                  tooltipPadding: const EdgeInsets.all(12),
                  tooltipMargin: 8,
                  getTooltipColor: (_) => AppColors.profileGraphTooltipBg,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final aggregate = _gatedAggregates[groupIndex];
                    final value = aggregate.valueFor(widget.metric);
                    return BarTooltipItem(
                      '${_weekRangeLabel(aggregate.weekStart)}\n',
                      GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: _valueLabel(value),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text:
                              '\n${aggregate.workoutCount} workout${aggregate.workoutCount == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (event, response) {
                  final index = response?.spot?.touchedBarGroupIndex;
                  if (event is FlTapDownEvent || event is FlLongPressStart) {
                    HapticFeedback.selectionClick();
                  }
                  setState(() {
                    if (event is FlTapUpEvent ||
                        event is FlTapCancelEvent ||
                        event is FlPanEndEvent ||
                        event is FlLongPressEnd) {
                      _touchedIndex = null;
                    } else {
                      _touchedIndex = index;
                    }
                    // Recolor the touched/last bars off the new selection.
                    _computeBars();
                  });
                },
              ),
            ),
            swapAnimationDuration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  String _buildAccessibilitySummary() {
    final latest = _gatedAggregates.lastOrNull;
    if (latest == null) return 'Weekly training chart';

    final latestValue = _valueLabel(latest.valueFor(widget.metric));
    final previous = _gatedAggregates.length >= 2
        ? _gatedAggregates[_gatedAggregates.length - 2]
        : null;
    String change = '';
    if (previous != null && previous.valueFor(widget.metric) != 0) {
      final delta = (latest.valueFor(widget.metric) -
              previous.valueFor(widget.metric)) /
          previous.valueFor(widget.metric);
      final pct = (delta * 100).round().abs();
      final direction = delta >= 0 ? 'up' : 'down';
      change = ', $direction $pct percent from previous week';
    }
    return 'Weekly ${widget.metric.label.toLowerCase()} chart, '
        '${_gatedAggregates.length} weeks, latest week $latestValue$change';
  }
}

// ── Supporting widgets for the comparison/low-data view ──────────────────────────

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool dim;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.dim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.caption(
            color: dim ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: dim ? AppColors.textSecondary : AppColors.textPrimary,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _UnlockProgress extends StatelessWidget {
  final double progressFraction;
  final String bannerText;

  const _UnlockProgress({
    required this.progressFraction,
    required this.bannerText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.badge),
          child: LinearProgressIndicator(
            value: progressFraction,
            minHeight: 4,
            backgroundColor: AppColors.surface3,
            valueColor: AlwaysStoppedAnimation<Color>(
              context.accent.base,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                bannerText,
                style: AppText.caption(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
