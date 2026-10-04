// Exercise the audited typing sites through actual screens/dialogs, with no saves.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_name.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_selection_screen.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercises_provider.dart';
import 'package:gymlog/features/exercises/presentation/widgets/create_exercise_dialog.dart';
import 'package:gymlog/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:gymlog/features/profile/presentation/screens/help_feedback_screen.dart';
import 'package:gymlog/features/routines/domain/ai_import_models.dart';
import 'package:gymlog/features/routines/presentation/providers/ai_routine_import_provider.dart';
import 'package:gymlog/features/routines/presentation/providers/explore_providers.dart';
import 'package:gymlog/features/routines/presentation/screens/ai_routine_review_screen.dart';
import 'package:gymlog/features/routines/presentation/screens/explore_screen.dart';
import 'package:gymlog/features/routines/presentation/screens/routine_editor_screen.dart';
import 'package:gymlog/features/workout/presentation/widgets/finish_summary_sheet.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_routines_implemented_render_test.dart' show IllustrativeKeyboard;
import 'input_consistency_test.dart'
    show prepareView, expectRounded, captureInput;
import 'session_1_render_test.dart' show loadSessionFonts;

class EmptyInputCatalog extends ExerciseList {
  @override
  Future<List<Exercise>> build() async => const [];

  @override
  Future<void> search(String query) async => state = const AsyncData([]);
}

class InputReviewFixture extends AiRoutineImportNotifier {
  InputReviewFixture(super.ref) {
    state = const AiRoutineImportState(
      status: AiImportStatus.success,
      reconciledRoutine: ReconciledRoutine(routineName: 'Push Day A', days: [
        ReconciledDay(dayName: 'Day 1', exercises: [
          ReconciledExercise(
              rawName: 'Bench Press',
              matchedExerciseId: 1,
              matchedExerciseName: 'Bench Press',
              status: ReconciliationStatus.verified,
              defaultReps: 8),
        ]),
      ]),
    );
  }
}

void main() {
  setUpAll(loadSessionFonts);
  for (final palette in ThemePalette.values) {
    for (final surface in [
      'onboarding-name',
      'exercise-search',
      'create-exercise',
      'delete-confirmation',
      'feedback-topic',
      'feedback-details',
      'review-name',
      'review-reps',
      'explore-search',
      'routine-name',
      'finish-name',
      'shared-name'
    ]) {
      testWidgets('$surface-${palette.name}', (tester) async {
        prepareView(tester);
        SharedPreferences.setMockInitialValues({'first_run_tour_step': -1});
        final key = ValueKey('$surface-${palette.name}');
        final child = switch (surface) {
          'onboarding-name' => Scaffold(body: StepName(onNext: () {})),
          'exercise-search' => const ExerciseSelectionScreen(browse: true),
          'delete-confirmation' => const DeleteAccountScreen(),
          'feedback-topic' || 'feedback-details' => const Scaffold(
              body: SingleChildScrollView(
                  child: ReportProblemForm(
                      appVersion: '1.0.0+1',
                      dbSchemaVersion: 1,
                      catalogVersion: 1,
                      osName: 'synthetic',
                      opRef: 'test'))),
          'review-name' || 'review-reps' => const AiRoutineReviewScreen(),
          'explore-search' => const ExploreScreen(),
          'routine-name' => const RoutineEditorScreen(),
          _ => Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () {
                        if (surface == 'create-exercise') {
                          showCreateExerciseDialog(context: context);
                        } else if (surface == 'finish-name') {
                          showFinishSummarySheet(
                              context: context,
                              duration: const Duration(minutes: 45),
                              volumeKg: 2500,
                              sets: 12,
                              unit: 'kg',
                              initialName: 'Push Day A');
                        } else {
                          showAppTextInputDialog(
                              context: context,
                              title: 'Edit name',
                              hint: 'Name');
                        }
                      },
                      child: const Text('Open input')))),
        };
        final router =
            GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => child)]);
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              exerciseListProvider.overrideWith(EmptyInputCatalog.new),
              filteredExploreRoutinesProvider.overrideWith((ref) => []),
              filteredExploreProgramsProvider.overrideWith((ref) => []),
              authProvider.overrideWithValue(null),
              aiRoutineImportProvider
                  .overrideWith((ref) => InputReviewFixture(ref)),
            ],
            child: RepaintBoundary(
                key: key,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(palette.tokens, palette: palette),
                  routerConfig: router,
                  builder: (context, child) => Stack(children: [
                    child!,
                    if (MediaQuery.viewInsetsOf(context).bottom > 0)
                      const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IllustrativeKeyboard()),
                  ]),
                ))));
        await tester.pumpAndSettle();
        if (find.text('Open input').evaluate().isNotEmpty) {
          await tester.tap(find.text('Open input'));
          await tester.pumpAndSettle();
        }
        if (surface == 'delete-confirmation') {
          await tester.scrollUntilVisible(find.byType(TextField), 300,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
        }
        if (surface == 'review-reps') {
          await tester.tap(find.text('8 reps'));
          await tester.pumpAndSettle();
        }
        final fields = find.byType(TextField);
        final field = surface == 'feedback-details' || surface == 'review-reps'
            ? fields.last
            : fields.first;
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        final input = surface == 'delete-confirmation'
            ? 'DELETE'
            : surface == 'review-reps'
                ? '8-10'
                : 'Sample';
        await tester.enterText(field, input);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(field).controller!.text, input);
        expectRounded(tester);
        expect(tester.takeException(), isNull);
        await captureInput(tester, key, '$surface-${palette.name}');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
