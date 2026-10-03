import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/routines/domain/ai_import_models.dart';

void main() {
  late AppDatabase db;
  const userId = 'user-ai-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertCatalogExercise(String name, String bodyPart) async {
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
      name: name,
      bodyPart: bodyPart,
      equipment: 'barbell',
      target: bodyPart,
    ));
    final all = await db.exercisesDao.getAllExercises();
    return all.firstWhere((e) => e.name == name).id;
  }

  test(
      'saveReconciledRoutine atomically saves routine and creates custom exercises',
      () async {
    final benchId = await insertCatalogExercise('Barbell Bench Press', 'chest');

    final routine = ReconciledRoutine(
      routineName: 'Push & Novel Movements',
      days: [
        ReconciledDay(
          dayName: 'Day 1 - Push',
          exercises: [
            ReconciledExercise(
              rawName: 'Barbell Bench Press',
              matchedExerciseId: benchId,
              matchedExerciseName: 'Barbell Bench Press',
              status: ReconciliationStatus.verified,
              sets: 4,
              defaultReps: 8,
              defaultWeightKg: 80.0,
            ),
            const ReconciledExercise(
              rawName: 'Tibialis Anterior Bar Raise',
              matchedExerciseId: null, // Unmatched -> will be created as custom
              status: ReconciliationStatus.unmatched,
              sets: 3,
              defaultReps: 15,
              matchedEquipment: 'barbell',
              matchedBodyPart: 'lower legs',
            ),
          ],
        ),
      ],
    );

    final routineId = await db.routinesDao.saveReconciledRoutine(
      userId: userId,
      routine: routine,
    );

    expect(routineId, isNotEmpty);

    // 1. Verify custom exercise was created in exercises table
    final allExercises = await db.exercisesDao.getAllExercises(userId: userId);
    final custom =
        allExercises.firstWhere((e) => e.name == 'Tibialis Anterior Bar Raise');
    expect(custom.isCustom, true);
    expect(custom.createdBy, userId);
    expect(custom.equipment, 'barbell');
    expect(custom.bodyPart, 'lower legs');

    // 2. Verify routine detail is hydrated completely
    final detail = await db.routinesDao.getHydratedRoutineDetail(routineId);
    expect(detail, isNotNull);
    expect(detail!.routine.name, 'Push & Novel Movements');
    expect(detail.exercises.length, 2);

    expect(detail.exercises[0].exercise.name, 'Barbell Bench Press');
    expect(detail.exercises[0].config.defaultSets, 4);
    expect(detail.exercises[0].config.defaultReps, 8);
    expect(detail.exercises[0].config.defaultWeightKg, 80.0);

    expect(detail.exercises[1].exercise.name, 'Tibialis Anterior Bar Raise');
    expect(detail.exercises[1].config.defaultSets, 3);
    expect(detail.exercises[1].config.defaultReps, 15);
  });

  test('saveReconciledRoutine handles multi-day routines preserving day order',
      () async {
    final squatId = await insertCatalogExercise('Barbell Squat', 'legs');
    final rowId = await insertCatalogExercise('Barbell Row', 'back');

    final multiDayRoutine = ReconciledRoutine(
      routineName: 'Upper / Lower',
      days: [
        ReconciledDay(
          dayName: 'Day 1 - Upper',
          exercises: [
            ReconciledExercise(
              rawName: 'Barbell Row',
              matchedExerciseId: rowId,
              status: ReconciliationStatus.verified,
              sets: 3,
            ),
          ],
        ),
        ReconciledDay(
          dayName: 'Day 2 - Lower',
          exercises: [
            ReconciledExercise(
              rawName: 'Barbell Squat',
              matchedExerciseId: squatId,
              status: ReconciliationStatus.verified,
              sets: 4,
            ),
          ],
        ),
      ],
    );

    final routineId = await db.routinesDao.saveReconciledRoutine(
      userId: userId,
      routine: multiDayRoutine,
    );

    final days = await db.routinesDao.getDaysForRoutine(routineId);
    expect(days.length, 2);
    expect(days[0].name, 'Day 1 - Upper');
    expect(days[0].orderIndex, 0);
    expect(days[1].name, 'Day 2 - Lower');
    expect(days[1].orderIndex, 1);

    final day1Exercises = await db.routinesDao.getExercisesForDay(days[0].id);
    expect(day1Exercises.length, 1);
    expect(day1Exercises[0].exerciseId, rowId);

    final day2Exercises = await db.routinesDao.getExercisesForDay(days[1].id);
    expect(day2Exercises.length, 1);
    expect(day2Exercises[0].exerciseId, squatId);
  });
}
