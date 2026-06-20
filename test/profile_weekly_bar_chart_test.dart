import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/profile/presentation/widgets/graph_kpi_header.dart';
import 'package:gymlog/features/profile/presentation/widgets/profile_graph_empty_state.dart';
import 'package:gymlog/features/profile/presentation/widgets/profile_graph_low_data_banner.dart';
import 'package:gymlog/features/profile/presentation/widgets/weekly_bar_chart.dart';

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

    testWidgets('shows latest value and delta pill when ≥2 weeks have data',
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
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('hides delta pill when fewer than 2 weeks have data',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphKpiHeader(
              aggregates: twoWeeks.sublist(0, 1),
              metric: ProfileGraphMetric.volume,
            ),
          ),
        ),
      );

      expect(find.text('3,000 kg'), findsOneWidget);
      expect(find.text('%'), findsNothing);
    });

    testWidgets('shows neutral dash when previous week value is zero',
        (tester) async {
      final withZeroPrevious = [
        WeeklyAggregate(
          weekStart: DateTime(2024, 6, 10),
          volumeKg: 0,
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
      expect(find.text('—'), findsOneWidget);
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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4k'), findsWidgets);
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

