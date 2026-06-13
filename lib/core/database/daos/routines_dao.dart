import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables/routines_table.dart';
import '../tables/routine_days_table.dart';
import '../tables/routine_exercises_table.dart';
import 'workouts_dao.dart';
import '../../services/sync_codec.dart';

part 'routines_dao.g.dart';

/// Title-cases a lowercase body-part string ("upper legs" -> "Upper Legs").
String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Hydrated representation of a Routine with fully resolved exercise names/IDs,
/// plus list-card metadata (distinct muscle groups + last-trained date).
class HydratedRoutine {
  final Routine routine;
  final List<String> exerciseNames;
  final List<int> exerciseIds;

  /// Distinct body parts across the routine's exercises, Title-Cased,
  /// in first-seen order (e.g. ["Chest", "Shoulders", "Triceps"]).
  final List<String> muscleTags;

  /// Most recent COMPLETED session date for this routine, or null if never done.
  final DateTime? lastTrained;

  const HydratedRoutine({
    required this.routine,
    required this.exerciseNames,
    required this.exerciseIds,
    this.muscleTags = const [],
    this.lastTrained,
  });
}

/// Rich detail representation for [RoutineDetailScreen].
/// Includes full exercise metadata + per-exercise routine config.
class HydratedRoutineExercise {
  final Exercise exercise;
  final RoutineExercise config;

  const HydratedRoutineExercise({
    required this.exercise,
    required this.config,
  });
}

class HydratedRoutineDetail {
  final Routine routine;
  final List<HydratedRoutineExercise> exercises;

  const HydratedRoutineDetail({
    required this.routine,
    required this.exercises,
  });
}

/// One exercise entry inside the routine editor's draft state.
class RoutineDraftExercise {
  final int exerciseId;
  final int defaultSets;
  final int? defaultReps;
  final double? defaultWeightKg;

  const RoutineDraftExercise({
    required this.exerciseId,
    this.defaultSets = 3,
    this.defaultReps,
    this.defaultWeightKg,
  });
}

@DriftAccessor(tables: [Routines, RoutineDays, RoutineExercises])
class RoutinesDao extends DatabaseAccessor<AppDatabase>
    with _$RoutinesDaoMixin {
  RoutinesDao(super.db);

  // Routines
  Future<List<Routine>> getRoutinesForUser(String userId) =>
      (select(routines)..where((t) => t.userId.equals(userId))).get();

  /// Reactive stream of raw routines for a user.
  Stream<List<Routine>> watchRoutinesForUser(String userId) {
    return (select(routines)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Resolves exercise names, IDs, muscle tags and last-trained dates for
  /// every routine — in 3 fixed queries total, re-emitting whenever routines,
  /// their exercises, the exercise library, or workout history change.
  ///
  /// (The old version looped days → exercises → getExerciseById per routine:
  /// a textbook N+1 storm, and it never refreshed "Last trained" after a
  /// workout because it only watched the routines table.)
  Stream<List<HydratedRoutine>> watchHydratedRoutinesForUser(String userId) {
    final driver = customSelect(
      'SELECT COUNT(*) AS c FROM routines WHERE user_id = ?',
      variables: [Variable.withString(userId)],
      readsFrom: {
        routines,
        routineDays,
        routineExercises,
        db.exercises,
        db.workoutSessions,
      },
    ).watch();
    return driver.asyncMap((_) => _getHydratedRoutines(userId));
  }

  Future<List<HydratedRoutine>> _getHydratedRoutines(String userId) async {
    final routineList = await (select(routines)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (routineList.isEmpty) return const [];

    final ids = routineList.map((r) => r.id).toList();

    // Batch 1: every exercise of every routine, ordered, with metadata.
    final exerciseRows = await _exercisesForRoutines(ids);

    // Batch 2: last-trained per routine.
    final lastTrainedById = await db.workoutsDao.lastTrainedForRoutines(ids);

    return [
      for (final routine in routineList)
        _assembleHydratedRoutine(
          routine,
          exerciseRows[routine.id] ?? const [],
          lastTrainedById[routine.id],
        ),
    ];
  }

  HydratedRoutine _assembleHydratedRoutine(
    Routine routine,
    List<(Exercise, RoutineExercise)> rows,
    DateTime? lastTrained,
  ) {
    final names = <String>[];
    final ids = <int>[];
    final tags = <String>{}; // LinkedHashSet — preserves first-seen order
    for (final (exercise, _) in rows) {
      names.add(exercise.name);
      ids.add(exercise.id);
      if (exercise.bodyPart.isNotEmpty) {
        tags.add(_titleCase(exercise.bodyPart));
      }
    }
    return HydratedRoutine(
      routine: routine,
      exerciseNames: names,
      exerciseIds: ids,
      muscleTags: tags.toList(),
      lastTrained: lastTrained,
    );
  }

  /// All (exercise, config) pairs for the given routines in ONE query,
  /// grouped by routine id and ordered by day + exercise order.
  Future<Map<String, List<(Exercise, RoutineExercise)>>> _exercisesForRoutines(
      List<String> routineIds) async {
    if (routineIds.isEmpty) return {};
    final rows = await (select(routineExercises).join([
      innerJoin(
          routineDays, routineDays.id.equalsExp(routineExercises.routineDayId)),
      innerJoin(
          db.exercises, db.exercises.id.equalsExp(routineExercises.exerciseId)),
    ])
          ..where(routineDays.routineId.isIn(routineIds))
          ..orderBy([
            OrderingTerm.asc(routineDays.orderIndex),
            OrderingTerm.asc(routineExercises.orderIndex),
          ]))
        .get();

    final map = <String, List<(Exercise, RoutineExercise)>>{};
    for (final row in rows) {
      final day = row.readTable(routineDays);
      map.putIfAbsent(day.routineId, () => []).add((
        row.readTable(db.exercises),
        row.readTable(routineExercises),
      ));
    }
    return map;
  }

  /// Reactive stream of a single hydrated routine by ID.
  Stream<HydratedRoutine?> watchHydratedRoutine(String routineId) {
    return customSelect(
      'SELECT COUNT(*) AS c FROM routines WHERE id = ?',
      variables: [Variable.withString(routineId)],
      readsFrom: {
        routines,
        routineDays,
        routineExercises,
        db.exercises,
        db.workoutSessions,
      },
    ).watch().asyncMap((_) async {
      final routine = await (select(routines)
            ..where((t) => t.id.equals(routineId)))
          .getSingleOrNull();
      if (routine == null) return null;
      final exercises = await _exercisesForRoutines([routineId]);
      final lastTrained = await db.workoutsDao.lastTrainedForRoutine(routineId);
      return _assembleHydratedRoutine(
        routine,
        exercises[routineId] ?? const [],
        lastTrained,
      );
    });
  }

  /// Reactive stream of a single routine with full exercise metadata + config.
  /// Re-emits when the routine, its day/exercise structure, or the exercise
  /// library change — so the detail screen updates live after editor saves.
  Stream<HydratedRoutineDetail?> watchHydratedRoutineDetail(String routineId) {
    return customSelect(
      'SELECT COUNT(*) AS c FROM routines WHERE id = ?',
      variables: [Variable.withString(routineId)],
      readsFrom: {routines, routineDays, routineExercises, db.exercises},
    ).watch().asyncMap((_) => getHydratedRoutineDetail(routineId));
  }

  Future<HydratedRoutineDetail?> getHydratedRoutineDetail(
      String routineId) async {
    final routine = await (select(routines)
          ..where((t) => t.id.equals(routineId)))
        .getSingleOrNull();
    if (routine == null) return null;

    final rows = await _exercisesForRoutines([routineId]);
    return HydratedRoutineDetail(
      routine: routine,
      exercises: [
        for (final (exercise, config)
            in rows[routineId] ?? const <(Exercise, RoutineExercise)>[])
          HydratedRoutineExercise(exercise: exercise, config: config),
      ],
    );
  }

  Future<Routine> getRoutine(String id) =>
      (select(routines)..where((t) => t.id.equals(id))).getSingle();

  // ── Sync serialization ─────────────────────────────────────────────────────

  /// Self-contained JSON snapshot of a routine and all its days + exercises,
  /// for cloud sync. Dates are epoch millis. Null if the routine is gone.
  Future<Map<String, dynamic>?> exportRoutineJson(String routineId) async {
    final r = await (select(routines)..where((t) => t.id.equals(routineId)))
        .getSingleOrNull();
    if (r == null) return null;
    final days = await getDaysForRoutine(routineId);
    final daysJson = <Map<String, dynamic>>[];
    for (final d in days) {
      final exs = await getExercisesForDay(d.id);
      daysJson.add({
        'id': d.id,
        'routineId': d.routineId,
        'name': d.name,
        'orderIndex': d.orderIndex,
        'exercises': [
          for (final e in exs)
            {
              'id': e.id,
              'routineDayId': e.routineDayId,
              'exerciseId': e.exerciseId,
              'orderIndex': e.orderIndex,
              'defaultSets': e.defaultSets,
              'defaultReps': e.defaultReps,
              'defaultWeightKg': e.defaultWeightKg,
              'restSeconds': e.restSeconds,
            }
        ],
      });
    }
    return {
      'routine': {
        'id': r.id,
        'userId': r.userId,
        'name': r.name,
        'notes': r.notes,
        'createdAt': r.createdAt.millisecondsSinceEpoch,
        'updatedAt': r.updatedAt.millisecondsSinceEpoch,
      },
      'days': daysJson,
    };
  }

  /// Rehydrate a routine snapshot into local storage (cloud restore).
  /// Idempotent: the routine is upserted and its days/exercises rebuilt.
  Future<void> importRoutineJson(Map<String, dynamic> data) async {
    final rj = data['routine'] as Map<String, dynamic>;
    final routineId = rj['id'] as String;
    DateTime ms(dynamic v) => DateTime.fromMillisecondsSinceEpoch(v as int);

    await transaction(() async {
      await into(routines).insertOnConflictUpdate(RoutinesCompanion.insert(
        id: Value(routineId),
        userId: rj['userId'] as String,
        name: rj['name'] as String,
        notes: Value(rj['notes'] as String? ?? ''),
        createdAt: ms(rj['createdAt']),
        updatedAt: ms(rj['updatedAt']),
      ));

      // Rebuild children deterministically.
      await customUpdate(
        'DELETE FROM routine_exercises WHERE routine_day_id IN '
        '(SELECT id FROM routine_days WHERE routine_id = ?)',
        variables: [Variable.withString(routineId)],
        updates: {routineExercises},
        updateKind: UpdateKind.delete,
      );
      await (delete(routineDays)..where((t) => t.routineId.equals(routineId)))
          .go();

      for (final d in (data['days'] as List).cast<Map<String, dynamic>>()) {
        await into(routineDays).insert(RoutineDaysCompanion.insert(
          id: Value(d['id'] as String),
          routineId: d['routineId'] as String,
          name: d['name'] as String,
          orderIndex: d['orderIndex'] as int,
        ));
        for (final e
            in (d['exercises'] as List).cast<Map<String, dynamic>>()) {
          await into(routineExercises).insert(RoutineExercisesCompanion.insert(
            id: Value(e['id'] as String),
            routineDayId: e['routineDayId'] as String,
            exerciseId: e['exerciseId'] as int,
            orderIndex: e['orderIndex'] as int,
            defaultSets: Value(e['defaultSets'] as int? ?? 3),
            defaultReps: Value(e['defaultReps'] as int?),
            defaultWeightKg: Value((e['defaultWeightKg'] as num?)?.toDouble()),
            restSeconds: Value(e['restSeconds'] as int?),
          ));
        }
      }
    });
  }

  /// Queues a routine's current state for cloud upload. Called from every
  /// routine mutation below so coverage is guaranteed at the DAO layer — no
  /// UI call site can forget to sync. Best-effort: a serialization hiccup
  /// never breaks the local write that already succeeded.
  Future<void> _enqueueRoutineUpsert(String routineId, String userId) async {
    try {
      final data = await exportRoutineJson(routineId);
      if (data == null) return;
      await db.syncOutboxDao.enqueue(
        entityType: 'routine',
        entityId: routineId,
        userId: userId,
        payload: SyncCodec.encode(data),
      );
    } catch (_) {/* never block a local write on sync bookkeeping */}
  }

  Future<void> _enqueueRoutineDelete(String routineId, String userId) async {
    try {
      await db.syncOutboxDao.enqueue(
        entityType: 'routine',
        entityId: routineId,
        userId: userId,
        op: 'delete',
        payload: '',
      );
    } catch (_) {/* tombstone is best-effort */}
  }

  Future<void> insertRoutine(RoutinesCompanion routine) =>
      into(routines).insert(routine);

  Future<void> updateRoutine(RoutinesCompanion routine) =>
      update(routines).replace(routine);

  /// Renames a routine (targeted update — preserves all other columns + FKs).
  Future<void> renameRoutine(String id, String name) async {
    await (update(routines)..where((t) => t.id.equals(id)))
        .write(RoutinesCompanion(
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
    final r = await (select(routines)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (r != null) await _enqueueRoutineUpsert(id, r.userId);
  }

  /// Deletes a routine **and all of its children** atomically.
  /// Past workout sessions keep their routineId reference by design —
  /// history must survive routine deletion.
  Future<void> deleteRoutine(String id) async {
    // Capture owner before deletion so we can enqueue a cloud tombstone.
    final r =
        await (select(routines)..where((t) => t.id.equals(id))).getSingleOrNull();
    await transaction(() async {
      await customUpdate(
        'DELETE FROM routine_exercises WHERE routine_day_id IN '
        '(SELECT id FROM routine_days WHERE routine_id = ?)',
        variables: [Variable.withString(id)],
        updates: {routineExercises},
        updateKind: UpdateKind.delete,
      );
      await (delete(routineDays)..where((t) => t.routineId.equals(id))).go();
      await (delete(routines)..where((t) => t.id.equals(id))).go();
    });
    if (r != null) await _enqueueRoutineDelete(id, r.userId);
  }

  // RoutineDays
  Future<List<RoutineDay>> getDaysForRoutine(String routineId) =>
      (select(routineDays)
            ..where((t) => t.routineId.equals(routineId))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  Future<void> insertDay(RoutineDaysCompanion day) =>
      into(routineDays).insert(day);

  Future<void> deleteDay(String id) =>
      (delete(routineDays)..where((t) => t.id.equals(id))).go();

  // RoutineExercises
  Future<List<RoutineExercise>> getExercisesForDay(String routineDayId) =>
      (select(routineExercises)
            ..where((t) => t.routineDayId.equals(routineDayId))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  Future<void> insertRoutineExercise(RoutineExercisesCompanion exercise) =>
      into(routineExercises).insert(exercise);

  Future<void> deleteRoutineExercise(String id) =>
      (delete(routineExercises)..where((t) => t.id.equals(id))).go();

  /// Returns the routine's first day, creating "Day 1" if none exists yet.
  Future<RoutineDay> _ensureFirstDay(String routineId) async {
    final days = await getDaysForRoutine(routineId);
    if (days.isNotEmpty) return days.first;

    final dayId = const Uuid().v4();
    await insertDay(RoutineDaysCompanion.insert(
      id: Value(dayId),
      routineId: routineId,
      name: 'Day 1',
      orderIndex: 0,
    ));
    return RoutineDay(
        id: dayId, routineId: routineId, name: 'Day 1', orderIndex: 0);
  }

  /// Appends an exercise to the routine's first day.
  /// Powers the "Add Exercise" button on RoutineDetailScreen.
  Future<void> addExerciseToRoutine(
    String routineId,
    int exerciseId, {
    int defaultSets = 3,
  }) async {
    await transaction(() async {
      final day = await _ensureFirstDay(routineId);
      final existing = await getExercisesForDay(day.id);
      await insertRoutineExercise(RoutineExercisesCompanion.insert(
        id: Value(const Uuid().v4()),
        routineDayId: day.id,
        exerciseId: exerciseId,
        orderIndex: existing.length,
        defaultSets: Value(defaultSets),
      ));
      await (update(routines)..where((t) => t.id.equals(routineId)))
          .write(RoutinesCompanion(updatedAt: Value(DateTime.now())));
    });
    final r = await (select(routines)..where((t) => t.id.equals(routineId)))
        .getSingleOrNull();
    if (r != null) await _enqueueRoutineUpsert(routineId, r.userId);
  }

  /// Creates a brand-new routine from the editor's draft. Returns its id.
  Future<String> createRoutine({
    required String userId,
    required String name,
    required List<RoutineDraftExercise> exercises,
  }) async {
    final routineId = await transaction(() async {
      final id = const Uuid().v4();
      final now = DateTime.now();
      await insertRoutine(RoutinesCompanion.insert(
        id: Value(id),
        userId: userId,
        name: name,
        createdAt: now,
        updatedAt: now,
      ));
      final dayId = const Uuid().v4();
      await insertDay(RoutineDaysCompanion.insert(
        id: Value(dayId),
        routineId: id,
        name: 'Day 1',
        orderIndex: 0,
      ));
      await _insertDraftExercises(dayId, exercises);
      return id;
    });
    await _enqueueRoutineUpsert(routineId, userId);
    return routineId;
  }

  /// Replaces a routine's name + exercise list with the editor's draft.
  /// Workout history is untouched — sessions reference exercises directly.
  Future<void> replaceRoutineStructure({
    required String routineId,
    required String name,
    required List<RoutineDraftExercise> exercises,
  }) async {
    await transaction(() async {
      await (update(routines)..where((t) => t.id.equals(routineId)))
          .write(RoutinesCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
      ));

      final day = await _ensureFirstDay(routineId);

      // Clear all existing exercises across every day, then rebuild on day 1.
      await customUpdate(
        'DELETE FROM routine_exercises WHERE routine_day_id IN '
        '(SELECT id FROM routine_days WHERE routine_id = ?)',
        variables: [Variable.withString(routineId)],
        updates: {routineExercises},
        updateKind: UpdateKind.delete,
      );

      await _insertDraftExercises(day.id, exercises);
    });
    final r = await (select(routines)..where((t) => t.id.equals(routineId)))
        .getSingleOrNull();
    if (r != null) await _enqueueRoutineUpsert(routineId, r.userId);
  }

  Future<void> _insertDraftExercises(
    String dayId,
    List<RoutineDraftExercise> exercises,
  ) async {
    for (var i = 0; i < exercises.length; i++) {
      final draft = exercises[i];
      await insertRoutineExercise(RoutineExercisesCompanion.insert(
        id: Value(const Uuid().v4()),
        routineDayId: dayId,
        exerciseId: draft.exerciseId,
        orderIndex: i,
        defaultSets: Value(draft.defaultSets),
        defaultReps: Value(draft.defaultReps),
        defaultWeightKg: Value(draft.defaultWeightKg),
      ));
    }
  }

  Future<void> saveWorkoutAsRoutine(String userId, String routineName,
      List<HydratedWorkoutExercise> exercises) async {
    return createRoutine(
      userId: userId,
      name: routineName,
      exercises: [
        for (final ex in exercises)
          RoutineDraftExercise(
            exerciseId: ex.exerciseMetadata.id,
            defaultSets: ex.sets.isNotEmpty ? ex.sets.length : 3,
            defaultReps: ex.sets.isNotEmpty ? ex.sets.first.reps : null,
            defaultWeightKg: ex.sets.isNotEmpty ? ex.sets.first.weightKg : null,
          ),
      ],
    ).then((_) {});
  }
}
