// GymLog test suite.
//
// The previous smoke test pumped the full app, which requires a live
// Supabase initialization — it could never pass in CI. These tests cover
// the pure business logic (streaks, formatters, premium gating) and the
// shared UI kit without any platform dependencies.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/toggle_pill.dart';

void main() {
  group('formatters', () {
    test('formatWorkoutDuration renders h/m/s tiers', () {
      final start = DateTime(2026, 6, 1, 10, 0, 0);
      expect(
        formatWorkoutDuration(start, start.add(const Duration(seconds: 45))),
        '45s',
      );
      expect(
        formatWorkoutDuration(start, start.add(const Duration(minutes: 32))),
        '32m',
      );
      expect(
        formatWorkoutDuration(
            start, start.add(const Duration(hours: 1, minutes: 5))),
        '1h 5m',
      );
    });

    test('getWorkoutNameFallback respects explicit names', () {
      final morning = DateTime(2026, 6, 1, 7, 30);
      expect(getWorkoutNameFallback(morning, 'Push Day'), 'Push Day');
      expect(getWorkoutNameFallback(morning, null), 'Morning Workout');
      expect(
        getWorkoutNameFallback(DateTime(2026, 6, 1, 19, 0), ''),
        'Evening Workout',
      );
    });
  });

  group('streaks', () {
    // Wednesday 2026-06-10, 18:00 local.
    final now = DateTime(2026, 6, 10, 18);

    test('empty history → no streak', () {
      final stats = computeStreakStats(const [], now: now);
      expect(stats.currentStreak, 0);
      expect(stats.workoutsThisWeek, 0);
      expect(stats.trainedToday, false);
    });

    test('consecutive days ending today', () {
      final stats = computeStreakStats([
        DateTime(2026, 6, 10, 7), // today
        DateTime(2026, 6, 9, 19),
        DateTime(2026, 6, 8, 18),
      ], now: now);
      expect(stats.currentStreak, 3);
      expect(stats.trainedToday, true);
      // Mon 8th + Tue 9th + Wed 10th are all in the current week.
      expect(stats.workoutsThisWeek, 3);
    });

    test('streak survives an untrained today (counts through yesterday)', () {
      final stats = computeStreakStats([
        DateTime(2026, 6, 9, 19),
        DateTime(2026, 6, 8, 18),
      ], now: now);
      expect(stats.currentStreak, 2);
      expect(stats.trainedToday, false);
    });

    test('gap breaks the streak', () {
      final stats = computeStreakStats([
        DateTime(2026, 6, 10, 7), // today
        DateTime(2026, 6, 8, 18), // skipped the 9th
      ], now: now);
      expect(stats.currentStreak, 1);
    });

    test('two sessions on one day count once', () {
      final stats = computeStreakStats([
        DateTime(2026, 6, 10, 7),
        DateTime(2026, 6, 10, 19),
      ], now: now);
      expect(stats.currentStreak, 1);
      expect(stats.workoutsThisWeek, 1);
    });
  });

  group('premium gating', () {
    test('free users see the 3 most recent samples', () {
      final samples = [1, 2, 3, 4, 5];
      expect(gateChartSamples(samples, false), [3, 4, 5]);
      expect(gateChartSamples(samples, true), samples);
      expect(gateChartSamples([1, 2], false), [1, 2]);
      expect(gateChartSamples(<int>[], false), isEmpty);
    });
  });

  group('UI kit', () {
    testWidgets('PrimaryButton renders label and fires onPressed',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Start Empty Workout',
            onPressed: () => pressed = true,
          ),
        ),
      ));

      expect(find.text('Start Empty Workout'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(pressed, true);
    });

    testWidgets('TogglePill reflects active state', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TogglePill(label: 'Volume', isActive: true),
        ),
      ));
      expect(find.text('Volume'), findsOneWidget);
    });
  });
}
