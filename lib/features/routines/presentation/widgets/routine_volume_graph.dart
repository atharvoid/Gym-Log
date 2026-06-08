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

    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.volume)).toList();

    final values = data.map((d) => d.volume).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    // gymlog-fix A1: pad y-axis max by 15% and dedupe peak label
    final rawMax = maxVal * 1.15;
    final rawInterval = rawMax / 4;
    double niceInterval = 50;
    if (rawInterval <= 50) {
      niceInterval = 50;
    } else if (rawInterval <= 100) {
      niceInterval = 100;
    } else if (rawInterval <= 200) {
      niceInterval = 200;
    } else if (rawInterval <= 250) {
      niceInterval = 250;
    } else if (rawInterval <= 500) {
      niceInterval = 500;
    } else if (rawInterval <= 1000) {
      niceInterval = 1000;
    } else {
      niceInterval = ((rawInterval / 1000).ceil() * 1000).toDouble();
    }

    final maxY = niceInterval * 4;
    const double minY = 0.0;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 8),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.none(),
          gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: niceInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: niceInterval,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8, right: 8),
                  child: Text(
                    '${value.toInt()}',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF6A6A6A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _bottomInterval(spots.last.x),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > spots.last.x.toInt() || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM d').format(data[index].day),
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: -0.5,
        maxX: spots.last.x + 0.5,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.accentPrimary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isLast = index == spots.length - 1;
                return FlDotCirclePainter(
                  radius: isLast ? 4 : 3,
                  color: AppColors.accentPrimary,
                  strokeWidth: isLast ? 2 : 0,
                  strokeColor:
                      isLast ? AppColors.textPrimary : Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accentPrimary.withValues(alpha: 0.25),
                  AppColors.accentPrimary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF121212),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final index = s.x.toInt();
              final sample = data[index];
              final dateStr = DateFormat('MMM d').format(sample.day);
              
              List<TextSpan> children = [];
              children.add(TextSpan(
                text: '\n$dateStr',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ));
              
              return LineTooltipItem(
                '${s.y.toStringAsFixed(0)} kg',
                GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFE9E9EE),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                children: children,
              );
            }).toList(),
          ),
          handleBuiltInTouches: true,
        ),
      ),
    ));
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

  double _bottomInterval(double count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 7;
    if (count <= 90) return 14;
    return 30;
  }
}
