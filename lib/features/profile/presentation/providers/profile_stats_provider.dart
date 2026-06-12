import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Derived streak + weekly numbers for Home and Profile.
class StreakStats {
  /// Consecutive training days ending today (or yesterday, if today is
  /// still pending). 0 means the chain is broken.
  final int currentStreak;

  /// Whether the user has already trained today — drives copy like
  /// "Train today to keep your streak".
  final bool trainedToday;

  /// Distinct training days inside the current week (Monday-start).
  final int workoutsThisWeek;

  const StreakStats({
    this.currentStreak = 0,
    this.trainedToday = false,
    this.workoutsThisWeek = 0,
  });
}

/// Live list of completed-session start timestamps (newest first).
final _trainingDatesProvider = StreamProvider<List<DateTime>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchCompletedSessionDates(user.id);
});

/// Streak math happens in Dart on LOCAL dates — SQLite's DATE() would
/// bucket by UTC and break streaks for anyone training late at night.
final streakStatsProvider = Provider<StreakStats>((ref) {
  final dates = ref.watch(_trainingDatesProvider).valueOrNull;
  return computeStreakStats(dates ?? const []);
});

/// Pure streak computation — exposed for unit testing.
/// [now] is injectable so tests are deterministic.
StreakStats computeStreakStats(List<DateTime> dates, {DateTime? now}) {
  if (dates.isEmpty) return const StreakStats();

  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  final trainingDays = dates.map(dayOf).toSet();

  final today = dayOf(now ?? DateTime.now());
  final trainedToday = trainingDays.contains(today);

  // Walk backwards from today (or yesterday if today hasn't happened yet).
  var cursor = trainedToday ? today : today.subtract(const Duration(days: 1));
  var streak = 0;
  while (trainingDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Monday-start week window.
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final workoutsThisWeek = trainingDays
      .where((d) => !d.isBefore(weekStart) && !d.isAfter(today))
      .length;

  return StreakStats(
    currentStreak: streak,
    trainedToday: trainedToday,
    workoutsThisWeek: workoutsThisWeek,
  );
}

// ── Weekly goal (SharedPreferences-backed, 1–7 days) ─────────────────────────

class WeeklyGoalNotifier extends StateNotifier<int> {
  static const _key = 'weekly_goal_days';

  WeeklyGoalNotifier() : super(3) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_key);
    if (stored != null && mounted) state = stored.clamp(1, 7);
  }

  Future<void> setGoal(int days) async {
    state = days.clamp(1, 7);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, state);
  }
}

final weeklyGoalProvider =
    StateNotifierProvider<WeeklyGoalNotifier, int>((ref) {
  return WeeklyGoalNotifier();
});

// ── Profile chart data ────────────────────────────────────────────────────────

/// Per-session stats for the trailing 12 weeks — the Profile chart
/// aggregates them per week client-side for Duration / Volume / Reps.
final sessionStatsProvider = StreamProvider<List<SessionStat>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  final since = DateTime.now().subtract(const Duration(days: 84));
  return db.workoutsDao.watchSessionStatsForUser(user.id, since: since);
});

/// One aggregated point per ISO week for the Profile chart.
class WeeklyMetricPoint {
  final DateTime weekStart;
  final double duration; // minutes
  final double volume; // kg
  final double reps;

  const WeeklyMetricPoint({
    required this.weekStart,
    required this.duration,
    required this.volume,
    required this.reps,
  });
}

final weeklyMetricsProvider = Provider<List<WeeklyMetricPoint>>((ref) {
  final stats = ref.watch(sessionStatsProvider).valueOrNull ?? const [];
  if (stats.isEmpty) return const [];

  DateTime weekStartOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  final byWeek = <DateTime, List<SessionStat>>{};
  for (final s in stats) {
    byWeek.putIfAbsent(weekStartOf(s.date), () => []).add(s);
  }

  final weeks = byWeek.keys.toList()..sort();
  return [
    for (final week in weeks)
      WeeklyMetricPoint(
        weekStart: week,
        duration: byWeek[week]!
            .fold<double>(0, (sum, s) => sum + s.duration.inMinutes),
        volume: byWeek[week]!.fold<double>(0, (sum, s) => sum + s.volumeKg),
        reps: byWeek[week]!.fold<double>(0, (sum, s) => sum + s.reps),
      ),
  ];
});
