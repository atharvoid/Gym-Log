// Proves the custom-exercise reconciliation: duplicate customs are merged into
// the catalog (with workout history re-pointed) and remaining "other" customs
// are re-tagged with the correct muscle split.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  const userId = 'user-1';

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    }
  });

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> seedCatalog(String name, String equipment) async {
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
      name: name,
      bodyPart: 'chest',
      equipment: equipment,
      target: 'Chest',
      secondaryMuscles: const Value('["Triceps","Shoulders"]'),
    ));
    final all = await db.exercisesDao.getAllExercises();
    return all.firstWhere((e) => e.name == name).id;
  }

  test('merges duplicate customs and re-tags "other" customs', () async {
    // Catalog: two equipment variants → movement family {bench press} has 2.
    final dumbbellId = await seedCatalog('Bench Press (Dumbbell)', 'Dumbbell');
    await seedCatalog('Bench Press (Barbell)', 'Barbell');

    // A duplicate custom (same name as the dumbbell catalog entry) + history.
    final dupCustom = await db.exercisesDao
        .createCustomExercise('Bench Press (Dumbbell)', userId: userId);
    const sessionId = 's1';
    const weId = 'we1';
    await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
        id: const Value(sessionId),
        userId: userId,
        startedAt: DateTime(2026, 1, 1),
        endedAt: Value(DateTime(2026, 1, 1, 1))));
    await db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
        id: const Value(weId),
        sessionId: sessionId,
        exerciseId: dupCustom,
        orderIndex: 0));
    await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
        workoutExerciseId: weId,
        exerciseId: dupCustom,
        orderIndex: 0,
        weightKg: 50,
        reps: 5));

    // An "other" custom whose movement family is ambiguous (2 catalog entries)
    // so it can't be merged — it must be re-tagged instead.
    final machineCustom = await db.exercisesDao
        .createCustomExercise('Bench Press (Machine)', userId: userId);

    final res = await db.exercisesDao.reconcileCustomExercises();

    expect(res.merged, 1, reason: 'the duplicate custom should merge');
    expect(res.retagged, 1, reason: 'the machine custom should be re-tagged');

    // Duplicate custom is gone; its history points at the catalog exercise.
    final all = await db.exercisesDao.getAllExercises();
    expect(all.any((e) => e.id == dupCustom), isFalse);
    final sets = await db.select(db.workoutSets).get();
    expect(sets.single.exerciseId, dumbbellId);

    // The machine custom survived but is no longer "other".
    final machine = all.firstWhere((e) => e.id == machineCustom);
    expect(machine.target, 'Chest');
    expect(machine.bodyPart, 'chest');

    // Nothing in the DB is left tagged "other".
    expect(all.where((e) => e.target.toLowerCase() == 'other'), isEmpty);
  });
}
