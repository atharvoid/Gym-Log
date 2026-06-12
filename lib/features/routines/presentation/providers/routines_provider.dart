import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

/// Reactive list of all user routines with resolved exercise names + IDs.
/// Automatically updates when routines are saved from the workout detail screen.
final hydratedRoutinesProvider = StreamProvider<List<HydratedRoutine>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  final db = ref.watch(databaseProvider);
  return db.routinesDao.watchHydratedRoutinesForUser(user.id);
});

/// Reactive single-routine detail with full exercise metadata + config.
final routineDetailProvider =
    StreamProvider.family<HydratedRoutineDetail?, String>((ref, routineId) {
  final db = ref.watch(databaseProvider);
  return db.routinesDao.watchHydratedRoutineDetail(routineId);
});

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
    default:
      return null;
  }
}

/// Reactive daily volume history for a routine, filterable by time range.
/// Key: (routineId, selectedRange) — e.g. ('uuid', '3M') or ('uuid', 'All Time').
final routineDailyVolumeProvider =
    StreamProvider.family<List<DailyVolumeSample>, (String, String)>(
        (ref, args) {
  final (routineId, selectedRange) = args;
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchDailyVolumeForRoutine(
    routineId,
    since: _sinceForRange(selectedRange),
  );
});

/// Live last-session sets for every exercise in a routine, keyed by
/// exerciseId (string). One SQL statement, and it re-emits after every
/// workout — the set tables can never go stale.
final routineLastSetsProvider =
    StreamProvider.family<Map<String, List<LastSessionSetData>>, String>(
        (ref, routineId) {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(const {});
  return db.workoutsDao.watchLastSessionSetsForRoutine(
    routineId: routineId,
    userId: user.id,
  );
});
