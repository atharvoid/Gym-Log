// Session 2 regression coverage revised for the owner-approved correction.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/routines/presentation/providers/training_plan_provider.dart';
import 'package:gymlog/features/routines/presentation/widgets/routine_card.dart';
import 'package:gymlog/features/routines/presentation/widgets/training_launchpad.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/start_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_2_fixtures.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'training_plan_test.dart' show FailedPreferences;

void main() {
  setUpAll(loadSessionFonts);
  Future<void> render(WidgetTester tester, String screen,
      {Object? chosen = 'sample-0',
      List<HydratedRoutine>? routines,
      Stream<List<HydratedRoutine>>? routineStream,
      bool previousError = false,
      bool activeWorkout = false,
      ValueNotifier<String>? screenSelection,
      double scale = 1,
      List<Override> overrides = const [],
      Stream<List<WorkoutSessionPreview>>? completedStream,
      Stream<List<WorkoutSessionPreview>>? programStream,
      LaunchState state = LaunchState.returning}) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    SharedPreferences.setMockInitialValues({
      'first_run_tour_step': -1,
      if (chosen != null) 'training_routine:local': chosen
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(launchFixtureApp(
        child: screenSelection == null
            ? currentLaunchScreen(screen)
            : ValueListenableBuilder<String>(
                valueListenable: screenSelection,
                builder: (_, value, child) => currentLaunchScreen(value)),
        palette: ThemePalette.higgsfield,
        scale: scale,
        screen: screen,
        fixtureState: state,
        routines: routines,
        routineStream: routineStream,
        previousError: previousError,
        activeWorkout: activeWorkout,
        overrides: overrides,
        completedStream: completedStream,
        programStream: programStream,
        captureKey: const ValueKey('launchpad-test')));
    if (routineStream == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
      'Home chooser explains following once and has four searchable choices',
      (tester) async {
    await render(tester, 'home');
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Follow a program after each completed workout, or repeat a routine.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('choose-sample-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('choose-sample-4')), findsNothing);
    await tester.enterText(find.byType(TextField), 'Outdoor');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('choose-sample-4')), findsOneWidget);
  });
  testWidgets('Library never creates a second persistent chooser',
      (tester) async {
    for (final active in [false, true]) {
      for (final choice in ['sample-0', null, 'deleted', 7]) {
        await render(tester, 'library', chosen: choice, activeWorkout: active);
        expect(find.byType(TrainingLaunchpad), findsNothing);
        expect(find.byKey(const ValueKey('change-training-routine')),
            findsNothing);
        expect(
            find.byKey(const ValueKey('library-New routine')), findsOneWidget);
      }
    }
  });
  testWidgets(
      'explicit repeat of a program member persists across chooser reopening',
      (tester) async {
    await render(tester, 'home');
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeat one routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-sample-0')));
    await tester.pumpAndSettle();
    expect(find.text('Start Push A'), findsOneWidget);
    expect(find.text('Repeating your chosen routine'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final saved =
        TrainingPlan.decode(prefs.getString('training_plan:v1:local')!);
    expect(saved.followsProgram, isFalse);
    expect(saved.anchorId, 'sample-0');
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);
    expect(find.text('Repeat this routine · 4 exercises'), findsWidgets);
  });
  testWidgets('persistent selection updates Home and the actual Library card',
      (tester) async {
    final screen = ValueNotifier('home');
    addTearDown(screen.dispose);
    await render(tester, 'home', screenSelection: screen);
    expect(find.text('Start Legs A'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('choose-sample-3')));
    await tester.tap(find.byKey(const ValueKey('choose-sample-3')));
    await tester.pumpAndSettle();
    expect(find.text('Start Full Body'), findsOneWidget);
    final persisted = (await SharedPreferences.getInstance())
        .getString('training_plan:v1:local');
    expect(TrainingPlan.decode(persisted!).anchorId, 'sample-3');
    screen.value = 'library';
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Start Full Body'), 240);
    final card = tester.widget<RoutineCard>(find.ancestor(
        of: find.text('Start Full Body'), matching: find.byType(RoutineCard)));
    expect(card.routineId, 'sample-3');
    expect(card.isNext, isTrue);
    screen.value = 'home';
    await tester.pumpAndSettle();
    expect(find.text('Start Full Body'), findsOneWidget);
  });
  testWidgets(
      'pending repeat mode explains saving and closing cancels its draft',
      (tester) async {
    await render(tester, 'home');
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString('training_plan:v1:local');
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeat one routine'));
    await tester.pumpAndSettle();
    expect(
        find.text('Tap a routine to save. Close without choosing to cancel.'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Close routine chooser'));
    await tester.pumpAndSettle();
    expect(prefs.getString('training_plan:v1:local'), before);
    expect(find.text('Start Legs A'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
    expect(
        find.text(
            'Program days follow saved order; standalone routines repeat.'),
        findsOneWidget);
  });
  testWidgets('save failure is visible above choices while intent is retained',
      (tester) async {
    await render(tester, 'home', chosen: null, overrides: [
      trainingPlanProvider.overrideWith((ref) {
        final n = TrainingPlanNotifier(
            'local', () async => sampleRoutines(LaunchState.returning),
            preferences: () async => FailedPreferences());
        n.load();
        return n;
      })
    ]);
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-sample-0')));
    await tester.pumpAndSettle();
    final error = find.text("Couldn't save your plan. Try again.");
    expect(error.hitTestable(), findsOneWidget);
    expect(tester.getRect(error).bottom, lessThan(780));
  });
  testWidgets('narrow large-text Library title stays on one line',
      (tester) async {
    await render(tester, 'library', scale: 2);
    tester.view.physicalSize = const Size(320, 844);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.text('Routines').first).height, lessThan(80));
  });
  testWidgets('no choice never infers a program from unrelated history',
      (tester) async {
    await render(tester, 'home', chosen: null);
    expect(find.text('Choose training plan'), findsOneWidget);
    expect(find.text('Start Legs A'), findsNothing);
    expect(find.text('Last workout'), findsOneWidget);
  });
  testWidgets(
      'choosing a new program resolves tied imported completions explicitly',
      (tester) async {
    final history = sampleHistory(LaunchState.returning);
    final end = history.first.session.endedAt!;
    final tied = WorkoutSessionPreview(
        session: history.last.session.copyWith(endedAt: Value(end)),
        duration: history.last.duration,
        totalVolumeKg: history.last.totalVolumeKg,
        prCount: 0,
        topExercises: history.last.topExercises,
        totalExerciseCount: history.last.totalExerciseCount);
    await render(tester, 'home',
        chosen: 'sample-3', programStream: Stream.value([history.first, tied]));
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeat one routine'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('choose-sample-0')));
    await tester.tap(find.byKey(const ValueKey('choose-sample-0')));
    await tester.pumpAndSettle();
    expect(find.text('Start Push A'), findsOneWidget);
    final saved = TrainingPlan.decode((await SharedPreferences.getInstance())
        .getString('training_plan:v1:local')!);
    expect(saved.startAfter?.isAtSameMomentAs(end), isTrue);
  });
  testWidgets(
      'deleted and corrupt choices recover explicitly and preserve stored intent',
      (tester) async {
    await render(tester, 'home', chosen: 'deleted');
    expect(
        find.text('Your saved training plan needs a choice.'), findsOneWidget);
    expect(find.text('Start Legs A'), findsNothing);
    expect(
        (await SharedPreferences.getInstance())
            .getString('training_routine:local'),
        'deleted');
    await render(tester, 'home', chosen: 7);
    expect(find.text("Couldn't load your training plan"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
  testWidgets('active Home resumes actual identity and has no competing start',
      (tester) async {
    for (final choice in ['sample-0', null, 'deleted', 7]) {
      await render(tester, 'home', chosen: choice, activeWorkout: true);
      expect(
          find.widgetWithText(PrimaryButton, 'Resume Pull A'), findsOneWidget);
      expect(find.text('Start Legs A'), findsNothing);
      expect(find.text('Train something else'), findsNothing);
    }
  });
  testWidgets(
      'active Library leaves routine controls disabled and utility actions available',
      (tester) async {
    await render(tester, 'library', activeWorkout: true);
    expect(find.byType(PrimaryButton), findsNothing);
    for (final button
        in tester.widgetList<StartButton>(find.byType(StartButton))) {
      expect(button.enabled, isFalse);
      expect(button.onPressed, isNull);
    }
    expect(find.byKey(const ValueKey('library-Explore')), findsOneWidget);
  });
  testWidgets('empty Library offers New routine as the single primary action',
      (tester) async {
    await render(tester, 'library', chosen: null, state: LaunchState.empty);
    expect(find.widgetWithText(PrimaryButton, 'New routine'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();
    expect(find.text('Create from Scratch'), findsOneWidget);
    expect(find.text('AI Import from Image or Text'), findsOneWidget);
  });
  testWidgets(
      'Library explains missing plan markers while preserving saved routines',
      (tester) async {
    for (final choice in ['deleted', 7]) {
      await render(tester, 'library', chosen: choice);
      expect(find.text('Training plan needs attention'), findsOneWidget);
      expect(find.text('View Home'), findsOneWidget);
      expect(find.byKey(const ValueKey('library-New routine')), findsOneWidget);
      expect(find.text('Push A'), findsOneWidget);
      expect(find.text('Following on Home'), findsNothing);
    }
  });
  testWidgets('older last-workout dates include the year', (tester) async {
    final sample = sampleHistory(LaunchState.returning).first;
    final previousYear = WorkoutSessionPreview(
        session: sample.session
            .copyWith(endedAt: Value(DateTime(2025, 9, 30, 12, 48))),
        duration: sample.duration,
        totalVolumeKg: sample.totalVolumeKg,
        prCount: 0,
        topExercises: sample.topExercises,
        totalExerciseCount: sample.totalExerciseCount);
    await render(tester, 'home', completedStream: Stream.value([previousYear]));
    expect(find.textContaining('30 Sep 2025'), findsOneWidget);
  });
  testWidgets(
      'an empty next day offers editing instead of starting an empty routine',
      (tester) async {
    final plans = sampleRoutines(LaunchState.returning);
    final empty = [
      for (final r in plans)
        r.routine.id != 'sample-2'
            ? r
            : HydratedRoutine(
                routine: r.routine,
                exerciseNames: const [],
                exerciseIds: const [])
    ];
    await render(tester, 'home', routines: empty);
    expect(find.text('Add exercises'), findsOneWidget);
    expect(find.text('0 exercises · 0 planned sets'), findsOneWidget);
    expect(find.text('Start Legs A'), findsNothing);
  });
  testWidgets(
      'Library read failure exposes one announced retry and creation stays usable',
      (tester) async {
    await render(tester, 'library', state: LaunchState.error);
    expect(find.text("Couldn't load your routines"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final regions = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true);
    expect(
        find.descendant(
            of: regions, matching: find.text("Couldn't load your routines")),
        findsOneWidget);
  });
  testWidgets(
      'Home keeps the session override available during routine read failures',
      (tester) async {
    await render(tester, 'home', state: LaunchState.error);
    expect(find.text('Train something else'), findsOneWidget);
    await tester.tap(find.text('Train something else'));
    await tester.pumpAndSettle();
    expect(find.text('Routine choices unavailable'), findsOneWidget);
    expect(find.text('Start without a routine'), findsOneWidget);
  });
  testWidgets(
      'last workout is global and non-weight activity does not fabricate volume',
      (tester) async {
    final sample = sampleHistory(LaunchState.returning).first;
    final walk = WorkoutSessionPreview(
        session: sample.session.copyWith(
            name: const Value('Outdoor walk'),
            routineId: const Value('sample-4')),
        duration: const Duration(minutes: 45),
        totalVolumeKg: 0,
        prCount: 0,
        topExercises: const [],
        totalExerciseCount: 1);
    await render(tester, 'home', completedStream: Stream.value([walk]));
    expect(find.text('Start Legs A'), findsOneWidget);
    expect(find.text('Outdoor walk'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.textContaining('0 kg volume'), findsNothing);
  });
  testWidgets(
      'last workout converts stored kg volume once to the selected unit',
      (tester) async {
    await render(tester, 'home',
        overrides: [weightUnitProvider.overrideWithValue('lbs')]);
    expect(find.text('8,487.8 lbs volume'), findsOneWidget);
  });
  testWidgets(
      'previous-set failure cannot block next Start or invent first-session history',
      (tester) async {
    await render(tester, 'home', previousError: true);
    expect(find.text('Start Legs A'), findsOneWidget);
    expect(find.text('No previous logged set for this plan'), findsNothing);
  });
  testWidgets('Home retains weekly day counts and the full History shortcut',
      (tester) async {
    await render(tester, 'home');
    expect(find.text('Training days this week'), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label?.contains('2 of 3 training days') ?? false)),
        findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Workout History')).top, lessThan(600));
  });
  testWidgets(
      'View next navigates to the actual card while preserving program order',
      (tester) async {
    await render(tester, 'library', scale: 1.6);
    await tester.ensureVisible(find.text('View next'));
    await tester.tap(find.text('View next'));
    await tester.pumpAndSettle();
    expect(find.text('Start Legs A'), findsOneWidget);
    expect(tester.getRect(find.text('Start Legs A')).bottom, lessThan(780));
    expect(
        tester
            .widgetList<RoutineCard>(find.byType(RoutineCard))
            .any((r) => r.routineId == 'sample-2' && r.isNext),
        isTrue);
  });
  for (final scale in [1.6, 2.0]) {
    testWidgets('Home and Library wrap identities and utilities at $scale',
        (tester) async {
      final plans = sampleRoutines(LaunchState.returning);
      final long = [
        for (final r in plans)
          HydratedRoutine(
              routine: r.routine.copyWith(
                  name:
                      '${r.routine.name} — Strength and conditioning with a very long full identity'),
              exerciseNames: r.exerciseNames,
              exerciseIds: r.exerciseIds)
      ];
      for (final screen in ['home', 'library']) {
        await render(tester, screen, scale: scale, routines: long);
        expect(tester.takeException(), isNull);
        final identities = tester.widgetList<Text>(find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('very long full identity') ?? false)));
        expect(identities, isNotEmpty);
        if (screen == 'home') {
          expect(find.text('Start workout').hitTestable(), findsOneWidget);
          expect(
              tester.getRect(find.text('Start workout')).bottom, lessThan(780));
          expect(
              find.byWidgetPredicate((w) =>
                  w is Semantics &&
                  w.properties.button == true &&
                  w.properties.label == 'Start ${long[2].routine.name}'),
              findsOneWidget);
        }
        for (final text in identities) {
          expect(text.maxLines, isNull);
        }
      }
    });
  }
}
