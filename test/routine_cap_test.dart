// Pure-logic tests for the free-tier routine cap + chart gating helpers.
// No database, no widgets — just the gating math.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/providers/premium_provider.dart';

void main() {
  test('free routine cap is 4 and gates exactly at the limit', () {
    expect(kFreeRoutineLimit, 4);

    // Free users: blocked only at/over the cap.
    expect(isAtFreeRoutineLimit(isPremium: false, routineCount: 0), isFalse);
    expect(isAtFreeRoutineLimit(isPremium: false, routineCount: 3), isFalse);
    expect(isAtFreeRoutineLimit(isPremium: false, routineCount: 4), isTrue);

    // Grandfathered free users (legacy / post-downgrade) keep their routines
    // but stay blocked from adding more until back under the cap.
    expect(isAtFreeRoutineLimit(isPremium: false, routineCount: 9), isTrue);

    // Pro is never gated.
    expect(isAtFreeRoutineLimit(isPremium: true, routineCount: 99), isFalse);
  });

  test('gateChartSamples shows 3 recent for free, everything for pro', () {
    final series = List<int>.generate(10, (i) => i);
    expect(gateChartSamples(series, false), [7, 8, 9]);
    expect(gateChartSamples(series, true), series);
    // Short series are never clipped.
    expect(gateChartSamples(<int>[1, 2], false), [1, 2]);
  });
}
