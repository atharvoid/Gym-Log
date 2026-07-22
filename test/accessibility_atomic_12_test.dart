import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_event_provider.dart';
import 'package:gymlog/features/workout/presentation/widgets/set_row.dart';
import 'package:gymlog/shared/widgets/branded_line_chart.dart';
import 'package:gymlog/shared/widgets/motion/app_motion.dart';
import 'package:gymlog/shared/widgets/ui/segmented_control.dart';
import 'package:gymlog/shared/widgets/ui/toggle_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ATOMIC-12 Accessibility & Screen-Reader Qualification', () {
    testWidgets(
        'SetRow renders single coherent semantic label with custom actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      const setData = WorkoutSetState(
        id: 's1',
        weightKg: 82.5,
        reps: 8,
        isCompleted: false,
        setType: 'normal',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SetRow(
                setIndex: 1,
                setData: setData,
                measurementType: MeasurementType.weightAndReps,
                previousWeight: 80.0,
                previousReps: 8,
                unit: 'kg',
                onChanged: (_) {},
                onToggleComplete: () {},
              ),
            ),
          ),
        ),
      );

      // Find semantics node for SetRow
      final setRowFinder = find.byType(SetRow);
      expect(setRowFinder, findsOneWidget);

      final semanticsNode = tester.getSemantics(setRowFinder);
      expect(semanticsNode.label, contains('Set 2'));
      expect(semanticsNode.label, contains('Previous: 80kg x 8'));
      expect(semanticsNode.label, contains('Weight: 82.5 kilograms'));
      expect(semanticsNode.label, contains('Reps: 8'));
      expect(semanticsNode.label, contains('Not completed'));

      expect(semanticsNode.getSemanticsData().customSemanticsActionIds,
          isNotEmpty);

      handle.dispose();
    });

    testWidgets('AppMotion respects disableAnimations', (tester) async {
      late Duration normalDuration;
      late Duration reducedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              normalDuration = AppMotion.effective(
                context,
                const Duration(milliseconds: 300),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                reducedDuration = AppMotion.effective(
                  context,
                  const Duration(milliseconds: 300),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(normalDuration, equals(const Duration(milliseconds: 300)));
      expect(reducedDuration, equals(Duration.zero));
    });

    testWidgets('Pills and Controls expose button and selected semantics',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TogglePill(
                  label: 'Active Filter',
                  isActive: true,
                  onTap: () {},
                ),
                SegmentedControl(
                  segments: const ['Kg', 'Lbs'],
                  selected: 'Kg',
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final toggleFinder = find.byType(TogglePill);
      final toggleSemantics = tester.getSemantics(toggleFinder);
      expect(toggleSemantics, isSemantics(isButton: true, isSelected: true));

      handle.dispose();
    });

    testWidgets('BrandedLineChart exposes summary semantics and data table',
        (tester) async {
      final handle = tester.ensureSemantics();
      final points = [
        ChartPoint(DateTime(2026, 1, 1), 1000),
        ChartPoint(DateTime(2026, 1, 2), 1200),
        ChartPoint(DateTime(2026, 1, 3), 1500),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BrandedLineChart(
                data: points,
                valueFormatter: (v) => '${v.toInt()} kg',
                yAxisUnit: 'kg',
              ),
            ),
          ),
        ),
      );

      final chartFinder = find.byType(BrandedLineChart);
      final chartSemantics = tester.getSemantics(chartFinder);
      expect(chartSemantics.label, contains('kg chart'));
      expect(chartSemantics.label, contains('Latest: 1500 kg'));
      expect(chartSemantics.label, contains('Min: 1000 kg'));
      expect(chartSemantics.label, contains('Max: 1500 kg'));
      expect(chartSemantics.label, contains('Trend: Increasing'));
      expect(chartSemantics.label, contains('3 points'));

      // Tap View Data Table
      final buttonFinder = find.text('View data table');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Hide data table'), findsOneWidget);
      expect(find.text('1500 kg'), findsWidgets);

      handle.dispose();
    });

    testWidgets('SetRow renders without overflow at 200% text scale',
        (tester) async {
      const setData = WorkoutSetState(
        id: 's1',
        weightKg: 100.0,
        reps: 10,
        isCompleted: false,
        setType: 'normal',
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
          ),
          child: ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SetRow(
                  setIndex: 0,
                  setData: setData,
                  measurementType: MeasurementType.weightAndReps,
                  previousWeight: 95.0,
                  previousReps: 10,
                  unit: 'kg',
                  onChanged: (_) {},
                  onToggleComplete: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('Timer events contain exerciseName for accessibility announcements',
        () {
      const startEv = TimerStartedEvent(
        seconds: 90,
        workoutId: 'w1',
        exerciseId: 1,
        setId: 's1',
        exerciseName: 'Deadlift',
      );

      const expEv = TimerExpiredEvent(
        workoutId: 'w1',
        exerciseId: 1,
        setId: 's1',
        exerciseName: 'Deadlift',
      );

      expect(startEv.exerciseName, equals('Deadlift'));
      expect(expEv.exerciseName, equals('Deadlift'));
    });
  });
}
