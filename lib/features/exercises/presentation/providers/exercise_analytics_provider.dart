import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';

/// Maps a time-range label to a [DateTime] cutoff, or null for all-time.
DateTime? _sinceForRange(String range) {
  final now = DateTime.now();
  switch (range) {
    case '1M':
      return now.subtract(const Duration(days: 30));
    case '3M':
      return now.subtract(const Duration(days: 90));
    case '6M':
      return now.subtract(const Duration(days: 180));
    case '1Y':
      return now.subtract(const Duration(days: 365));
    default: // 'All Time' or anything else
      return null;
  }
}

/// Family key: (exerciseId, selectedRange) — e.g. (42, '3M') or (42, 'All Time').
final exerciseAnalyticsProvider =
    StreamProvider.family<List<ExerciseHistoryData>, (int, String)>(
        (ref, args) {
  final (exerciseId, selectedRange) = args;
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchExerciseHistory(
    exerciseId,
    since: _sinceForRange(selectedRange),
  );
});

