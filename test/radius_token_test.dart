import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:gymlog/core/services/account_deletion_service.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import 'package:gymlog/features/home/presentation/screens/home_screen.dart';
import 'package:gymlog/features/home/presentation/providers/home_provider.dart';
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

class MockExerciseList extends ExerciseList {
  final List<Exercise> _exercises;
  MockExerciseList(this._exercises);

  @override
  Future<List<Exercise>> build() async => _exercises;
}

class MockAccountDeletionService extends AccountDeletionService {
  MockAccountDeletionService(super.db, super.client);
}

class MockWorkoutHistoryNotifier extends WorkoutHistoryNotifier {
  MockWorkoutHistoryNotifier(super.ref) {
    state = const WorkoutHistoryState(isInitialLoad: true);
  }

  @override
  Future<void> refresh() async {}
  @override
  Future<void> retry() async {}
  @override
  Future<void> fetchNextPage() async {}
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

  testWidgets(
      'DeleteAccountScreen danger chip and _SectionCard use correct AppRadius tokens',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          accountDeletionServiceProvider.overrideWithValue(
              MockAccountDeletionService(db, supabaseClient)),
        ],
        child: const MaterialApp(
          home: DeleteAccountScreen(),
        ),
      ),
    );

    await tester.pump();

    // 1. Danger-icon chip (48x48 Container, expected: AppRadius.buttonPrimaryAll)
    final dangerChipFinder = find.byWidgetPredicate((w) =>
        w is Container &&
        w.constraints != null &&
        w.constraints!.minWidth == 48 &&
        w.constraints!.minHeight == 48 &&
        w.decoration is BoxDecoration);
    expect(dangerChipFinder, findsOneWidget);
    final dangerChip = tester.widget<Container>(dangerChipFinder);
    expect((dangerChip.decoration as BoxDecoration).borderRadius,
        AppRadius.buttonPrimaryAll);

    // 2. _SectionCard container (expected: AppRadius.cardAll)
    final sectionCardFinder = find.byWidgetPredicate((w) =>
        w is Container &&
        w.padding == const EdgeInsets.fromLTRB(16, 14, 16, 14) &&
        w.decoration is BoxDecoration);
    expect(sectionCardFinder, findsAtLeastNWidgets(1));
    final sectionCard = tester.widget<Container>(sectionCardFinder.first);
    expect((sectionCard.decoration as BoxDecoration).borderRadius,
        AppRadius.cardAll);
  });

  testWidgets(
      'ExerciseSelectionScreen filter chip uses AppRadius.buttonSecondaryAll',
      (tester) async {
    final exercises = [
      const Exercise(
        id: 1,
        name: 'Bench Press',
        bodyPart: 'chest',
        equipment: 'Barbell',
        target: 'Chest',
        isCustom: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
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

    final filterButtonFinder = find
        .ancestor(
          of: find.text('Muscle'),
          matching: find.byType(Material),
        )
        .first;
    expect(filterButtonFinder, findsOneWidget);
    final material = tester.widget<Material>(filterButtonFinder);
    expect(material.borderRadius, AppRadius.buttonSecondaryAll);
  });

  testWidgets('HomeScreen initial skeleton uses AppRadius.card',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          workoutHistoryProvider
              .overrideWith((ref) => MockWorkoutHistoryNotifier(ref)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    final skeletonBoxFinder =
        find.byWidgetPredicate((w) => w is SkeletonBox && w.height == 124);
    expect(skeletonBoxFinder, findsOneWidget);
    final skeletonBox = tester.widget<SkeletonBox>(skeletonBoxFinder);
    expect(skeletonBox.radius, AppRadius.card);
  });
}
