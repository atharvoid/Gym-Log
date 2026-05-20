import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';

final workoutDetailProvider =
    StreamProvider.family<HydratedWorkout?, String>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchHydratedWorkout(sessionId);
});
