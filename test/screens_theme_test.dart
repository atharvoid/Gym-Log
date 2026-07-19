import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/home/presentation/screens/home_screen.dart';
import 'package:gymlog/features/workout/presentation/screens/workout_detail_screen.dart';
import 'package:gymlog/features/routines/presentation/screens/routine_detail_screen.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_detail_provider.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercise_analytics_provider.dart';
import 'package:gymlog/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:gymlog/features/import/presentation/screens/import_screen.dart';
import 'package:gymlog/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:gymlog/features/routines/presentation/screens/explore_routines_screen.dart';
import 'package:gymlog/core/services/account_deletion_service.dart';
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

class MockAccountDeletionService extends AccountDeletionService {
  MockAccountDeletionService(super.db, super.client);

  @override
  Future<AccountDeletionOutcome> deleteAccount() async {
    return const AccountDeletionOutcome(
      cloudPurged: true,
      authUserDeleted: true,
      localWiped: true,
    );
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

  group('Screens Theme Verification Tests', () {
    testWidgets('HomeScreen renders under multiple accents', (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp(
              theme: buildAppTheme(palette.tokens, palette: palette),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(HomeScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('WorkoutDetailScreen renders under multiple accents',
        (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
              workoutDetailProvider('w123')
                  .overrideWith((ref) => Stream.value(null)),
            ],
            child: MaterialApp(
              theme: buildAppTheme(palette.tokens, palette: palette),
              home: const WorkoutDetailScreen(sessionId: 'w123'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context =
            tester.element(find.byType(WorkoutDetailScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('RoutineDetailScreen renders under multiple accents',
        (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
              routineDetailProvider('r123')
                  .overrideWith((ref) => Stream.value(null)),
            ],
            child: MaterialApp(
              theme: buildAppTheme(palette.tokens, palette: palette),
              home: const RoutineDetailScreen(routineId: 'r123'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context =
            tester.element(find.byType(RoutineDetailScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('ExerciseDetailScreen renders under multiple accents',
        (tester) async {
      const dummyExercise = Exercise(
        id: 42,
        name: 'Bench Press Test',
        bodyPart: 'Chest',
        equipment: 'Barbell',
        target: 'Chest',
        isCustom: false,
        measurementType: 'weight_and_reps',
      );

      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
              exerciseAnalyticsProvider((42, '6M'))
                  .overrideWith((ref) => Stream.value(<ExerciseHistoryData>[])),
            ],
            child: MaterialApp(
              theme: buildAppTheme(palette.tokens, palette: palette),
              home: const ExerciseDetailScreen(
                exerciseId: 42,
                exercise: dummyExercise,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context =
            tester.element(find.byType(ExerciseDetailScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('DeleteAccountScreen renders under multiple accents',
        (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DeleteAccountScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
              accountDeletionServiceProvider.overrideWithValue(
                  MockAccountDeletionService(db, supabaseClient)),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(palette.tokens, palette: palette),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context =
            tester.element(find.byType(DeleteAccountScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('ImportScreen renders under multiple accents', (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ImportScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(palette.tokens, palette: palette),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(ImportScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('ActiveWorkoutScreen renders under multiple accents',
        (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp(
              theme: buildAppTheme(palette.tokens, palette: palette),
              home: const ActiveWorkoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context =
            tester.element(find.byType(ActiveWorkoutScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });

    testWidgets('ExploreRoutinesScreen renders under multiple accents',
        (tester) async {
      for (final palette in [
        ThemePalette.neonPurple,
        ThemePalette.higgsfield
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              authProvider.overrideWithValue(null),
              databaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp(
              theme: buildAppTheme(palette.tokens, palette: palette),
              home: const ExploreRoutinesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context =
            tester.element(find.byType(ExploreRoutinesScreen));
        expect(context.accent.base, palette.tokens.base);
      }
    });
  });
}
