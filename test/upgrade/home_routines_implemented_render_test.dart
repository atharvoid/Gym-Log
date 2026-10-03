// Real production widgets; synthetic local data and illustrative OS keyboard.
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymlog/features/routines/presentation/providers/training_plan_provider.dart';
import 'active_bar_large_text_test.dart' show FixedWorkoutTimer;
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';
import 'training_plan_test.dart' show FailedPreferences;

class PendingPreferences extends FailedPreferences {
  final Completer<bool> completion;
  PendingPreferences(this.completion);
  @override
  Future<bool> setString(String key, String value) => completion.future;
}

void main() {
  setUpAll(loadSessionFonts);
  for (final palette in ThemePalette.values) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final screen in ['home', 'library']) {
        for (final state in [
          'completed',
          'long-name',
          if (screen == 'home') ...['plan-repeat', 'plan-empty'],
          if (scale == 2 && screen == 'home') ...['last-error', 'last-older'],
          if (scale == 2 && screen == 'home') ...[
            'repeat-committed',
            'repeat-canceled',
            'plan-saving',
            'plan-save-error',
            'empty-next'
          ],
          if (scale == 2 && screen == 'library') 'plan-error',
          if (scale == 2) ...['ready', 'empty', 'error', 'active']
        ]) {
          testWidgets('$screen-$state-${palette.name}-${scale}x',
              (tester) async {
            await render(tester, screen, palette, scale, state);
          });
        }
      }
      for (final plan in [false, true]) {
        testWidgets(
            '${plan ? 'plan' : 'override'}-keyboard-${palette.name}-${scale}x',
            (tester) async {
          await render(tester, 'home', palette, scale,
              plan ? 'plan-keyboard' : 'override-keyboard');
        });
      }
      testWidgets('library-next-${palette.name}-${scale}x', (tester) async {
        await render(tester, 'library', palette, scale, 'view-next');
      });
    }
    for (final scale in [1.0, 2.0]) {
      for (final screen in ['home', 'library']) {
        testWidgets('$screen-narrow-ready-${palette.name}-${scale}x',
            (tester) async {
          await render(tester, screen, palette, scale, 'narrow-ready',
              width: 320);
        });
      }
    }
  }
}

Future<void> render(WidgetTester tester, String screen, ThemePalette palette,
    double scale, String name,
    {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final state = name == 'empty' || name == 'plan-empty'
      ? LaunchState.empty
      : name == 'error'
          ? LaunchState.error
          : LaunchState.returning;
  SharedPreferences.setMockInitialValues({
    'first_run_tour_step': -1,
    if (state != LaunchState.empty)
      'training_routine:local': name == 'plan-error' ? 7 : 'sample-0'
  });
  final key = ValueKey('implemented-$screen-$name-${palette.name}-${scale}x');
  List<HydratedRoutine>? routines;
  final pending = name == 'plan-saving' ? Completer<bool>() : null;
  if (name == 'empty-next') {
    routines = [
      for (final r in sampleRoutines(state))
        r.routine.id == 'sample-2'
            ? HydratedRoutine(
                routine: r.routine,
                exerciseNames: const [],
                exerciseIds: const [])
            : r
    ];
  }
  if (name == 'long-name') {
    routines = [
      for (final r in sampleRoutines(state))
        HydratedRoutine(
            routine: r.routine.copyWith(
                name:
                    '${r.routine.name} — Strength and conditioning with a very long full identity'),
            exerciseNames: r.exerciseNames,
            exerciseIds: r.exerciseIds,
            muscleTags: r.muscleTags,
            lastTrained: r.lastTrained)
    ];
  }
  List<WorkoutSessionPreview>? completed;
  if (name == 'last-older') {
    final sample = sampleHistory(state).first;
    completed = [
      WorkoutSessionPreview(
          session: sample.session
              .copyWith(endedAt: Value(DateTime(2025, 9, 30, 12, 48))),
          duration: sample.duration,
          totalVolumeKg: sample.totalVolumeKg,
          prCount: 0,
          topExercises: sample.topExercises,
          totalExerciseCount: sample.totalExerciseCount)
    ];
  }
  if (name == 'completed') {
    final sample = sampleHistory(state).first;
    completed = [
      WorkoutSessionPreview(
          session: sample.session.copyWith(
              name: const Value('Legs A'),
              routineId: const Value('sample-2'),
              endedAt: Value(session2Date)),
          duration: sample.duration,
          totalVolumeKg: sample.totalVolumeKg,
          prCount: 0,
          topExercises: sample.topExercises,
          totalExerciseCount: sample.totalExerciseCount)
    ];
  }
  await tester.pumpWidget(launchFixtureApp(
      child: currentLaunchScreen(screen, miniPlayer: name == 'active'),
      palette: palette,
      scale: scale,
      screen: screen,
      fixtureState: state,
      routines: routines,
      activeWorkout: name == 'active',
      completedStream: name == 'last-error'
          ? Stream.error(StateError('Synthetic last-workout read failure'))
          : completed == null
              ? null
              : Stream.value(completed),
      programStream: completed == null ? null : Stream.value(completed),
      overrides: [
        workoutTimerProvider.overrideWith(FixedWorkoutTimer.new),
        if (name == 'plan-saving' || name == 'plan-save-error')
          trainingPlanProvider.overrideWith((ref) {
            final n = TrainingPlanNotifier(
                'local', () async => sampleRoutines(state),
                preferences: () async => pending == null
                    ? FailedPreferences()
                    : PendingPreferences(pending));
            n.load();
            return n;
          }),
      ],
      keyboardOverlay: const IllustrativeKeyboard(),
      captureKey: key));
  if (name == 'active') {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
  if (name == 'empty-next') {
    expect(find.text('Add exercises'), findsOneWidget);
    expect(find.text('0 exercises · 0 planned sets'), findsOneWidget);
  }
  if (['repeat-committed', 'repeat-canceled', 'plan-saving', 'plan-save-error']
      .contains(name)) {
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    if (name.startsWith('repeat-')) {
      await tester.tap(find.text('Repeat one routine'));
      await tester.pumpAndSettle();
    }
    if (name == 'repeat-canceled') {
      await tester.tap(find.byTooltip('Close routine chooser'));
      await tester.pumpAndSettle();
      expect(find.text('Start Legs A'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('change-training-routine')));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse);
    } else {
      final choice = find.byKey(const ValueKey('choose-sample-0'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      if (pending == null) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Saving training plan').hitTestable(), findsOneWidget);
      }
      if (name == 'repeat-committed') {
        expect(find.text('Start Push A'), findsOneWidget);
      }
      if (name == 'plan-save-error') {
        expect(find.text("Couldn't save your plan. Try again.").hitTestable(),
            findsOneWidget);
      }
    }
  }
  if (name == 'last-error' || name == 'last-older') {
    await tester.ensureVisible(name == 'last-error'
        ? find.text("Couldn't load your last workout")
        : find.textContaining('30 Sep 2025'));
    await tester.pumpAndSettle();
  }
  if (name == 'plan-repeat' || name == 'plan-empty') {
    await tester.tap(find.byKey(const ValueKey('change-training-routine')));
    await tester.pumpAndSettle();
    if (name == 'plan-repeat') {
      await tester.tap(find.text('Repeat one routine'));
      await tester.pumpAndSettle();
    } else {
      expect(find.text('No saved routines yet'), findsOneWidget);
      expect(find.text('Browse programs').last.hitTestable(), findsOneWidget);
    }
  }
  if (name == 'completed' && screen == 'home') {
    expect(find.text('Start Push A'), findsOneWidget);
    expect(find.text('After Legs A in your saved order'), findsOneWidget);
  }
  if (name == 'view-next') {
    await tester.tap(find.text('View next'));
    await tester.pumpAndSettle();
    expect(find.text('Start Legs A'), findsOneWidget);
  }
  if (name.endsWith('keyboard')) {
    final open = name == 'plan-keyboard'
        ? find.byKey(const ValueKey('change-training-routine'))
        : find.text('Train something else');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.enterText(
        find.byType(TextField), name == 'plan-keyboard' ? 'Pull' : 'Full');
    await tester.pumpAndSettle();
    final action = find.byKey(ValueKey(
        name == 'plan-keyboard' ? 'choose-sample-1' : 'choose-sample-3'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(tester.getRect(action).bottom, lessThanOrEqualTo(564));
    expect(
        tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(564));
    expect(tester.getRect(action).top, greaterThanOrEqualTo(0));
    expect(tester.getRect(find.byType(TextField)).top, greaterThanOrEqualTo(0));
    expect(
        tester
            .getRect(find
                .text(name == 'plan-keyboard'
                    ? 'Training plan'
                    : 'For this session')
                .last)
            .top,
        greaterThanOrEqualTo(0));
  }
  expect(tester.takeException(), isNull);
  await expectLater(
      find.byKey(key),
      matchesGoldenFile(
          'goldens/home-routines-correction/$screen-$name-${palette.name}-${scale}x.png'));
  if (Platform.environment['HOME_ROUTINES_SAVE_AFTER'] == '1') {
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final raster = await boundary.toImage(pixelRatio: 2);
      final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
          'docs/upgrade/renders/home-routines-correction/after/$screen-$name-${palette.name}-${scale}x.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      raster.dispose();
    });
  }
  if (pending != null) {
    pending.complete(true);
    await tester.pumpAndSettle();
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

class IllustrativeKeyboard extends StatelessWidget {
  const IllustrativeKeyboard({super.key});
  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
      child: Material(
          color: context.surface.surface2,
          child: SizedBox(
              height: 280,
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    const SizedBox(
                        height: 32,
                        child:
                            Center(child: Text('Search keyboard · simulated'))),
                    for (final row in ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'])
                      Expanded(
                          child: Row(children: [
                        for (final letter in row.split(''))
                          Expanded(
                              child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                      color: context.surface.surface3,
                                      borderRadius: AppRadius.badgeAll),
                                  alignment: Alignment.center,
                                  child: Text(letter, style: AppText.body())))
                      ])),
                    Expanded(
                        child: Row(children: [
                      Expanded(
                          flex: 4,
                          child: Container(
                              margin: const EdgeInsets.all(3),
                              color: context.surface.surface3,
                              child: const Center(child: Text('space')))),
                      Expanded(
                          child: Container(
                              margin: const EdgeInsets.all(3),
                              color: context.surface.surface3,
                              child: const Center(
                                  child: Icon(Icons.search_rounded))))
                    ])),
                  ])))));
}
