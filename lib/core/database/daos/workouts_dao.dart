import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables/workouts_table.dart';
import '../../../features/workout/domain/active_workout_state.dart';

part 'workouts_dao.g.dart';

class ExerciseHistoryData {
  final DateTime date;
  final double weight;
  final int reps;
  final double estimated1RM;
  final double volume;

  const ExerciseHistoryData({
    required this.date,
    required this.weight,
    required this.reps,
    required this.estimated1RM,
    required this.volume,
  });
}

class HydratedWorkoutExercise {
  final WorkoutExercise workoutExercise;
  final Exercise exerciseMetadata;
  final List<WorkoutSet> sets;

  /// Sets from the most recent prior session for the same exercise.
  /// Empty list means this is the user's first time logging this exercise.
  /// Used to power the "VS PREV" column in WorkoutDetailScreen.
  final List<WorkoutSet> previousSets;

  const HydratedWorkoutExercise({
    required this.workoutExercise,
    required this.exerciseMetadata,
    required this.sets,
    this.previousSets = const [],
  });
}

class HydratedWorkout {
  final WorkoutSession session;
  final List<HydratedWorkoutExercise> exercises;

  const HydratedWorkout({
    required this.session,
    required this.exercises,
  });
}

// ── HomeScreen feed data classes ─────────────────────────────────────────────

class LastSessionSetData {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final String? setType;
  final bool isPr;

  const LastSessionSetData({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.setType,
    this.isPr = false,
  });
}

/// A single exercise row inside a [WorkoutSessionPreview].
class ExercisePreviewItem {
  final String exerciseName;
  final String? gifUrl;
  final int setCount;

  const ExercisePreviewItem({
    required this.exerciseName,
    this.gifUrl,
    required this.setCount,
  });
}

/// Denormalized session summary for the HomeScreen infinite-scroll feed.
/// Assembled by [WorkoutsDao.getSessionPreviewsForUser].
class WorkoutSessionPreview {
  final WorkoutSession session;
  final Duration duration;
  final double totalVolumeKg;
  final int prCount;
  final List<ExercisePreviewItem> topExercises;
  final int totalExerciseCount;

  const WorkoutSessionPreview({
    required this.session,
    required this.duration,
    required this.totalVolumeKg,
    required this.prCount,
    required this.topExercises,
    required this.totalExerciseCount,
  });
}

class DailyVolumeSample {
  final DateTime day;
  final double volume;

  const DailyVolumeSample({
    required this.day,
    required this.volume,
  });
}

@DriftAccessor(tables: [WorkoutSessions, WorkoutExercises, WorkoutSets])
class WorkoutsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutsDaoMixin {
  WorkoutsDao(super.db);

  // WorkoutSessions
  Future<WorkoutSession> getSession(String id) =>
      (select(workoutSessions)..where((t) => t.id.equals(id))).getSingle();

  Future<List<WorkoutSession>> getSessionsForUser(String userId) =>
      (select(workoutSessions)..where((t) => t.userId.equals(userId))).get();

  Future<void> insertSession(WorkoutSessionsCompanion session) =>
      into(workoutSessions).insert(session);

  Future<void> updateSession(WorkoutSessionsCompanion session) =>
      update(workoutSessions).replace(session);

  Future<void> deleteSession(String id) =>
      (delete(workoutSessions)..where((t) => t.id.equals(id))).go();

  Stream<int> watchWorkoutCountForUser(String userId) {
    return (select(workoutSessions)
          ..where((t) => t.userId.equals(userId) & t.endedAt.isNotNull()))
        .watch()
        .map((rows) => rows.length);
  }

  Stream<List<WorkoutSession>> watchSessionsForUser(String userId) {
    return (select(workoutSessions)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  // WorkoutExercises
  Future<List<WorkoutExercise>> getExercisesForSession(String sessionId) =>
      (select(workoutExercises)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  Future<void> insertWorkoutExercise(WorkoutExercisesCompanion exercise) =>
      into(workoutExercises).insert(exercise);

  Future<void> deleteWorkoutExercise(String id) =>
      (delete(workoutExercises)..where((t) => t.id.equals(id))).go();

  // WorkoutSets
  Future<List<WorkoutSet>> getSetsForExercise(String workoutExerciseId) =>
      (select(workoutSets)
            ..where((t) => t.workoutExerciseId.equals(workoutExerciseId))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  /// Returns the ordered sets from the **most recent completed session**
  /// (excluding [currentSessionId]) in which [exerciseId] was logged.
  ///
  /// Returns an empty list when this is the exercise's first appearance,
  /// so callers can hide the "VS PREV" column rather than show blanks.
  ///
  /// Query is two bounded steps — not N+1:
  ///   1. Find the latest session_id for this exercise (LIMIT 1).
  ///   2. Fetch that session's workout_exercise row, then its sets.
  Future<List<WorkoutSet>> getPreviousSessionSets(
    int exerciseId,
    String currentSessionId,
  ) async {
    // Step 1: most recent completed session for this exercise, not the current one.
    final sessionRows = await customSelect(
      '''
      SELECT s.id
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions  s  ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND s.id           != ?
        AND s.ended_at     IS NOT NULL
      ORDER BY s.started_at DESC
      LIMIT 1
      ''',
      variables: [
        Variable.withInt(exerciseId),
        Variable.withString(currentSessionId),
      ],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    if (sessionRows.isEmpty) return [];
    final prevSessionId = sessionRows.first.read<String>('id');

    // Step 2: workout_exercise row for that session + exercise.
    final weRow = await (select(workoutExercises)
          ..where(
            (t) =>
                t.sessionId.equals(prevSessionId) &
                t.exerciseId.equals(exerciseId),
          ))
        .getSingleOrNull();

    if (weRow == null) return [];
    return getSetsForExercise(weRow.id);
  }

  Future<List<LastSessionSetData>> getLastSessionSetsForExercise({
    required int exerciseId,
    required String userId,
  }) async {
    // 1. Find the single most recent session where this exercise appears
    final sessionRows = await customSelect(
      '''
      SELECT s.id
      FROM workout_sessions s
      JOIN workout_exercises we ON s.id = we.session_id
      WHERE we.exercise_id = ?
        AND s.user_id = ?
        AND s.ended_at IS NOT NULL
      ORDER BY s.started_at DESC
      LIMIT 1
      ''',
      variables: [
        Variable.withInt(exerciseId),
        Variable.withString(userId),
      ],
      readsFrom: {workoutSessions, workoutExercises},
    ).get();

    if (sessionRows.isEmpty) return [];
    final sessionId = sessionRows.first.read<String>('id');

    // 2. Fetch the sets from that session for this exercise
    final setsRows = await customSelect(
      '''
      SELECT ws.order_index, ws.weight_kg, ws.reps, ws.set_type
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      WHERE we.session_id = ? AND ws.exercise_id = ?
      ORDER BY ws.order_index ASC
      ''',
      variables: [
        Variable.withString(sessionId),
        Variable.withInt(exerciseId),
      ],
      readsFrom: {workoutSets, workoutExercises},
    ).get();

    return setsRows.map((row) {
      return LastSessionSetData(
        setNumber: row.read<int>('order_index') + 1,
        weightKg: row.read<double?>('weight_kg'),
        reps: row.read<int?>('reps'),
        setType: row.read<String?>('set_type'),
      );
    }).toList();
  }

  /// Single-query fetch of the last performed session's sets for every
  /// exercise in a given routine. Returns a map keyed by exerciseId string.
  Future<Map<String, List<LastSessionSetData>>> getLastSessionSetsForRoutine({
    required String routineId,
    required String userId,
  }) async {
    final rows = await customSelect(
      '''
      SELECT ws.exercise_id, ws.order_index, ws.weight_kg, ws.reps, ws.set_type, ws.is_pr
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      WHERE we.session_id = (
        SELECT s.id
        FROM workout_sessions s
        WHERE s.routine_id = ?
          AND s.user_id = ?
          AND s.ended_at IS NOT NULL
        ORDER BY s.started_at DESC
        LIMIT 1
      )
      ORDER BY ws.exercise_id, ws.order_index ASC
      ''',
      variables: [
        Variable.withString(routineId),
        Variable.withString(userId),
      ],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    final map = <String, List<LastSessionSetData>>{};
    for (final row in rows) {
      final exId = row.read<int>('exercise_id').toString();
      map.putIfAbsent(exId, () => []);
      map[exId]!.add(LastSessionSetData(
        setNumber: row.read<int>('order_index') + 1,
        weightKg: row.read<double?>('weight_kg'),
        reps: row.read<int?>('reps'),
        setType: row.read<String?>('set_type'),
        isPr: row.read<bool?>('is_pr') ?? false,
      ));
    }
    return map;
  }

  Future<void> insertSet(WorkoutSetsCompanion set) =>
      into(workoutSets).insert(set);

  Future<void> updateSet(WorkoutSetsCompanion set) =>
      update(workoutSets).replace(set);

  Future<void> deleteSet(String id) =>
      (delete(workoutSets)..where((t) => t.id.equals(id))).go();

  // ── Epley 1RM Formula ────────────────────────────────────────────────────

  /// Brzycki/Epley one-rep-max estimate.
  /// Guard: at reps <= 1 the formula is undefined or trivially returns weight.
  double _epley(double weight, int reps) {
    if (reps <= 1) return weight;
    return weight * (1 + reps / 30);
  }

  Future<List<ExerciseHistoryData>> getExerciseHistory(int exerciseId) async {
    const query = '''
      SELECT
        COALESCE(s.ended_at, s.started_at) AS session_date,
        MAX(ws.weight_kg) AS max_weight,
        MAX(ws.reps) AS max_reps,
        SUM(ws.weight_kg * ws.reps) AS total_volume
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND ws.weight_kg > 0
        AND ws.reps > 0
      GROUP BY s.id, COALESCE(s.ended_at, s.started_at)
      ORDER BY session_date ASC
    ''';

    final rows = await customSelect(
      query,
      variables: [Variable.withInt(exerciseId)],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    return rows.map((row) {
      final date = DateTime.parse(row.read<String>('session_date'));
      final weight = row.read<double>('max_weight');
      final reps = row.read<int>('max_reps');
      final volume = row.read<double>('total_volume');
      final estimated1RM = _epley(weight, reps);

      return ExerciseHistoryData(
        date: date,
        weight: weight,
        reps: reps,
        estimated1RM: estimated1RM,
        volume: volume,
      );
    }).toList();
  }

  Stream<List<ExerciseHistoryData>> watchExerciseHistory(int exerciseId, {DateTime? since}) {
    final sinceClause = since != null ? '\n        AND ws.completed_at >= ?' : '';
    final query = '''
      SELECT
        COALESCE(s.ended_at, s.started_at) AS session_date,
        MAX(ws.weight_kg) AS max_weight,
        MAX(ws.reps) AS max_reps,
        SUM(ws.weight_kg * ws.reps) AS total_volume
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND ws.weight_kg > 0
        AND ws.reps > 0$sinceClause
      GROUP BY s.id, COALESCE(s.ended_at, s.started_at)
      ORDER BY session_date ASC
    ''';

    final variables = <Variable>[
      Variable.withInt(exerciseId),
      if (since != null) Variable.withString(since.toIso8601String()),
    ];

    return customSelect(
      query,
      variables: variables,
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).watch().map((rows) {
      return rows.map((row) {
        final date = DateTime.parse(row.read<String>('session_date'));
        final weight = row.read<double>('max_weight');
        final reps = row.read<int>('max_reps');
        final volume = row.read<double>('total_volume');
        final estimated1RM = _epley(weight, reps);

        return ExerciseHistoryData(
          date: date,
          weight: weight,
          reps: reps,
          estimated1RM: estimated1RM,
          volume: volume,
        );
      }).toList();
    });
  }

  Future<HydratedWorkout?> getHydratedWorkout(String sessionId) async {
    final session = await getSession(sessionId);

    final workoutExercises = await getExercisesForSession(sessionId);

    final hydratedExercises = <HydratedWorkoutExercise>[];
    for (final we in workoutExercises) {
      final exerciseRow = await db.exercisesDao.getExerciseById(we.exerciseId);

      final sets = await getSetsForExercise(we.id);

      // Fetch cross-session historical sets to power "VS PREV" column.
      // Returns [] on first appearance — UI hides the column in that case.
      final previousSets =
          await getPreviousSessionSets(we.exerciseId, sessionId);

      hydratedExercises.add(HydratedWorkoutExercise(
        workoutExercise: we,
        exerciseMetadata: exerciseRow,
        sets: sets,
        previousSets: previousSets,
      ));
    }

    return HydratedWorkout(
      session: session,
      exercises: hydratedExercises,
    );
  }

  // ── Paginated session previews ───────────────────────────────────────────

  /// Returns up to [limit] previews starting at [offset], ordered newest-first.
  /// Pass `limit = pageSize + 1` to detect `hasMore` — caller discards the
  /// extra item and treats `length == limit` as a hasMore signal.
  Future<List<WorkoutSessionPreview>> getSessionPreviewsForUser(
    String userId, {
    required int limit,
    required int offset,
  }) async {
    final sessions = await (select(workoutSessions)
          ..where((t) => t.userId.equals(userId) & t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit, offset: offset))
        .get();

    if (sessions.isEmpty) return [];

    final previews = <WorkoutSessionPreview>[];

    for (final session in sessions) {
      // ── PR count + exercise count via JOIN ──────────────────────────────
      final statsRows = await customSelect(
        '''
        SELECT
          COUNT(DISTINCT we.id)                                        AS exercise_count,
          COALESCE(SUM(CASE WHEN wset.is_pr = 1 THEN 1 ELSE 0 END), 0) AS pr_count
        FROM workout_exercises we
        LEFT JOIN workout_sets wset ON wset.workout_exercise_id = we.id
        WHERE we.session_id = ?
        ''',
        variables: [Variable.withString(session.id)],
        readsFrom: {workoutExercises, workoutSets},
      ).get();

      final exerciseCount = statsRows.isNotEmpty
          ? statsRows.first.read<int>('exercise_count')
          : 0;
      final prCount =
          statsRows.isNotEmpty ? statsRows.first.read<int>('pr_count') : 0;

      // ── Top 2 exercises with GIF url ─────────────────────────────────────
      final topWeRows = await (select(workoutExercises)
            ..where((t) => t.sessionId.equals(session.id))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
            ..limit(2))
          .get();

      final topExercises = <ExercisePreviewItem>[];
      for (final we in topWeRows) {
        final exercise = await db.exercisesDao.getExerciseById(we.exerciseId);
        // All persisted sets are completed (finishWorkout only saves isCompleted==true)
        final setCount = await (select(workoutSets)
              ..where((t) => t.workoutExerciseId.equals(we.id)))
            .get()
            .then((rows) => rows.length);

        topExercises.add(ExercisePreviewItem(
          exerciseName: exercise.name,
          gifUrl: exercise.gifUrl,
          setCount: setCount,
        ));
      }

      previews.add(WorkoutSessionPreview(
        session: session,
        duration: session.endedAt!.difference(session.startedAt),
        totalVolumeKg: session.totalVolumeKg,
        prCount: prCount,
        topExercises: topExercises,
        totalExerciseCount: exerciseCount,
      ));
    }

    return previews;
  }

  // ── PR Detection ──────────────────────────────────────────────────────────

  /// Marks the best-1RM set per exercise in [sessionId] as a PR if it exceeds
  /// the historical max for that exercise across all sessions before [sessionStart].
  ///
  /// Epley formula: `estimated1RM = weight × (1 + reps / 30)`
  /// Only the single best set per exercise per session is ever marked.
  Future<void> detectAndMarkPrs(String sessionId, DateTime sessionStart) async {
    try {
      final exercises = await getExercisesForSession(sessionId);

      for (final we in exercises) {
        final sets = await getSetsForExercise(we.id);
        final priorMax =
            await _getMaxEstimated1rmBefore(we.exerciseId, sessionStart);

        double sessionBest1rm = 0;
        String? bestSetId;

        for (final set in sets) {
          if (set.weightKg > 0 && set.reps > 0) {
            final e1rm = _epley(set.weightKg, set.reps);
            if (e1rm > sessionBest1rm) {
              sessionBest1rm = e1rm;
              bestSetId = set.id;
            }
          }
        }

        if (bestSetId != null && sessionBest1rm > priorMax) {
          await (update(workoutSets)..where((t) => t.id.equals(bestSetId!)))
              .write(WorkoutSetsCompanion(
            isPr: const Value(true),
            estimated1rm: Value(sessionBest1rm),
          ));
          debugPrint(
            '[WorkoutsDao] PR ✓ exercise=${we.exerciseId} '
            '1RM=${sessionBest1rm.toStringAsFixed(1)}kg '
            '(prior=${priorMax.toStringAsFixed(1)}kg)',
          );
        }
      }
    } catch (e) {
      debugPrint('[WorkoutsDao] detectAndMarkPrs failed: $e');
    }
  }

  Future<double> _getMaxEstimated1rmBefore(
      int exerciseId, DateTime before) async {
    final rows = await customSelect(
      '''
      SELECT COALESCE(MAX(ws.weight_kg * (1.0 + ws.reps / 30.0)), 0) AS max_1rm
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s   ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND s.ended_at < ?
        AND ws.weight_kg > 0
        AND ws.reps > 0
      ''',
      variables: [
        Variable.withInt(exerciseId),
        Variable.withString(before.toIso8601String()),
      ],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    if (rows.isEmpty) return 0.0;
    return rows.first.read<double>('max_1rm');
  }

  Stream<HydratedWorkout?> watchHydratedWorkout(String sessionId) {
    return customSelect(
      'SELECT 1 FROM workout_sessions WHERE id = ?',
      variables: [Variable.withString(sessionId)],
      readsFrom: {workoutSessions, workoutExercises, workoutSets},
    ).watch().asyncMap((_) => getHydratedWorkout(sessionId));
  }

  Future<void> deleteOrphanedSessions(String userId) async {
    await (delete(workoutSessions)
      ..where((s) => s.userId.equals(userId) &
                     s.endedAt.isNull() &
                     s.startedAt.isSmallerThanValue(
                       DateTime.now().subtract(const Duration(hours: 24))))
    ).go();
  }

  // ── Routine Volume History ───────────────────────────────────────────────

  Future<List<DailyVolumeSample>> dailyVolumeForRoutine(String routineId) async {
    final rows = await customSelect(
      '''
      SELECT
        DATE(s.started_at) AS day,
        CAST(SUM(st.weight_kg * st.reps) AS REAL) AS volume
      FROM workout_sets st
      JOIN workout_exercises we ON we.id = st.workout_exercise_id
      JOIN workout_sessions  s  ON s.id  = we.session_id
      WHERE s.routine_id = ?
      GROUP BY DATE(s.started_at)
      ORDER BY day ASC;
      ''',
      variables: [Variable.withString(routineId)],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    final samples = rows.map((r) {
      final dayStr = r.read<String>('day');
      return DailyVolumeSample(
        day: DateTime.parse(dayStr),
        volume: r.read<double>('volume'),
      );
    }).toList();
    
    return samples;
  }

  /// Atomically updates a historical workout by:
  ///   1. Updating the session row (name, totalVolumeKg, synced).
  ///   2. Deleting all existing workout_exercises and workout_sets.
  ///   3. Re-inserting exercises and sets from the current state.
  ///   4. Re-running PR detection.
  Future<void> updateHistoricalWorkout(ActiveWorkoutState state) async {
    final sessionId = state.originalSessionId!;

    return transaction(() async {
      // 1. Fetch existing session to preserve startedAt / endedAt
      final existing = await getSession(sessionId);

      // 2. Calculate total volume from completed sets
      double totalVolume = 0;
      for (final ex in state.exercises) {
        for (final set in ex.sets) {
          if (set.isCompleted) {
            totalVolume += set.weightKg * set.reps;
          }
        }
      }

      // 3. Update session — only mutable fields
      await (update(workoutSessions)
            ..where((t) => t.id.equals(sessionId)))
          .write(WorkoutSessionsCompanion(
        name: Value(state.name),
        totalVolumeKg: Value(totalVolume),
        synced: const Value(false),
      ));

      // 4. Delete existing sets first (FK safety), then exercises
      final existingExercises = await getExercisesForSession(sessionId);
      for (final we in existingExercises) {
        await (delete(workoutSets)
              ..where((t) => t.workoutExerciseId.equals(we.id)))
            .go();
      }
      await (delete(workoutExercises)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();

      // 5. Re-insert exercises and sets from current state
      final exercisesToSave = state.exercises
          .where((ex) => ex.sets.any((s) => s.isCompleted))
          .toList();

      for (final exEntry in exercisesToSave.asMap().entries) {
        final exIndex = exEntry.key;
        final exercise = exEntry.value;

        final workoutExerciseId = const Uuid().v4();
        await insertWorkoutExercise(
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
            await insertSet(
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

      // 6. Recalculate PRs against history prior to this session
      await detectAndMarkPrs(sessionId, existing.startedAt);
    });
  }
}
