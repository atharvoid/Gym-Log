import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:uuid/uuid.dart';

part 'active_workout_state.freezed.dart';

@freezed
class WorkoutSetState with _$WorkoutSetState {
  @Assert("id != ''", 'Set ID must not be empty')
  const factory WorkoutSetState({
    required String id,
    @Default('normal') String setType,
    double? weightKg,
    @Default(0) int reps,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
  }) = _WorkoutSetState;

  factory WorkoutSetState.create({double? weightKg}) => WorkoutSetState(
        id: const Uuid().v4(),
        weightKg: weightKg,
      );
}

@freezed
class WorkoutExerciseState with _$WorkoutExerciseState {
  const factory WorkoutExerciseState({
    @Default('') String id,
    required int exerciseId,
    required String name,
    @Default('weight_and_reps') String measurementType,
    @Default([]) List<WorkoutSetState> sets,
    int? restSecondsOverride,
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
    final rawType = he.exercise.measurementType;
    final mType = rawType.isNotEmpty
        ? MeasurementType.fromString(rawType)
        : MeasurementType.inferLegacyMeasurementType(
            equipment: he.exercise.equipment,
            exerciseName: he.exercise.name,
          );

    final initialWeight = mType.isRepsOnly ? null : 0.0;
    final sets = List.generate(
        count, (_) => WorkoutSetState.create(weightKg: initialWeight));
    return WorkoutExerciseState(
      id: const Uuid().v4(),
      exerciseId: he.exercise.id,
      name: he.exercise.name,
      measurementType: mType.raw,
      sets: sets,
    );
  }).toList();
}
