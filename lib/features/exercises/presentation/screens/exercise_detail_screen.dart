import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import '../providers/exercise_analytics_provider.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  int _activeToggleIndex = 0;
  String _selectedTimeRange = 'All Time';

  static const _toggleLabels = [
    'Heaviest Weight',
    'One Rep Max',
    'Best Set',
    'Best Volume',
  ];

  static const _timeRangeOptions = ['1M', '3M', '6M', '1Y', 'All Time'];

  List<ExerciseHistoryData> _filteredHistory(List<ExerciseHistoryData> history) {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case '1M':
        return history
            .where((e) => e.date.isAfter(now.subtract(const Duration(days: 30))))
            .toList();
      case '3M':
        return history
            .where((e) => e.date.isAfter(now.subtract(const Duration(days: 90))))
            .toList();
      case '6M':
        return history
            .where((e) => e.date.isAfter(now.subtract(const Duration(days: 180))))
            .toList();
      case '1Y':
        return history
            .where((e) => e.date.isAfter(now.subtract(const Duration(days: 365))))
            .toList();
      default:
        return history;
    }
  }

  double _metricForToggle(ExerciseHistoryData e, int index) {
    switch (index) {
      case 0:
        return e.weight;
      case 1:
        return e.estimated1RM;
      case 2:
        return e.weight;
      case 3:
        return e.volume;
      default:
        return e.weight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync =
        ref.watch(exerciseAnalyticsProvider(widget.exercise.id));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          widget.exercise.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.bgSurface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Media Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
            ),
          ),

          const SizedBox(height: 16),

          // Exercise Name & Metadata
          Text(
            widget.exercise.name,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.exercise.target} • ${widget.exercise.equipment}',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 24),

          historyAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CircularProgressIndicator(
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Text(
                  'Failed to load analytics',
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
              ),
            ),
            data: (history) {
              final filtered = _filteredHistory(history);
              return Column(
                children: [
                  _buildGraphSection(filtered),
                  const SizedBox(height: 24),
                  _buildStatToggles(),
                  const SizedBox(height: 24),
                  _buildPersonalRecords(filtered),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection(List<ExerciseHistoryData> history) {
    final spots = history.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return FlSpot(i.toDouble(), _metricForToggle(e, _activeToggleIndex));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _toggleLabels[_activeToggleIndex],
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              offset: const Offset(0, 36),
              color: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                setState(() => _selectedTimeRange = val);
              },
              itemBuilder: (context) => _timeRangeOptions.map((opt) {
                return PopupMenuItem(
                  value: opt,
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      color: _selectedTimeRange == opt
                          ? AppColors.accentPrimary
                          : AppColors.textPrimary,
                      fontWeight: _selectedTimeRange == opt
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTimeRange,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: spots.isEmpty
              ? Center(
                  child: Text(
                    'No data yet',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                )
              : LineChart(_chartData(spots, history)),
        ),
      ],
    );
  }

  LineChartData _chartData(List<FlSpot> spots, List<ExerciseHistoryData> history) {
    final maxY = spots.isEmpty
        ? 50.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.15;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.borderSubtle.withValues(alpha: 0.4),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _bottomLabelInterval(spots.length),
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i >= 0 && i < history.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM d').format(history[i].date),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()} kg',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.accentPrimary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accentPrimary.withValues(alpha: 0.3),
                AppColors.accentPrimary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.bgSurface,
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
            final i = s.x.toInt();
            final dateStr = i >= 0 && i < history.length
                ? DateFormat('MMM d').format(history[i].date)
                : '';
            return LineTooltipItem(
              '${s.y.toStringAsFixed(1)} kg\n$dateStr',
              GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: AppColors.accentPrimary.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, i) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accentPrimary,
                  strokeWidth: 2,
                  strokeColor: AppColors.bgBase,
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  double _bottomLabelInterval(int count) {
    if (count <= 5) return 1;
    if (count <= 10) return 2;
    if (count <= 20) return 4;
    return (count / 5).ceilToDouble();
  }

  Widget _buildStatToggles() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _toggleLabels.asMap().entries.map((entry) {
          final isActive = entry.key == _activeToggleIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeToggleIndex = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.accentPrimary : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalRecords(List<ExerciseHistoryData> history) {
    final maxWeight = history.isEmpty
        ? 0.0
        : history.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final max1RM = history.isEmpty
        ? 0.0
        : history.map((e) => e.estimated1RM).reduce((a, b) => a > b ? a : b);
    final maxVolume = history.isEmpty
        ? 0.0
        : history.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
    final maxReps = history.isEmpty
        ? 0
        : history.map((e) => e.reps).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              'Personal Records',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _prRow('Heaviest Weight', '${maxWeight.toStringAsFixed(1)} kg'),
              _prDivider(),
              _prRow('Best 1RM', '${max1RM.toStringAsFixed(2)} kg'),
              _prDivider(),
              _prRow('Best Set Volume', '${maxVolume.toStringAsFixed(0)} kg'),
              _prDivider(),
              _prRow('Max Reps', '$maxReps reps'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prDivider() {
    return const Divider(
      color: AppColors.borderSubtle,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
