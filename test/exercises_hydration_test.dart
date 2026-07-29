import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ATOMIC-RC3-04 Exercises Hydration Engine v9', () {
    test('1. Runs hydration and converts raw types when v9 key is missing',
        () async {
      // Seed initial SharedPreferences with an old hydration key
      SharedPreferences.setMockInitialValues({
        'exercises_hydrated_v8': true,
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('exercises_hydrated_v9'), isNull);

      // Initially DB has no exercises
      var exercises = await db.exercisesDao.getAllExercises();
      expect(exercises.isEmpty, isTrue);

      // Run hydration
      await db.exercisesDao.hydrateFromJson();

      // DB should now be seeded
      exercises = await db.exercisesDao.getAllExercises();
      expect(exercises.isNotEmpty, isTrue);

      // Verify that specific exercises are mapped correctly
      final pushUp =
          exercises.firstWhere((e) => e.name.toLowerCase() == 'push up');
      expect(pushUp.measurementType, MeasurementType.repsOnly.raw);

      // Verify 4-digit zero-padded GitHub raw GIF URL
      expect(pushUp.gifUrl,
          contains('raw.githubusercontent.com/atharvoid/gymlog-assets/main/'));
      final gifFilename = pushUp.gifUrl!.split('/').last;
      expect(gifFilename, matches(r'^\d{4}\.gif$'));

      final plank =
          exercises.firstWhere((e) => e.name.toLowerCase().contains('plank'));
      expect(plank.measurementType, MeasurementType.duration.raw);

      final bench = exercises
          .firstWhere((e) => e.name.toLowerCase() == 'bench press (barbell)');
      expect(bench.measurementType, MeasurementType.weightAndReps.raw);

      // SharedPreferences should have exercises_hydrated_v9 set to true
      expect(prefs.getBool('exercises_hydrated_v9'), isTrue);
      // exercises_hydrated_v8 should be removed
      expect(prefs.getBool('exercises_hydrated_v8'), isNull);
    });

    test('2. Skips hydration if exercises_hydrated_v9 is already true',
        () async {
      SharedPreferences.setMockInitialValues({
        'exercises_hydrated_v9': true,
      });

      // DB should not be populated when running hydration since key says it's done
      await db.exercisesDao.hydrateFromJson();

      final exercises = await db.exercisesDao.getAllExercises();
      expect(exercises.isEmpty, isTrue);
    });

    test('3. seedDefaultExercises runs the resolver and seeds correctly',
        () async {
      await db.exercisesDao.seedDefaultExercises();

      final exercises = await db.exercisesDao.getAllExercises();
      expect(exercises.length, 10);

      final pullup = exercises.firstWhere((e) => e.name == 'Pull-up');
      expect(pullup.measurementType, MeasurementType.repsOnly.raw);

      final bench =
          exercises.firstWhere((e) => e.name == 'Barbell Bench Press');
      expect(bench.measurementType, MeasurementType.weightAndReps.raw);
    });
  });
}
