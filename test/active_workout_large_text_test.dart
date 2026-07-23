import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_timer_provider.dart';

class _StubTimer extends WorkoutTimer {
  @override
  String build() => '00:00:00';
}

ProviderContainer createContainer() {
  final container = ProviderContainer(
    overrides: [
      workoutTimerProvider.overrideWith(() => _StubTimer()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget buildApp(WidgetTester tester, ProviderContainer pc,
    {double textScale = 1.0}) {
  final mq = MediaQueryData.fromView(tester.view).copyWith(
    textScaler: TextScaler.linear(textScale),
  );
  return MediaQuery(
    data: mq,
    child: UncontrolledProviderScope(
      container: pc,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/active',
          routes: [
            GoRoute(
              path: '/active',
              builder: (_, __) => const ActiveWorkoutScreen(),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('ActiveWorkout large-text header', () {
    testWidgets('pumps at 390x844 1.0x', (tester) async {
      final container = createContainer();
      setViewport(tester, const Size(390, 844));
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        name: 'Test',
        initialExercises: const [
          WorkoutExerciseState(id: 'e1', exerciseId: 1, name: 'Push Up'),
        ],
      );
      await tester.pumpWidget(buildApp(tester, container));
      await tester.pump();

      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Push Up'), findsOneWidget);
    });

    testWidgets('pumps at 390x844 1.6x', (tester) async {
      final container = createContainer();
      setViewport(tester, const Size(390, 844));
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        name: 'Test',
        initialExercises: const [
          WorkoutExerciseState(id: 'e1', exerciseId: 1, name: 'Push Up'),
        ],
      );
      await tester.pumpWidget(buildApp(tester, container, textScale: 1.6));
      await tester.pump();

      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Push Up'), findsOneWidget);
    });

    testWidgets('pumps at 390x844 2.0x', (tester) async {
      final container = createContainer();
      setViewport(tester, const Size(390, 844));
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        name: 'Test',
        initialExercises: const [
          WorkoutExerciseState(id: 'e1', exerciseId: 1, name: 'Push Up'),
        ],
      );
      await tester.pumpWidget(buildApp(tester, container, textScale: 2.0));
      await tester.pump();

      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Push Up'), findsOneWidget);
    });

    testWidgets('Finish button renders at default scale', (tester) async {
      final container = createContainer();
      setViewport(tester, const Size(390, 844));
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(
        name: 'Test',
        initialExercises: const [
          WorkoutExerciseState(id: 'e1', exerciseId: 1, name: 'Push Up'),
        ],
      );
      await tester.pumpWidget(buildApp(tester, container));
      await tester.pump();

      expect(find.text('Finish'), findsOneWidget);
    });
  });
}
