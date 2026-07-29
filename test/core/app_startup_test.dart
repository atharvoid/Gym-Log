import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/app.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/cloud_readiness_provider.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/router/router.dart';
import 'package:gymlog/core/services/notification_service.dart';
import 'package:gymlog/core/services/premium_service.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show User, Session, AuthState, SupabaseClient;

void main() {
  late AppDatabase db;
  late SupabaseClient supabaseClient;
  late MockAuthRepository mockRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    supabaseClient = SupabaseClient('https://example.com', 'key');
    mockRepo = MockAuthRepository(supabaseClient);
  });

  tearDown(() async {
    supabaseClient.auth.stopAutoRefresh();
    await db.close();
  });

  testWidgets('GymLogApp builds without throwing when cloud is not ready',
      (tester) async {
    final overrides = <Override>[
      databaseProvider.overrideWithValue(db),
      premiumServiceProvider.overrideWithValue(PremiumService(db)),
      notificationServiceProvider.overrideWithValue(NotificationService()),
      initialAccentPaletteProvider.overrideWithValue(ThemePalette.fallback),
      authRepositoryProvider.overrideWithValue(mockRepo),
      authProvider.overrideWithValue(null),
      cloudReadinessProvider.overrideWithValue(Future.value(false)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const GymLogApp(),
      ),
    );
    await tester.pump();

    // Pre-fix: GymLogApp.initState called Supabase.instance.client
    // synchronously, which threw LateInitializationError (release) or
    // AssertionError (debug). After fix: no exception, MaterialApp.router
    // renders via the deferred auth wiring and readiness-aware router.
    expect(tester.takeException(), isNull,
        reason: 'GymLogApp must not throw during mount when Supabase is '
            'uninitialized');
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('router is constructable without Supabase being initialized',
      (tester) async {
    // Construct the router in a ProviderContainer with cloud not ready.
    final container = ProviderContainer(overrides: [
      cloudReadinessProvider.overrideWithValue(Future.value(false)),
    ]);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    // Pre-fix: routerProvider tried to read Supabase.instance.client at
    // provider creation time, throwing LateInitializationError.
    expect(router, isNotNull);
  });
}

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
