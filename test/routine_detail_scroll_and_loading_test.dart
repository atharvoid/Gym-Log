import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/features/routines/presentation/screens/routine_detail_screen.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
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

void main() {
  late AppDatabase db;
  late SupabaseClient supabaseClient;
  late MockAuthRepository mockAuthRepository;

  final dummyDetail = HydratedRoutineDetail(
    routine: Routine(
      id: 'r1',
      userId: 'u1',
      name: 'Routine 1',
      notes: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    exercises: const [],
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    supabaseClient = SupabaseClient('https://example.com', 'key');
    mockAuthRepository = MockAuthRepository(supabaseClient);
  });

  tearDown(() async {
    supabaseClient.auth.stopAutoRefresh();
    await db.close();
  });

  testWidgets(
      'RoutineDetailScreen loaded view uses AlwaysScrollableScrollPhysics',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          isPremiumProvider.overrideWithValue(true),
          routineDetailProvider('r1')
              .overrideWith((ref) => Stream.value(dummyDetail)),
          routineLastSetsProvider('r1').overrideWith((ref) => Stream.value({})),
          routineSessionStatsProvider('r1').overrideWith((ref) => Stream.value(
                const RoutineSessionStats(
                    count: 0, bestVolumeKg: 0, totalVolumeKg: 0),
              )),
          routineDailyVolumeProvider(('r1', '6M'))
              .overrideWith((ref) => Stream.value([])),
          routineDailyVolumeProvider(('r1', 'All'))
              .overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: RoutineDetailScreen(routineId: 'r1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final csv = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(csv.physics, isA<AlwaysScrollableScrollPhysics>());
    expect(csv.physics, isNot(isA<BouncingScrollPhysics>()));
  });

  testWidgets(
      '_RoutineVolumeSection loading shows SkeletonBox instead of CircularProgressIndicator',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          isPremiumProvider.overrideWithValue(true),
          routineDetailProvider('r1')
              .overrideWith((ref) => Stream.value(dummyDetail)),
          routineLastSetsProvider('r1').overrideWith((ref) => Stream.value({})),
          routineSessionStatsProvider('r1').overrideWith((ref) => Stream.value(
                const RoutineSessionStats(
                    count: 0, bestVolumeKg: 0, totalVolumeKg: 0),
              )),
          // Force volume provider to stay in loading state
          routineDailyVolumeProvider(('r1', '6M'))
              .overrideWith((ref) => const Stream.empty()),
          routineDailyVolumeProvider(('r1', 'All'))
              .overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: RoutineDetailScreen(routineId: 'r1'),
        ),
      ),
    );

    // Pump widget (no settle since it stays loading)
    await tester.pump();

    // Verify detail screen is loaded (so routine title is shown)
    expect(find.text('Routine 1'), findsOneWidget);

    // Verify there is no CircularProgressIndicator in the volume section
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify the loading SkeletonBox for the volume graph is present (height 198)
    final skeletonFinder = find.byWidgetPredicate(
      (widget) => widget is SkeletonBox && widget.height == 198,
    );
    expect(skeletonFinder, findsOneWidget);
  });
}
