import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'routine_detail_styles.dart';

/// Hevy-style volume chart. Dumb widget — renders only from [data].
/// The screen owns the section header, range dropdown, and delta pill.
/// Holds just the touched-point selection so the value header can update.
class RoutineVolumeGraph extends StatefulWidget {
  final List<DailyVolumeSample> data;
  const RoutineVolumeGraph({super.key, required this.data});

  @override
  State<RoutineVolumeGraph> createState() => _RoutineVolumeGraphState();
}

class _RoutineVolumeGraphState extends State<RoutineVolumeGraph> {
  int? _touchedIndex;

  double _step(double maxV) => maxV <= 1500 ? 500 : 1000;
  double _niceMaxY(double maxV) {
    final s = _step(maxV);
    return maxV <= 0 ? s : ((maxV * 1.1) / s).ceil() * s;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) return _empty();

    final maxV =
        data.map((s) => s.volume).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = _niceMaxY(maxV);
    final step = _step(maxV);
    final spots = [
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].volume)
    ];

    final n = data.length;
    final selIndex =
        (_touchedIndex == null || _touchedIndex! >= n) ? n - 1 : _touchedIndex!;
    final sel = data[selIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        gradient: RDStyles.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: RDStyles.hairlineBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hevy-style value header — updates on tap.
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${sel.volume.toStringAsFixed(0)} kg',
                    style: RDStyles.chartValue),
                const SizedBox(width: 8),
                Text(DateFormat('MMM d').format(sel.day),
                    style: RDStyles.chartDate),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: -0.35,
                maxX: (n - 1) + 0.35,
                clipData: const FlClipData.none(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: step,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: RDStyles.hairline, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: step,
                      getTitlesWidget: (v, m) => (v < 0 || v > maxY)
                          ? const SizedBox.shrink()
                          : SideTitleWidget(
                              axisSide: m.axisSide,
                              space: 8,
                              child: Text(v.toInt().toString(),
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
                        return SideTitleWidget(
                          axisSide: m.axisSide,
                          space: 8,
                          child: Text(DateFormat('MMM d').format(data[i].day),
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
                              color: AppColors.accentPrimary
                                  .withValues(alpha: 0.25),
                              strokeWidth: 1,
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (s, p, b, ix) =>
                                  FlDotCirclePainter(
                                radius: 5.5,
                                color: AppColors.accentPrimary,
                                strokeWidth: 2.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                          ))
                      .toList(),
                  touchCallback: (e, resp) {
                    if (resp?.lineBarSpots?.isNotEmpty ?? false) {
                      setState(() =>
                          _touchedIndex = resp!.lineBarSpots!.first.spotIndex);
                    }
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: AppColors.accentPrimary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, i) {
                        final last = i == spots.length - 1;
                        return FlDotCirclePainter(
                          radius: last ? 5.5 : 3.5,
                          color: AppColors.accentPrimary,
                          strokeWidth: last ? 2.5 : 0,
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
                          AppColors.accentPrimary.withValues(alpha: 0.30),
                          AppColors.accentPrimary.withValues(alpha: 0.02),
                        ],
                      ),
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

  Widget _empty() => Container(
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
                        borderRadius: BorderRadius.circular(3),
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
            Text('No sessions logged yet', style: RDStyles.emptyTitle),
            const SizedBox(height: 3),
            Text('Finish a workout to see your volume trend',
                style: RDStyles.emptySub),
          ],
        ),
      );
}
