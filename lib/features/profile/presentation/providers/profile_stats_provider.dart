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

/// Metrics supported by the Profile weekly bar chart.
enum ProfileGraphMetric {
  volume('Volume'),
  duration('Duration'),
  reps('Reps');

  final String label;
  const ProfileGraphMetric(this.label);

  static ProfileGraphMetric fromString(String? value,
      {ProfileGraphMetric fallback = volume}) {
    if (value == null) return fallback;
    final lower = value.toLowerCase();
    return ProfileGraphMetric.values.firstWhere(
      (m) => m.name == lower || m.label.toLowerCase() == lower,
      orElse: () => fallback,
    );
  }
}

/// Per-session stats for the trailing 8 weeks — the Profile chart
/// aggregates them per week client-side for Duration / Volume / Reps.
final sessionStatsProvider = StreamProvider<List<SessionStat>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  final since = DateTime.now().subtract(const Duration(days: 56));
  return db.workoutsDao.watchSessionStatsForUser(user.id, since: since);
});

/// One aggregated bucket per calendar week for the Profile chart.
/// Weeks with no logged workouts are still emitted with zeroed values.
class WeeklyAggregate {
  final DateTime weekStart; // Monday 00:00:00 local
  final double volumeKg;
  final int totalReps;
  final Duration duration;
  final int workoutCount;

  const WeeklyAggregate({
    required this.weekStart,
    required this.volumeKg,
    required this.totalReps,
    required this.duration,
    required this.workoutCount,
  });

  /// The value to plot for the given metric.
  double valueFor(ProfileGraphMetric metric) => switch (metric) {
        ProfileGraphMetric.volume => volumeKg,
        ProfileGraphMetric.duration => duration.inMinutes.toDouble(),
        ProfileGraphMetric.reps => totalReps.toDouble(),
      };
}

/// Returns exactly 8 Monday-aligned weeks ending in the current week.
/// Missing weeks are filled with zeroed aggregates so the X-axis is continuous.
final weeklyAggregatesProvider = Provider<List<WeeklyAggregate>>((ref) {
  final stats = ref.watch(sessionStatsProvider).valueOrNull ?? const [];
  final now = DateTime.now();

  DateTime weekStartOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  final currentWeek = weekStartOf(now);
  // Oldest first so the chart reads left-to-right.
  final weeks = List.generate(
    8,
    (i) => currentWeek.subtract(const Duration(days: 7) * (7 - i)),
  );

  final byWeek = <DateTime, List<SessionStat>>{};
  for (final s in stats) {
    final week = weekStartOf(s.date);
    if (!week.isBefore(weeks.first) && !week.isAfter(weeks.last)) {
      byWeek.putIfAbsent(week, () => []).add(s);
    }
  }

  return [
    for (final week in weeks)
      WeeklyAggregate(
        weekStart: week,
        volumeKg:
            byWeek[week]?.fold<double>(0, (sum, s) => sum + s.volumeKg) ?? 0,
        totalReps: byWeek[week]?.fold<int>(0, (sum, s) => sum + s.reps) ?? 0,
        duration: Duration(
          minutes: byWeek[week]?.fold<int>(
                0,
                (sum, s) => sum + s.duration.inMinutes,
              ) ??
              0,
        ),
        workoutCount: byWeek[week]?.length ?? 0,
      ),
  ];
});

// ── Last-selected profile chart metric ───────────────────────────────────────

/// Persists the user's preferred chart metric on Profile so switching tabs
/// does not reset it to Volume every time.
class ProfileChartMetricNotifier extends StateNotifier<ProfileGraphMetric> {
  static const _key = 'profile_chart_metric';
  static const _default = ProfileGraphMetric.volume;

  ProfileChartMetricNotifier() : super(_default) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null && mounted) {
      state = ProfileGraphMetric.fromString(stored, fallback: _default);
    }
  }

  Future<void> setMetric(ProfileGraphMetric metric) async {
    state = metric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, metric.name);
  }
}

final profileChartMetricProvider =
    StateNotifierProvider<ProfileChartMetricNotifier, ProfileGraphMetric>(
        (ref) {
  return ProfileChartMetricNotifier();
});
