import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables/routines_table.dart';
import '../tables/routine_days_table.dart';
import '../tables/routine_exercises_table.dart';
import 'workouts_dao.dart';

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

  /// Resolves exercise names and IDs for every routine in one reactive stream.
  Stream<List<HydratedRoutine>> watchHydratedRoutinesForUser(String userId) {
    return watchRoutinesForUser(userId).asyncMap((routineList) async {
      final result = <HydratedRoutine>[];
      for (final routine in routineList) {
        final hydrated = await _hydrateRoutine(routine);
        result.add(hydrated);
      }
      return result;
    });
  }

  /// Reactive stream of a single hydrated routine by ID.
  Stream<HydratedRoutine?> watchHydratedRoutine(String routineId) {
    return (select(routines)..where((t) => t.id.equals(routineId)))
        .watchSingleOrNull()
        .asyncMap((routine) async {
      if (routine == null) return null;
      return _hydrateRoutine(routine);
    });
  }

  /// Reactive stream of a single routine with full exercise metadata + config.
  Stream<HydratedRoutineDetail?> watchHydratedRoutineDetail(String routineId) {
    return (select(routines)..where((t) => t.id.equals(routineId)))
        .watchSingleOrNull()
        .asyncMap((routine) async {
      if (routine == null) return null;
      return getHydratedRoutineDetail(routineId);
    });
  }

  Future<HydratedRoutineDetail?> getHydratedRoutineDetail(
      String routineId) async {
    final routine = await (select(routines)
          ..where((t) => t.id.equals(routineId)))
        .getSingleOrNull();
    if (routine == null) return null;

    final days = await getDaysForRoutine(routineId);
    final exercises = <HydratedRoutineExercise>[];

    for (final day in days) {
      final routineExercises = await getExercisesForDay(day.id);
      for (final re in routineExercises) {
        final exercise = await db.exercisesDao.getExerciseById(re.exerciseId);
        exercises.add(HydratedRoutineExercise(
          exercise: exercise,
          config: re,
        ));
      }
    }

    return HydratedRoutineDetail(
      routine: routine,
      exercises: exercises,
    );
  }

  Future<HydratedRoutine> _hydrateRoutine(Routine routine) async {
    final days = await getDaysForRoutine(routine.id);
    final names = <String>[];
    final ids = <int>[];
    final tags = <String>{}; // LinkedHashSet — preserves first-seen order
    for (final day in days) {
      final routineExercises = await getExercisesForDay(day.id);
      for (final re in routineExercises) {
        final exercise = await db.exercisesDao.getExerciseById(re.exerciseId);
        names.add(exercise.name);
        ids.add(exercise.id);
        if (exercise.bodyPart.isNotEmpty) {
          tags.add(_titleCase(exercise.bodyPart));
        }
      }
    }

    // Latest completed session date for the "Last trained …" label.
    final lastTrained =
        await db.workoutsDao.lastTrainedForRoutine(routine.id);

    return HydratedRoutine(
      routine: routine,
      exerciseNames: names,
      exerciseIds: ids,
      muscleTags: tags.toList(),
      lastTrained: lastTrained,
    );
  }

  Future<Routine> getRoutine(String id) =>
      (select(routines)..where((t) => t.id.equals(id))).getSingle();

  Future<void> insertRoutine(RoutinesCompanion routine) =>
      into(routines).insert(routine);

  Future<void> updateRoutine(RoutinesCompanion routine) =>
      update(routines).replace(routine);

  /// Renames a routine (targeted update — preserves all other columns + FKs).
  Future<void> renameRoutine(String id, String name) {
    return (update(routines)..where((t) => t.id.equals(id)))
        .write(RoutinesCompanion(
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteRoutine(String id) =>
      (delete(routines)..where((t) => t.id.equals(id))).go();

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

  Future<void> saveWorkoutAsRoutine(String userId, String routineName,
      List<HydratedWorkoutExercise> exercises) async {
    return transaction(() async {
      final routineId = const Uuid().v4();
      final now = DateTime.now();
      await insertRoutine(RoutinesCompanion.insert(
        id: Value(routineId),
        userId: userId,
        name: routineName,
        createdAt: now,
        updatedAt: now,
      ));

      final dayId = const Uuid().v4();
      await insertDay(RoutineDaysCompanion.insert(
        id: Value(dayId),
        routineId: routineId,
        name: 'Day 1',
        orderIndex: 0,
      ));

      for (int i = 0; i < exercises.length; i++) {
        final ex = exercises[i];
        final setsCount = ex.sets.length;
        int? defaultReps;
        double? defaultWeightKg;

        if (setsCount > 0) {
          defaultReps = ex.sets.first.reps;
          defaultWeightKg = ex.sets.first.weightKg;
        }

        await insertRoutineExercise(RoutineExercisesCompanion.insert(
          id: Value(const Uuid().v4()),
          routineDayId: dayId,
          exerciseId: ex.exerciseMetadata.id,
          orderIndex: i,
          defaultSets: Value(setsCount > 0 ? setsCount : 3),
          defaultReps: Value(defaultReps),
          defaultWeightKg: Value(defaultWeightKg),
        ));
      }
    });
  }
}
