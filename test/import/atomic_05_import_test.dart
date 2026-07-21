import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/import/data/workout_csv_parser.dart';
import 'package:gymlog/features/import/data/workout_import_service.dart';
import 'package:sqlite3/open.dart';

void main() {
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

  group('ATOMIC-05 Section A: Flexible Decimal Parsing', () {
    test('47,5 → 47.5', () {
      expect(WorkoutCsvParser.parseFlexibleDecimal('47,5'), 47.5);
    });

    test('1.234,5 → 1234.5', () {
      expect(WorkoutCsvParser.parseFlexibleDecimal('1.234,5'), 1234.5);
    });

    test('1,234.5 → 1234.5', () {
      expect(WorkoutCsvParser.parseFlexibleDecimal('1,234.5'), 1234.5);
    });

    test('1 234,5 → 1234.5', () {
      expect(WorkoutCsvParser.parseFlexibleDecimal('1 234,5'), 1234.5);
    });

    test('empty string or whitespace → null', () {
      expect(WorkoutCsvParser.parseFlexibleDecimal(''), isNull);
      expect(WorkoutCsvParser.parseFlexibleDecimal('   '), isNull);
    });

    test('NaN / Infinity → null', () {
      expect(WorkoutCsvParser.parseFlexibleDecimal('NaN'), isNull);
      expect(WorkoutCsvParser.parseFlexibleDecimal('Infinity'), isNull);
    });
  });

  group('ATOMIC-05 Section B, C, D, E & F: Metric-Aware Import Suite', () {
    late AppDatabase db;
    late WorkoutImportService service;
    const userId = 'user-test-05';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = WorkoutImportService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Hevy bodyweight row without weight parses as repsOnly', () {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"\n'
          '"Bodyweight Day","10 Jul 2025, 08:00","Push Up",0,"normal",,15';

      final result = WorkoutCsvParser.parse(csv);
      expect(result.sessions.length, 1);
      final set = result.sessions.single.exercises.single.sets.single;
      expect(set.reps, 15);
      expect(set.weightKg, isNull);
      expect(set.measurementType, MeasurementType.repsOnly);
    });

    test('Strong bodyweight row without weight parses as repsOnly', () {
      const csv =
          'Date;Workout Name;Exercise Name;Set Order;Weight;Weight Unit;Reps\n'
          '2025-07-10 08:00:00;Bodyweight Day;Pull Up;1;;kg;12';

      final result = WorkoutCsvParser.parse(csv);
      expect(result.sessions.length, 1);
      final set = result.sessions.single.exercises.single.sets.single;
      expect(set.reps, 12);
      expect(set.weightKg, isNull);
      expect(set.measurementType, MeasurementType.repsOnly);
    });

    test('weighted row parses weightAndReps', () {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"\n'
          '"Chest Day","10 Jul 2025, 08:00","Bench Press",0,"normal",100,8';

      final result = WorkoutCsvParser.parse(csv);
      expect(result.sessions.length, 1);
      final set = result.sessions.single.exercises.single.sets.single;
      expect(set.weightKg, 100.0);
      expect(set.reps, 8);
      expect(set.measurementType, MeasurementType.weightAndReps);
    });

    test('duration row parses duration', () {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps","duration_seconds"\n'
          '"Core Day","10 Jul 2025, 08:00","Plank",0,"normal",,,60';

      final result = WorkoutCsvParser.parse(csv);
      expect(result.sessions.length, 1);
      final set = result.sessions.single.exercises.single.sets.single;
      expect(set.durationSeconds, 60);
      expect(set.measurementType, MeasurementType.duration);
    });

    test('invalid negative values generate row-specific skip warnings', () {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"\n'
          '"Chest Day","10 Jul 2025, 08:00","Bench Press",0,"normal",100,-5';

      final result = WorkoutCsvParser.parse(csv);
      expect(result.skippedRows, 1);
      expect(result.warnings.length, 1);
      expect(result.warnings.first,
          contains('Row 2 skipped: reps are missing for Bench Press.'));
    });

    test('unknown exercise is resolved and custom exercise is created',
        () async {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"\n'
          '"Custom Day","10 Jul 2025, 08:00","Unicorn Deadlift (Barbell)",0,"normal",120,5';

      final importRes = await service.import(csv, userId: userId);
      expect(importRes.sessionsImported, 1);
      expect(
          importRes.exercisesCreated, contains('Unicorn Deadlift (Barbell)'));

      final exercises = await db.exercisesDao.getAllExercises();
      expect(
          exercises.any((e) => e.name == 'Unicorn Deadlift (Barbell)'), isTrue);
    });

    test('preview reports row warnings correctly', () async {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"\n'
          '"Valid","10 Jul 2025, 08:00","Bench Press",0,"normal",80,8\n'
          '"Invalid","10 Jul 2025, 09:00","Push Up",0,"normal",,';

      final summary = await service.preview(csv, userId: userId);
      expect(
          summary.warnings.any((w) =>
              w.contains('Row 3 skipped: reps are missing for Push Up.')),
          isTrue);
    });

    test('re-importing the same file is idempotent', () async {
      const csv =
          '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"\n'
          '"Idempotency","10 Jul 2025, 08:00","Squat",0,"normal",100,5';

      final firstImport = await service.import(csv, userId: userId);
      expect(firstImport.sessionsImported, 1);
      expect(firstImport.sessionsSkipped, 0);

      final secondImport = await service.import(csv, userId: userId);
      expect(secondImport.sessionsImported, 0);
      expect(secondImport.sessionsSkipped, 1);

      final sessions = await db.workoutsDao.getSessionsForUser(userId);
      expect(sessions.length, 1);
    });
  });
}
