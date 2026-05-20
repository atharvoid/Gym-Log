import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/workouts_table.dart';

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

  const HydratedWorkoutExercise({
    required this.workoutExercise,
    required this.exerciseMetadata,
    required this.sets,
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

@DriftAccessor(tables: [WorkoutSessions, WorkoutExercises, WorkoutSets])
class WorkoutsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutsDaoMixin {
  WorkoutsDao(super.db);

  // WorkoutSessions
  Future<WorkoutSession> getSession(String id) =>
      (select(workoutSessions)..where((t) => t.id.equals(id))).getSingle();

  Future<List<WorkoutSession>> getSessionsForUser(String userId) =>
      (select(workoutSessions)..where((t) => t.userId.equals(userId)))
          .get();

  Future<void> insertSession(WorkoutSessionsCompanion session) =>
      into(workoutSessions).insert(session);

  Future<void> updateSession(WorkoutSessionsCompanion session) =>
      update(workoutSessions).replace(session);

  Future<void> deleteSession(String id) =>
      (delete(workoutSessions)..where((t) => t.id.equals(id))).go();

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

  Future<void> insertSet(WorkoutSetsCompanion set) =>
      into(workoutSets).insert(set);

  Future<void> updateSet(WorkoutSetsCompanion set) =>
      update(workoutSets).replace(set);

  Future<void> deleteSet(String id) =>
      (delete(workoutSets)..where((t) => t.id.equals(id))).go();

  Future<List<ExerciseHistoryData>> getExerciseHistory(int exerciseId) async {
    final query = '''
      SELECT
        COALESCE(s.ended_at, s.started_at) AS session_date,
        ws.weight_kg,
        ws.reps
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND ws.weight_kg > 0
        AND ws.reps > 0
      ORDER BY session_date ASC
    ''';

    final rows = await customSelect(
      query,
      variables: [Variable.withInt(exerciseId)],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).get();

    return rows.map((row) {
      final date = DateTime.parse(row.read<String>('session_date'));
      final weight = row.read<double>('weight_kg');
      final reps = row.read<int>('reps');
      final estimated1RM = weight * (1 + reps / 30);
      final volume = weight * reps;

      return ExerciseHistoryData(
        date: date,
        weight: weight,
        reps: reps,
        estimated1RM: estimated1RM,
        volume: volume,
      );
    }).toList();
  }

  Stream<List<ExerciseHistoryData>> watchExerciseHistory(int exerciseId) {
    final query = '''
      SELECT
        COALESCE(s.ended_at, s.started_at) AS session_date,
        ws.weight_kg,
        ws.reps
      FROM workout_sets ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      JOIN workout_sessions s ON we.session_id = s.id
      WHERE ws.exercise_id = ?
        AND ws.weight_kg > 0
        AND ws.reps > 0
      ORDER BY session_date ASC
    ''';

    return customSelect(
      query,
      variables: [Variable.withInt(exerciseId)],
      readsFrom: {workoutSets, workoutExercises, workoutSessions},
    ).watch().map((rows) {
      return rows.map((row) {
        final date = DateTime.parse(row.read<String>('session_date'));
        final weight = row.read<double>('weight_kg');
        final reps = row.read<int>('reps');
        final estimated1RM = weight * (1 + reps / 30);
        final volume = weight * reps;

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
      final exerciseRow =
          await db.exercisesDao.getExerciseById(we.exerciseId);

      final sets = await getSetsForExercise(we.id);

      hydratedExercises.add(HydratedWorkoutExercise(
        workoutExercise: we,
        exerciseMetadata: exerciseRow,
        sets: sets,
      ));
    }

    return HydratedWorkout(
      session: session,
      exercises: hydratedExercises,
    );
  }

  Stream<HydratedWorkout?> watchHydratedWorkout(String sessionId) {
    return customSelect(
      'SELECT 1 FROM workout_sessions WHERE id = ?',
      variables: [Variable.withString(sessionId)],
      readsFrom: {workoutSessions, workoutExercises, workoutSets},
    ).watch().asyncMap((_) => getHydratedWorkout(sessionId));
  }
}
