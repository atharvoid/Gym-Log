import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercise_analytics_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, User, Session, AuthState;

class MockAuthRepository extends AuthRepository {
  MockAuthRepository(super._client);
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signOut() async {}
  @override
  User? get currentUser => null;
  @override
  Session? get currentSession => null;
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

class SynchronousStream<T> extends Stream<T> {
  final T value;
  SynchronousStream(this.value);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onData?.call(value);
    return StreamController<T>().stream.listen(null);
  }
}

void main() {
  late AppDatabase db;
  late SupabaseClient supabaseClient;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    supabaseClient = SupabaseClient('https://example.com', 'key');
    mockAuthRepository = MockAuthRepository(supabaseClient);
  });

  tearDown(() async {
    supabaseClient.auth.stopAutoRefresh();
    await db.close();
  });

  testWidgets('worked-muscle chips distinguish primary and secondary targets',
      (tester) async {
    const dummyExercise = Exercise(
      id: 42,
      name: 'Bench Press Test',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      target: 'Chest',
      secondaryMuscles: '["Triceps", "Shoulders"]',
      isCustom: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          databaseProvider.overrideWithValue(db),
          exerciseAnalyticsProvider((42, '6M'))
              .overrideWith((ref) => Stream.value(<ExerciseHistoryData>[])),
        ],
        child: const MaterialApp(
          home: ExerciseDetailScreen(
            exerciseId: 42,
            exercise: dummyExercise,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final chestChipFinder = find
        .ancestor(
          of: find.text('Chest'),
          matching: find.byType(Container),
        )
        .first;

    final tricepsChipFinder = find
        .ancestor(
          of: find.text('Triceps'),
          matching: find.byType(Container),
        )
        .first;

    final chestContainer = tester.widget<Container>(chestChipFinder);
    final tricepsContainer = tester.widget<Container>(tricepsChipFinder);

    final chestDeco = chestContainer.decoration as BoxDecoration;
    final tricepsDeco = tricepsContainer.decoration as BoxDecoration;

    // Primary chip must be tinted with accent (not surface3)
    expect(chestDeco.color, isNot(tricepsDeco.color));

    // Assert primary has accent-derived border
    final chestBorder = chestDeco.border as Border;
    final tricepsBorder = tricepsDeco.border as Border;
    expect(chestBorder.top.color, isNot(tricepsBorder.top.color));
  });

  testWidgets('stat toggles enforce >=48dp touch constraints', (tester) async {
    const dummyExercise = Exercise(
      id: 42,
      name: 'Bench Press Test',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      target: 'Chest',
      isCustom: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          databaseProvider.overrideWithValue(db),
          exerciseAnalyticsProvider((42, '6M'))
              .overrideWith((ref) => Stream.value(<ExerciseHistoryData>[])),
        ],
        child: const MaterialApp(
          home: ExerciseDetailScreen(
            exerciseId: 42,
            exercise: dummyExercise,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final toggleContainerFinder = find
        .ancestor(
          of: find.text('Heaviest Weight'),
          matching: find.byType(Container),
        )
        .at(1); // The outer container

    final container = tester.widget<Container>(toggleContainerFinder);
    expect(container.constraints?.minHeight, greaterThanOrEqualTo(48.0));
  });

  testWidgets('analytics-error retry invalidates and recovers', (tester) async {
    const dummyExercise = Exercise(
      id: 42,
      name: 'Bench Press Test',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      target: 'Chest',
      isCustom: false,
    );

    var analyticsCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          databaseProvider.overrideWithValue(db),
          exerciseAnalyticsProvider((42, '6M')).overrideWith((ref) {
            analyticsCalls++;
            if (analyticsCalls == 1) {
              return Stream.error(Exception('Failed to load'));
            } else {
              return Stream.value([
                ExerciseHistoryData(
                  date: DateTime(2026, 6, 1),
                  weight: 100.0,
                  estimated1RM: 120.0,
                  bestSetWeight: 100.0,
                  volume: 500.0,
                  reps: 5,
                )
              ]);
            }
          }),
        ],
        child: const MaterialApp(
          home: ExerciseDetailScreen(
            exerciseId: 42,
            exercise: dummyExercise,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify error state is shown
    expect(find.byType(AsyncErrorState), findsOneWidget);
    expect(find.text('Failed to load analytics'), findsOneWidget);

    // Tap retry
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    // Verify recovery and successful data display
    expect(find.byType(AsyncErrorState), findsNothing);
    expect(find.text('Personal Records'), findsOneWidget);
    expect(find.text('100.0 kg'), findsOneWidget);
  });

  testWidgets(
      'motion collapses to zero (immediate value 1.0) under disableAnimations',
      (tester) async {
    const dummyExercise = Exercise(
      id: 42,
      name: 'Bench Press Test',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      target: 'Chest',
      isCustom: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          databaseProvider.overrideWithValue(db),
          exerciseAnalyticsProvider((42, '6M')).overrideWith(
              (ref) => SynchronousStream(<ExerciseHistoryData>[])),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: ExerciseDetailScreen(
              exerciseId: 42,
              exercise: dummyExercise,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Find the entry FadeTransition and assert its value is 1.0 immediately
    final fadeFinder = find
        .descendant(
          of: find.byType(ExerciseDetailScreen),
          matching: find.byType(FadeTransition),
        )
        .first;

    final fadeWidget = tester.widget<FadeTransition>(fadeFinder);
    expect(fadeWidget.opacity.value, 1.0);
  });
}
