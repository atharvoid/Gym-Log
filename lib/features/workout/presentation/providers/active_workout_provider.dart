import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ActiveSet {
  final String id;
  String type;
  double weightKg;
  int reps;
  bool isComplete;

  ActiveSet({String? id, this.type = 'normal', this.weightKg = 0.0, this.reps = 0, this.isComplete = false}) : id = id ?? const Uuid().v4();
}

class ActiveExercise {
  final int exerciseId;
  final String exerciseName;
  final List<ActiveSet> sets;

  ActiveExercise({required this.exerciseId, required this.exerciseName, List<ActiveSet>? sets}) : sets = sets ?? [];
}

class ActiveWorkoutState {
  final bool isActive;
  final String? sessionId;
  final DateTime? startedAt;
  final List<ActiveExercise> exercises;

  ActiveWorkoutState({this.isActive = false, this.sessionId, this.startedAt, List<ActiveExercise>? exercises}) : exercises = exercises ?? [];

  ActiveWorkoutState copyWith({bool? isActive, String? sessionId, DateTime? startedAt, List<ActiveExercise>? exercises}) {
    return ActiveWorkoutState(
      isActive: isActive ?? this.isActive,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      exercises: exercises ?? this.exercises,
    );
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  ActiveWorkoutNotifier() : super(ActiveWorkoutState());

  void startWorkout() {
    state = state.copyWith(isActive: true, sessionId: const Uuid().v4(), startedAt: DateTime.now());
  }

  void finishWorkout() {
    state = ActiveWorkoutState();
  }

  void discardWorkout() {
    state = ActiveWorkoutState();
  }

  void addExercise(int exerciseId, String name) {
    final ex = ActiveExercise(exerciseId: exerciseId, exerciseName: name);
    final list = [...state.exercises, ex];
    state = state.copyWith(exercises: list);
  }

  void addSet(int exerciseIndex) {
    final list = [...state.exercises];
    list[exerciseIndex].sets.add(ActiveSet());
    state = state.copyWith(exercises: list);
  }

  void toggleSetComplete(int ei, int si) {
    final list = [...state.exercises];
    final set = list[ei].sets[si];
    set.isComplete = !set.isComplete;
    state = state.copyWith(exercises: list);
  }
}

final activeWorkoutProvider = StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) => ActiveWorkoutNotifier());
