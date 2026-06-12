import 'dart:convert';
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/shared/widgets/exercise_gif_widget.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import '../providers/exercise_analytics_provider.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  final Exercise? exercise;

  const ExerciseDetailScreen({super.key, required this.exerciseId, this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

final _exerciseFallbackProvider =
    FutureProvider.autoDispose.family<Exercise, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.exercisesDao.getExerciseById(id);
});

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  int _activeToggleIndex = 0;
  String _selectedTimeRange = 'All Time';

  static const _toggleLabels = [
    'Heaviest Weight',
    'One Rep Max',
    'Best Set',
    'Session Volume',
  ];

  static const _timeRangeOptions = ['1M', '3M', '6M', '1Y', 'All Time'];


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
        ref.watch(exerciseAnalyticsProvider((widget.exerciseId, _selectedTimeRange)));

    final exerciseAsync = widget.exercise != null 
        ? AsyncValue.data(widget.exercise!) 
        : ref.watch(_exerciseFallbackProvider(widget.exerciseId));

    return exerciseAsync.when(
      loading: () => const Scaffold(backgroundColor: AppColors.bgBase, body: Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))),
      error: (e, st) => Scaffold(backgroundColor: AppColors.bgBase, body: Center(child: Text('Error loading exercise', style: GoogleFonts.inter(color: AppColors.error)))),
      data: (exercise) {
        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: Text(
              exercise.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppColors.bgBase,
            scrolledUnderElevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Exercise GIF — loads from Supabase, cached permanently offline
              ExerciseGifWidget(
                gifUrl: exercise.gifUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              // Exercise Name & Metadata
              Text(
                exercise.name,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${exercise.target} • ${exercise.equipment}',
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
                  // Free tier: 3 most recent sessions in the chart as a
                  // teaser. PR aggregates stay free — they're core
                  // motivation, not deep analytics.
                  final isPremium = ref.watch(isPremiumProvider);
                  final visible = gateChartSamples(history, isPremium);
                  return Column(
                    children: [
                      _buildGraphSection(visible,
                          showProPill: !isPremium && history.length > 3),
                      const SizedBox(height: 24),
                      _buildStatToggles(),
                      if (history.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildPersonalRecords(history),
                      ],
                      const SizedBox(height: 24),
                      _buildInstructions(exercise),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGraphSection(List<ExerciseHistoryData> history,
      {bool showProPill = false}) {
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
            if (showProPill)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: ProLockPill(label: 'FULL HISTORY'),
              ),
            PopupMenuButton<String>(
              offset: const Offset(0, 36),
              color: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                HapticFeedback.lightImpact();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  LineChartData _chartData(
      List<FlSpot> spots, List<ExerciseHistoryData> history) {
    double minY;
    double maxY;
    if (spots.isEmpty) {
      minY = 0;
      maxY = 100;
    } else {
      final values = history
          .map((d) => _metricForToggle(d, _activeToggleIndex))
          .toList();
      final minVal = values.reduce(min);
      final maxVal = values.reduce(max);
      minY = (minVal * 0.9).floorToDouble();
      maxY = (maxVal * 1.1).ceilToDouble();
    }
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
      minY: minY,
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
            const Icon(Icons.emoji_events, color: AppColors.warning, size: 20),
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
              _prRow('Max Session Volume', '${maxVolume.toStringAsFixed(0)} kg'),
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

  Widget _buildInstructions(Exercise exercise) {
    if (exercise.instructions == null ||
        exercise.instructions!.isEmpty) {
      return const SizedBox.shrink();
    }

    List<String> steps;
    try {
      steps = (jsonDecode(exercise.instructions!) as List<dynamic>)
          .cast<String>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt_rounded,
                color: AppColors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              'How to Perform',
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
            children: steps.asMap().entries.map((entry) {
              final isLast = entry.key == steps.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.inter(
                                color: AppColors.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      color: AppColors.borderSubtle,
                      height: 1,
                      indent: 52,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
