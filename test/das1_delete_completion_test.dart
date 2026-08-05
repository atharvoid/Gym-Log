import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/account_deletion_service.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthState, Session, SupabaseClient, User;

class _MockAuthRepository extends AuthRepository {
  _MockAuthRepository(super._client);

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

class _StubDeletionService extends AccountDeletionService {
  _StubDeletionService(super.db, super.client, this._outcome);

  final AccountDeletionOutcome Function() _outcome;

  @override
  Future<AccountDeletionOutcome> deleteAccount() async => _outcome();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DAS-1 Delete Account Completion Honesty', () {
    late AppDatabase db;
    late SupabaseClient supabaseClient;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      supabaseClient = SupabaseClient('https://example.com', 'key');
    });

    tearDown(() async {
      supabaseClient.auth.stopAutoRefresh();
      await db.close();
    });

    Future<void> pumpScreen(
      WidgetTester tester, {
      required AccountDeletionOutcome outcome,
    }) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DeleteAccountScreen(),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('AuthScreen'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
                _MockAuthRepository(supabaseClient)),
            authProvider.overrideWithValue(null),
            databaseProvider.overrideWithValue(db),
            accountDeletionServiceProvider.overrideWithValue(
              _StubDeletionService(db, () => supabaseClient, () => outcome),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountScreen), findsOneWidget);

      await tester.dragUntilVisible(
        find.byType(TextField),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Delete my account permanently'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.text('Delete my account permanently'));
      await tester.pumpAndSettle();
    }

    testWidgets('full success shows permanent-deletion copy and routes to auth',
        (tester) async {
      await pumpScreen(
        tester,
        outcome: const AccountDeletionOutcome(
          cloudPurged: true,
          authUserDeleted: true,
          localWiped: true,
        ),
      );

      expect(find.textContaining('permanently deleted'), findsOneWidget);
      expect(find.text('AuthScreen'), findsOneWidget);
    });

    testWidgets(
        'cloud-failure deletion shows honest partial copy, not success',
        (tester) async {
      await pumpScreen(
        tester,
        outcome: const AccountDeletionOutcome(
          cloudPurged: false,
          authUserDeleted: false,
          localWiped: true,
        ),
      );

      expect(find.textContaining('permanently deleted'), findsNothing);
      expect(
        find.textContaining('some cloud data could not be removed'),
        findsOneWidget,
      );
      expect(find.text('AuthScreen'), findsOneWidget);
    });

    testWidgets('local-wipe failure stays on screen and offers retry',
        (tester) async {
      await pumpScreen(
        tester,
        outcome: const AccountDeletionOutcome(
          cloudPurged: false,
          authUserDeleted: false,
          localWiped: false,
        ),
      );

      expect(find.textContaining('Deletion failed'), findsOneWidget);
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      expect(find.text('AuthScreen'), findsNothing);
    });
  });
}
