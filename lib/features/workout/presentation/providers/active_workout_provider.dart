import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/daos/workouts_dao.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/presentation/providers/recent_workouts_provider.dart';
import '../../domain/active_workout_state.dart';

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref _ref;

  ActiveWorkoutNotifier(this._ref) : super(null);

  Future<void> startWorkout({
    String? routineId,
    List<WorkoutExerciseState>? initialExercises,
  }) async {
    state = ActiveWorkoutState(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      routineId: routineId,
      exercises: initialExercises ?? [],
    );

    if (routineId != null && initialExercises == null) {
      final db = _ref.read(databaseProvider);
      final days = await db.routinesDao.getDaysForRoutine(routineId);
      if (days.isNotEmpty) {
        final routineExercises = await db.routinesDao.getExercisesForDay(days.first.id);
        final exercises = <WorkoutExerciseState>[];
        
        for (final re in routineExercises) {
          final exerciseMeta = await db.exercisesDao.getExerciseById(re.exerciseId);
          final prevSets = await db.workoutsDao.getPreviousSessionSets(re.exerciseId, '');
          
          final sets = <WorkoutSetState>[];
          for (int i = 0; i < re.defaultSets; i++) {
            double weight = 0.0;
            int reps = 0;
            if (i < prevSets.length) {
              weight = prevSets[i].weightKg;
              reps = prevSets[i].reps;
            } else {
              weight = re.defaultWeightKg ?? 0.0;
              reps = re.defaultReps ?? 0;
            }
            sets.add(WorkoutSetState(id: const Uuid().v4(), weightKg: weight, reps: reps));
          }
          exercises.add(WorkoutExerciseState(
            id: const Uuid().v4(),
            exerciseId: re.exerciseId,
            name: exerciseMeta.name,
            sets: sets.isEmpty ? [WorkoutSetState.create()] : sets,
          ));
        }
        
        if (state != null && state!.routineId == routineId) {
          state = state!.copyWith(exercises: exercises);
        }
      }
    }
  }

  Future<void> finishWorkout() async {
    if (state == null) return;

    final hasAnyCompletedSet = state!.exercises.any((e) => e.sets.any((s) => s.isCompleted));
    if (!hasAnyCompletedSet) {
      state = null;
      return;
    }

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

    try {
      await db.transaction(() async {
        await db.workoutsDao.insertSession(
          WorkoutSessionsCompanion(
            id: Value(sessionId),
            userId: Value(userId),
            routineId: Value(state!.routineId),
            name: Value(state!.name),
            startedAt: Value(state!.startTime),
            endedAt: Value(DateTime.now()),
            totalVolumeKg: Value(totalVolume),
          ),
        );

        // Strip exercises where the user completed zero sets (phantom exercise fix)
        final exercisesToSave = state!.exercises
            .where((ex) => ex.sets.any((s) => s.isCompleted))
            .toList();

        for (final exEntry in exercisesToSave.asMap().entries) {
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
                  completedAt: Value(set.completedAt ?? DateTime.now()),
                ),
              );
            }
          }
        }

        // PR detection: marks best Epley 1RM set per exercise against prior history
        await db.workoutsDao.detectAndMarkPrs(sessionId, state!.startTime);
      });

      // Signal the HomeScreen feed to reset to page 1
      _ref.read(workoutCompletedSignalProvider.notifier).state++;
      _ref.invalidate(recentWorkoutsProvider);
      state = null;
    } catch (e) {
      debugPrint('[finishWorkout] transaction failed: $e');
    }
  }

  void loadForEdit(HydratedWorkout historicalWorkout) {
    final session = historicalWorkout.session;

    final exercises = historicalWorkout.exercises.map((he) {
      return WorkoutExerciseState(
        id: const Uuid().v4(),
        exerciseId: he.exerciseMetadata.id,
        name: he.exerciseMetadata.name,
        sets: he.sets.map((s) => WorkoutSetState(
          id: const Uuid().v4(),
          setType: s.setType,
          weightKg: s.weightKg,
          reps: s.reps,
          isCompleted: true,
          completedAt: s.completedAt,
        )).toList(),
      );
    }).toList();

    state = ActiveWorkoutState(
      id: const Uuid().v4(),
      startTime: session.startedAt,
      routineId: session.routineId,
      name: session.name,
      exercises: exercises,
      originalSessionId: session.id,
      historicalDuration: session.endedAt?.difference(session.startedAt),
    );
  }

  Future<void> saveEditedWorkout() async {
    if (state == null || state!.originalSessionId == null) return;

    final db = _ref.read(databaseProvider);

    try {
      await db.workoutsDao.updateHistoricalWorkout(state!);

      _ref.invalidate(recentWorkoutsProvider);
      _ref.invalidate(workoutHistoryProvider);
      state = null;
    } catch (e) {
      debugPrint('[saveEditedWorkout] transaction failed: $e');
    }
  }

  void discardWorkout() {
    state = null;
  }

  void addExercise(int exerciseId, String name) {
    if (state == null) return;
    final exercise = WorkoutExerciseState(
      id: const Uuid().v4(),
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
      sets: [...exercise.sets, WorkoutSetState(id: const Uuid().v4())],
    );
    state = state!.copyWith(exercises: exercises);
  }

  void updateSet(int exerciseIndex, int setIndex,
      {double? weight, int? reps, String? type}) {
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
    sets[setIndex] = current.copyWith(
      isCompleted: !current.isCompleted,
      completedAt: !current.isCompleted ? DateTime.now() : null,
    );
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  void replaceExercise(int exerciseIndex, int exerciseId, String name) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises[exerciseIndex] = WorkoutExerciseState(
      id: exercises[exerciseIndex].id,
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
