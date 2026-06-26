import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

void main() {
  testWidgets(
      'ActiveWorkoutScreen minimize handle has tap gesture, semantics and pops router',
      (tester) async {
    final container = ProviderContainer();
    final notifier = container.read(activeWorkoutProvider.notifier);

    // Initialize with a mock active workout state
    await notifier.startWorkout(
      initialExercises: const [
        WorkoutExerciseState(id: 'ex1', exerciseId: 1, name: 'Bench Press'),
      ],
    );

    // Track navigation pop
    bool didPop = false;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            if (didPop) {
              return const Scaffold(body: Text('Home Popped'));
            }
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/active'),
                child: const Text('Go Active'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/active',
          builder: (context, state) => const ActiveWorkoutScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to active screen
    await tester.tap(find.text('Go Active'));
    await tester.pumpAndSettle();

    // Verify grab handle semantics properties
    final semanticsFinder = find.byWidgetPredicate((widget) =>
        widget is Semantics &&
        widget.properties.label == 'Minimize workout' &&
        widget.properties.button == true);

    expect(semanticsFinder, findsOneWidget);

    // Verify touch target size is >= 48dp vertically
    final targetSize = tester.getSize(semanticsFinder);
    expect(targetSize.height, greaterThanOrEqualTo(48.0),
        reason: 'Touch target height must be >= 48dp');

    // Tap grab handle
    didPop = true; // Mark that pop is about to occur
    await tester.tap(semanticsFinder);
    await tester.pumpAndSettle();

    // Verify router popped back to initial route /
    expect(find.text('Home Popped'), findsOneWidget,
        reason: 'Tapping minimize grab handle should pop navigation');
  });
}
