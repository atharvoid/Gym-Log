import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/routines/domain/ai_import_models.dart';
import 'package:gymlog/features/routines/presentation/providers/ai_routine_import_provider.dart';
import 'package:gymlog/features/routines/presentation/screens/ai_routine_review_screen.dart';

void main() {
  testWidgets('AiRoutineReviewScreen renders reconciled exercises and badges',
      (tester) async {
    final container = ProviderContainer();
    const testRoutine = ReconciledRoutine(
      routineName: 'Push Hypertrophy',
      days: [
        ReconciledDay(
          dayName: 'Day 1 - Push',
          exercises: [
            ReconciledExercise(
              rawName: 'Incline DB Bench',
              matchedExerciseId: 101,
              matchedExerciseName: 'Incline Dumbbell Bench Press',
              status: ReconciliationStatus.verified,
              sets: 3,
              defaultReps: 10,
              defaultWeightKg: 28.0,
            ),
            ReconciledExercise(
              rawName: 'Cable Lu Raises',
              matchedExerciseId: 102,
              matchedExerciseName: 'Cable Lateral Raise',
              status: ReconciliationStatus.suggested,
              sets: 3,
              isDefaultedSets: true,
              defaultReps: 15,
            ),
            ReconciledExercise(
              rawName: 'Tibialis Barbell Lift',
              status: ReconciliationStatus.unmatched,
              sets: 3,
              defaultReps: 12,
            ),
          ],
        ),
      ],
    );

    container.read(aiRoutineImportProvider.notifier).state =
        const AiRoutineImportState(
      status: AiImportStatus.idle,
      reconciledRoutine: testRoutine,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(ThemePalette.neonPurple.tokens),
          home: const AiRoutineReviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review Routine'), findsOneWidget);
    expect(find.text('Push Hypertrophy'), findsOneWidget);

    // Badges
    expect(find.text('Verified Match'), findsOneWidget);
    expect(find.text('Suggested Match'), findsOneWidget);
    expect(find.text('Custom Exercise'), findsOneWidget);
    expect(find.text('sets defaulted'), findsOneWidget);

    // Exercises
    expect(find.text('Incline Dumbbell Bench Press'), findsOneWidget);
    expect(find.text('Cable Lateral Raise'), findsOneWidget);
    expect(find.text('Tibialis Barbell Lift'), findsOneWidget);

    // Save Routine CTA
    expect(find.text('Save Routine'), findsOneWidget);
  });

  testWidgets('AiRoutineReviewScreen stepper increments set count',
      (tester) async {
    final container = ProviderContainer();
    const testRoutine = ReconciledRoutine(
      routineName: 'Chest Day',
      days: [
        ReconciledDay(
          dayName: 'Day 1',
          exercises: [
            ReconciledExercise(
              rawName: 'Barbell Bench Press',
              matchedExerciseId: 101,
              matchedExerciseName: 'Barbell Bench Press',
              status: ReconciliationStatus.verified,
              sets: 3,
            ),
          ],
        ),
      ],
    );

    container.read(aiRoutineImportProvider.notifier).state =
        const AiRoutineImportState(
      status: AiImportStatus.idle,
      reconciledRoutine: testRoutine,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(ThemePalette.neonPurple.tokens),
          home: const AiRoutineReviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 sets'), findsOneWidget);

    // Tap add set button
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('4 sets'), findsOneWidget);
  });
}
