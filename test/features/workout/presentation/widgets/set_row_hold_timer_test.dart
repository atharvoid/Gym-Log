import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/widgets/set_row.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SetRow Hold Timer Integration Tests', () {
    testWidgets(
        'renders play icon trigger and TextField for duration measurementType',
        (tester) async {
      var started = false;

      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData: const WorkoutSetState(id: 's1', reps: 0),
            measurementType: MeasurementType.duration,
            onChanged: (_) {},
            onToggleComplete: () {},
            onStartHoldTimer: () => started = true,
          ),
        ),
      );

      // Finds the quick play timer trigger icon
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tapping the play icon triggers onStartHoldTimer
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(started, isTrue);

      // For unweighted duration, only ONE TextField exists (TIME field)
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows two TextFields for weighted duration exercise',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData: const WorkoutSetState(id: 's1', reps: 0),
            measurementType: MeasurementType.duration,
            showsWeightColumn: true,
            onChanged: (_) {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Weight (+KG) and Duration (TIME) text fields are both rendered
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('renders active running pill when isHoldTimerRunning is true',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData: const WorkoutSetState(id: 's1', reps: 0),
            measurementType: MeasurementType.duration,
            isHoldTimerRunning: true,
            holdTimerDisplaySeconds: 24,
            onChanged: (_) {},
            onToggleComplete: () {},
          ),
        ),
      );

      expect(find.text('0:24'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('renders replay icon when set is completed', (tester) async {
      var restarted = false;

      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData:
                const WorkoutSetState(id: 's1', reps: 45, isCompleted: true),
            measurementType: MeasurementType.duration,
            onChanged: (_) {},
            onToggleComplete: () {},
            onStartHoldTimer: () => restarted = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
      expect(find.text('45s'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.replay_rounded));
      expect(restarted, isTrue);
    });

    testWidgets('tapping running timer pill triggers onFinishHoldTimer',
        (tester) async {
      var finished = false;

      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData: const WorkoutSetState(id: 's1', reps: 0),
            measurementType: MeasurementType.duration,
            isHoldTimerRunning: true,
            holdTimerDisplaySeconds: 12,
            onChanged: (_) {},
            onToggleComplete: () {},
            onFinishHoldTimer: () => finished = true,
          ),
        ),
      );

      expect(find.text('0:12'), findsOneWidget);
      await tester.tap(find.text('0:12'));
      expect(finished, isTrue);
    });

    testWidgets(
        'tapping checkmark while timer is running triggers onFinishHoldTimer',
        (tester) async {
      var finished = false;

      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData: const WorkoutSetState(id: 's1', reps: 0),
            measurementType: MeasurementType.duration,
            isHoldTimerRunning: true,
            holdTimerDisplaySeconds: 30,
            onChanged: (_) {},
            onToggleComplete: () {},
            onFinishHoldTimer: () => finished = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check_rounded));
      expect(finished, isTrue);
    });

    testWidgets('completed duration renders 45s and allows tapping to edit',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData:
                const WorkoutSetState(id: 's1', reps: 45, isCompleted: true),
            measurementType: MeasurementType.duration,
            onChanged: (_) {},
            onToggleComplete: () {},
          ),
        ),
      );

      expect(find.text('45s'), findsOneWidget);
      await tester.tap(find.text('45s'));
      await tester.pumpAndSettle();

      // Enters inline edit mode with TextField
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('running timer pill does not overflow on 320px narrow viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(
          SetRow(
            setIndex: 0,
            setData: const WorkoutSetState(id: 's1', reps: 0),
            measurementType: MeasurementType.duration,
            isHoldTimerRunning: true,
            holdTimerDisplaySeconds: 125,
            onChanged: (_) {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Verify label is rendered inside the running badge and no Flutter errors
      expect(find.text('2:05'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
