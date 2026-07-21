import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/daos/workouts_dao.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/sync_engine.dart';
import '../../../../core/services/workout_draft_store.dart';
import '../../../../core/models/measurement_type.dart';
import '../../../../core/models/personal_record.dart';
import '../../../../core/models/rest_preference.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/active_workout_state.dart';
import 'rest_timer_provider.dart';
import 'workout_event_provider.dart';

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref _ref;
  Timer? _draftDebounce;

  ActiveWorkoutNotifier(this._ref) : super(null) {
    addListener(_persistDraftOnChange, fireImmediately: false);
  }

  void saveDraftNow([ActiveWorkoutState? targetState]) {
    _draftDebounce?.cancel();
    final store = _ref.read(workoutDraftStoreProvider);
    final s = targetState ?? state;
    if (s == null) {
      unawaited(store.clear());
      return;
    }
    if (s.originalSessionId != null) return;

    final user = _ref.read(authProvider);
    final timerState = _ref.read(restTimerProvider);
    RestTimerSnapshot? timerSnapshot;
    if (timerState != null && timerState.remainingSeconds > 0) {
      timerSnapshot = RestTimerSnapshot(
        totalSeconds: timerState.totalSeconds,
        endTime: timerState.endTime,
        workoutId: timerState.workoutId,
        exerciseId: timerState.exerciseId,
        setId: timerState.setId,
      );
    }
    unawaited(store.save(s, userId: user?.id, restTimer: timerSnapshot));
  }

  void _persistDraftOnChange(ActiveWorkoutState? s) {
    _draftDebounce?.cancel();
    final store = _ref.read(workoutDraftStoreProvider);
    if (s == null) {
      unawaited(store.clear());
      return;
    }
    if (s.originalSessionId != null) return;
    _draftDebounce = Timer(const Duration(milliseconds: 800), () {
      saveDraftNow(s);
    });
  }

  void resumeDraft(ActiveWorkoutState draft) {
    state = draft;
    saveDraftNow(draft);
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
        final rawType = meta.measurementType;
        final mType = rawType.isNotEmpty
            ? MeasurementType.fromString(rawType)
            : MeasurementType.inferLegacyMeasurementType(
                equipment: meta.equipment, exerciseName: meta.name);

        final prevSets = prevSetsByExercise[re.exerciseId] ?? const [];

        final sets = <WorkoutSetState>[];
        for (int i = 0; i < re.defaultSets; i++) {
          double? weight;
          int reps;
          if (i < prevSets.length) {
            weight = mType.isRepsOnly ? null : prevSets[i].weightKg;
            reps = prevSets[i].reps;
          } else {
            weight = mType.isRepsOnly ? null : (re.defaultWeightKg ?? 0.0);
            reps = re.defaultReps ?? 0;
          }
          sets.add(WorkoutSetState(
              id: const Uuid().v4(), weightKg: weight, reps: reps));
        }
        exercises.add(WorkoutExerciseState(
          id: const Uuid().v4(),
          exerciseId: re.exerciseId,
          name: meta.name,
          measurementType: mType.raw,
          sets: sets.isEmpty
              ? [
                  WorkoutSetState.create(
                      weightKg: mType.isRepsOnly ? null : 0.0)
                ]
              : sets,
        ));
      }

      if (state != null && state!.routineId == routineId) {
        state = state!.copyWith(exercises: exercises);
      }
    }
    saveDraftNow();
  }

  /// Persists the active workout and returns any personal records that
  /// were set. The local commit always happens regardless of sync gate.
  /// `enqueueSession`/`syncNow` are no-ops when the gate is closed.
  Future<List<PersonalRecord>> finishWorkout({String? name}) async {
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

    double totalVolume = 0;
    for (final ex in state!.exercises) {
      for (final set in ex.sets) {
        if (set.isCompleted) {
          totalVolume += (set.weightKg ?? 0.0) * set.reps;
        }
      }
    }

    final sessionId = const Uuid().v4();
    final workoutName =
        (name != null && name.trim().isNotEmpty) ? name.trim() : state!.name;

    try {
      final prs = await db.transaction<List<PersonalRecord>>(() async {
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

        return db.workoutsDao.detectAndMarkPrs(sessionId, state!.startTime);
      });

      state = null;

      // The gate is checked inside the engine — no-op when closed.
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
      final rawType = he.exerciseMetadata.measurementType;
      final mType = rawType.isNotEmpty
          ? MeasurementType.fromString(rawType)
          : MeasurementType.inferLegacyMeasurementType(
              equipment: he.exerciseMetadata.equipment,
              exerciseName: he.exerciseMetadata.name,
            );

      return WorkoutExerciseState(
        id: const Uuid().v4(),
        exerciseId: he.exerciseMetadata.id,
        name: he.exerciseMetadata.name,
        measurementType: mType.raw,
        sets: he.sets
            .map((s) => WorkoutSetState(
                  id: const Uuid().v4(),
                  setType: s.setType,
                  weightKg: mType.isRepsOnly ? null : s.weightKg,
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
    final sessionId = state!.originalSessionId!;
    final user = _ref.read(authProvider);
    final userId = user?.id ?? '';

    try {
      await db.workoutsDao.updateHistoricalWorkout(state!);
      state = null;

      // The gate is checked inside the engine — no-op when closed.
      if (userId.isNotEmpty) {
        final engine = _ref.read(syncEngineProvider);
        await engine.enqueueSession(userId, sessionId);
        unawaited(engine.syncNow(userId, reason: 'workout_edited'));
      }
    } catch (e) {
      debugPrint('[saveEditedWorkout] transaction failed: $e');
    }
  }

  void discardWorkout() {
    state = null;
  }

  void addExerciseFromEntity(Exercise exercise) {
    addExercise(exercise.id, exercise.name,
        measurementType: exercise.measurementType);
  }

  Future<void> addExercise(int exerciseId, String name,
      {String? measurementType}) async {
    if (state == null) return;
    String? resolvedType = measurementType;
    if (resolvedType == null || resolvedType.isEmpty) {
      try {
        final db = _ref.read(databaseProvider);
        final row = await (db.select(db.exercises)
              ..where((t) => t.id.equals(exerciseId)))
            .getSingleOrNull();
        if (row != null) {
          resolvedType = row.measurementType;
        }
      } catch (e) {
        debugPrint(
            '[ActiveWorkoutNotifier] Failed to resolve measurementType for exercise $exerciseId: $e');
      }
    }
    final mType = MeasurementType.fromString(resolvedType);
    final exercise = WorkoutExerciseState(
      id: const Uuid().v4(),
      exerciseId: exerciseId,
      name: name,
      measurementType: mType.raw,
      sets: [WorkoutSetState.create(weightKg: mType.isRepsOnly ? null : 0.0)],
    );
    state = state!.copyWith(exercises: [...state!.exercises, exercise]);
    saveDraftNow();
  }

  void addSet(int exerciseIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final mType = MeasurementType.fromString(exercise.measurementType);
    exercises[exerciseIndex] = exercise.copyWith(
      sets: [
        ...exercise.sets,
        WorkoutSetState.create(weightKg: mType.isRepsOnly ? null : 0.0)
      ],
    );
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  void updateSet(int exerciseIndex, int setIndex,
      {double? weight, int? reps, String? type}) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets];
    final mType = MeasurementType.fromString(exercise.measurementType);
    sets[setIndex] = sets[setIndex].copyWith(
      weightKg: mType.isRepsOnly ? null : (weight ?? sets[setIndex].weightKg),
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
    saveDraftNow();
  }

  void replaceExerciseFromEntity(int exerciseIndex, Exercise exercise) {
    replaceExercise(exerciseIndex, exercise.id, exercise.name,
        measurementType: exercise.measurementType);
  }

  Future<void> replaceExercise(int exerciseIndex, int exerciseId, String name,
      {String? measurementType}) async {
    if (state == null) return;
    final exercises = [...state!.exercises];
    String? resolvedType = measurementType;
    if (resolvedType == null || resolvedType.isEmpty) {
      try {
        final db = _ref.read(databaseProvider);
        final row = await (db.select(db.exercises)
              ..where((t) => t.id.equals(exerciseId)))
            .getSingleOrNull();
        if (row != null) {
          resolvedType = row.measurementType;
        }
      } catch (e) {
        debugPrint(
            '[ActiveWorkoutNotifier] Failed to resolve replacement measurementType for exercise $exerciseId: $e');
      }
    }
    final mType = MeasurementType.fromString(resolvedType);
    exercises[exerciseIndex] = WorkoutExerciseState(
      id: exercises[exerciseIndex].id,
      exerciseId: exerciseId,
      name: name,
      measurementType: mType.raw,
      sets: [WorkoutSetState.create(weightKg: mType.isRepsOnly ? null : 0.0)],
    );
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  Future<void> replaceExerciseWithPolicy(
    int exerciseIndex,
    int newExerciseId,
    String newName, {
    required bool keepCompatibleValues,
    String? measurementType,
  }) async {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;

    final oldExercise = exercises[exerciseIndex];
    String? resolvedType = measurementType;
    if (resolvedType == null || resolvedType.isEmpty) {
      try {
        final db = _ref.read(databaseProvider);
        final row = await (db.select(db.exercises)
              ..where((t) => t.id.equals(newExerciseId)))
            .getSingleOrNull();
        if (row != null) {
          resolvedType = row.measurementType;
        }
      } catch (e) {
        debugPrint(
            '[ActiveWorkoutNotifier] Failed to resolve replacement measurementType for exercise $newExerciseId: $e');
      }
    }
    final oldMType = MeasurementType.fromString(oldExercise.measurementType);
    final newMType = MeasurementType.fromString(resolvedType);

    final List<WorkoutSetState> newSets;
    if (keepCompatibleValues) {
      newSets = adaptSetsForMeasurementType(
        oldSets: oldExercise.sets,
        oldType: oldMType,
        newType: newMType,
      );
    } else {
      newSets = [
        WorkoutSetState.create(weightKg: newMType.isRepsOnly ? null : 0.0),
      ];
    }

    exercises[exerciseIndex] = WorkoutExerciseState(
      id: oldExercise.id,
      exerciseId: newExerciseId,
      name: newName,
      measurementType: newMType.raw,
      sets: newSets,
      restSecondsOverride: oldExercise.restSecondsOverride,
    );
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  void removeExercise(int exerciseIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises.removeAt(exerciseIndex);
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  RemovedSetSnapshot? removeSetWithSnapshot({
    required String exerciseInstanceId,
    required String setId,
  }) {
    if (state == null) return null;
    final exercises = [...state!.exercises];
    final exerciseIndex =
        exercises.indexWhere((e) => e.id == exerciseInstanceId);
    if (exerciseIndex == -1) return null;

    final exercise = exercises[exerciseIndex];
    final setIndex = exercise.sets.indexWhere((s) => s.id == setId);
    if (setIndex == -1) return null;

    final removedSet = exercise.sets[setIndex];
    final snapshot = RemovedSetSnapshot(
      exerciseInstanceId: exerciseInstanceId,
      set: removedSet,
      originalIndex: setIndex,
    );

    final updatedSets = [...exercise.sets]..removeAt(setIndex);
    exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();

    _ref.read(workoutEventBusProvider).fire(SetRemovedEvent(
          exerciseIndex,
          setIndex,
          removedSet,
          snapshot: snapshot,
        ));

    return snapshot;
  }

  bool restoreRemovedSet(RemovedSetSnapshot snapshot) {
    if (state == null) return false;
    final exercises = [...state!.exercises];
    final exerciseIndex =
        exercises.indexWhere((e) => e.id == snapshot.exerciseInstanceId);
    if (exerciseIndex == -1) return false;

    final exercise = exercises[exerciseIndex];
    if (exercise.sets.any((s) => s.id == snapshot.set.id)) {
      return false;
    }

    final targetIndex = snapshot.originalIndex.clamp(0, exercise.sets.length);
    final updatedSets = [...exercise.sets]..insert(targetIndex, snapshot.set);

    exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();

    return true;
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= state!.exercises.length) return;
    final exercise = state!.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;
    removeSetWithSnapshot(
      exerciseInstanceId: exercise.id,
      setId: exercise.sets[setIndex].id,
    );
  }

  void insertSet(int exerciseIndex, int setIndex, WorkoutSetState set) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets];
    if (setIndex < 0 || setIndex > sets.length) return;
    sets.insert(setIndex, set);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  void reorderExercise(int oldIndex, int newIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (oldIndex < 0 || oldIndex >= exercises.length) return;
    final target = newIndex.clamp(0, exercises.length - 1);
    final item = exercises.removeAt(oldIndex);
    exercises.insert(target, item);
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  void setRestPreference(int exerciseIndex, RestPreference preference) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;
    final globalSeconds = _ref.read(defaultRestSecondsProvider);
    final normalized = normalizeRestPreference(
      preference: preference,
      globalSeconds: globalSeconds,
    );
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      restSecondsOverride: restPreferenceToStorage(normalized),
    );
    state = state!.copyWith(exercises: exercises);
    saveDraftNow();
  }

  void setRestSecondsOverride(int exerciseIndex, int? seconds) {
    setRestPreference(exerciseIndex, restPreferenceFromStorage(seconds));
  }

  (double, int) get sessionTotals {
    final current = state;
    if (current == null) return (0, 0);
    double volume = 0;
    var sets = 0;
    for (final ex in current.exercises) {
      for (final set in ex.sets) {
        if (set.isCompleted) {
          volume += (set.weightKg ?? 0.0) * set.reps;
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

/// Derived provider: total volume (kg) and completed set count.
///
/// Uses `.select` so it only notifies listeners when the computed
/// (volume, sets) tuple changes — not on every keystroke inside a
/// weight/reps field.
final sessionTotalsProvider = Provider<(double, int)>((ref) {
  return ref.watch(activeWorkoutProvider.select((state) {
    if (state == null) return (0.0, 0);
    double volume = 0;
    int completed = 0;
    for (final ex in state.exercises) {
      for (final set in ex.sets) {
        if (set.isCompleted) {
          volume += (set.weightKg ?? 0.0) * set.reps;
          completed++;
        }
      }
    }
    return (volume, completed);
  }));
});
