import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/routines/presentation/providers/training_launch_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';

class RecordingLauncher implements TrainingLauncher {
  final calls = <String?>[];
  final Completer<LaunchResult>? completion;
  RecordingLauncher([this.completion]);
  @override
  Future<LaunchResult> startRoutine(String id) async {
    calls.add(id);
    return completion == null ? LaunchResult.started : await completion!.future;
  }

  @override
  Future<LaunchResult> startFreestyle() async {
    calls.add(null);
    return LaunchResult.started;
  }
}

void main() {
  setUpAll(loadSessionFonts);
  Future<void> render(WidgetTester tester, RecordingLauncher launcher,
      {bool empty = false}) async {
    SharedPreferences.setMockInitialValues({
      'first_run_tour_step': -1,
      if (!empty) 'training_routine:local': 'sample-0'
    });
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, state) => currentLaunchScreen('home')),
      GoRoute(
          path: '/workout/active',
          builder: (_, state) => const Scaffold(body: Text('Active route'))),
      GoRoute(
          path: '/workout/detail/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['id']}'))),
    ]);
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(launchFixtureApp(
        child: const SizedBox.shrink(),
        router: router,
        palette: ThemePalette.higgsfield,
        scale: 1,
        screen: 'home',
        fixtureState: empty ? LaunchState.empty : LaunchState.returning,
        captureKey: const ValueKey('actions'),
        overrides: [trainingLauncherProvider.overrideWithValue(launcher)]));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'empty Home starts the first workout directly without saving a plan',
      (tester) async {
    final launcher = RecordingLauncher();
    await render(tester, launcher, empty: true);
    final start = find.text('Start workout');
    expect(start.hitTestable(), findsOneWidget);
    expect(find.text('Browse programs'), findsOneWidget);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(launcher.calls, [null]);
    expect(find.text('Active route'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance())
            .getString('training_plan:v1:local'),
        isNull);
  });

  for (final freestyle in [false, true]) {
    testWidgets(
        'one-session ${freestyle ? 'freestyle' : 'routine'} launches without changing saved plan',
        (tester) async {
      final launcher = RecordingLauncher();
      await render(tester, launcher);
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString('training_plan:v1:local');
      await tester.tap(find.text('Train something else'));
      await tester.pumpAndSettle();
      final target = freestyle
          ? find.text('Start without a routine')
          : find.byKey(const ValueKey('choose-sample-1'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(launcher.calls, [freestyle ? null : 'sample-1']);
      expect(find.text('Active route'), findsOneWidget);
      expect(prefs.getString('training_plan:v1:local'), before);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'double-tapping an override issues one launch; failure leaves choices retryable',
      (tester) async {
    final completion = Completer<LaunchResult>();
    final launcher = RecordingLauncher(completion);
    await render(tester, launcher);
    await tester.tap(find.text('Train something else'));
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('choose-sample-0'));
    await tester.tap(choice);
    await tester.tap(choice);
    expect(launcher.calls, ['sample-0']);
    completion.complete(LaunchResult.unavailable);
    await tester.pumpAndSettle();
    expect(find.text('This routine is unavailable. Choose another.'),
        findsOneWidget);
    expect(find.text('For this session'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance())
            .getString('training_routine:local'),
        'sample-0');
  });
  testWidgets('last-workout card opens the persisted global session detail',
      (tester) async {
    await render(tester, RecordingLauncher());
    await tester.tap(find.text('Pull A').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail sample-session-1'), findsOneWidget);
  });
}
