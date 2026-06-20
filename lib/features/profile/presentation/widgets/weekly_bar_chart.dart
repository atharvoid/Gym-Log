import 'dart:math' show pi, max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/shared/widgets/branded_line_chart.dart';
import 'package:intl/intl.dart';

/// Categorical weekly bar chart for the Profile "Training" section.
/// Accepts the exact weeks the caller wants to display; empty weeks are rendered
/// as 1px ghost bars so the baseline stays rhythmically consistent.
class WeeklyBarChart extends StatefulWidget {
  final List<WeeklyAggregate> aggregates;
  final ProfileGraphMetric metric;

  const WeeklyBarChart({
    super.key,
    required this.aggregates,
    required this.metric,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int? _touchedIndex;
  List<BarChartGroupData> _barGroups = const [];
  double _maxY = 1;
  double _interval = 1;

  @override
  void initState() {
    super.initState();
    _computeBars();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aggregates != widget.aggregates ||
        oldWidget.metric != widget.metric) {
      _computeBars();
    }
  }

  void _computeBars() {
    final metric = widget.metric;
    final values = widget.aggregates.map((a) => a.valueFor(metric)).toList();
    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    _interval = _niceInterval(maxValue, metric);
    _maxY = _axisMax(maxValue, metric, _interval);

    final now = DateTime.now();
    final currentWeekStart = _weekStartOf(now);
    final isCurrentWeekInProgress = widget.aggregates.isNotEmpty &&
        widget.aggregates.last.weekStart == currentWeekStart &&
        now.weekday != DateTime.sunday;

    _barGroups = [
      for (var i = 0; i < widget.aggregates.length; i++)
        _buildGroup(
          index: i,
          aggregate: widget.aggregates[i],
          value: values[i],
          isLatest: i == widget.aggregates.length - 1,
          isInProgress:
              isCurrentWeekInProgress && i == widget.aggregates.length - 1,
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

    final Color rodColor;
    final Gradient? rodGradient;
    if (isTouched) {
      rodColor = AppColors.profileGraphActiveBarBright;
      rodGradient = null;
    } else if (isInProgress) {
      rodColor = AppColors.profileGraphInactiveBar;
      rodGradient = _hatchedGradient();
    } else if (isLatest) {
      rodColor = AppColors.profileGraphActiveBar;
      rodGradient = null;
    } else if (hasValue) {
      rodColor = AppColors.profileGraphPreviousBar;
      rodGradient = null;
    } else {
      rodColor = AppColors.profileGraphGhostBar;
      rodGradient = null;
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
          color: rodGradient == null ? rodColor : null,
          gradient: rodGradient,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Gradient _hatchedGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      transform: const GradientRotation(pi / 4),
      colors: [
        AppColors.profileGraphActiveBar.withValues(alpha: 0.3),
        AppColors.profileGraphActiveBar.withValues(alpha: 0.3),
        AppColors.profileGraphInactiveBar,
        AppColors.profileGraphInactiveBar,
      ],
      stops: const [0.0, 0.2, 0.2, 0.4],
      tileMode: TileMode.repeated,
    );
  }

  /// Nice interval for gridlines and axis labels.
  double _niceInterval(double max, ProfileGraphMetric metric) {
    if (max <= 0) {
      return switch (metric) {
        ProfileGraphMetric.duration => 30,
        ProfileGraphMetric.reps => 100,
        ProfileGraphMetric.volume => 1000,
      };
    }
    const steps = <double>[
      1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000,
      100000,
    ];
    for (final step in steps) {
      if (max / step <= 4) return step;
    }
    return steps.last;
  }

  /// Upper bound of the Y-axis. For volume we round to the nearest 1k so the
  /// top label is not overscaled (e.g. 6,780 -> 7k instead of 8k).
  double _axisMax(double max, ProfileGraphMetric metric, double interval) {
    if (max <= 0) return interval;
    if (metric == ProfileGraphMetric.volume) {
      final kCeiling = ((max / 1000).ceil() * 1000).toDouble();
      return kCeiling < interval ? interval : kCeiling;
    }
    return ((max / interval).ceil() * interval);
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

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final boldText = MediaQuery.boldTextOf(context);

    if (_barGroups.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: _buildAccessibilitySummary(),
      child: Padding(
        // Prevent the top Y-axis label from being clipped by the container.
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
                  color: AppColors.profileGraphGridLine,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
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
                    reservedSize: 48,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= widget.aggregates.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Transform.rotate(
                          angle: -pi / 4,
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            DateFormat('MMM d')
                                .format(widget.aggregates[index].weekStart),
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
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(12),
                  tooltipMargin: 8,
                  getTooltipColor: (_) => AppColors.profileGraphTooltipBg,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final aggregate = widget.aggregates[groupIndex];
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
    final latest = widget.aggregates.lastOrNull;
    if (latest == null) return 'Weekly training chart';

    final latestValue = _valueLabel(latest.valueFor(widget.metric));
    final previous = widget.aggregates.length >= 2
        ? widget.aggregates[widget.aggregates.length - 2]
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
        '${widget.aggregates.length} weeks, latest week $latestValue$change';
  }
}
