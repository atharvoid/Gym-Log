import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/domain/workout_save_result.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingWorkoutsDao extends WorkoutsDao {
  FailingWorkoutsDao(super.db);

  bool shouldFail = false;

  @override
  Future<void> insertSession(dynamic companion) async {
    if (shouldFail) {
      throw Exception('Simulated database write error');
    }
    return super.insertSession(companion);
  }

  @override
  Future<void> updateHistoricalWorkout(ActiveWorkoutState state) async {
    if (shouldFail) {
      throw Exception('Simulated database edit error');
    }
    return super.updateHistoricalWorkout(state);
  }
}

class TestFailingDatabase extends AppDatabase {
  late final FailingWorkoutsDao failingWorkoutsDao;

  TestFailingDatabase() : super.forTesting(NativeDatabase.memory()) {
    failingWorkoutsDao = FailingWorkoutsDao(this);
  }

  @override
  FailingWorkoutsDao get workoutsDao => failingWorkoutsDao;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> mockStorage;
  late WorkoutDraftStore store;
  late TestFailingDatabase db;

  Future<void> seedExercise(int id, String name) async {
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: Value(id),
            name: name,
            bodyPart: 'Chest',
            equipment: 'Barbell',
            target: 'Chest',
            secondaryMuscles: const Value('[]'),
            isCustom: const Value(false),
            measurementType: const Value('weight_and_reps'),
          ),
        );
  }

  setUp(() async {
    mockStorage = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(mockStorage);
    SharedPreferences.setMockInitialValues({});
    store = WorkoutDraftStore(const FlutterSecureStorage());
    db = TestFailingDatabase();

    // Perform migrations/setup if needed, but forTesting already initializes schema.
  });

  tearDown(() async {
    await db.close();
  });

  group('ATOMIC-RC3-01 Persistence Fail Closed Suite', () {
    test('1. Transaction failure retains state and draft', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await seedExercise(101, 'Bench Press');
      await notifier.startWorkout(
        name: 'My Custom Workout',
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Bench Press',
            sets: [
              WorkoutSetState(
                  id: 's-1', weightKg: 80, reps: 8, isCompleted: true),
            ],
          ),
        ],
      );

      // Force save failure
      db.failingWorkoutsDao.shouldFail = true;

      final result = await notifier.finishWorkout(name: 'My Custom Workout');

      expect(result, isA<WorkoutSaveFailure>());
      // Active workout state must NOT be null
      expect(container.read(activeWorkoutProvider), isNotNull);
      expect(container.read(activeWorkoutProvider)!.name, 'My Custom Workout');

      // Verify that draft store still contains the draft
      final draft = await store.load();
      expect(draft, isNotNull);
      expect(draft!.name, 'My Custom Workout');
    });

    test('2. Successful save clears state and draft', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await seedExercise(101, 'Bench Press');
      await notifier.startWorkout(
        name: 'Success Workout',
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Bench Press',
            sets: [
              WorkoutSetState(
                  id: 's-1', weightKg: 80, reps: 8, isCompleted: true),
            ],
          ),
        ],
      );

      // Ensure success
      db.failingWorkoutsDao.shouldFail = false;

      final result = await notifier.finishWorkout(name: 'Success Workout');

      expect(result, isA<WorkoutSaveSuccess>());
      // Active workout state must be cleared
      expect(container.read(activeWorkoutProvider), looksLikeNull);

      // Verify draft is cleared
      final draft = await store.load();
      expect(draft, isNull);
    });

    test('3. Edited-workout failure retains state', () async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);

      // Seed a session into database manually first
      const sessionId = 'historical-session-123';
      await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: const Value(sessionId),
              userId: 'user-1',
              name: const Value('Old Workout Name'),
              startedAt: DateTime.now(),
              endedAt: Value(DateTime.now()),
              totalVolumeKg: const Value(0.0),
            ),
          );

      // Load for editing
      final historicalWorkout = HydratedWorkout(
        session: await db.workoutsDao.getSession(sessionId),
        exercises: const [],
      );
      notifier.loadForEdit(historicalWorkout);

      // Ensure loaded
      expect(container.read(activeWorkoutProvider), isNotNull);
      expect(
          container.read(activeWorkoutProvider)!.originalSessionId, sessionId);

      // Force save failure
      db.failingWorkoutsDao.shouldFail = true;

      final result = await notifier.saveEditedWorkout();

      expect(result, isA<WorkoutSaveFailure>());
      // Edit state must NOT be cleared on failure
      expect(container.read(activeWorkoutProvider), isNotNull);
      expect(
          container.read(activeWorkoutProvider)!.originalSessionId, sessionId);
    });
  });
}

const Matcher looksLikeNull = _LooksLikeNull();

class _LooksLikeNull extends Matcher {
  const _LooksLikeNull();
  @override
  bool matches(dynamic item, Map matchState) => item == null;
  @override
  Description describe(Description description) => description.add('null');
}
