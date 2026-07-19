import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import 'package:gymlog/features/auth/presentation/screens/auth_screen.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/core/providers/database_provider.dart';
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
      '_FilterChipButton in ExerciseSelectionScreen is at least 48dp tall',
      (tester) async {
    final exercises = [
      const Exercise(
        id: 1,
        name: 'Bench Press',
        bodyPart: 'chest',
        equipment: 'Barbell',
        target: 'Chest',
        isCustom: false,
        measurementType: 'weight_and_reps',
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

    final muscleButtonFinder = find.ancestor(
      of: find.text('Muscle'),
      matching: find.byType(InkWell),
    );
    final equipmentButtonFinder = find.ancestor(
      of: find.text('Equipment'),
      matching: find.byType(InkWell),
    );

    expect(muscleButtonFinder, findsOneWidget);
    expect(equipmentButtonFinder, findsOneWidget);

    final muscleSize = tester.getSize(muscleButtonFinder);
    final equipmentSize = tester.getSize(equipmentButtonFinder);

    expect(muscleSize.height, greaterThanOrEqualTo(48));
    expect(equipmentSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('_LegalLink buttons in AuthScreen are at least 48dp tall',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    await tester.pump();

    final termsTapTarget = find.ancestor(
      of: find.text('Terms of Service'),
      matching: find.byType(GestureDetector),
    );
    final privacyTapTarget = find.ancestor(
      of: find.text('Privacy Policy'),
      matching: find.byType(GestureDetector),
    );

    expect(termsTapTarget, findsOneWidget);
    expect(privacyTapTarget, findsOneWidget);

    final termsSize = tester.getSize(termsTapTarget);
    final privacySize = tester.getSize(privacyTapTarget);

    expect(termsSize.height, greaterThanOrEqualTo(48));
    expect(privacySize.height, greaterThanOrEqualTo(48));
  });
}
