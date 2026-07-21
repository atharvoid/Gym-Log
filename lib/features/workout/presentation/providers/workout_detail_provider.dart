import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';

import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

final workoutDetailProvider =
    StreamProvider.family<HydratedWorkout?, String>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(null);
  return db.workoutsDao.watchHydratedWorkout(sessionId, userId: user.id);
});
