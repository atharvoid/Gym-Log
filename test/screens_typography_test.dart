import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/screens/auth_screen.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:gymlog/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:gymlog/features/import/presentation/screens/import_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercise_analytics_provider.dart';
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

  testWidgets('AuthScreen renders without exceptions and key text is present',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    expect(find.text('GymLog'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets(
      'ExerciseDetailScreen renders without exceptions and key text is present',
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

    expect(find.text('Bench Press Test'), findsAtLeast(1));
    expect(find.text('Barbell'), findsOneWidget);
  });

  testWidgets(
      'DeleteAccountScreen renders without exceptions and key text is present',
      (tester) async {
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
          databaseProvider.overrideWithValue(db),
          accountDeletionServiceProvider.overrideWithValue(
              MockAccountDeletionService(db, supabaseClient)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('This is permanent'), findsOneWidget);
  });

  testWidgets('ImportScreen renders without exceptions and key text is present',
      (tester) async {
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
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    expect(find.text('Import workouts'), findsOneWidget);
    expect(find.text('Bring your history with you'), findsOneWidget);
  });
}
