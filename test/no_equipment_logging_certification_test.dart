import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/core/services/workout_export_service.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> mockStorage;
  late WorkoutDraftStore store;
  late AppDatabase db;

  setUp(() {
    mockStorage = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(mockStorage);
    SharedPreferences.setMockInitialValues({});
    store = WorkoutDraftStore(const FlutterSecureStorage());
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ATOMIC-RC3-06 No-Equipment Logging End-to-End Certification', () {
    test(
        'Logs push-up and pull-up exercises without weight and exports cleanly',
        () async {
      // 1. Seed database with standard no-equipment and weighted exercises
      await db.exercisesDao.insertExercises([
        ExercisesCompanion.insert(
          id: const drift.Value(1),
          name: 'Push Up',
          bodyPart: 'chest',
          equipment: 'bodyweight',
          target: 'pectorals',
          measurementType: const drift.Value('reps_only'),
        ),
        ExercisesCompanion.insert(
          id: const drift.Value(2),
          name: 'Assisted Pull-up',
          bodyPart: 'back',
          equipment: 'assisted',
          target: 'lats',
          measurementType: const drift.Value('weight_and_reps'),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);

      // 2. Start a workout session with Push Up (no-equipment) and Assisted Pull-up (weighted)
      const pushUpEx = WorkoutExerciseState(
        id: 'we-pushup',
        exerciseId: 1,
        name: 'Push Up',
        measurementType: 'reps_only',
        sets: [
          WorkoutSetState(
              id: 's-pushup-1', weightKg: null, reps: 15, isCompleted: false),
        ],
      );

      const pullupEx = WorkoutExerciseState(
        id: 'we-pullup',
        exerciseId: 2,
        name: 'Assisted Pull-up',
        measurementType: 'weight_and_reps',
        sets: [
          WorkoutSetState(
              id: 's-pullup-1', weightKg: 20.0, reps: 8, isCompleted: false),
        ],
      );

      await notifier.startWorkout(
        name: 'Bodyweight & Machine Session',
        initialExercises: [pushUpEx, pullupEx],
      );

      // 3. Mark the sets as completed
      notifier.replaceSet(pushUpEx.id, pushUpEx.sets[0].id,
          pushUpEx.sets[0].copyWith(isCompleted: true));
      notifier.replaceSet(pullupEx.id, pullupEx.sets[0].id,
          pullupEx.sets[0].copyWith(isCompleted: true));

      // 4. Finish the workout session
      final prList = await notifier.finishWorkout();
      expect(prList, isNotNull);

      // 5. Verify the data saved in the database
      final sessions = await db.workoutsDao.getSessionsForUser('');
      expect(sessions.length, 1);

      final savedWorkout = await db.workoutsDao
          .getHydratedWorkout(sessions.first.id, userId: '');
      expect(savedWorkout, isNotNull);
      expect(savedWorkout!.exercises.length, 2);

      final savedPushup =
          savedWorkout.exercises.firstWhere((e) => e.exerciseMetadata.id == 1);
      expect(savedPushup.exerciseMetadata.measurementType, 'reps_only');
      expect(savedPushup.sets.first.weightKg, isNull);
      expect(savedPushup.sets.first.reps, 15);

      final savedPullup =
          savedWorkout.exercises.firstWhere((e) => e.exerciseMetadata.id == 2);
      expect(savedPullup.exerciseMetadata.measurementType, 'weight_and_reps');
      expect(savedPullup.sets.first.weightKg, 20.0);
      expect(savedPullup.sets.first.reps, 8);

      // 6. Export the workout and verify the CSV layout
      final exportService = WorkoutExportService(db);
      final csvContent = await exportService.buildCsv('');
      expect(csvContent, isNotNull);

      // CSV columns should be present, and push-up weight should be empty (null)
      final lines = csvContent.split('\n');
      expect(lines.length, greaterThan(2));

      // The header should be the first line
      final header = lines.first;
      expect(header.contains('weight_kg'), isTrue);

      // Verify the push-up row has empty weight field
      final pushupCsvRow = lines.firstWhere((l) => l.contains('Push Up'));
      final pushupFields = pushupCsvRow.split(',');
      // Find the index of the weight_kg column in the header
      final headerFields = header.split(',');
      final weightIndex = headerFields.indexOf('weight_kg');
      expect(weightIndex, greaterThan(-1));
      expect(pushupFields[weightIndex].trim(), isEmpty);

      // Verify the pull-up row has correct weight
      final pullupCsvRow =
          lines.firstWhere((l) => l.contains('Assisted Pull-up'));
      final pullupFields = pullupCsvRow.split(',');
      expect(double.parse(pullupFields[weightIndex].trim()), 20.0);
    });
  });
}
