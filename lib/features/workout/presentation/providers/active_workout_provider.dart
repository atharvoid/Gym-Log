import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/daos/workouts_dao.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/sync_engine.dart';
import '../../../../core/services/workout_draft_store.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/active_workout_state.dart';

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref _ref;
  Timer? _draftDebounce;

  ActiveWorkoutNotifier(this._ref) : super(null) {
    // Crash/kill resilience: persist a debounced snapshot of the live session
    // and drop it on finish/discard. This is a passive side-effect on state
    // changes — it does NOT alter how sets are logged.
    addListener(_persistDraftOnChange, fireImmediately: false);
  }

  void _persistDraftOnChange(ActiveWorkoutState? s) {
    _draftDebounce?.cancel();
    final store = _ref.read(workoutDraftStoreProvider);
    if (s == null) {
      // Finished or discarded — remove the draft immediately.
      unawaited(store.clear());
      return;
    }
    // Only NEW live sessions are resumable; editing history is not.
    if (s.originalSessionId != null) return;
    // updateSet fires per keystroke — debounce the encrypted write.
    _draftDebounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(store.save(s));
    });
  }

  /// Restores a persisted draft as the live session (used by the launch-time
  /// "resume interrupted workout?" prompt).
  void resumeDraft(ActiveWorkoutState draft) {
    state = draft;
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    super.dispose();
  }

  Future<void> startWorkout({
    String? routineId,
    String? name,
    List<WorkoutExerciseState>? initialExercises,
  }) async {
    // Safety net: every exercise MUST have a unique id — the active-workout
    // list and the reorder sheet key on it. Callers that pass initialExercises
    // sometimes omit it (it defaults to ''), which would collapse the list to
    // a single row during reorder. Backfill any missing id here so no caller
    // can reintroduce that bug.
    final seeded = <WorkoutExerciseState>[
      for (final e in (initialExercises ?? const <WorkoutExerciseState>[]))
        e.id.isEmpty ? e.copyWith(id: const Uuid().v4()) : e,
    ];
    state = ActiveWorkoutState(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      routineId: routineId,
      name: name,
      exercises: seeded,
    );

    if (routineId != null && initialExercises == null) {
      final db = _ref.read(databaseProvider);
      final days = await db.routinesDao.getDaysForRoutine(routineId);
      if (days.isEmpty) return;

      final routineExercises =
          await db.routinesDao.getExercisesForDay(days.first.id);
      if (routineExercises.isEmpty) return;

      // Batch lookups — one query for metadata, one for previous sets,
      // instead of 4 queries per routine exercise.
      final exerciseIds =
          routineExercises.map((re) => re.exerciseId).toSet().toList();
      final metaRows = await (db.select(db.exercises)
            ..where((t) => t.id.isIn(exerciseIds)))
          .get();
      final metaById = {for (final e in metaRows) e.id: e};
      final prevSetsByExercise =
          await db.workoutsDao.getPreviousSessionSetsBatch(exerciseIds, '');

      final exercises = <WorkoutExerciseState>[];
      for (final re in routineExercises) {
        final meta = metaById[re.exerciseId];
        if (meta == null) continue;
        final prevSets = prevSetsByExercise[re.exerciseId] ?? const [];

        final sets = <WorkoutSetState>[];
        for (int i = 0; i < re.defaultSets; i++) {
          double weight;
          int reps;
          if (i < prevSets.length) {
            weight = prevSets[i].weightKg;
            reps = prevSets[i].reps;
          } else {
            weight = re.defaultWeightKg ?? 0.0;
            reps = re.defaultReps ?? 0;
          }
          sets.add(WorkoutSetState(
              id: const Uuid().v4(), weightKg: weight, reps: reps));
        }
        exercises.add(WorkoutExerciseState(
          id: const Uuid().v4(),
          exerciseId: re.exerciseId,
          name: meta.name,
          sets: sets.isEmpty ? [WorkoutSetState.create()] : sets,
        ));
      }

      // Guard against the user discarding / switching routines mid-load.
      if (state != null && state!.routineId == routineId) {
        state = state!.copyWith(exercises: exercises);
      }
    }
  }

  /// Persists the active workout and returns any personal records that
  /// were set — the screen turns them into a celebration moment.
  /// The HomeScreen feed reloads itself via its Drift revision stream.
  Future<List<PrRecord>> finishWorkout({String? name}) async {
    if (state == null) return const [];

    final hasAnyCompletedSet =
        state!.exercises.any((e) => e.sets.any((s) => s.isCompleted));
    if (!hasAnyCompletedSet) {
      state = null;
      return const [];
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

    // The name the user confirmed at finish wins; otherwise fall back to the
    // in-progress name (the routine name, when started from one).
    final workoutName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : state!.name;

    try {
      final prs = await db.transaction<List<PrRecord>>(() async {
        await db.workoutsDao.insertSession(
          WorkoutSessionsCompanion(
            id: Value(sessionId),
            userId: Value(userId),
            routineId: Value(state!.routineId),
            name: Value(workoutName),
            startedAt: Value(state!.startTime),
            endedAt: Value(DateTime.now()),
            totalVolumeKg: Value(totalVolume),
          ),
        );

        // Strip exercises where the user completed zero sets
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

          // Compact, gap-free set ordering — incomplete sets are skipped,
          // so order_index must not inherit their slots ("Set 1, Set 3").
          var setIndex = 0;
          for (final set in exercise.sets) {
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
              setIndex++;
            }
          }
        }

        // PR detection: marks best Epley 1RM set per exercise against
        // prior history, and reports what was beaten.
        return db.workoutsDao.detectAndMarkPrs(sessionId, state!.startTime);
      });

      state = null;

      // Local commit is done — now mirror to the cloud. Queue a compressed
      // snapshot and fire an immediate post-workout sync (explicit trigger).
      // Entirely non-blocking: a failure just leaves the row queued.
      if (userId.isNotEmpty) {
        final engine = _ref.read(syncEngineProvider);
        await engine.enqueueSession(userId, sessionId);
        unawaited(engine.syncNow(userId, reason: 'post_workout'));
      }

      return prs;
    } catch (e) {
      debugPrint('[finishWorkout] transaction failed: $e');
      return const [];
    }
  }

  void loadForEdit(HydratedWorkout historicalWorkout) {
    final session = historicalWorkout.session;

    final exercises = historicalWorkout.exercises.map((he) {
      return WorkoutExerciseState(
        id: const Uuid().v4(),
        exerciseId: he.exerciseMetadata.id,
        name: he.exerciseMetadata.name,
        sets: he.sets
            .map((s) => WorkoutSetState(
                  id: const Uuid().v4(),
                  setType: s.setType,
                  weightKg: s.weightKg,
                  reps: s.reps,
                  isCompleted: true,
                  completedAt: s.completedAt,
                ))
            .toList(),
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

  /// Removes a single set (swipe-to-delete). Keeps at least the list valid —
  /// an exercise with zero sets simply shows its "+ Add Set" footer.
  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;
    final sets = [...exercise.sets]..removeAt(setIndex);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  /// Reorders an exercise from [oldIndex] to [newIndex] (drag-to-reorder).
  /// Uses ReorderableListView.onReorderItem semantics — [newIndex] is
  /// already adjusted for the removed item, so no manual decrement.
  void reorderExercise(int oldIndex, int newIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (oldIndex < 0 || oldIndex >= exercises.length) return;
    final target = newIndex.clamp(0, exercises.length - 1);
    final item = exercises.removeAt(oldIndex);
    exercises.insert(target, item);
    state = state!.copyWith(exercises: exercises);
  }

  /// Live investment readout for the header: (volumeKg, completedSets).
  (double, int) get sessionTotals {
    final current = state;
    if (current == null) return (0, 0);
    double volume = 0;
    var sets = 0;
    for (final ex in current.exercises) {
      for (final set in ex.sets) {
        if (set.isCompleted) {
          volume += set.weightKg * set.reps;
          sets++;
        }
      }
    }
    return (volume, sets);
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>(
  (ref) => ActiveWorkoutNotifier(ref),
);
