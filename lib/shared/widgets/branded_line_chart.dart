import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/widgets/routine_detail_styles.dart';

/// One data point on a [BrandedLineChart].
class ChartPoint {
  final DateTime date;
  final double value;
  const ChartPoint(this.date, this.value);
}

/// THE app chart. Routine Detail, Exercise Detail and Profile all render
/// through this single component so curve behavior, dot styling, axis
/// formatting, touch handling and empty states are pixel-identical.
///
/// ACCENT: fl_chart does NOT read ThemeData — every colored element is an
/// explicit argument. So the accent is resolved once per build from the live
/// palette (`context.accent`) and injected into the line, dots, touch
/// indicator, area fill AND the selected-date header (via
/// `RDStyles.chartDate.copyWith(color: accent.light)`, because a static
/// TextStyle can't react). No accent hex is hardcoded here.
///
/// Interaction model (Hevy-benchmarked, per design memory): no floating
/// tooltip box — touching a point updates the value+date header above the
/// plot. The latest point is emphasized with a ringed dot. Data changes
/// animate implicitly.
class BrandedLineChart extends StatefulWidget {
  final List<ChartPoint> data;

  /// Formats the header value ("12,450 kg", "128 min").
  final String Function(double value) valueFormatter;

  /// Formats Y-axis labels (compact, unitless — the section title owns
  /// the unit).
  final String Function(double value) axisFormatter;

  /// Formats the header date ("Jun 8" / "week of Jun 8").
  final String Function(DateTime date) dateFormatter;

  final String emptyTitle;
  final String emptySubtitle;
  final double height;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  /// Optional unit suffix for Y-axis labels (e.g. "kg", "min", "reps").
  /// The value formatter still owns the full header value; this only affects
  /// the compact axis ticks so the chart reads as a standard labelled plot.
  final String? yAxisUnit;

  BrandedLineChart({
    super.key,
    required this.data,
    required this.valueFormatter,
    String Function(double value)? axisFormatter,
    String Function(DateTime date)? dateFormatter,
    this.emptyTitle = 'No data yet',
    this.emptySubtitle = 'Finish a workout to see your trend',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.yAxisUnit,
    this.height = 180,
  })  : axisFormatter = axisFormatter ?? defaultAxisFormat,
        dateFormatter = dateFormatter ?? ((d) => DateFormat('MMM d').format(d));

  /// Compact axis labels with no float noise: 850 → "850", 3000 → "3k",
  /// 9000 → "9k" (never "9.0k"), 12500 → "12.5k". One rule for every
  /// chart in the app — axis language must not differ between screens.
  /// Public (not underscored) so the regression test can pin the contract.
  static String defaultAxisFormat(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return k == k.truncateToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  @override
  State<BrandedLineChart> createState() => _BrandedLineChartState();
}

class _BrandedLineChartState extends State<BrandedLineChart> {
  int? _touchedIndex;

  double _niceInterval(double maxV) {
    if (maxV <= 0) return 1;
    final raw = maxV / 3;
    final magnitude = raw <= 10
        ? 5.0
        : raw <= 100
            ? 25.0
            : raw <= 500
                ? 100.0
                : raw <= 1500
                    ? 500.0
                    : 1000.0;
    return (raw / magnitude).ceil() * magnitude;
  }

  String _axisLabel(double v) {
    final unit = widget.yAxisUnit;
    final value = widget.axisFormatter(v);
    if (unit == null || unit.isEmpty) return value;
    return '$value $unit';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) return _empty(context);
    // A line needs two points to be a line. With exactly one session a lone
    // floating dot reads as "broken" — show the value as a confident single
    // stat instead (the most common state for a new / just-imported routine).
    if (data.length == 1) return _single(context, data.first);

    // Accent is resolved once per build — every brand-colored mark below
    // (line, dots, touch indicator, area fill, date header) reads from the
    // live palette. fl_chart ignores ThemeData, so this explicit injection is
    // the ONLY way the chart tracks the accent.
    final accent = context.accent;

    final maxV =
        data.map((s) => s.value).fold<double>(0, (a, b) => a > b ? a : b);
    final interval = _niceInterval(maxV);
    final maxY =
        maxV <= 0 ? interval : ((maxV * 1.1) / interval).ceil() * interval;

    final n = data.length;
    final selIndex =
        (_touchedIndex == null || _touchedIndex! >= n) ? n - 1 : _touchedIndex!;
    final sel = data[selIndex];

    final spots = [
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), data[i].value)
    ];

    // Intentional X-label density: first, last, and ~2 between.
    final labelStep = n <= 4 ? 1 : (n / 4).ceil();

    // Average reference line — only meaningful with 3+ points AND visible
    // spread. On a flat series avg == every value, so the dashed line would
    // draw directly on top of the data line and trail past the last point
    // with a stray "avg" caption crowding the selected dot.
    final minV = data
        .map((s) => s.value)
        .fold<double>(double.infinity, (a, b) => a < b ? a : b);
    final bool hasSpread = (maxV - minV) > 0.001;
    final double? avg = (n >= 3 && hasSpread)
        ? data.map((s) => s.value).reduce((a, b) => a + b) / n
        : null;

    final Widget chart = Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        gradient: RDStyles.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: RDStyles.hairlineBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value header — updates on touch, no floating tooltip box.
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // liveRegion: scrubbing the chart updates this value, so a
                // screen reader announces the newly selected point.
                Semantics(
                  liveRegion: true,
                  child: Text(widget.valueFormatter(sel.value),
                      style: RDStyles.chartValue),
                ),
                const SizedBox(width: 8),
                Text(widget.dateFormatter(sel.date),
                    style: RDStyles.chartDate.copyWith(color: accent.light)),
              ],
            ),
          ),
          SizedBox(
            height: widget.height,
            child: LineChart(
              // Reduce-motion: render the chart instantly, no entry tween.
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: -0.35,
                maxX: (n - 1) + 0.35,
                clipData: const FlClipData.none(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: 1,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: RDStyles.hairline, strokeWidth: 1),
                  getDrawingVerticalLine: (v) =>
                      FlLine(color: RDStyles.hairline, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (v, m) => (v <= 0 || v > maxY)
                          ? const SizedBox.shrink()
                          : SideTitleWidget(
                              axisSide: m.axisSide,
                              space: 8,
                              child: Text(_axisLabel(v),
                                  style: RDStyles.axis),
                            ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (v, m) => (v <= 0 || v > maxY)
                          ? const SizedBox.shrink()
                          : SideTitleWidget(
                              axisSide: m.axisSide,
                              space: 8,
                              child: Text(_axisLabel(v),
                                  style: RDStyles.axis),
                            ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (v, m) {
                        if (v != v.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        final i = v.toInt();
                        if (i < 0 || i >= n) return const SizedBox.shrink();
                        final isEdge = i == 0 || i == n - 1;
                        if (!isEdge && i % labelStep != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: m.axisSide,
                          space: 8,
                          child: Text(widget.dateFormatter(data[i].date),
                              style: RDStyles.axis),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 0,
                    getTooltipItems: (s) => s.map((_) => null).toList(),
                  ),
                  getTouchedSpotIndicator: (bar, idx) => idx
                      .map((i) => TouchedSpotIndicatorData(
                            FlLine(
                              color: accent.base.withValues(alpha: 0.25),
                              strokeWidth: 1,
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (s, p, b, ix) =>
                                  FlDotCirclePainter(
                                radius: 5.5,
                                color: accent.base,
                                strokeWidth: 2.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                          ))
                      .toList(),
                  touchCallback: (e, resp) {
                    final i = (resp?.lineBarSpots?.isNotEmpty ?? false)
                        ? resp!.lineBarSpots!.first.spotIndex
                        : null;
                    // Selecting a point is a discrete selection — buzz like
                    // every other selection in the app, only when it changes.
                    if (i != null && i != _touchedIndex) {
                      HapticFeedback.selectionClick();
                      setState(() => _touchedIndex = i);
                    }
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: accent.base,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, i) {
                        // Only the SELECTED point (defaults to latest, moves
                        // on tap) gets the emphasized ringed dot — no
                        // permanent white ring decorating the last point.
                        final isSelected = i == selIndex;
                        return FlDotCirclePainter(
                          radius: isSelected ? 5.5 : 3,
                          color: accent.base,
                          strokeWidth: isSelected ? 2.5 : 0,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.base.withValues(alpha: 0.08),
                          accent.base.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                // Dashed average line — a quiet reference the eye can read
                // each point against. Hidden for trivial 1-2 point series.
                extraLinesData: ExtraLinesData(
                  horizontalLines: avg == null
                      ? const []
                      : [
                          HorizontalLine(
                            y: avg,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.20),
                            strokeWidth: 1,
                            dashArray: const [4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding:
                                  const EdgeInsets.only(right: 4, bottom: 2),
                              style: RDStyles.axis,
                              labelResolver: (_) => 'avg',
                            ),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: 'Volume chart, ${data.length} sessions. '
          'Selected ${widget.valueFormatter(sel.value)} '
          'on ${widget.dateFormatter(sel.date)}.',
      child: chart,
    );
  }

  /// Single-session state — a confident stat, not a lonely dot.
  Widget _single(BuildContext context, ChartPoint p) {
    final accent = context.accent;
    return Semantics(
      container: true,
      label: 'Volume chart, one session: '
          '${widget.valueFormatter(p.value)} on ${widget.dateFormatter(p.date)}.',
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: RDStyles.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: RDStyles.hairlineBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(widget.valueFormatter(p.value), style: RDStyles.chartValue),
                const SizedBox(width: 8),
                Text(widget.dateFormatter(p.date),
                    style: RDStyles.chartDate.copyWith(color: accent.light)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 15, color: accent.light),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'One session logged — finish another to chart your trend',
                    style: RDStyles.emptySub,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: RDStyles.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: RDStyles.hairlineBorder,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 34,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in const [0.40, 0.65, 0.50, 0.80, 0.95])
                    Container(
                      width: 6,
                      height: 34 * h,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF3A2A55), Color(0xFF1A1A1D)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(widget.emptyTitle, style: RDStyles.emptyTitle),
            const SizedBox(height: 3),
            Text(widget.emptySubtitle, style: RDStyles.emptySub),
            if (widget.onEmptyAction != null && widget.emptyActionLabel != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: widget.onEmptyAction,
                child: Text(
                  widget.emptyActionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.accent.light,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
