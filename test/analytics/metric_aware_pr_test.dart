import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/models/personal_record.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ATOMIC-07: PersonalRecord Model & Formatters', () {
    test('PersonalRecord backwards compatibility getters', () {
      const pr = PersonalRecord(
        type: PersonalRecordType.estimatedOneRepMax,
        exerciseId: 1,
        exerciseName: 'Bench Press',
        value: 100.0,
        unit: 'kg',
        setId: 'set-1',
        previousValue: 90.0,
      );

      expect(pr.estimated1rm, equals(100.0));
      expect(pr.previousBest1rm, equals(90.0));
      expect(pr.weightKg, equals(100.0));
    });

    test(
        'MeasurementFormatter formats all canonical MeasurementTypes correctly',
        () {
      expect(
        MeasurementFormatter.formatSet(
          measurementType: MeasurementType.weightAndReps,
          weightKg: 80.0,
          reps: 8,
        ),
        equals('80 kg × 8'),
      );

      expect(
        MeasurementFormatter.formatSet(
          measurementType: MeasurementType.repsOnly,
          weightKg: null,
          reps: 12,
        ),
        equals('12 reps'),
      );

      expect(
        MeasurementFormatter.formatSet(
          measurementType: MeasurementType.duration,
          weightKg: null,
          reps: 90,
        ),
        equals('1:30'),
      );

      expect(
        MeasurementFormatter.formatSet(
          measurementType: MeasurementType.distance,
          weightKg: 2400.0, // stored in meters
          reps: 761, // 12:41 in seconds
        ),
        equals('2.4 km · 12:41'),
      );
    });

    test('Null weight never renders 0 kg for reps-only', () {
      final text = MeasurementFormatter.formatSet(
        measurementType: MeasurementType.repsOnly,
        weightKg: null,
        reps: 20,
      );
      expect(text.contains('0 kg'), isFalse);
      expect(text, equals('20 reps'));
    });
  });

  group('ATOMIC-07: PR Detection Engine', () {
    Future<int> insertEx(
        String name, String equipment, String measurementType) async {
      await db.exercisesDao.insertExercise(ExercisesCompanion(
        name: Value(name),
        bodyPart: const Value('Chest'),
        equipment: Value(equipment),
        target: const Value('Pectorals'),
        measurementType: Value(measurementType),
      ));
      final all = await db.exercisesDao.getAllExercises();
      return all.firstWhere((e) => e.name == name).id;
    }

    test('Detects weighted e1RM PRs and Max Weight PRs', () async {
      final exerciseId =
          await insertEx('Bench Press', 'Barbell', 'weight_and_reps');

      // Session 1: 80kg x 5 (e1RM = 80 * (1 + 5/30) = 93.33)
      final s1Start = DateTime(2026, 6, 1, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s1'),
              userId: 'user1',
              startedAt: s1Start,
              endedAt: Value(s1Start.add(const Duration(minutes: 45))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we1'),
              sessionId: 's1',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set1'),
              workoutExerciseId: 'we1',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(80.0),
              reps: 5,
            ),
          );

      final prs1 = await db.workoutsDao.detectAndMarkPrs('s1', s1Start);
      expect(prs1.isNotEmpty, isTrue);
      expect(prs1.first.type, equals(PersonalRecordType.estimatedOneRepMax));
      expect(prs1.first.value, closeTo(93.33, 0.1));

      // Session 2: 90kg x 5 (e1RM = 105.0) -> New e1RM PR
      final s2Start = DateTime(2026, 6, 2, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s2'),
              userId: 'user1',
              startedAt: s2Start,
              endedAt: Value(s2Start.add(const Duration(minutes: 45))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we2'),
              sessionId: 's2',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set2'),
              workoutExerciseId: 'we2',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(90.0),
              reps: 5,
            ),
          );

      final prs2 = await db.workoutsDao.detectAndMarkPrs('s2', s2Start);
      expect(prs2.isNotEmpty, isTrue);
      expect(prs2.first.value, closeTo(105.0, 0.1));
      expect(prs2.first.previousValue, closeTo(93.33, 0.1));
    });

    test('Detects Reps-Only PRs correctly', () async {
      final exerciseId = await insertEx('Push Ups', 'Bodyweight', 'reps_only');

      final s1Start = DateTime(2026, 6, 1, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s1'),
              userId: 'user1',
              startedAt: s1Start,
              endedAt: Value(s1Start.add(const Duration(minutes: 30))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we1'),
              sessionId: 's1',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set1'),
              workoutExerciseId: 'we1',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              reps: 20,
            ),
          );

      final prs1 = await db.workoutsDao.detectAndMarkPrs('s1', s1Start);
      expect(prs1.length, equals(1));
      expect(prs1.first.type, equals(PersonalRecordType.maxReps));
      expect(prs1.first.value, equals(20.0));
    });

    test('Detects Duration PRs correctly', () async {
      final exerciseId = await insertEx('Plank', 'Bodyweight', 'duration');

      final s1Start = DateTime(2026, 6, 1, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s1'),
              userId: 'user1',
              startedAt: s1Start,
              endedAt: Value(s1Start.add(const Duration(minutes: 30))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we1'),
              sessionId: 's1',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set1'),
              workoutExerciseId: 'we1',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              reps: 90, // 90 seconds
            ),
          );

      final prs1 = await db.workoutsDao.detectAndMarkPrs('s1', s1Start);
      expect(prs1.length, equals(1));
      expect(prs1.first.type, equals(PersonalRecordType.maxDuration));
      expect(prs1.first.value, equals(90.0));
    });

    test('Assisted exercises do not award max weight PR for higher assistance',
        () async {
      final exerciseId =
          await insertEx('Assisted Dip', 'Assisted', 'weight_and_reps');

      final s1Start = DateTime(2026, 6, 1, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s1'),
              userId: 'user1',
              startedAt: s1Start,
              endedAt: Value(s1Start.add(const Duration(minutes: 30))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we1'),
              sessionId: 's1',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set1'),
              workoutExerciseId: 'we1',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(40.0),
              reps: 10,
            ),
          );
      await db.workoutsDao.detectAndMarkPrs('s1', s1Start);

      // Session 2: Log set with 50kg assistance (MORE assistance / easier) x 10 reps
      final s2Start = DateTime(2026, 6, 2, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s2'),
              userId: 'user1',
              startedAt: s2Start,
              endedAt: Value(s2Start.add(const Duration(minutes: 30))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we2'),
              sessionId: 's2',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set2'),
              workoutExerciseId: 'we2',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(50.0),
              reps: 10,
            ),
          );

      final prs2 = await db.workoutsDao.detectAndMarkPrs('s2', s2Start);
      // Higher assistance must NOT be awarded as a max weight PR!
      expect(prs2.any((p) => p.type == PersonalRecordType.maxWeight), isFalse);
      expect(prs2.any((p) => p.type == PersonalRecordType.estimatedOneRepMax),
          isFalse);
    });

    test('recalculateAllPrs is idempotent and preserves chronological history',
        () async {
      final exerciseId = await insertEx('Squat', 'Barbell', 'weight_and_reps');

      final s1Start = DateTime(2026, 6, 1, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s1'),
              userId: 'user1',
              startedAt: s1Start,
              endedAt: Value(s1Start.add(const Duration(minutes: 45))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we1'),
              sessionId: 's1',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set1'),
              workoutExerciseId: 'we1',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(100.0),
              reps: 5,
            ),
          );

      await db.workoutsDao.detectAndMarkPrs('s1', s1Start);

      // Run recalculateAllPrs multiple times
      await db.workoutsDao.recalculateAllPrs();
      await db.workoutsDao.recalculateAllPrs();

      final sets = await (db.select(db.workoutSets)
            ..where((t) => t.id.equals('set1')))
          .get();
      expect(sets.first.isPr, isTrue);
    });

    test('Editing or deleting a PR recalculates later history', () async {
      final exerciseId =
          await insertEx('Deadlift', 'Barbell', 'weight_and_reps');

      // Session 1: 150kg x 5 -> PR
      final s1Start = DateTime(2026, 6, 1, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s1'),
              userId: 'user1',
              startedAt: s1Start,
              endedAt: Value(s1Start.add(const Duration(minutes: 45))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we1'),
              sessionId: 's1',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set1'),
              workoutExerciseId: 'we1',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(150.0),
              reps: 5,
            ),
          );
      await db.workoutsDao.detectAndMarkPrs('s1', s1Start);

      // Session 2: 140kg x 5 -> Not a PR
      final s2Start = DateTime(2026, 6, 2, 10, 0);
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value('s2'),
              userId: 'user1',
              startedAt: s2Start,
              endedAt: Value(s2Start.add(const Duration(minutes: 45))),
            ),
          );
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: const Value('we2'),
              sessionId: 's2',
              exerciseId: exerciseId,
              orderIndex: 0,
            ),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: const Value('set2'),
              workoutExerciseId: 'we2',
              exerciseId: exerciseId,
              orderIndex: 0,
              setType: const Value('normal'),
              weightKg: const Value(140.0),
              reps: 5,
            ),
          );
      await db.workoutsDao.detectAndMarkPrs('s2', s2Start);

      final setsBeforeDelete = await (db.select(db.workoutSets)
            ..where((t) => t.id.equals('set2')))
          .get();
      expect(setsBeforeDelete.first.isPr, isFalse);

      // Delete session 1 (which contained the 150kg PR)
      await db.workoutsDao.deleteSession('s1');

      // Now session 2's set2 should be recalculated as the new PR!
      final setsAfterDelete = await (db.select(db.workoutSets)
            ..where((t) => t.id.equals('set2')))
          .get();
      expect(setsAfterDelete.first.isPr, isTrue);
    });
  });
}
