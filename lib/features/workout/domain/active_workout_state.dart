import 'package:freezed_annotation/freezed_annotation.dart';
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
