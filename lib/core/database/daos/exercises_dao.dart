import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase> with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<Exercise> getExerciseById(int id) =>
      (select(exercises)..where((t) => t.id.equals(id))).getSingle();

  Future<List<Exercise>> searchExercises(String query) =>
      (select(exercises)..where((t) => t.name.like('%$query%'))).get();

  Future<List<Exercise>> filterByBodyPart(String bodyPart) =>
      (select(exercises)..where((t) => t.bodyPart.equals(bodyPart))).get();

  Future<List<Exercise>> filterByEquipment(String equipment) =>
      (select(exercises)..where((t) => t.equipment.equals(equipment))).get();

  Future<void> insertExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);

  Future<void> insertExercises(List<ExercisesCompanion> list) =>
      batch((b) => b.insertAll(exercises, list));

  Future<int> getExerciseCount() =>
      (select(exercises).get()).then((rows) => rows.length);

  Future<void> seedDefaultExercises() async {
    final existing = await getAllExercises();
    if (existing.isNotEmpty) return;

    await insertExercises([
      ExercisesCompanion.insert(
        name: 'Barbell Bench Press',
        bodyPart: 'chest',
        equipment: 'barbell',
        target: 'pectorals',
      ),
      ExercisesCompanion.insert(
        name: 'Barbell Squat',
        bodyPart: 'upper legs',
        equipment: 'barbell',
        target: 'quadriceps',
      ),
      ExercisesCompanion.insert(
        name: 'Deadlift',
        bodyPart: 'back',
        equipment: 'barbell',
        target: 'spine',
      ),
      ExercisesCompanion.insert(
        name: 'Pull-up',
        bodyPart: 'back',
        equipment: 'body weight',
        target: 'lats',
      ),
      ExercisesCompanion.insert(
        name: 'Overhead Press',
        bodyPart: 'shoulders',
        equipment: 'barbell',
        target: 'delts',
      ),
      ExercisesCompanion.insert(
        name: 'Dumbbell Lateral Raise',
        bodyPart: 'shoulders',
        equipment: 'dumbbell',
        target: 'delts',
      ),
      ExercisesCompanion.insert(
        name: 'Tricep Pushdown',
        bodyPart: 'upper arms',
        equipment: 'cable',
        target: 'triceps',
      ),
      ExercisesCompanion.insert(
        name: 'Bicep Curl',
        bodyPart: 'upper arms',
        equipment: 'dumbbell',
        target: 'biceps',
      ),
      ExercisesCompanion.insert(
        name: 'Leg Press',
        bodyPart: 'upper legs',
        equipment: 'machine',
        target: 'quadriceps',
      ),
      ExercisesCompanion.insert(
        name: 'Romanian Deadlift',
        bodyPart: 'upper legs',
        equipment: 'barbell',
        target: 'hamstrings',
      ),
    ]);
  }
}
