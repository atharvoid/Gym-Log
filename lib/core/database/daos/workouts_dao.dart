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
  final double bestSetWeight;

  const ExerciseHistoryData({
    required this.date,
    required this.weight,
    required this.reps,
    required this.estimated1RM,
    required this.volume,
    required this.bestSetWeight,
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

/// Per-session aggregates for a routine — the TRUE session count (not
/// day-grouped, so two sessions on the same day count as two) plus best and
/// total session volume.
class RoutineSessionStats {
  final int count;
  final double totalVolumeKg;
  final double bestVolumeKg;

  const RoutineSessionStats({
    required this.count,
    required this.totalVolumeKg,
    required this.bestVolumeKg,
  });

  double get avgVolumeKg => count == 0 ? 0 : totalVolumeKg / count;
}

/// A personal record detected at workout finish.
/// Returned by [WorkoutsDao.detectAndMarkPrs] so the UI can celebrate it.
class PrRecord {
  final int exerciseId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double estimated1rm;

  /// The previous best estimated 1RM for this exercise (0 if first ever).
  final double previousBest1rm;

  const PrRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.estimated1rm,
    required this.previousBest1rm,
  });
}

/// Per-session aggregate used by the Profile dashboard chart.
class SessionStat {
  final DateTime date;
  final Duration duration;
  final double volumeKg;
  final int reps;

  const SessionStat({
    required this.date,
    required this.duration,
    required this.volumeKg,
    required this.reps,
  });
}

@DriftAccessor(tables: [WorkoutSessions, WorkoutExercises, WorkoutSets])
class WorkoutsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutsDaoMixin {
  WorkoutsDao(super.db);

  // WorkoutSessions
  Future<WorkoutSession> getSession(String id) =>
      (select(workoutSessions)..where((t) => t.id.equals(id))).getSingle();

  Future<WorkoutSession?> getSessionOrNull(String id) =>
      (select(workoutSessions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  // ── Sync serialization ─────────────────────────────────────────────────────

  /// A self-contained JSON snapshot of a session and ALL its children
  /// (exercises + sets) for cloud sync. Dates are epoch millis. Returns null
  /// if the session no longer exists. No exercise metadata is included — the
  /// catalog is bundled with the app, so only the user's logged data travels.
  Future<Map<String, dynamic>?> exportSessionJson(String sessionId) async {
    final s = await getSessionOrNull(sessionId);
    if (s == null) return null;
    final exs = await (select(workoutExercises)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    final exIds = exs.map((e) => e.id).toList();
    final sets = exIds.isEmpty
        ? <WorkoutSet>[]
        : await (select(workoutSets)
              ..where((t) => t.workoutExerciseId.isIn(exIds)))
            .get();
    return {
      'session': {
        'id': s.id,
        'userId': s.userId,
        'routineId': s.routineId,
        'name': s.name,
        'startedAt': s.startedAt.millisecondsSinceEpoch,
        'endedAt': s.endedAt?.millisecondsSinceEpoch,
        'notes': s.notes,
        'totalVolumeKg': s.totalVolumeKg,
      },
      'exercises': [
        for (final e in exs)
          {
            'id': e.id,
            'sessionId': e.sessionId,
            'exerciseId': e.exerciseId,
            'orderIndex': e.orderIndex,
            'notes': e.notes,
          }
      ],
      'sets': [
        for (final st in sets)
          {
            'id': st.id,
            'workoutExerciseId': st.workoutExerciseId,
            'exerciseId': st.exerciseId,
            'orderIndex': st.orderIndex,
            'setType': st.setType,
            'weightKg': st.weightKg,
            'reps': st.reps,
            'rpe': st.rpe,
            'isPr': st.isPr,
            'estimated1rm': st.estimated1rm,
            'completedAt': st.completedAt?.millisecondsSinceEpoch,
          }
      ],
    };
  }

  /// Rehydrate a session snapshot into local storage (used when restoring
  /// from the cloud — e.g. after a reinstall). Idempotent and replace-based:
  /// the session row is upserted and its children are rebuilt, so re-pulling
  /// the same payload is safe.
  Future<void> importSessionJson(Map<String, dynamic> data) async {
    final sj = data['session'] as Map<String, dynamic>;
    final sessionId = sj['id'] as String;
    DateTime? ms(dynamic v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

    await transaction(() async {
      await into(workoutSessions).insertOnConflictUpdate(
        WorkoutSessionsCompanion.insert(
          id: Value(sessionId),
          userId: sj['userId'] as String,
          routineId: Value(sj['routineId'] as String?),
          name: Value(sj['name'] as String?),
          startedAt: ms(sj['startedAt'])!,
          endedAt: Value(ms(sj['endedAt'])),
          notes: Value(sj['notes'] as String? ?? ''),
          totalVolumeKg: Value((sj['totalVolumeKg'] as num?)?.toDouble() ?? 0),
          synced: const Value(true),
        ),
      );

      // Rebuild children deterministically.
      final existing = await (select(workoutExercises)
            ..where((t) => t.sessionId.equals(sessionId)))
          .get();
      final existingIds = existing.map((e) => e.id).toList();
      if (existingIds.isNotEmpty) {
        await (delete(workoutSets)
              ..where((t) => t.workoutExerciseId.isIn(existingIds)))
            .go();
      }
      await (delete(workoutExercises)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();

      for (final e in (data['exercises'] as List).cast<Map<String, dynamic>>()) {
        await into(workoutExercises).insert(WorkoutExercisesCompanion.insert(
          id: Value(e['id'] as String),
          sessionId: e['sessionId'] as String,
          exerciseId: e['exerciseId'] as int,
          orderIndex: e['orderIndex'] as int,
          notes: Value(e['notes'] as String?),
        ));
      }
      for (final st in (data['sets'] as List).cast<Map<String, dynamic>>()) {
        await into(workoutSets).insert(WorkoutSetsCompanion.insert(
          id: Value(st['id'] as String),
          workoutExerciseId: st['workoutExerciseId'] as String,
          exerciseId: st['exerciseId'] as int,
          orderIndex: st['orderIndex'] as int,
          setType: Value(st['setType'] as String? ?? 'normal'),
          weightKg: (st['weightKg'] as num).toDouble(),
          reps: st['reps'] as int,
          rpe: Value((st['rpe'] as num?)?.toDouble()),
          isPr: Value(st['isPr'] as bool? ?? false),
          estimated1rm: Value((st['estimated1rm'] as num?)?.toDouble()),
          completedAt: Value(ms(st['completedAt'])),
        ));
      }
    });
  }

  Future<List<WorkoutSession>> getSessionsForUser(String userId) =>
      (select(workoutSessions)..where((t) => t.userId.equals(userId))).get();

  Future<void> insertSession(WorkoutSessionsCompanion session) =>
      into(workoutSessions).insert(session);

  Future<void> updateSession(WorkoutSessionsCompanion session) =>
      update(workoutSessions).replace(session);

  /// Deletes a session **and all of its children** atomically.
  ///
  /// workout_sets / workout_exercises reference the session via FKs; deleting
  /// only the parent row would leave orphaned sets that keep polluting PR
  /// detection and exercise history forever.
  Future<void> deleteSession(String id) {
    return transaction(() async {
      await customUpdate(
        'DELETE FROM workout_sets WHERE workout_exercise_id IN '
        '(SELECT id FROM workout_exercises WHERE session_id = ?)',
        variables: [Variable.withString(id)],
        updates: {workoutSets},
        updateKind: UpdateKind.delete,
      );
      await (delete(workoutExercises)..where((t) => t.sessionId.equals(id)))
          .go();
      await (delete(workoutSessions)..where((t) => t.id.equals(id))).go();
    });
  }

  Stream<int> watchWorkoutCountForUser(String userId) {
    final count = workoutSessions.id.count();
    final query = selectOnly(workoutSessions)
      ..addColumns([count])
      ..where(workoutSessions.userId.equals(userId) &
          workoutSessions.endedAt.isNotNull());
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Stream<List<WorkoutSession>> watchSessionsForUser(String userId) {
    return (select(workoutSessions)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  /// Emits whenever anything in the workout tables changes for this user.
  /// Drives the HomeScreen feed so it reloads reactively — no manual
  /// invalidation signals needed after finishing / editing / deleting.
  Stream<void> watchHistoryRevision(String userId) {
    return customSelect(
      'SELECT COUNT(*) AS c FROM workout_sessions WHERE user_id = ?',
      variables: [Variable.withString(userId)],
      readsFrom: {workoutSessions, workoutExercises, workoutSets},
    ).watch().map((_) {});
  }

  /// Start dates of every completed session, newest first.
  /// Day-grouping happens in Dart so streaks respect the local time zone.
  Stream<List<DateTime>> watchCompletedSessionDates(String userId) {
    final query = selectOnly(workoutSessions)
      ..addColumns([workoutSessions.startedAt])
      ..where(workoutSessions.userId.equals(userId) &
          workoutSessions.endedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(workoutSessions.startedAt)]);
    return query.watch().map(
        (rows) => rows.map((r) => r.read(workoutSessions.startedAt)!).toList());
  }

  /// Most recently trained exercise ids, newest first — powers the
  /// "Recent" section at the top of the exercise library.
  Stream<List<int>> watchRecentExerciseIds(String userId, {int limit = 8}) {
    return customSelect(
      '''
      SELECT we.exercise_id, MAX(s.started_at) AS last_used
      FROM workout_exercises we
      JOIN workout_sessions s ON s.id = we.session_id
      WHERE s.user_id = ? AND s.ended_at IS NOT NULL
      GROUP BY we.exercise_id
      ORDER BY last_used DESC
      LIMIT ?
      ''',
      variables: [Variable.withString(userId), Variable.withInt(limit)],
      readsFrom: {workoutSessions, workoutExercises},
    )
        .watch()
        .map((rows) => rows.map((r) => r.read<int>('exercise_id')).toList());
  }

  /// Per-session (date, duration, volume, reps) for the Profile chart.
  Stream<List<SessionStat>> watchSessionStatsForUser(
    String userId, {
    DateTime? since,
  }) {
    final sinceClause = since != null ? ' AND s.started_at >= ?' : '';
    return customSelect(
      '''
      SELECT s.started_at, s.ended_at, s.total_volume_kg,
        COALESCE((SELECT SUM(ws.reps)
                  FROM workout_sets ws
                  JOIN workout_exercises we ON ws.workout_exercise_id = we.id
                  WHERE we.session_id = s.id), 0) AS total_reps
      FROM workout_sessions s
      WHERE s.user_id = ? AND s.ended_at IS NOT NULL$sinceClause
      ORDER BY s.started_at ASC
      ''',
      variables: [
        Variable.withString(userId),
        if (since != null) Variable.withDateTime(since),
      ],
      readsFrom: {workoutSessions, workoutExercises, workoutSets},
    ).watch().map((rows) => rows.map((r) {
          final start = r.read<DateTime>('started_at');
          final end = r.read<DateTime>('ended_at');
          return SessionStat(
            date: start,
            duration: end.difference(start),
            volumeKg: r.read<double>('total_volume_kg'),
            reps: r.read<int>('total_reps'),
          );
        }).toList());
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

  /// All sets of a session in ONE query, grouped by workout_exercise id.
  Future<Map<String, List<WorkoutSet>>> _getSetsForSession(
      String sessionId) async {
    final rows = await (select(workoutSets).join([
      innerJoin(
        workoutExercises,
        workoutExercises.id.equalsExp(workoutSets.workoutExerciseId),
      ),
    ])
          ..where(workoutExercises.sessionId.equals(sessionId))
          ..orderBy([OrderingTerm.asc(workoutSets.orderIndex)]))
        .get();

    final map = <String, List<WorkoutSet>>{};
    for (final row in rows) {
      final set = row.readTable(workoutSets);
      map.putIfAbsent(set.workoutExerciseId, () => []).add(set);
    }
    return map;
  }

  /// Returns the ordered sets from the **most recent completed session**
  /// (excluding [currentSessionId]) in which [exerciseId] was logged.
  ///
  /// Returns an empty list when this is the exercise's first appearance,
  /// so callers can hide the "VS PREV" column rather than show blanks.
  Future<List<WorkoutSet>> getPreviousSessionSets(
    int exerciseId,
    String currentSessionId,
  ) async {
    final map = await getPreviousSessionSetsBatch(
      [exerciseId],
      currentSessionId,
    );
    return map[exerciseId] ?? const [];
  }

  /// Previous-session sets for MANY exercises in a single query.
  ///
  /// For each exercise id, finds its most recent completed session (excluding
  /// [currentSessionId]) and returns that session's ordered sets. One SQL
  /// round-trip total — this used to be 3 queries *per exercise*.
  Future<Map<int, List<WorkoutSet>>> getPreviousSessionSetsBatch(
    List<int> exerciseIds,
    String currentSessionId,
  ) async {
    if (exerciseIds.isEmpty) return {};
    final placeholders = List.filled(exerciseIds.length, '?').join(',');

    final rows = await customSelect(
      '''
      SELECT cur.ex_id AS for_exercise,
             ws.id, ws.workout_exercise_id, ws.exercise_id, ws.order_index,
             ws.set_type, ws.weight_kg, ws.reps, ws.rpe, ws.is_pr,
             ws.estimated1rm, ws.completed_at
      FROM (SELECT DISTINCT exercise_id AS ex_id FROM workout_exercises
            WHERE exercise_id IN ($placeholders)) AS cur
      JOIN workout_exercises we
        ON we.exercise_id = cur.ex_id
       AND we.session_id = (
            SELECT s.id
            FROM workout_sessions s
            JOIN workout_exercises we2
              ON we2.session_id = s.id AND we2.exercise_id = cur.ex_id
            WHERE s.id != ? AND s.ended_at IS NOT NULL
            ORDER BY s.started_at DESC
            LIMIT 1)
      JOIN workout_sets ws ON ws.workout_exercise_id = we.id
      ORDER BY cur.ex_id, ws.order_index ASC
      ''',
      variables: [
        for (final id in exerciseIds) Variable.withInt(id),
        Variable.withString(currentSessionId),
      ],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    final map = <int, List<WorkoutSet>>{};
    for (final r in rows) {
      final forExercise = r.read<int>('for_exercise');
      map.putIfAbsent(forExercise, () => []).add(WorkoutSet(
            id: r.read<String>('id'),
            workoutExerciseId: r.read<String>('workout_exercise_id'),
            exerciseId: r.read<int>('exercise_id'),
            orderIndex: r.read<int>('order_index'),
            setType: r.read<String>('set_type'),
            weightKg: r.read<double>('weight_kg'),
            reps: r.read<int>('reps'),
            rpe: r.read<double?>('rpe'),
            isPr: r.read<bool>('is_pr'),
            // NB: drift's snake_case mapping does NOT split before digits —
            // the generated column is `estimated1rm`, not `estimated_1rm`.
            estimated1rm: r.read<double?>('estimated1rm'),
            completedAt: r.read<DateTime?>('completed_at'),
          ));
    }
    return map;
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
    final rows = await _lastSessionSetsForRoutineQuery(
      routineId: routineId,
      userId: userId,
    ).get();
    return _mapLastSessionRows(rows);
  }

  /// Reactive version of [getLastSessionSetsForRoutine] — re-emits whenever
  /// workout data changes so the Routine Detail set tables never go stale.
  Stream<Map<String, List<LastSessionSetData>>> watchLastSessionSetsForRoutine({
    required String routineId,
    required String userId,
  }) {
    return _lastSessionSetsForRoutineQuery(routineId: routineId, userId: userId)
        .watch()
        .map(_mapLastSessionRows);
  }

  Selectable<QueryRow> _lastSessionSetsForRoutineQuery({
    required String routineId,
    required String userId,
  }) {
    return customSelect(
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
    );
  }

  Map<String, List<LastSessionSetData>> _mapLastSessionRows(
      List<QueryRow> rows) {
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

  /// Epley one-rep-max estimate.
  /// Guard: at reps <= 1 the formula is undefined or trivially returns weight.
  double _epley(double weight, int reps) {
    if (reps <= 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// SQL mirror of [_epley] over the `workout_sets ws` alias. MUST stay in
  /// sync with the Dart version.
  ///
  /// The `reps <= 1` guard is the whole point: a true 1-rep max IS the weight
  /// lifted, but raw Epley returns `weight × 31/30` (~3.3% high) at 1 rep.
  /// Without this guard the SQL inflated every single-rep set, so a genuine
  /// 1-rep PR could read *lower* than the inflated historical max and never
  /// fire — and the exercise-history "Best 1RM" was overstated. Used by PR
  /// detection ([_getMaxEstimated1rmBefore]) and the strength-trend chart
  /// ([_exerciseHistoryQuery]) so both agree with [_epley] to the decimal.
  static const String _epleySqlWs =
      'ws.weight_kg * (CASE WHEN ws.reps <= 1 THEN 1.0 '
      'ELSE 1.0 + ws.reps / 30.0 END)';

  Future<List<ExerciseHistoryData>> getExerciseHistory(int exerciseId) =>
      _exerciseHistoryQuery(exerciseId, null).get().then(_mapHistoryRows);

  Stream<List<ExerciseHistoryData>> watchExerciseHistory(
    int exerciseId, {
    DateTime? since,
  }) {
    return _exerciseHistoryQuery(exerciseId, since)
        .watch()
        .map(_mapHistoryRows);
  }

  /// NOTE: dates are bound with [Variable.withDateTime] and read back with
  /// `read<DateTime>` so they round-trip through drift's storage format
  /// (unix seconds). Binding ISO strings here silently breaks every
  /// comparison — SQLite orders INTEGER below TEXT, so `int >= 'iso'` is
  /// always false and `int < 'iso'` is always true.
  Selectable<QueryRow> _exerciseHistoryQuery(int exerciseId, DateTime? since) {
    final sinceClause = since != null ? '\n        AND s.started_at >= ?' : '';
    return customSelect(
      '''
      SELECT
        COALESCE(s.ended_at, s.started_at) AS session_date,
        MAX(ws.weight_kg) AS max_weight,
        MAX(ws.reps) AS max_reps,
        MAX($_epleySqlWs) AS best_e1rm,
        SUM(ws.weight_kg * ws.reps) AS total_volume,
        (
          SELECT inner_ws.weight_kg
          FROM workout_sets inner_ws
          JOIN workout_exercises inner_we ON inner_ws.workout_exercise_id = inner_we.id
          WHERE inner_ws.exercise_id = ws.exercise_id
            AND inner_we.session_id = s.id
            AND inner_ws.weight_kg > 0
            AND inner_ws.reps > 0
          ORDER BY (inner_ws.weight_kg * (CASE WHEN inner_ws.reps <= 1 THEN 1.0 ELSE 1.0 + inner_ws.reps / 30.0 END)) DESC
          LIMIT 1
        ) AS best_set_weight
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND ws.weight_kg > 0
        AND ws.reps > 0$sinceClause
      GROUP BY s.id, COALESCE(s.ended_at, s.started_at)
      ORDER BY session_date ASC
      ''',
      variables: [
        Variable.withInt(exerciseId),
        if (since != null) Variable.withDateTime(since),
      ],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    );
  }

  List<ExerciseHistoryData> _mapHistoryRows(List<QueryRow> rows) {
    return rows.map((row) {
      final date = row.read<DateTime>('session_date');
      final weight = row.read<double>('max_weight');
      final reps = row.read<int>('max_reps');
      final volume = row.read<double>('total_volume');
      final best1rm = row.read<double>('best_e1rm');
      final bestSetWeight = row.read<double>('best_set_weight');

      return ExerciseHistoryData(
        date: date,
        weight: weight,
        reps: reps,
        estimated1RM: best1rm,
        volume: volume,
        bestSetWeight: bestSetWeight,
      );
    }).toList();
  }

  /// Fully hydrates a workout in a FIXED number of queries (5), regardless
  /// of how many exercises it contains:
  ///   1. session row
  ///   2. workout_exercises
  ///   3. exercise metadata batch (IN clause)
  ///   4. all sets of the session (single JOIN)
  ///   5. previous-session sets for every exercise (single CTE query)
  Future<HydratedWorkout?> getHydratedWorkout(String sessionId) async {
    final session = await getSessionOrNull(sessionId);
    if (session == null) return null;

    final exercises = await getExercisesForSession(sessionId);
    if (exercises.isEmpty) {
      return HydratedWorkout(session: session, exercises: const []);
    }

    final exerciseIds = exercises.map((e) => e.exerciseId).toSet().toList();

    final metaRows = await (db.select(db.exercises)
          ..where((t) => t.id.isIn(exerciseIds)))
        .get();
    final metaById = {for (final e in metaRows) e.id: e};

    final setsByWorkoutExercise = await _getSetsForSession(sessionId);
    final previousByExercise =
        await getPreviousSessionSetsBatch(exerciseIds, sessionId);

    final hydratedExercises = <HydratedWorkoutExercise>[];
    for (final we in exercises) {
      final meta = metaById[we.exerciseId];
      if (meta == null) continue; // exercise row deleted — skip defensively
      hydratedExercises.add(HydratedWorkoutExercise(
        workoutExercise: we,
        exerciseMetadata: meta,
        sets: setsByWorkoutExercise[we.id] ?? const [],
        previousSets: previousByExercise[we.exerciseId] ?? const [],
      ));
    }

    return HydratedWorkout(session: session, exercises: hydratedExercises);
  }

  // ── Paginated session previews ───────────────────────────────────────────

  /// Returns up to [limit] previews starting at [offset], ordered newest-first.
  /// Pass `limit = pageSize + 1` to detect `hasMore` — caller discards the
  /// extra item and treats `length == limit` as a hasMore signal.
  ///
  /// Runs exactly 3 queries per page (sessions + stats batch + top-exercise
  /// batch) — previously this was ~6 queries *per session card*.
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

    final ids = sessions.map((s) => s.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final idVars = [for (final id in ids) Variable.withString(id)];

    // ── Batch 1: exercise count + PR count per session ─────────────────────
    final statsRows = await customSelect(
      '''
      SELECT we.session_id,
        COUNT(DISTINCT we.id) AS exercise_count,
        COALESCE(SUM(CASE WHEN wset.is_pr = 1 THEN 1 ELSE 0 END), 0) AS pr_count
      FROM workout_exercises we
      LEFT JOIN workout_sets wset ON wset.workout_exercise_id = we.id
      WHERE we.session_id IN ($placeholders)
      GROUP BY we.session_id
      ''',
      variables: idVars,
      readsFrom: {workoutExercises, workoutSets},
    ).get();

    final statsBySession = <String, (int, int)>{
      for (final r in statsRows)
        r.read<String>('session_id'): (
          r.read<int>('exercise_count'),
          r.read<int>('pr_count'),
        ),
    };

    // ── Batch 2: top-2 exercises per session, with name/gif/set count ──────
    final topRows = await customSelect(
      '''
      SELECT we.session_id, we.order_index, e.name, e.gif_url,
        (SELECT COUNT(*) FROM workout_sets ws
         WHERE ws.workout_exercise_id = we.id) AS set_count
      FROM workout_exercises we
      JOIN exercises e ON e.id = we.exercise_id
      WHERE we.session_id IN ($placeholders) AND we.order_index <= 1
      ORDER BY we.session_id, we.order_index ASC
      ''',
      variables: idVars,
      readsFrom: {workoutExercises, workoutSets, db.exercises},
    ).get();

    final topBySession = <String, List<ExercisePreviewItem>>{};
    for (final r in topRows) {
      topBySession
          .putIfAbsent(r.read<String>('session_id'), () => [])
          .add(ExercisePreviewItem(
            exerciseName: r.read<String>('name'),
            gifUrl: r.read<String?>('gif_url'),
            setCount: r.read<int>('set_count'),
          ));
    }

    return [
      for (final session in sessions)
        WorkoutSessionPreview(
          session: session,
          duration: session.endedAt!.difference(session.startedAt),
          totalVolumeKg: session.totalVolumeKg,
          prCount: statsBySession[session.id]?.$2 ?? 0,
          topExercises: topBySession[session.id] ?? const [],
          totalExerciseCount: statsBySession[session.id]?.$1 ?? 0,
        ),
    ];
  }

  // ── PR Detection ──────────────────────────────────────────────────────────

  /// Marks the best-1RM set per exercise in [sessionId] as a PR if it exceeds
  /// the historical max for that exercise across all sessions before
  /// [sessionStart], and returns the list of PRs so the UI can celebrate.
  ///
  /// Epley formula: `estimated1RM = weight × (1 + reps / 30)`
  /// Only the single best set per exercise per session is ever marked.
  Future<List<PrRecord>> detectAndMarkPrs(
    String sessionId,
    DateTime sessionStart,
  ) async {
    final prs = <PrRecord>[];
    try {
      final exercises = await getExercisesForSession(sessionId);
      if (exercises.isEmpty) return prs;

      final setsByWorkoutExercise = await _getSetsForSession(sessionId);

      for (final we in exercises) {
        final sets = setsByWorkoutExercise[we.id] ?? const [];
        final priorMax =
            await _getMaxEstimated1rmBefore(we.exerciseId, sessionStart);

        double sessionBest1rm = 0;
        WorkoutSet? bestSet;

        for (final set in sets) {
          if (set.weightKg > 0 && set.reps > 0) {
            final e1rm = _epley(set.weightKg, set.reps);
            if (e1rm > sessionBest1rm) {
              sessionBest1rm = e1rm;
              bestSet = set;
            }
          }
        }

        if (bestSet != null && sessionBest1rm > priorMax) {
          await (update(workoutSets)..where((t) => t.id.equals(bestSet!.id)))
              .write(WorkoutSetsCompanion(
            isPr: const Value(true),
            estimated1rm: Value(sessionBest1rm),
          ));
          prs.add(PrRecord(
            exerciseId: we.exerciseId,
            exerciseName: '', // filled from batch lookup below
            weightKg: bestSet.weightKg,
            reps: bestSet.reps,
            estimated1rm: sessionBest1rm,
            previousBest1rm: priorMax,
          ));
        }
      }

      if (prs.isEmpty) return prs;

      // Resolve exercise names in one query.
      final nameRows = await (db.select(db.exercises)
            ..where((t) => t.id.isIn(prs.map((p) => p.exerciseId).toList())))
          .get();
      final nameById = {for (final e in nameRows) e.id: e.name};

      return [
        for (final p in prs)
          PrRecord(
            exerciseId: p.exerciseId,
            exerciseName: nameById[p.exerciseId] ?? 'Exercise',
            weightKg: p.weightKg,
            reps: p.reps,
            estimated1rm: p.estimated1rm,
            previousBest1rm: p.previousBest1rm,
          ),
      ];
    } catch (e) {
      if (kDebugMode) debugPrint('[WorkoutsDao] detectAndMarkPrs failed: $e');
      return prs;
    }
  }

  Future<double> _getMaxEstimated1rmBefore(
      int exerciseId, DateTime before) async {
    final rows = await customSelect(
      '''
      SELECT COALESCE(MAX($_epleySqlWs), 0) AS max_1rm
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s   ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND s.ended_at IS NOT NULL
        AND s.started_at < ?
        AND ws.weight_kg > 0
        AND ws.reps > 0
      ''',
      variables: [
        Variable.withInt(exerciseId),
        // Bound as a typed DateTime so it serializes to the same storage
        // format as the column. An ISO-string bind compares INTEGER < TEXT,
        // which is unconditionally true in SQLite — that made priorMax
        // include the CURRENT session, so no PR could ever fire.
        Variable.withDateTime(before),
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

  /// Removes sessions that were started but never finished within 24h,
  /// including any children they may have accumulated.
  Future<void> deleteOrphanedSessions(String userId) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final stale = await (select(workoutSessions)
          ..where((s) =>
              s.userId.equals(userId) &
              s.endedAt.isNull() &
              s.startedAt.isSmallerThanValue(cutoff)))
        .get();
    if (stale.isEmpty) return;

    await transaction(() async {
      for (final session in stale) {
        await deleteSession(session.id);
      }
    });
  }

  // ── Routine Volume History ───────────────────────────────────────────────

  Stream<List<DailyVolumeSample>> watchDailyVolumeForRoutine(
    String routineId, {
    DateTime? since,
  }) {
    final dayExpr = workoutSessions.startedAt.date;
    final volSum = workoutSessions.totalVolumeKg.sum();

    final query = selectOnly(workoutSessions)
      ..addColumns([dayExpr, volSum])
      ..where(workoutSessions.routineId.equals(routineId))
      ..where(workoutSessions.endedAt.isNotNull())
      ..groupBy([dayExpr])
      ..orderBy([OrderingTerm.asc(dayExpr)]);
    if (since != null) {
      query.where(workoutSessions.startedAt.isBiggerOrEqualValue(since));
    }

    return query.watch().map((rows) => rows
        .map((r) => DailyVolumeSample(
              day: DateTime.parse(r.read(dayExpr)!),
              volume: (r.read(volSum) ?? 0).toDouble(),
            ))
        .toList());
  }

  /// TRUE per-session stats for a routine (count / total / best session
  /// volume). Deliberately NOT day-grouped — [watchDailyVolumeForRoutine] groups
  /// by day for the chart trend, but the header's "Sessions" count must reflect
  /// every completed session, so two on the same day are counted as two.
  Stream<RoutineSessionStats> watchRoutineSessionStats(String routineId) {
    final countExpr = workoutSessions.id.count();
    final sumExpr = workoutSessions.totalVolumeKg.sum();
    final maxExpr = workoutSessions.totalVolumeKg.max();

    final query = selectOnly(workoutSessions)
      ..addColumns([countExpr, sumExpr, maxExpr])
      ..where(workoutSessions.routineId.equals(routineId))
      ..where(workoutSessions.endedAt.isNotNull());

    return query.watch().map((rows) {
      final r = rows.isNotEmpty ? rows.first : null;
      return RoutineSessionStats(
        count: r?.read(countExpr) ?? 0,
        totalVolumeKg: r?.read(sumExpr) ?? 0.0,
        bestVolumeKg: r?.read(maxExpr) ?? 0.0,
      );
    });
  }

  /// Most recent COMPLETED session date for a routine — powers the
  /// "Last trained …" label on the routines list. Null if never completed.
  Future<DateTime?> lastTrainedForRoutine(String routineId) async {
    final session = await (select(workoutSessions)
          ..where((t) => t.routineId.equals(routineId) & t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
    return session?.startedAt;
  }

  /// Last-trained dates for MANY routines in one query.
  Future<Map<String, DateTime>> lastTrainedForRoutines(
      List<String> routineIds) async {
    if (routineIds.isEmpty) return {};
    final lastStarted = workoutSessions.startedAt.max();
    final query = selectOnly(workoutSessions)
      ..addColumns([workoutSessions.routineId, lastStarted])
      ..where(workoutSessions.routineId.isIn(routineIds) &
          workoutSessions.endedAt.isNotNull())
      ..groupBy([workoutSessions.routineId]);

    final rows = await query.get();
    return {
      for (final r in rows)
        if (r.read(workoutSessions.routineId) != null &&
            r.read(lastStarted) != null)
          r.read(workoutSessions.routineId)!: r.read(lastStarted)!,
    };
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
      await (update(workoutSessions)..where((t) => t.id.equals(sessionId)))
          .write(WorkoutSessionsCompanion(
        name: Value(state.name),
        totalVolumeKg: Value(totalVolume),
        synced: const Value(false),
      ));

      // 4. Delete existing sets first (FK safety), then exercises
      await customUpdate(
        'DELETE FROM workout_sets WHERE workout_exercise_id IN '
        '(SELECT id FROM workout_exercises WHERE session_id = ?)',
        variables: [Variable.withString(sessionId)],
        updates: {workoutSets},
        updateKind: UpdateKind.delete,
      );
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

        var setIndex = 0;
        for (final set in exercise.sets) {
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
            setIndex++;
          }
        }
      }

      // 6. Recalculate PRs against history prior to this session
      await detectAndMarkPrs(sessionId, existing.startedAt);
    });
  }
}
