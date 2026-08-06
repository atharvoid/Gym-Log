import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart'
    show ExerciseHistoryData;
import 'package:gymlog/core/providers/cloud_readiness_provider.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/router/router.dart';
import 'package:gymlog/core/services/notification_service.dart';
import 'package:gymlog/core/services/premium_service.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercise_analytics_provider.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_detail_screen.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<int> seedExercise(AppDatabase db) async {
    await db.exercisesDao.insertExercise(
      ExercisesCompanion.insert(
        name: 'Deep Link Squat',
        bodyPart: 'Upper Legs',
        equipment: 'Barbell',
        target: 'Quadriceps',
        isCustom: const Value(false),
        measurementType: const Value('weight_and_reps'),
      ),
    );
    final all = await db.exercisesDao.getAllExercises();
    return all.singleWhere((e) => e.name == 'Deep Link Squat').id;
  }

  GoRouter buildRouter({
    required AppDatabase db,
    required SupabaseClient client,
    List<(int, String)> analyticsKeys = const [],
  }) {
    final overrides = <Override>[
      cloudReadinessProvider.overrideWithValue(Future.value(false)),
      databaseProvider.overrideWithValue(db),
      premiumServiceProvider.overrideWithValue(PremiumService(db)),
      notificationServiceProvider.overrideWithValue(NotificationService()),
      authRepositoryProvider.overrideWithValue(_MockAuthRepository(client)),
      authProvider.overrideWithValue(null),
    ];
    for (final key in analyticsKeys) {
      overrides.add(
        exerciseAnalyticsProvider(key)
            .overrideWith((ref) => Stream.value(<ExerciseHistoryData>[])),
      );
    }
    return ProviderContainer(overrides: overrides).read(routerProvider);
  }

  testWidgets(
      'deep link without extra loads the exercise by id instead of crashing',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final client = SupabaseClient('https://example.com', 'key');
    try {
      final exerciseId = await seedExercise(db);
      final router = buildRouter(
        db: db,
        client: client,
        analyticsKeys: [(exerciseId, '6M')],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudReadinessProvider.overrideWithValue(Future.value(false)),
            databaseProvider.overrideWithValue(db),
            premiumServiceProvider.overrideWithValue(PremiumService(db)),
            notificationServiceProvider
                .overrideWithValue(NotificationService()),
            authRepositoryProvider
                .overrideWithValue(_MockAuthRepository(client)),
            authProvider.overrideWithValue(null),
            exerciseAnalyticsProvider((exerciseId, '6M'))
                .overrideWith((ref) => Stream.value(<ExerciseHistoryData>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // A deep link arrives with NO extra — only the path id.
      router.go('/exercise/detail/$exerciseId');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull,
          reason: 'deep link with null extra must not throw');
      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
      expect(find.text('Deep Link Squat'), findsWidgets,
          reason: 'the screen must fall back to loading the exercise by id');
    } finally {
      await db.close();
      client.auth.stopAutoRefresh();
    }
  });

  testWidgets('non-numeric deep link falls back to the library, no crash',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final client = SupabaseClient('https://example.com', 'key');
    try {
      final router = buildRouter(db: db, client: client);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudReadinessProvider.overrideWithValue(Future.value(false)),
            databaseProvider.overrideWithValue(db),
            premiumServiceProvider.overrideWithValue(PremiumService(db)),
            notificationServiceProvider
                .overrideWithValue(NotificationService()),
            authRepositoryProvider
                .overrideWithValue(_MockAuthRepository(client)),
            authProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      router.go('/exercise/detail/not-a-number');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull,
          reason: 'a non-numeric id must not throw mid-navigation');
    } finally {
      await db.close();
      client.auth.stopAutoRefresh();
    }
  });
}
