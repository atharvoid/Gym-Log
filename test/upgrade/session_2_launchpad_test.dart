import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_2_fixtures.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'package:gymlog/features/routines/presentation/widgets/routine_card.dart';
import 'package:gymlog/shared/widgets/ui/start_button.dart';
import 'package:gymlog/features/routines/presentation/widgets/training_launchpad.dart';

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
      LaunchState state = LaunchState.returning}) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    SharedPreferences.setMockInitialValues({
      'first_run_tour_step': -1,
      if (chosen != null) 'training_routine:local': chosen,
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
        captureKey: const ValueKey('launchpad-test')));
    if (routineStream == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
      'Home chooser explains its setting and scopes the suggestion to one row',
      (tester) async {
    await render(tester, 'home');
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    expect(find.text('Routine on Home'), findsOneWidget);
    expect(
        find.text(
            'Choose the routine shown on Home. Suggestions are optional.'),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('choose-sample-2')),
            matching: find.textContaining('Next in your program')),
        findsOneWidget);
  });

  testWidgets(
      'Library has no second routine chooser in ready or recovery states',
      (tester) async {
    for (final active in [false, true]) {
      for (final choice in ['sample-0', null, 'deleted', 7]) {
        await render(tester, 'library', chosen: choice, activeWorkout: active);
        expect(find.byKey(const ValueKey('change-training-routine')),
            findsNothing);
        expect(find.widgetWithText(TextButton, 'Choose routine'), findsNothing);
        expect(
            find.widgetWithText(PrimaryButton, 'Choose routine'), findsNothing);
        expect(find.byType(ListTile), findsNothing);
      }
    }
  });

  testWidgets(
      'Home selection updates the same read-only Library marker without remounting state',
      (tester) async {
    final screen = ValueNotifier('home');
    addTearDown(screen.dispose);
    await render(tester, 'home', screenSelection: screen);
    expect(find.text('HOME ROUTINE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-sample-2')));
    await tester.pumpAndSettle();
    expect(find.text('Start Legs A'), findsOneWidget);
    screen.value = 'library';
    await tester.pumpAndSettle();
    expect(find.text('HOME ROUTINE'), findsOneWidget);
    expect(find.text('Start Legs A'), findsOneWidget);
    expect(find.byKey(const ValueKey('change-training-routine')), findsNothing);
    expect(find.text('Chosen on Home'), findsOneWidget);
    screen.value = 'home';
    await tester.pumpAndSettle();
    expect(find.text('Start Legs A'), findsOneWidget);
  });

  for (final screen in ['home', 'library']) {
    testWidgets('$screen first-session logging has an explicit start label',
        (tester) async {
      await render(tester, screen, chosen: null, state: LaunchState.empty);
      expect(find.text('Start workout'), findsOneWidget);
      expect(find.text('Log a different workout'), findsNothing);
    });
    testWidgets(
        '$screen prioritizes the actual active workout in fallback states',
        (tester) async {
      for (final state in [
        LaunchState.returning,
        LaunchState.empty,
        LaunchState.error
      ]) {
        await render(tester, screen,
            activeWorkout: true,
            state: state,
            chosen: state == LaunchState.empty ? null : 'sample-0');
        expect(find.widgetWithText(PrimaryButton, 'Resume Pull A'),
            findsOneWidget);
        expect(find.text('Resume workout'), findsNothing);
        expect(find.text('Workout in progress'), findsOneWidget);
        expect(find.text('Log a different workout'), findsNothing);
        expect(find.text('Start Push A'), findsNothing);
        if (screen == 'library') {
          for (final button
              in tester.widgetList<StartButton>(find.byType(StartButton))) {
            expect(button.label, 'Start');
            expect(button.enabled, isFalse);
            expect(button.onPressed, isNull);
          }
        }
      }
    });
    testWidgets('$screen labels a one-set plan in the singular',
        (tester) async {
      await render(tester, screen,
          chosen: 'sample-4', state: LaunchState.lowData);
      if (screen == 'home') {
        expect(
            find.descendant(
                of: find.byType(TrainingLaunchpad),
                matching: find.text('1 exercise · 1 planned set')),
            findsOneWidget);
      } else {
        expect(find.text('1 exercise'), findsOneWidget);
      }
    });
    testWidgets('$screen guards an emptied chosen plan', (tester) async {
      final plans = sampleRoutines(LaunchState.returning);
      await render(tester, screen, routines: [
        HydratedRoutine(
            routine: plans.first.routine,
            lastTrained: plans.first.lastTrained,
            exerciseNames: [],
            exerciseIds: []),
        ...plans.skip(1)
      ]);
      expect(find.text('Your chosen routine has no exercises'), findsOneWidget);
      expect(find.byKey(const ValueKey('chosen-routine-start')), findsNothing);
      expect(find.text('Add exercises'), findsOneWidget);
      expect(find.text('Push A'), findsWidgets);
      expect(find.text('Last trained 4 days ago'), findsWidgets);
    });
    testWidgets('$screen choice read failure is distinct from no choice',
        (tester) async {
      await render(tester, screen, chosen: 7);
      expect(
          find.text(screen == 'library'
              ? "Home routine couldn't load"
              : "Couldn't load your training choice"),
          findsOneWidget);
      expect(find.text('Choose a routine for today'), findsNothing);
    });
    testWidgets(
        '$screen repairs a damaged saved choice through explicit selection',
        (tester) async {
      await render(tester, screen, chosen: 7);
      if (screen == 'library') {
        expect(find.text("Home routine couldn't load"), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(
            find.widgetWithText(PrimaryButton, 'Choose routine'), findsNothing);
        return;
      }
      await tester.tap(find.text('Choose routine'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-sample-0')));
      await tester.pumpAndSettle();
      expect(find.text('Start Push A'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('training_routine:local'), 'sample-0');
    });
    testWidgets(
        '$screen keeps Resume primary when choice is missing or damaged',
        (tester) async {
      for (final chosen in [null, 'deleted', 7]) {
        await render(tester, screen, chosen: chosen, activeWorkout: true);
        expect(find.widgetWithText(PrimaryButton, 'Resume Pull A'),
            findsOneWidget);
        expect(find.byType(PrimaryButton), findsOneWidget);
        expect(
            find.text(screen == 'home' ? 'Choose routine' : 'Choose on Home.'),
            findsOneWidget);
      }
    });
    testWidgets('$screen uses explicit choice and one-tap Change',
        (tester) async {
      await render(tester, screen);
      expect(find.text('Start Push A'), findsWidgets);
      expect(find.text('Last trained 4 days ago'), findsWidgets);
      if (screen == 'library') {
        expect(find.text('HOME ROUTINE'), findsOneWidget);
        expect(find.byKey(const ValueKey('change-training-routine')),
            findsNothing);
        return;
      }
      expect(find.byKey(const ValueKey('change-training-routine')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('change-training-routine')));
      await tester.pumpAndSettle();
      expect(find.text('Routine on Home'), findsOneWidget);
      expect(find.text('Next in your program · Follows Pull A in saved order'),
          findsOneWidget);
    });

    testWidgets('$screen never chooses the first routine by inference',
        (tester) async {
      await render(tester, screen, chosen: null);
      expect(
          find.text(screen == 'home'
              ? 'Choose a routine for today'
              : 'No Home routine chosen'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('chosen-routine-start')), findsNothing);
      expect(find.text('Next in your program'), findsNothing);
    });

    testWidgets('$screen shows a deleted choice without replacing it',
        (tester) async {
      await render(tester, screen, chosen: 'deleted');
      expect(
          find.text(screen == 'home'
              ? 'Chosen routine unavailable'
              : 'Home routine unavailable'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('chosen-routine-start')), findsNothing);
    });

    testWidgets('$screen new user has a designed first-session entry',
        (tester) async {
      await render(tester, screen, chosen: null, state: LaunchState.empty);
      expect(find.text('Your first session starts here'), findsOneWidget);
      expect(find.byKey(const ValueKey('chosen-routine-start')), findsNothing);
    });
  }

  testWidgets(
      'Library keeps a routine Start reachable below a compact choice at 1.6x',
      (tester) async {
    await render(tester, 'library', scale: 1.6);
    final firstCard = find.byType(RoutineCard).first;
    final button =
        find.descendant(of: firstCard, matching: find.byType(StartButton));
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(772));
  });
  for (final choice in <Object?>[null, 'deleted', 7]) {
    testWidgets('Library recovery $choice keeps saved Start visible at 1.6x',
        (tester) async {
      await render(tester, 'library', chosen: choice, scale: 1.6);
      final firstCard = find.byType(RoutineCard).first;
      final start =
          find.descendant(of: firstCard, matching: find.byType(StartButton));
      expect(tester.getRect(start).bottom, lessThanOrEqualTo(772));
      expect(find.text('Choose your Home routine on Home.'), findsNothing);
    });
  }
  testWidgets('Deleted Library choice exposes the logging action it describes',
      (tester) async {
    await render(tester, 'library', chosen: 'deleted');
    expect(find.text('Log a different workout'), findsOneWidget);
  });
  testWidgets('Empty Library plan uses one clear Home ownership label at 1.6x',
      (tester) async {
    final plans = sampleRoutines(LaunchState.returning);
    await render(tester, 'library', scale: 1.6, routines: [
      HydratedRoutine(
          routine: plans.first.routine,
          lastTrained: plans.first.lastTrained,
          exerciseNames: [],
          exerciseIds: []),
      ...plans.skip(1)
    ]);
    expect(find.text('HOME ROUTINE'), findsOneWidget);
    expect(find.text('Chosen on Home'), findsNothing);
    expect(find.text('Your chosen routine has no exercises'), findsOneWidget);
    expect(
        find.text('Add exercises to this routine, or choose another on Home.'),
        findsOneWidget);
    expect(find.text('Add exercises'), findsOneWidget);
    expect(find.byKey(const ValueKey('chosen-routine-start')), findsNothing);
  });
  testWidgets('Library announces arriving read errors', (tester) async {
    await render(tester, 'library', state: LaunchState.error);
    final regions = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true);
    expect(
        find.descendant(
            of: regions, matching: find.text("Couldn't load your routines")),
        findsOneWidget);
  });
  testWidgets('Home explains the weekly counted unit visually and in speech',
      (tester) async {
    await render(tester, 'home');
    expect(find.text('Training days this week'), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label?.contains('2 of 3 training days') ?? false)),
        findsOneWidget);
  });

  testWidgets('Empty Library prioritizes browsing and avoids duplicate errors',
      (tester) async {
    await render(tester, 'library', chosen: null, state: LaunchState.empty);
    expect(
        find.widgetWithText(PrimaryButton, 'Browse programs'), findsOneWidget);
    await render(tester, 'library', state: LaunchState.error);
    expect(find.text('Try again'), findsOneWidget);
  });
  testWidgets('Change exposes the selected choice to assistive technology',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await render(tester, 'home');
      await tester.tap(find.byKey(const ValueKey('change-training-routine')));
      await tester.pumpAndSettle();
      expect(
          tester
              .getSemantics(find.byKey(const ValueKey('choose-sample-0')))
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
      'Home preserves freestyle during library read failure and deleted-only state',
      (tester) async {
    await render(tester, 'home', state: LaunchState.error);
    expect(find.text('Log a different workout'), findsOneWidget);
    await render(tester, 'home', chosen: 'deleted', routines: []);
    expect(find.text('Log a different workout'), findsOneWidget);
  });

  testWidgets(
      'Change uses bounded searchable choices and preserves choice on read failure',
      (tester) async {
    final stream = StreamController<List<HydratedRoutine>>.broadcast();
    addTearDown(stream.close);
    await render(tester, 'home', routineStream: stream.stream);
    stream.add(sampleRoutines(LaunchState.returning));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(4));
    await tester.enterText(find.byType(TextField), 'Outdoor');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.byKey(const ValueKey('choose-sample-4')), findsOneWidget);
    stream.addError(StateError('read failed'));
    await tester.pumpAndSettle();
    expect(find.text('Routine choices unavailable'), findsOneWidget);
  });

  testWidgets(
      'Previous-set read failure does not invent no history or block Start',
      (tester) async {
    await render(tester, 'home', previousError: true);
    expect(find.text('Previous-set context unavailable'), findsOneWidget);
    expect(find.text('No previous logged set for this plan'), findsNothing);
    expect(find.text('Start Push A'), findsOneWidget);
  });

  testWidgets('Home keeps freestyle and History secondary and accessible',
      (tester) async {
    await render(tester, 'home');
    expect(find.text('Log a different workout'), findsOneWidget);
    expect(find.text('History'), findsWidgets);
  });

  testWidgets('Home has no guilt language on an inactive return',
      (tester) async {
    await render(tester, 'home', state: LaunchState.inactive);
    expect(find.text('Train at your own pace'), findsOneWidget);
    expect(find.textContaining('lost'), findsNothing);
    expect(find.text('Start Push A'), findsOneWidget);
  });

  testWidgets('Change selection updates both launch surfaces and persists',
      (tester) async {
    await render(tester, 'home');
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-sample-2')));
    await tester.pumpAndSettle();
    expect(find.text('Start Legs A'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('training_routine:local'), 'sample-2');
  });

  testWidgets('Library groups the program and quiets creation', (tester) async {
    await render(tester, 'library');
    expect(find.byKey(const ValueKey('program-sample-ppl')), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'New routine'), findsOneWidget);
    expect(find.byKey(const ValueKey('chosen-routine-start')), findsOneWidget);
  });
}
