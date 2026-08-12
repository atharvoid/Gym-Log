// Shared pump helper for Explore screen widget tests: builds the full
// GymLog theme + provider overrides (signed-out user, in-memory DB) around
// ExploreRoutinesScreen at a configurable viewport / text scale.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/presentation/screens/explore_routines_screen.dart';
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

/// Pumps [ExploreRoutinesScreen] with a compact viewport, the given palette,
/// and [textScale]. Also returns the in-memory DB for tests that need it.
Future<AppDatabase> pumpExplore(
  WidgetTester tester, {
  double width = 360,
  double height = 800,
  ThemePalette palette = ThemePalette.neonPurple,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final supabase = SupabaseClient('https://example.com', 'key');
  // The client constructor starts GoTrue's periodic auto-refresh timer; it is
  // a fake timer inside the test zone, so it must be cancelled synchronously
  // here rather than in a tearDown (the pending-timer check runs first).
  supabase.auth.stopAutoRefresh();
  final repo = MockAuthRepository(supabase);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWithValue(null),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(palette.tokens, palette: palette),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ExploreRoutinesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
