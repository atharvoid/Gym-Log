// CSV export tests against a real in-memory SQLite database.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/services/workout_export_service.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  late WorkoutExportService service;
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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = WorkoutExportService(db);
  });

  tearDown(() => db.close());

  Future<int> insertExercise(
    String name, {
    String measurementType = 'weight_and_reps',
  }) async {
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
      name: name,
      bodyPart: 'pectorals',
      equipment: 'barbell',
      target: 'pectorals',
      measurementType: Value(measurementType),
    ));
    final all = await db.exercisesDao.getAllExercises();
    return all.firstWhere((e) => e.name == name).id;
  }

  Future<void> insertSession({
    required String id,
    required String? name,
    required DateTime startedAt,
    DateTime? endedAt,
    required int exerciseId,
    required List<(double?, int)> sets,
  }) async {
    await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
          id: Value(id),
          userId: userId,
          name: Value(name),
          startedAt: startedAt,
          endedAt: Value(endedAt),
        ));
    final weId = '$id-we-0';
    await db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
          id: Value(weId),
          sessionId: id,
          exerciseId: exerciseId,
          orderIndex: 0,
        ));
    for (var i = 0; i < sets.length; i++) {
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            workoutExerciseId: weId,
            exerciseId: exerciseId,
            orderIndex: i,
            weightKg: Value(sets[i].$1),
            reps: sets[i].$2,
          ));
    }
  }

  test('exports v2 schema with 20 columns for completed sessions only',
      () async {
    final benchId = await insertExercise('Barbell Bench Press');

    await insertSession(
      id: 's-done',
      name: 'Morning Workout',
      startedAt: DateTime.utc(2026, 6, 1, 8, 30),
      endedAt: DateTime.utc(2026, 6, 1, 9, 15),
      exerciseId: benchId,
      sets: [(80.0, 8), (82.5, 6)],
    );
    // In-progress session must be excluded.
    await insertSession(
      id: 's-active',
      name: 'Abandoned',
      startedAt: DateTime.utc(2026, 6, 2, 18, 0),
      endedAt: null,
      exerciseId: benchId,
      sets: [(100.0, 1)],
    );

    final csv = await service.buildCsv(userId);
    final lines = csv.trim().split('\n');

    expect(lines.first, WorkoutExportService.csvHeader);
    expect(lines.length, 3, reason: 'header + 2 completed sets only');

    final set1 = lines[1].split(',');
    expect(set1[0], '2'); // gymlog_schema_version
    expect(set1[1], 's-done'); // workout_id
    expect(set1[2], 'Morning Workout'); // workout_name
    expect(set1[3], '2026-06-01T08:30:00.000Z'); // workout_started_at
    expect(set1[4], '2026-06-01T09:15:00.000Z'); // workout_ended_at
    expect(set1[7], 'Barbell Bench Press'); // exercise_name
    expect(set1[8], 'weight_and_reps'); // measurement_type
    expect(set1[9], '0'); // set_index
    expect(set1[10], 'normal'); // set_type
    expect(set1[11], '80'); // weight_kg
    expect(set1[12], '8'); // reps
    expect(set1[16], 'false'); // is_pr
    expect(set1[17], 'none'); // pr_type

    expect(csv, isNot(contains('Abandoned')));
  });

  test('escapes commas and quotes per RFC 4180', () async {
    final id = await insertExercise('Squat, High-Bar "ATG"');
    await insertSession(
      id: 's-1',
      name: 'Leg, Day',
      startedAt: DateTime.utc(2026, 6, 3, 7, 0),
      endedAt: DateTime.utc(2026, 6, 3, 8, 0),
      exerciseId: id,
      sets: [(120.0, 5)],
    );

    final csv = await service.buildCsv(userId);
    expect(csv, contains('"Leg, Day"'));
    expect(csv, contains('"Squat, High-Bar ""ATG"""'));
  });

  test('field escaping + number formatting helpers', () {
    expect(WorkoutExportService.escapeCsvField('plain'), 'plain');
    expect(WorkoutExportService.escapeCsvField('a,b'), '"a,b"');
    expect(WorkoutExportService.escapeCsvField('say "hi"'), '"say ""hi"""');
    expect(WorkoutExportService.formatNumber(80.0), '80');
    expect(WorkoutExportService.formatNumber(82.5), '82.5');
  });

  test('empty database exports header only', () async {
    final csv = await service.buildCsv(userId);
    expect(csv.trim(), WorkoutExportService.csvHeader);
  });
}
