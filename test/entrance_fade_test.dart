import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/motion/entrance_fade.dart';

void main() {
  testWidgets('snaps to final state immediately under disableAnimations',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: EntranceFade(child: Text('hi')),
        ),
      ),
    );
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(EntranceFade),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('animates from hidden to shown when motion is enabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EntranceFade(child: Text('hi'))),
    );
    await tester.pump(); // first frame: hidden
    final fadeStart = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(EntranceFade),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fadeStart.opacity.value, lessThan(1.0));
    await tester.pumpAndSettle(); // entrance completes
    final fadeEnd = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(EntranceFade),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fadeEnd.opacity.value, 1.0);
  });
}
