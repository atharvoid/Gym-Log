import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
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

class SpyingList extends ListMixin<Exercise> {
  final List<Exercise> _delegate;
  int accessCount = 0;

  SpyingList(this._delegate);

  @override
  int get length => _delegate.length;

  @override
  set length(int newLength) => _delegate.length = newLength;

  @override
  Exercise operator [](int index) {
    return _delegate[index];
  }

  @override
  void operator []=(int index, Exercise value) {
    _delegate[index] = value;
  }

  @override
  Iterable<Exercise> where(bool Function(Exercise element) test) {
    accessCount++;
    return _delegate.where(test);
  }
}

class MockExerciseList extends ExerciseList {
  final SpyingList _exercises;
  MockExerciseList(this._exercises);

  @override
  Future<List<Exercise>> build() async => _exercises;

  @override
  Future<void> search(String query) async {
    state = AsyncData(_exercises);
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

  testWidgets(
      'ExerciseSelectionScreen filters catalog and handles caching correctly',
      (tester) async {
    final rawExercises = [
      const Exercise(
        id: 1,
        name: 'Bench Press',
        bodyPart: 'chest',
        equipment: 'Barbell',
        target: 'Chest',
        isCustom: false,
        measurementType: 'weight_and_reps',
      ),
      const Exercise(
        id: 2,
        name: 'Dumbbell Fly',
        bodyPart: 'chest',
        equipment: 'Dumbbell',
        target: 'Chest',
        isCustom: false,
        measurementType: 'weight_and_reps',
      ),
      const Exercise(
        id: 3,
        name: 'Squat',
        bodyPart: 'legs',
        equipment: 'Barbell',
        target: 'Legs',
        isCustom: false,
        measurementType: 'weight_and_reps',
      ),
    ];

    final spyingList = SpyingList(rawExercises);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          exerciseListProvider.overrideWith(() => MockExerciseList(spyingList)),
        ],
        child: const MaterialApp(
          home: ExerciseSelectionScreen(browse: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial render: 3 exercises present
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Fly'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);

    // Initial build should have run filtering (where called)
    expect(spyingList.accessCount, 1);

    // Rebuild with the same state (same list instance, same filters)
    final dynamic state = tester.state(find.byType(ExerciseSelectionScreen));
    state.setState(() {});
    await tester.pump();

    // With Option A caching implemented, accessCount must still be 1 (cache hit).
    // Current code will fail here because it recomputes unconditionally (accessCount becomes 2).
    expect(spyingList.accessCount, 1);
  });
}
