import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/recent_workouts_provider.dart';
import '../../domain/active_workout_state.dart';

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref _ref;

  ActiveWorkoutNotifier(this._ref) : super(null);

  void startWorkout({
    String? routineId,
    List<WorkoutExerciseState>? initialExercises,
  }) {
    state = ActiveWorkoutState(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      routineId: routineId,
      exercises: initialExercises ?? [],
    );
  }

  Future<void> finishWorkout() async {
    if (state == null) return;

    final db = _ref.read(databaseProvider);
    final user = _ref.read(authProvider);
    final userId = user?.id ?? '';

    // Calculate total volume from completed sets
    double totalVolume = 0;
    for (final ex in state!.exercises) {
      for (final set in ex.sets) {
        if (set.isCompleted) {
          totalVolume += set.weightKg * set.reps;
        }
      }
    }

    final sessionId = const Uuid().v4();

    await db.workoutsDao.insertSession(
      WorkoutSessionsCompanion(
        id: Value(sessionId),
        userId: Value(userId),
        routineId: Value(state!.routineId),
        startedAt: Value(state!.startTime),
        endedAt: Value(DateTime.now()),
        totalVolumeKg: Value(totalVolume),
      ),
    );

    for (final exEntry in state!.exercises.asMap().entries) {
      final exIndex = exEntry.key;
      final exercise = exEntry.value;

      final workoutExerciseId = const Uuid().v4();
      await db.workoutsDao.insertWorkoutExercise(
        WorkoutExercisesCompanion(
          id: Value(workoutExerciseId),
          sessionId: Value(sessionId),
          exerciseId: Value(exercise.exerciseId),
          orderIndex: Value(exIndex),
        ),
      );

      for (final setEntry in exercise.sets.asMap().entries) {
        final setIndex = setEntry.key;
        final set = setEntry.value;

        if (set.isCompleted) {
          await db.workoutsDao.insertSet(
            WorkoutSetsCompanion(
              id: Value(const Uuid().v4()),
              workoutExerciseId: Value(workoutExerciseId),
              exerciseId: Value(exercise.exerciseId),
              orderIndex: Value(setIndex),
              setType: Value(set.setType),
              weightKg: Value(set.weightKg),
              reps: Value(set.reps),
              completedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    }

    _ref.invalidate(recentWorkoutsProvider);
    state = null;
  }

  void discardWorkout() {
    state = null;
  }

  void addExercise(int exerciseId, String name) {
    if (state == null) return;
    final exercise = WorkoutExerciseState(
      exerciseId: exerciseId,
      name: name,
      sets: [WorkoutSetState.create()],
    );
    state = state!.copyWith(exercises: [...state!.exercises, exercise]);
  }

  void addSet(int exerciseIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    exercises[exerciseIndex] = exercise.copyWith(
      sets: [...exercise.sets, WorkoutSetState.create()],
    );
    state = state!.copyWith(exercises: exercises);
  }

  void updateSet(int exerciseIndex, int setIndex, {double? weight, int? reps, String? type}) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets];
    sets[setIndex] = sets[setIndex].copyWith(
      weightKg: weight ?? sets[setIndex].weightKg,
      reps: reps ?? sets[setIndex].reps,
      setType: type ?? sets[setIndex].setType,
    );
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  void toggleSetCompletion(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets];
    final current = sets[setIndex];
    sets[setIndex] = current.copyWith(isCompleted: !current.isCompleted);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  void replaceExercise(int exerciseIndex, int exerciseId, String name) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises[exerciseIndex] = WorkoutExerciseState(
      exerciseId: exerciseId,
      name: name,
      sets: [WorkoutSetState.create()],
    );
    state = state!.copyWith(exercises: exercises);
  }

  void removeExercise(int exerciseIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises.removeAt(exerciseIndex);
    state = state!.copyWith(exercises: exercises);
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>(
  (ref) => ActiveWorkoutNotifier(ref),
);
