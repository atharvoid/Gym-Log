import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/profile/presentation/widgets/graph_kpi_header.dart';
import 'package:gymlog/features/profile/presentation/widgets/profile_graph_empty_state.dart';
import 'package:gymlog/features/profile/presentation/widgets/profile_graph_low_data_banner.dart';
import 'package:gymlog/features/profile/presentation/widgets/weekly_bar_chart.dart';

// Helper to build 4 filled weeks of aggregates (delta pill threshold).
List<WeeklyAggregate> _fourWeeks({
  double week1 = 2000,
  double week2 = 2500,
  double week3 = 3000,
  double week4 = 4500,
}) =>
    [
      WeeklyAggregate(
        weekStart: DateTime(2024, 5, 27),
        volumeKg: week1,
        totalReps: 200,
        duration: const Duration(minutes: 60),
        workoutCount: 2,
      ),
      WeeklyAggregate(
        weekStart: DateTime(2024, 6, 3),
        volumeKg: week2,
        totalReps: 250,
        duration: const Duration(minutes: 75),
        workoutCount: 2,
      ),
      WeeklyAggregate(
        weekStart: DateTime(2024, 6, 10),
        volumeKg: week3,
        totalReps: 300,
        duration: const Duration(minutes: 90),
        workoutCount: 2,
      ),
      WeeklyAggregate(
        weekStart: DateTime(2024, 6, 17),
        volumeKg: week4,
        totalReps: 450,
        duration: const Duration(minutes: 120),
        workoutCount: 3,
      ),
    ];

void main() {
  group('ProfileGraphEmptyState', () {
    testWidgets('renders title, subtitle and CTA', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileGraphEmptyState(
              onStartWorkout: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No workouts yet'), findsOneWidget);
      expect(
        find.text('Log your first workout to see your weekly progress.'),
        findsOneWidget,
      );
      expect(find.text('Start Workout'), findsOneWidget);

      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('GraphKpiHeader', () {
    // Two weeks only — delta pill should be SUPPRESSED (n<4 is too noisy).
    final twoWeeks = [
      WeeklyAggregate(
        weekStart: DateTime(2024, 6, 10),
        volumeKg: 3000,
        totalReps: 300,
        duration: const Duration(minutes: 90),
        workoutCount: 2,
      ),
      WeeklyAggregate(
        weekStart: DateTime(2024, 6, 17),
        volumeKg: 4500,
        totalReps: 450,
        duration: const Duration(minutes: 120),
        workoutCount: 3,
      ),
    ];

    testWidgets(
        'shows latest value and "This week" caption always when data exists',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphKpiHeader(
              aggregates: twoWeeks,
              metric: ProfileGraphMetric.volume,
            ),
          ),
        ),
      );

      expect(find.text('4,500 kg'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('hides delta pill when fewer than 4 filled weeks have data',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphKpiHeader(
              aggregates: twoWeeks,
              metric: ProfileGraphMetric.volume,
            ),
          ),
        ),
      );

      // No percentage should appear — 2 weeks is too few to be meaningful.
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows delta pill once 4+ filled weeks have data',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphKpiHeader(
              aggregates: _fourWeeks(),
              metric: ProfileGraphMetric.volume,
            ),
          ),
        ),
      );

      expect(find.text('4,500 kg'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      // 4500 vs 3000 → +50%
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('shows neutral dash in delta pill when previous week value is zero',
        (tester) async {
      // Need ≥4 filled weeks for the pill to appear, with previous=0.
      final withZeroPrevious = [
        WeeklyAggregate(
          weekStart: DateTime(2024, 5, 27),
          volumeKg: 1000,
          totalReps: 100,
          duration: const Duration(minutes: 30),
          workoutCount: 1,
        ),
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 3),
          volumeKg: 1500,
          totalReps: 150,
          duration: const Duration(minutes: 45),
          workoutCount: 1,
        ),
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 10),
          volumeKg: 0, // previous week is zero
          totalReps: 0,
          duration: Duration.zero,
          workoutCount: 1,
        ),
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 17),
          volumeKg: 4000,
          totalReps: 400,
          duration: const Duration(minutes: 100),
          workoutCount: 2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphKpiHeader(
              aggregates: withZeroPrevious,
              metric: ProfileGraphMetric.volume,
            ),
          ),
        ),
      );

      expect(find.text('4,000 kg'), findsOneWidget);
      // When previous is 0, the pill shows "vs last week" neutral label (no %).
      expect(find.text('vs last week'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('WeeklyBarChart', () {
    final aggregates = [
      for (var i = 0; i < 8; i++)
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 3).add(Duration(days: 7 * i)),
          volumeKg: (i + 1) * 1000,
          totalReps: (i + 1) * 100,
          duration: Duration(minutes: (i + 1) * 30),
          workoutCount: i + 1,
        ),
    ];

    testWidgets('renders 8 weekly x-axis labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(
              aggregates: aggregates,
              metric: ProfileGraphMetric.volume,
              isPremium: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jun 3'), findsOneWidget);
      expect(find.text('Jun 10'), findsOneWidget);
      expect(find.text('Jun 17'), findsOneWidget);
      expect(find.text('Jun 24'), findsOneWidget);
      expect(find.text('Jul 1'), findsOneWidget);
      expect(find.text('Jul 8'), findsOneWidget);
      expect(find.text('Jul 15'), findsOneWidget);
      expect(find.text('Jul 22'), findsOneWidget);
    });

    testWidgets('uses duration unit on Y-axis for duration metric',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(
              aggregates: aggregates,
              metric: ProfileGraphMetric.duration,
              isPremium: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0m'), findsWidgets);
    });

    testWidgets('uses compact numbers on Y-axis for volume metric',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(
              aggregates: aggregates,
              metric: ProfileGraphMetric.volume,
              isPremium: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4k'), findsWidgets);
    });

    testWidgets('shows comparison view when fewer than 4 filled weeks',
        (tester) async {
      // Only 2 filled weeks — should render the comparison stat view, not a chart.
      final twoFilled = [
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 10),
          volumeKg: 3990,
          totalReps: 300,
          duration: const Duration(minutes: 90),
          workoutCount: 2,
        ),
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 17),
          volumeKg: 6780,
          totalReps: 450,
          duration: const Duration(minutes: 120),
          workoutCount: 3,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(
              aggregates: twoFilled,
              metric: ProfileGraphMetric.volume,
              isPremium: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Comparison view should show "This week" and "Last week" labels.
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Last week'), findsOneWidget);
      // Progress unlock message should be visible.
      expect(
        find.textContaining('more week'),
        findsOneWidget,
      );
    });
  });

  group('ProfileGraphLowDataBanner', () {
    testWidgets('renders info message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileGraphLowDataBanner()),
        ),
      );

      expect(
        find.text('Log 2 more workouts to unlock your full trend.'),
        findsOneWidget,
      );
    });
  });
}
