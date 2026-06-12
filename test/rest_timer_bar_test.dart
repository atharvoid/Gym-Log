// Guards against the catastrophic "rest timer fills the whole screen" bug.
//
// RestTimerBar lives in the Active Workout's bottomNavigationBar, which
// passes loose (up to full-screen) height constraints. This test pumps it
// in that exact position on a tall viewport and asserts the rendered tile
// stays compact — it must never stretch to fill the screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/widgets/rest_timer_bar.dart';

void main() {
  testWidgets('RestTimerBar stays compact in a bottomNavigationBar',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: RestTimerBar(
              state: RestTimerState(totalSeconds: 90, remainingSeconds: 54),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(RestTimerBar), findsOneWidget);
    expect(find.text('0:54'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // The whole bar (incl. padding + safe area) must be far smaller than the
    // screen — a regression to the full-screen layout would blow past this.
    final barHeight = tester.getSize(find.byType(RestTimerBar)).height;
    expect(barHeight, lessThan(140),
        reason: 'rest tile must stay compact, not fill the screen');
    expect(barHeight, greaterThan(kRestTileHeight - 1));
  });
}
