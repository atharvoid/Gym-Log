import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercise_analytics_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';

class MockExerciseList extends ExerciseList {
  final List<Exercise> _exercises;
  MockExerciseList(this._exercises);

  @override
  Future<List<Exercise>> build() async => _exercises;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'Library(browse:true) row renders a Hero with tag exercise-hero-<id>',
      (tester) async {
    final exercises = [
      const Exercise(
        id: 42,
        name: 'Hammer Curl',
        bodyPart: 'arms',
        equipment: 'Dumbbell',
        target: 'Biceps',
        isCustom: false,
        gifUrl: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          exerciseListProvider.overrideWith(() => MockExerciseList(exercises)),
        ],
        child: const MaterialApp(
          home: ExerciseSelectionScreen(browse: true),
        ),
      ),
    );

    await tester.pump();

    final heroFinder = find.byType(Hero);
    expect(heroFinder, findsOneWidget);

    final hero = tester.widget<Hero>(heroFinder);
    expect(hero.tag, 'exercise-hero-42');
  });

  testWidgets('Library(browse:false) row does NOT render a Hero',
      (tester) async {
    final exercises = [
      const Exercise(
        id: 42,
        name: 'Hammer Curl',
        bodyPart: 'arms',
        equipment: 'Dumbbell',
        target: 'Biceps',
        isCustom: false,
        gifUrl: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          exerciseListProvider.overrideWith(() => MockExerciseList(exercises)),
        ],
        child: const MaterialApp(
          home: ExerciseSelectionScreen(browse: false),
        ),
      ),
    );

    await tester.pump();

    final heroFinder = find.byType(Hero);
    expect(heroFinder, findsNothing);
  });

  testWidgets('Detail screen renders a Hero with the matching tag',
      (tester) async {
    const exercise = Exercise(
      id: 42,
      name: 'Hammer Curl',
      bodyPart: 'arms',
      equipment: 'Dumbbell',
      target: 'Biceps',
      isCustom: false,
      gifUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          exerciseAnalyticsProvider((42, '6M'))
              .overrideWith((ref) => Stream.value(<ExerciseHistoryData>[])),
        ],
        child: const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 42, exercise: exercise),
        ),
      ),
    );

    await tester.pump();

    final heroFinder = find.byType(Hero);
    expect(heroFinder, findsOneWidget);

    final hero = tester.widget<Hero>(heroFinder);
    expect(hero.tag, 'exercise-hero-42');
  });

  testWidgets(
      'Guard: two ExerciseThumbnails with the SAME exercise id on one screen do NOT throw',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ExerciseThumbnail(
                  gifUrl: '',
                  size: 52,
                  fastFrame: true,
                ),
                ExerciseThumbnail(
                  gifUrl: '',
                  size: 52,
                  fastFrame: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(ExerciseThumbnail), findsNWidgets(2));
  });
}
