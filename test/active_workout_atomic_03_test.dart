import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/widgets/compact_rest_chip.dart';
import 'package:gymlog/features/workout/presentation/widgets/set_row.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';

class MockActiveWorkoutNotifier extends ActiveWorkoutNotifier {
  MockActiveWorkoutNotifier(super.ref, ActiveWorkoutState? initialState) {
    state = initialState;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockWorkout = ActiveWorkoutState(
    id: 'w1',
    startTime: DateTime.now(),
    exercises: [
      const WorkoutExerciseState(
        id: 'we1',
        exerciseId: 1,
        name: 'Bench Press',
        sets: [
          WorkoutSetState(
            id: 's1',
            setType: 'normal',
            reps: 10,
            weightKg: 80,
            isCompleted: false,
          ),
        ],
      ),
    ],
  );

  group('ATOMIC-03 Active Workout & Card Geometry Suite', () {
    testWidgets('1. CompactRestChip visual height 34 & intrinsic width',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkoutProvider.overrideWith(
                (ref) => MockActiveWorkoutNotifier(ref, mockWorkout)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CompactRestChip(
                  exerciseIndex: 0,
                  exerciseName: 'Bench Press',
                ),
              ),
            ),
          ),
        ),
      );

      final chipFinder = find.byType(CompactRestChip);
      expect(chipFinder, findsOneWidget);

      final innerContainer = tester.widget<Container>(
        find
            .descendant(
              of: chipFinder,
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.constraints?.maxHeight == 34,
              ),
            )
            .first,
      );

      expect(innerContainer.constraints?.maxHeight, 34);
    });

    testWidgets('2. CompactRestChip touch target minimum 48x48',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkoutProvider.overrideWith(
                (ref) => MockActiveWorkoutNotifier(ref, mockWorkout)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CompactRestChip(
                  exerciseIndex: 0,
                  exerciseName: 'Bench Press',
                ),
              ),
            ),
          ),
        ),
      );

      final touchTargetSize = tester.getSize(find.byType(CompactRestChip));
      expect(touchTargetSize.height, greaterThanOrEqualTo(48));
      expect(touchTargetSize.width, greaterThanOrEqualTo(48));
    });

    testWidgets('3. SetRow cells have minHeight 48 and SetRow minHeight 56',
        (tester) async {
      const set = WorkoutSetState(
        id: 's1',
        setType: 'normal',
        weightKg: 80,
        reps: 10,
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetRow(
              setIndex: 0,
              setData: set,
              measurementType: MeasurementType.weightAndReps,
              onChanged: (_) {},
              onToggleComplete: () {},
            ),
          ),
        ),
      );

      final rowSize = tester.getSize(find.byType(SetRow));
      expect(rowSize.height, greaterThanOrEqualTo(56));

      final cellContainers = find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            w.constraints?.minHeight == 48 &&
            w.constraints?.minWidth == 48,
      );
      expect(cellContainers, findsNWidgets(2));
      for (final container in cellContainers.evaluate()) {
        final box = container.renderObject as RenderBox;
        expect(box.size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('4. Reps-only column behavior hides weight column',
        (tester) async {
      const set = WorkoutSetState(
        id: 's1',
        setType: 'normal',
        weightKg: null,
        reps: 15,
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetRow(
              setIndex: 0,
              setData: set,
              measurementType: MeasurementType.repsOnly,
              onChanged: (_) {},
              onToggleComplete: () {},
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsOneWidget);
    });

    testWidgets('5. showAppSnackBar renders floating snackbar with radius 14',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      message: '“Pull Day” added to routines',
                      actionLabel: 'View',
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('“Pull Day” added to routines'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
      final shape = snackBar.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(14));
    });

    testWidgets('6. showAppSnackBar clears timer bar offset when present',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      message: 'Set removed',
                      actionLabel: 'Undo',
                      additionalBottomOffset: 102,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final margin = snackBar.margin as EdgeInsets;
      expect(margin.bottom, greaterThan(100));
    });
  });
}
