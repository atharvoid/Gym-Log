import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/sign_out_coordinator.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/core/services/sync_entitlement_gate.dart';
import 'package:gymlog/core/services/sync_remote.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoOpRemote implements SyncRemote {
  @override
  Future<List<PushResult>> pushBatch(List<SyncObject> objects) async => [];
  @override
  Future<List<SyncObject>> pull(String userId) async => [];
}

class _ThrowingAuthRepository extends AuthRepository {
  _ThrowingAuthRepository() : super(null);
  @override
  Future<void> signOut() async => throw StateError('cloud unreachable');
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository() : super(null);
  bool signOutCalled = false;
  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

const _testUser = User(
  id: 'test-user',
  appMetadata: <String, dynamic>{},
  userMetadata: null,
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<SignOutOutcome> executeWith(AuthRepository authRepo,
      {User? signedInUser = _testUser}) async {
    final engine = SyncEngine(
      db: db,
      remote: _NoOpRemote(),
      gate: SyncEntitlementGate(SharedPreferences.getInstance),
    );
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authRepositoryProvider.overrideWithValue(authRepo),
      authProvider.overrideWithValue(signedInUser),
      authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
      syncEngineProvider.overrideWithValue(engine),
      workoutDraftStoreProvider.overrideWithValue(WorkoutDraftStore()),
      signOutCoordinatorProvider.overrideWith(
        (ref) => SignOutCoordinator(
          ref: ref,
          db: ref.read(databaseProvider),
          syncEngine: ref.read(syncEngineProvider),
          draftStore: ref.read(workoutDraftStoreProvider),
          authRepo: ref.read(authRepositoryProvider),
          logoutPurchases: () async {},
        ),
      ),
    ]);
    addTearDown(container.dispose);
    return container
        .read(signOutCoordinatorProvider)
        .execute(SignOutStrategy.forceSignOut);
  }

  group('SignOutCoordinator.execute outcome', () {
    test('reports cloudSignOutFailed when the Supabase sign-out throws',
        () async {
      final outcome =
          await executeWith(_ThrowingAuthRepository());
      expect(outcome, SignOutOutcome.cloudSignOutFailed);
    });

    test('reports complete when both cloud sign-outs succeed', () async {
      final repo = _RecordingAuthRepository();
      final outcome = await executeWith(repo);
      expect(outcome, SignOutOutcome.complete);
      expect(repo.signOutCalled, isTrue);
    });

    test('returns complete without touching cloud when no user is signed in',
        () async {
      final repo = _RecordingAuthRepository();
      final outcome = await executeWith(repo, signedInUser: null);
      expect(outcome, SignOutOutcome.complete);
      expect(repo.signOutCalled, isFalse);
    });
  });
}
