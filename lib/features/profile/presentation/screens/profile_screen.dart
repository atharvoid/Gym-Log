import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/premium_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/routines/presentation/widgets/routine_detail_styles.dart';
import '../../../../shared/widgets/premium_paywall.dart';
import '../../../../shared/widgets/ui/app_dialog.dart';
import '../../../../shared/widgets/ui/toggle_pill.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_stats_provider.dart';

/// Athlete dashboard — identity, streak, weekly goal ring, a real training
/// chart wired to Drift, and only functional actions. No placeholders,
/// no "Coming soon" graveyard.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedMetric = 'Volume';

  @override
  Widget build(BuildContext context) {
    final workoutCount = ref.watch(workoutCountProvider).valueOrNull ?? 0;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final streak = ref.watch(streakStatsProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final displayName = profile?.displayName ?? 'Athlete';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          // ── Identity ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB98CFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'PRO',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: const Color(0xFFCBB2FF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stats strip: streak · weekly ring · total ───────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              gradient: RDStyles.cardGradient,
              borderRadius: BorderRadius.circular(18),
              border: RDStyles.hairlineBorder,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    value: streak.currentStreak > 0
                        ? '${streak.currentStreak}'
                        : '—',
                    label: streak.currentStreak == 1
                        ? 'DAY STREAK'
                        : 'DAY STREAK',
                    leading: Icon(
                      Icons.local_fire_department_rounded,
                      size: 17,
                      color: streak.currentStreak > 0
                          ? const Color(0xFFFF9F0A)
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                _statDivider(),
                Expanded(
                  child: Semantics(
                    button: true,
                    label:
                        'Weekly goal: ${streak.workoutsThisWeek} of $goal workouts. Tap to change goal.',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showGoalSheet(context, goal),
                      child: _StatCell(
                        value: '${streak.workoutsThisWeek}/$goal',
                        label: 'THIS WEEK',
                        leading: _GoalRing(
                          progress: goal == 0
                              ? 0
                              : (streak.workoutsThisWeek / goal)
                                  .clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
                _statDivider(),
                Expanded(
                  child: _StatCell(
                    value: '$workoutCount',
                    label: 'WORKOUTS',
                    leading: const Icon(
                      Icons.fitness_center_rounded,
                      size: 16,
                      color: Color(0xFFB98CFF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nudge line under the strip — quiet, only when relevant.
          if (!streak.trainedToday && streak.currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Text(
                'Train today to keep your ${streak.currentStreak}-day streak alive.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 28),

          // ── Training chart ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Training ', style: RDStyles.sectionLabel),
                TextSpan(
                    text: '(weekly ${_unitFor(_selectedMetric)})',
                    style: RDStyles.sectionUnit),
              ])),
              if (!isPremium) const ProLockPill(label: 'FULL HISTORY'),
            ],
          ),
          const SizedBox(height: 12),
          _WeeklyChart(metric: _selectedMetric, isPremium: isPremium),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final metric in const ['Volume', 'Duration', 'Reps']) ...[
                TogglePill(
                  label: metric,
                  isActive: _selectedMetric == metric,
                  onTap: () => setState(() => _selectedMetric = metric),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // ── Actions (every row does something real) ─────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: RDStyles.cardGradient,
              borderRadius: BorderRadius.circular(18),
              border: RDStyles.hairlineBorder,
            ),
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: const Color(0xFFCBB2FF),
                  title: isPremium ? 'GymLog Pro' : 'Upgrade to Pro',
                  subtitle: isPremium
                      ? 'Active — full history unlocked'
                      : 'Full analytics history & more',
                  onTap: () {
                    if (isPremium) {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          'You are on GymLog Pro. Thanks for the support!',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary),
                        ),
                        backgroundColor: AppColors.bgSurface,
                        behavior: SnackBarBehavior.floating,
                      ));
                    } else {
                      showPremiumPaywall(context);
                    }
                  },
                ),
                _rowDivider(),
                _ActionRow(
                  icon: Icons.fitness_center_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'Exercise Library',
                  subtitle: 'Browse exercises, form guides & records',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/exercises/library');
                  },
                ),
                _rowDivider(),
                _ActionRow(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'Weekly goal',
                  subtitle: '$goal workout${goal != 1 ? 's' : ''} per week',
                  onTap: () => _showGoalSheet(context, goal),
                ),
                _rowDivider(),
                _ActionRow(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: 'Sign out',
                  titleColor: AppColors.error,
                  subtitle: 'Workout data stays on this device',
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _unitFor(String metric) => switch (metric) {
        'Duration' => 'min',
        'Reps' => 'reps',
        _ => 'kg',
      };

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.06),
      );

  Widget _rowDivider() => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Container(height: 1, color: RDStyles.hairline),
      );

  void _showGoalSheet(BuildContext context, int currentGoal) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A6A6A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Weekly goal',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How many days a week do you want to train?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var days = 1; days <= 7; days++)
                      _GoalOption(
                        days: days,
                        selected: days == currentGoal,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(weeklyGoalProvider.notifier)
                              .setGoal(days);
                          Navigator.of(sheetCtx).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Sign out?',
      message:
          'Your workouts are stored locally and will be here when you sign back in.',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

// ── Stats strip pieces ────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Widget leading;

  const _StatCell({
    required this.value,
    required this.label,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GoalRing extends StatelessWidget {
  final double progress;
  const _GoalRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = progress >= 1
            ? const Color(0xFF34C759)
            : AppColors.accentPrimary;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GoalOption extends StatelessWidget {
  final int days;
  final bool selected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$days',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Weekly training chart ─────────────────────────────────────────────────────

class _WeeklyChart extends ConsumerWidget {
  final String metric;
  final bool isPremium;

  const _WeeklyChart({required this.metric, required this.isPremium});

  double _valueOf(WeeklyMetricPoint p) => switch (metric) {
        'Duration' => p.duration,
        'Reps' => p.reps,
        _ => p.volume,
      };

  String _compact(double v) {
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPoints = ref.watch(weeklyMetricsProvider);
    final points = gateChartSamples(allPoints, isPremium);

    if (points.isEmpty) return const _EmptyChart();

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), _valueOf(points[i])),
    ];
    final maxV = spots.fold<double>(0, (a, s) => math.max(a, s.y));
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.18;
    final latest = points.last;

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
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${_compact(_valueOf(latest))} ${switch (metric) {
                    'Duration' => 'min',
                    'Reps' => 'reps',
                    _ => 'kg'
                  }}',
                  style: RDStyles.chartValue,
                ),
                const SizedBox(width: 8),
                Text(
                  'week of ${DateFormat('MMM d').format(latest.weekStart)}',
                  style: RDStyles.chartDate,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: LineChart(
                key: ValueKey('$metric${points.length}'),
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  minX: -0.3,
                  maxX: (points.length - 1) + 0.3,
                  clipData: const FlClipData.none(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 3,
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
                        reservedSize: 38,
                        interval: maxY / 3,
                        getTitlesWidget: (v, m) => v <= 0
                            ? const SizedBox.shrink()
                            : SideTitleWidget(
                                axisSide: m.axisSide,
                                space: 8,
                                child: Text(_compact(v), style: RDStyles.axis),
                              ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: math.max(1, (points.length / 4).ceil())
                            .toDouble(),
                        getTitlesWidget: (v, m) {
                          final i = v.toInt();
                          if (v != v.roundToDouble() ||
                              i < 0 ||
                              i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: m.axisSide,
                            space: 8,
                            child: Text(
                              DateFormat('MMM d')
                                  .format(points[i].weekStart),
                              style: RDStyles.axis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: AppColors.accentPrimary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, pct, bar, i) =>
                            FlDotCirclePainter(
                          radius: i == spots.length - 1 ? 5 : 3.5,
                          color: AppColors.accentPrimary,
                          strokeWidth: i == spots.length - 1 ? 2.5 : 0,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accentPrimary.withValues(alpha: 0.28),
                            AppColors.accentPrimary.withValues(alpha: 0.02),
                          ],
                        ),
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
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in const [0.40, 0.65, 0.50, 0.80, 0.95])
                  Container(
                    width: 6,
                    height: 30 * h,
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
          Text('No training data yet', style: RDStyles.emptyTitle),
          const SizedBox(height: 3),
          Text('Finish a workout to see your weekly trend',
              style: RDStyles.emptySub),
        ],
      ),
    );
  }
}

// ── Action rows ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
