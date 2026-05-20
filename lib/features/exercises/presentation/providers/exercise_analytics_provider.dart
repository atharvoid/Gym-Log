import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';

final exerciseAnalyticsProvider =
    StreamProvider.family<List<ExerciseHistoryData>, int>((ref, exerciseId) {
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchExerciseHistory(exerciseId);
});
