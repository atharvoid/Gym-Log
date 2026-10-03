import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/features/workout/domain/hold_timer_state.dart';
import 'package:gymlog/features/workout/presentation/widgets/hold_timer_bar.dart';

void main() {
  testWidgets('HoldTimerBar stays compact in a bottomNavigationBar',
      (tester) async {
    final state = HoldTimerState(
      workoutId: 'w1',
      exerciseIndex: 0,
      setIndex: 0,
      setId: 's1',
      exerciseName: 'Plank',
      mode: HoldTimerMode.countdown,
      phase: HoldTimerPhase.holding,
      targetSeconds: 45,
      elapsedSeconds: 15,
      startTime: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: HoldTimerBar(state: state),
          ),
        ),
      ),
    );

    expect(find.byType(HoldTimerBar), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    final barHeight = tester.getSize(find.byType(HoldTimerBar)).height;
    expect(barHeight, lessThan(140),
        reason: 'hold tile must stay compact, not stretch or fill screen');
    expect(barHeight, greaterThan(kHoldTileHeight - 1));
  });

  testWidgets('HoldTimerBar renders prep state correctly', (tester) async {
    final prepState = HoldTimerState(
      workoutId: 'w1',
      exerciseIndex: 0,
      setIndex: 0,
      setId: 's1',
      exerciseName: 'Dead Hang',
      mode: HoldTimerMode.stopwatch,
      phase: HoldTimerPhase.prep,
      prepSecondsRemaining: 3,
      elapsedSeconds: 0,
      startTime: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HoldTimerBar(state: prepState),
          ),
        ),
      ),
    );

    expect(find.text('GET READY'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('HoldTimerBar does NOT wrap digits vertically on narrow viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = HoldTimerState(
      workoutId: 'w1',
      exerciseIndex: 0,
      setIndex: 0,
      setId: 's1',
      exerciseName: 'Weighted Front Plank',
      mode: HoldTimerMode.stopwatch,
      phase: HoldTimerPhase.holding,
      elapsedSeconds: 23,
      startTime: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HoldTimerBar(state: state),
          ),
        ),
      ),
    );

    expect(find.text('0:23'), findsOneWidget);
    final textWidget = tester.widget<Text>(find.text('0:23'));
    expect(textWidget.softWrap, isFalse);
    expect(textWidget.maxLines, 1);
  });
}
