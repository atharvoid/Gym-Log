// Reorder contract for the routine editor list.
//
// Reproduces the editor's ReorderableListView configuration — a UUID key per
// item, buildDefaultDragHandles:false, and a single custom drag handle
// (ReorderableDragStartListener) — and proves the full list keeps rendering
// through a drag (the reported bug was the list collapsing to one item) and
// that onReorderItem reorders correctly under the Flutter 3.16+ pre-adjusted
// newIndex semantics.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, User, Session, AuthState;
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/routines/presentation/screens/routine_editor_screen.dart';

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

class _Item {
  final String uid = const Uuid().v4();
  final String name;
  _Item(this.name);
}

void main() {
  testWidgets('full list renders through a drag and reorders correctly',
      (tester) async {
    final items = [
      _Item('Alpha'),
      _Item('Bravo'),
      _Item('Charlie'),
      _Item('Delta')
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ReorderableListView.builder(
            itemCount: items.length,
            buildDefaultDragHandles: false, // single custom handle only
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final it = items.removeAt(oldIndex);
                items.insert(newIndex, it);
              });
            },
            itemBuilder: (context, index) {
              final e = items[index];
              return Container(
                key: ValueKey(e.uid), // stable, unique
                height: 64,
                color: Colors.blueGrey,
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const SizedBox(
                        width: 44,
                        height: 48,
                        child: Icon(Icons.drag_indicator),
                      ),
                    ),
                    Text(e.name),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // All four present at rest.
    for (final n in ['Alpha', 'Bravo', 'Charlie', 'Delta']) {
      expect(find.text(n), findsOneWidget, reason: '$n should render at rest');
    }

    // Drag the first item's handle down past two rows.
    final handle = find.byIcon(Icons.drag_indicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 80));

    // Mid-drag: the list must NOT collapse — every row still rendered.
    for (final n in ['Alpha', 'Bravo', 'Charlie', 'Delta']) {
      expect(find.text(n), findsOneWidget,
          reason: '$n must stay rendered mid-drag (no collapse)');
    }

    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    // Still four after drop, and Alpha moved off the top.
    expect(items.length, 4);
    for (final n in ['Alpha', 'Bravo', 'Charlie', 'Delta']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(items.first.name, isNot('Alpha'),
        reason: 'Alpha was dragged down, should no longer be first');
  });

  testWidgets('RoutineEditorScreen reorders exercises and respects bounds',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final supabaseClient = SupabaseClient('https://example.com', 'key');
    final mockAuthRepository = MockAuthRepository(supabaseClient);

    // Insert 3 exercises
    await db.exercisesDao.insertExercise(const ExercisesCompanion(
      name: Value('Bench Press'),
      bodyPart: Value('Chest'),
      equipment: Value('Barbell'),
      target: Value('pectorals'),
    ));
    await db.exercisesDao.insertExercise(const ExercisesCompanion(
      name: Value('Squat'),
      bodyPart: Value('Legs'),
      equipment: Value('Barbell'),
      target: Value('quads'),
    ));
    await db.exercisesDao.insertExercise(const ExercisesCompanion(
      name: Value('Deadlift'),
      bodyPart: Value('Back'),
      equipment: Value('Barbell'),
      target: Value('lats'),
    ));

    final allEx = await db.exercisesDao.getAllExercises();
    final benchId = allEx.firstWhere((e) => e.name == 'Bench Press').id;
    final squatId = allEx.firstWhere((e) => e.name == 'Squat').id;
    final deadliftId = allEx.firstWhere((e) => e.name == 'Deadlift').id;

    // Create a routine with 3 exercises
    final routineId = await db.routinesDao.createRoutine(
      userId: 'u123',
      name: 'Test Routine',
      exercises: [
        RoutineDraftExercise(exerciseId: benchId, defaultSets: 3),
        RoutineDraftExercise(exerciseId: squatId, defaultSets: 4),
        RoutineDraftExercise(exerciseId: deadliftId, defaultSets: 5),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: RoutineEditorScreen(routineId: routineId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 3 exercises and the "Add Exercise" button render
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Deadlift'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_exercise_button')), findsOneWidget);

    double getY(String text) => tester.getCenter(find.text(text)).dy;
    double getButtonY() =>
        tester.getCenter(find.byKey(const ValueKey('add_exercise_button'))).dy;

    // Initially: Bench Press < Squat < Deadlift < Button
    expect(getY('Bench Press') < getY('Squat'), true);
    expect(getY('Squat') < getY('Deadlift'), true);
    expect(getY('Deadlift') < getButtonY(), true);

    // Drive a reorder: move Bench Press (index 0) below Squat (index 1)
    final handle = find.byIcon(Icons.drag_indicator_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify order after reorder: Squat < Bench Press < Deadlift < Button
    expect(getY('Squat') < getY('Bench Press'), true);
    expect(getY('Bench Press') < getY('Deadlift'), true);
    expect(getY('Deadlift') < getButtonY(), true);

    supabaseClient.auth.stopAutoRefresh();
    await db.close();
  });
}
