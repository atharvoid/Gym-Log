import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:uuid/uuid.dart';

part 'active_workout_state.freezed.dart';

@freezed
class WorkoutSetState with _$WorkoutSetState {
  const factory WorkoutSetState({
    @Default('') String id,
    @Default('normal') String setType,
    @Default(0.0) double weightKg,
    @Default(0) int reps,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
  }) = _WorkoutSetState;

  factory WorkoutSetState.create() => WorkoutSetState(
        id: const Uuid().v4(),
      );
}

@freezed
class WorkoutExerciseState with _$WorkoutExerciseState {
  const factory WorkoutExerciseState({
    @Default('') String id,
    required int exerciseId,
    required String name,
    @Default([]) List<WorkoutSetState> sets,
  }) = _WorkoutExerciseState;
}

@freezed
class ActiveWorkoutState with _$ActiveWorkoutState {
  const factory ActiveWorkoutState({
    required String id,
    required DateTime startTime,
    String? routineId,
    String? name,
    @Default([]) List<WorkoutExerciseState> exercises,
    String? originalSessionId,
    Duration? historicalDuration,
  }) = _ActiveWorkoutState;
}

/// Seeds [WorkoutExerciseState]s from a saved routine's full detail, preserving
/// each exercise's configured set count, default weight, and default reps.
/// Both the routine-detail screen and the routine-card start path use this so
/// a routine always opens with its saved targets, never a single blank set.
List<WorkoutExerciseState> seedExercisesFromRoutine(
    HydratedRoutineDetail routine) {
  return routine.exercises.map((he) {
    final c = he.config;
    final count = c.defaultSets > 0 ? c.defaultSets : 1;
    final sets = List.generate(
      count,
      (_) => WorkoutSetState(
        id: const Uuid().v4(),
        weightKg: c.defaultWeightKg ?? 0.0,
        reps: c.defaultReps ?? 0,
      ),
    );
    return WorkoutExerciseState(
      id: const Uuid().v4(),
      exerciseId: he.exercise.id,
      name: he.exercise.name,
      sets: sets.isEmpty ? [WorkoutSetState.create()] : sets,
    );
  }).toList();
}
