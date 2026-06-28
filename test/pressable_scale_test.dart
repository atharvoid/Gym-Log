import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';

void main() {
  double scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('forwards taps to the child (does not steal the gesture)',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressableScale(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 200, height: 60),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnimatedScale));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('press squeezes, release springs back', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressableScale(
              pressedScale: 0.9,
              child: Container(
                width: 200,
                height: 60,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );

    expect(scaleOf(tester), 1.0);

    final g =
        await tester.startGesture(tester.getCenter(find.byType(AnimatedScale)));
    await tester.pump();
    expect(scaleOf(tester), 0.9);

    await g.up();
    await tester.pump();
    expect(scaleOf(tester), 1.0);
  });

  testWidgets('reduce motion → no squeeze', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: PressableScale(
                pressedScale: 0.9,
                child: Container(
                  width: 200,
                  height: 60,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final g =
        await tester.startGesture(tester.getCenter(find.byType(AnimatedScale)));
    await tester.pump();
    expect(scaleOf(tester), 1.0); // stayed still
    await g.up();
  });
}
