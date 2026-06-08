import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/home/presentation/providers/recent_workouts_provider.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';

class WorkoutActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WorkoutActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> deleteSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.workoutsDao.deleteSession(sessionId);
      _ref.invalidate(recentWorkoutsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveWorkoutAsRoutine(HydratedWorkout workout, String routineName) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.routinesDao.saveWorkoutAsRoutine(workout.session.userId, routineName, workout.exercises);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final workoutActionsProvider =
    StateNotifierProvider<WorkoutActionsNotifier, AsyncValue<void>>((ref) {
  return WorkoutActionsNotifier(ref);
});
