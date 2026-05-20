import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables/routines_table.dart';
import '../tables/routine_days_table.dart';
import '../tables/routine_exercises_table.dart';

part 'routines_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutineDays, RoutineExercises])
class RoutinesDao extends DatabaseAccessor<AppDatabase>
    with _$RoutinesDaoMixin {
  RoutinesDao(super.db);

  // Routines
  Future<List<Routine>> getRoutinesForUser(String userId) =>
      (select(routines)..where((t) => t.userId.equals(userId))).get();

  Future<Routine> getRoutine(String id) =>
      (select(routines)..where((t) => t.id.equals(id))).getSingle();

  Future<void> insertRoutine(RoutinesCompanion routine) =>
      into(routines).insert(routine);

  Future<void> updateRoutine(RoutinesCompanion routine) =>
      update(routines).replace(routine);

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

  Future<void> saveWorkoutAsRoutine(String userId, String routineName, List<int> exerciseIds) async {
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

      for (int i = 0; i < exerciseIds.length; i++) {
        await insertRoutineExercise(RoutineExercisesCompanion.insert(
          id: Value(const Uuid().v4()),
          routineDayId: dayId,
          exerciseId: exerciseIds[i],
          orderIndex: i,
        ));
      }
    });
  }
}
