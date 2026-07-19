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

class PersonalRecords {
  final double? maxWeight;
  final double? max1RM;
  final double maxVolume;
  final int maxReps;

  const PersonalRecords({
    this.maxWeight,
    this.max1RM,
    required this.maxVolume,
    required this.maxReps,
  });

  static const empty = PersonalRecords(
    maxWeight: null,
    max1RM: null,
    maxVolume: 0.0,
    maxReps: 0,
  );
}

final exercisePersonalRecordsProvider =
    Provider.family<PersonalRecords, (int, String)>((ref, args) {
  final historyAsync = ref.watch(exerciseAnalyticsProvider(args));
  return historyAsync.maybeWhen(
    data: (history) {
      if (history.isEmpty) return PersonalRecords.empty;
      final weights = history.map((e) => e.weight).whereType<double>();
      final maxWeight =
          weights.isEmpty ? null : weights.reduce((a, b) => a > b ? a : b);

      final e1rms = history.map((e) => e.estimated1RM).whereType<double>();
      final max1RM =
          e1rms.isEmpty ? null : e1rms.reduce((a, b) => a > b ? a : b);

      final maxVolume =
          history.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
      final maxReps =
          history.map((e) => e.reps).reduce((a, b) => a > b ? a : b);
      return PersonalRecords(
        maxWeight: maxWeight,
        max1RM: max1RM,
        maxVolume: maxVolume,
        maxReps: maxReps,
      );
    },
    orElse: () => PersonalRecords.empty,
  );
});
