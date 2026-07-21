import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/services/workout_export_service.dart';
import 'package:gymlog/features/import/data/workout_csv_parser.dart';
import 'package:gymlog/features/import/data/workout_import_service.dart';
import 'package:gymlog/features/import/domain/import_models.dart';
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

  group('ATOMIC-06: Lossless GymLog v2 Import/Export Round-Trip', () {
    late AppDatabase db;
    late WorkoutExportService exportService;
    const userId = 'user-roundtrip';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      exportService = WorkoutExportService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Round-trip invariant: decode(encode(workout)) preserves full history',
        () async {
      Future<int> insertEx(String name, String bodyPart, String equipment,
          String target, String measurementType) async {
        await db.exercisesDao.insertExercise(ExercisesCompanion(
          name: Value(name),
          bodyPart: Value(bodyPart),
          equipment: Value(equipment),
          target: Value(target),
          measurementType: Value(measurementType),
        ));
        final all = await db.exercisesDao.getAllExercises();
        return all.firstWhere((e) => e.name == name).id;
      }

      final benchId = await insertEx('Barbell Bench Press', 'pectorals',
          'barbell', 'pectorals', 'weight_and_reps');
      final pushupId = await insertEx(
          'Push Up', 'pectorals', 'bodyweight', 'pectorals', 'reps_only');
      final plankId =
          await insertEx('Plank', 'core', 'bodyweight', 'abs', 'duration');

      final startTime = DateTime.utc(2026, 7, 20, 10, 0);
      final endTime = DateTime.utc(2026, 7, 20, 11, 0);
      const sessionId = 'session-rt-1';

      await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
            id: const Value(sessionId),
            userId: userId,
            name: const Value('Full Body Metric Test'),
            startedAt: startTime,
            endedAt: Value(endTime),
            notes: const Value('Felt great today!'),
          ));

      // 1. Bench Press (weight_and_reps)
      const we1 = 'we-1';
      await db
          .into(db.workoutExercises)
          .insert(WorkoutExercisesCompanion.insert(
            id: const Value(we1),
            sessionId: sessionId,
            exerciseId: benchId,
            orderIndex: 0,
            notes: const Value('Pause reps'),
          ));
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            id: const Value('set-1'),
            workoutExerciseId: we1,
            exerciseId: benchId,
            orderIndex: 0,
            setType: const Value(SetTypes.warmup),
            weightKg: const Value(60.0),
            reps: 10,
            rpe: const Value(7.0),
            isPr: const Value(false),
          ));
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            id: const Value('set-2'),
            workoutExerciseId: we1,
            exerciseId: benchId,
            orderIndex: 1,
            setType: const Value(SetTypes.normal),
            weightKg: const Value(100.0),
            reps: 5,
            rpe: const Value(9.5),
            isPr: const Value(true),
            estimated1rm: const Value(116.67),
          ));

      // 2. Push Up (reps_only)
      const we2 = 'we-2';
      await db
          .into(db.workoutExercises)
          .insert(WorkoutExercisesCompanion.insert(
            id: const Value(we2),
            sessionId: sessionId,
            exerciseId: pushupId,
            orderIndex: 1,
          ));
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            id: const Value('set-3'),
            workoutExerciseId: we2,
            exerciseId: pushupId,
            orderIndex: 0,
            setType: const Value(SetTypes.normal),
            weightKg: const Value(null),
            reps: 25,
            isPr: const Value(true),
          ));

      // 3. Plank (duration)
      const we3 = 'we-3';
      await db
          .into(db.workoutExercises)
          .insert(WorkoutExercisesCompanion.insert(
            id: const Value(we3),
            sessionId: sessionId,
            exerciseId: plankId,
            orderIndex: 2,
          ));
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            id: const Value('set-4'),
            workoutExerciseId: we3,
            exerciseId: plankId,
            orderIndex: 0,
            setType: const Value(SetTypes.normal),
            weightKg: const Value(null),
            reps: 90, // 90 seconds
            isPr: const Value(false),
          ));

      // Export
      final exportedCsv = await exportService.buildCsv(userId);
      expect(exportedCsv, contains('gymlog_schema_version'));
      expect(exportedCsv, contains('Full Body Metric Test'));

      // Decode
      final parsed = WorkoutCsvParser.parse(exportedCsv);
      expect(parsed.source, ImportSource.gymlog);
      expect(parsed.sessions.length, 1);

      final s = parsed.sessions.single;
      expect(s.name, 'Full Body Metric Test');
      expect(s.notes, 'Felt great today!');
      expect(s.startedAt.isAtSameMomentAs(startTime), isTrue);
      expect(s.endedAt?.isAtSameMomentAs(endTime), isTrue);
      expect(s.exercises.length, 3);

      // Verify Exercise 1
      final ex1 = s.exercises[0];
      expect(ex1.name, 'Barbell Bench Press');
      expect(ex1.measurementType, MeasurementType.weightAndReps);
      expect(ex1.sets.length, 2);
      expect(ex1.sets[0].setType, SetTypes.warmup);
      expect(ex1.sets[0].weightKg, 60.0);
      expect(ex1.sets[0].reps, 10);
      expect(ex1.sets[1].isPr, isTrue);
      expect(ex1.sets[1].prType, 'estimated_1rm');
      expect(ex1.sets[1].estimated1rm, closeTo(116.67, 0.01));

      // Verify Exercise 2
      final ex2 = s.exercises[1];
      expect(ex2.name, 'Push Up');
      expect(ex2.measurementType, MeasurementType.repsOnly);
      expect(ex2.sets.single.weightKg, isNull);
      expect(ex2.sets.single.reps, 25);
      expect(ex2.sets.single.isPr, isTrue);

      // Verify Exercise 3
      final ex3 = s.exercises[2];
      expect(ex3.name, 'Plank');
      expect(ex3.measurementType, MeasurementType.duration);
      expect(ex3.sets.single.durationSeconds, 90);
      expect(ex3.sets.single.weightKg, isNull);

      // Re-import to a clean DB
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final importService2 = WorkoutImportService(db2);
      final importResult =
          await importService2.import(exportedCsv, userId: 'user-clean');

      expect(importResult.sessionsImported, 1);
      expect(importResult.setsImported, 4);

      final importedSessions =
          await db2.workoutsDao.getSessionsForUser('user-clean');
      expect(importedSessions.length, 1);
      expect(importedSessions.single.name, 'Full Body Metric Test');

      await db2.close();
    });

    test('v1 GymLog CSV remains readable', () {
      const v1Csv =
          'date,workout,exercise,set_number,set_type,weight_kg,reps,rpe,is_pr,estimated_1rm\n'
          '2026-06-01 08:30,Legacy Workout,Bench Press,1,normal,80,8,,false,';

      final result = WorkoutCsvParser.parse(v1Csv);
      expect(result.source, ImportSource.gymlog);
      expect(result.sessions.length, 1);

      final set = result.sessions.single.exercises.single.sets.single;
      expect(set.weightKg, 80.0);
      expect(set.reps, 8);
    });

    test('unsupported future version throws explicit ImportException', () {
      const v3Csv =
          'gymlog_schema_version,workout_id,workout_name,workout_started_at,exercise_name,set_index\n'
          '3,w-1,Future Workout,2026-06-01T08:30:00Z,Squat,0';

      expect(
        () => WorkoutCsvParser.parse(v3Csv),
        throwsA(isA<ImportException>().having((e) => e.message, 'message',
            contains('Unsupported export version: 3.'))),
      );
    });

    test('missing required v2 columns throws explicit ImportException', () {
      const badCsv = 'gymlog_schema_version,workout_id,workout_name\n'
          '2,w-1,Bad Format';

      expect(
        () => WorkoutCsvParser.parse(badCsv),
        throwsA(isA<ImportException>().having((e) => e.message, 'message',
            contains('Invalid GymLog CSV format: missing required column'))),
      );
    });
  });
}
