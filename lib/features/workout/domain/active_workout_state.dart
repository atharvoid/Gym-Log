import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:uuid/uuid.dart';

part 'active_workout_state.freezed.dart';

@freezed
class WorkoutSetState with _$WorkoutSetState {
  @Assert("id != ''", 'Set ID must not be empty')
  const factory WorkoutSetState({
    required String id,
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
/// each exercise's configured SET COUNT. Weight and reps stay empty (0) so each
/// row shows the PREVIOUS session's values as a ghost hint (wired via
/// previousSessionSetsProvider in ExerciseBlock/SetRow); the user commits it by
/// ticking. Both the routine-detail screen and the routine-card start path use
/// this so a routine always opens with the right number of empty rows.
List<WorkoutExerciseState> seedExercisesFromRoutine(
    HydratedRoutineDetail routine) {
  return routine.exercises.map((he) {
    final c = he.config;
    final count = c.defaultSets > 0 ? c.defaultSets : 1;
    // Seed only the set COUNT from the routine. Weight/reps stay 0 (empty) so
    // each row shows the PREVIOUS session's value as a ghost hint (wired via
    // previousSessionSetsProvider in ExerciseBlock/SetRow); the user commits it
    // by ticking. Baking c.defaultWeightKg/c.defaultReps here was the source of
    // the "random reps allocated on start" — those are routine-editor config
    // defaults, not the user's last performance.
    final sets = List.generate(count, (_) => WorkoutSetState.create());
    return WorkoutExerciseState(
      id: const Uuid().v4(),
      exerciseId: he.exercise.id,
      name: he.exercise.name,
      sets: sets,
    );
  }).toList();
}
