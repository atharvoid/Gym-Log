import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/daos/workouts_dao.dart';
import '../../../../core/theme/app_colors.dart';

/// [routine_volume_graph.dart]
/// Data-honest volume chart with strict threshold logic:
///   - n == 0: empty state
///   - n == 1: single annotated dot
///   - n == 2: straight line
///   - n >= 3: smooth cubic bezier + gradient fill
///   - Horizontal dotted grid at 4% opacity
///   - Y-axis uses Space Grotesk, includes 0 baseline

class RoutineVolumeGraph extends StatelessWidget {
  final List<DailyVolumeSample> data;

  const RoutineVolumeGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    if (data.length == 1) {
      return _buildSinglePoint(data.first);
    }

    final samples = data;
    double stepFn(double maxV) => maxV <= 1500 ? 500 : 1000;
    double niceMaxY(double maxV) {
      final s = stepFn(maxV);
      if (maxV <= 0) return s;
      return ((maxV * 1.1) / s).ceil() * s;
    }

    final maxV = samples.map((s) => s.volume).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = niceMaxY(maxV);
    final step = stepFn(maxV);
    final spots = [
      for (var i = 0; i < samples.length; i++) FlSpot(i.toDouble(), samples[i].volume)
    ];
    final axisStyle = GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.chartAxisLabel,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0E11), Color(0xFF09090B)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            minY: 0, maxY: maxY,
            minX: 0, maxX: (samples.length - 1).toDouble(),
            gridData: FlGridData(
              show: true, drawVerticalLine: false, horizontalInterval: step,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Colors.white.withValues(alpha: 0.07), strokeWidth: 1, dashArray: [4, 5]),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40, interval: step,
                  getTitlesWidget: (v, m) => SideTitleWidget(
                    axisSide: m.axisSide, space: 8,
                    child: Text(v.toInt().toString(), style: axisStyle)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24, interval: 1,
                  getTitlesWidget: (v, m) {
                    if (v != v.roundToDouble()) return const SizedBox.shrink(); // integer ticks only
                    final i = v.toInt();
                    if (i < 0 || i >= samples.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                      axisSide: m.axisSide, space: 8,
                      child: Text(DateFormat('MMM d').format(samples[i].day), style: axisStyle));
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: false, color: AppColors.accentPrimary,
                barWidth: 2.5, isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, i) {
                    final isLast = i == spots.length - 1;
                    return FlDotCirclePainter(
                      radius: isLast ? 5.5 : 3.5, color: AppColors.accentPrimary,
                      strokeWidth: isLast ? 2.5 : 0, strokeColor: Colors.white);
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No data yet',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildSinglePoint(DailyVolumeSample point) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 100,
          child: Container(
            height: 1,
            color: const Color(0x0DFFFFFF),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textPrimary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${point.volume.toStringAsFixed(0)} kg',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('MMM d').format(point.day),
                style: GoogleFonts.inter(
                  color: const Color(0xFF6A6A6A),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
