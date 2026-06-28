// Locks the five Hevy-inspired Active Workout set-row behaviours so a future
// refactor can't quietly reintroduce the clutter this pass removed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/widgets/set_row.dart';

void main() {
  Widget host(SetRow row) => MaterialApp(
        home: Scaffold(body: row),
      );

  testWidgets('PREVIOUS column shows "15kg x 12" when prior data exists',
      (tester) async {
    await tester.pumpWidget(host(SetRow(
      setIndex: 0,
      setData: const WorkoutSetState(id: 's1'),
      previousWeight: 15, // kg
      previousReps: 12,
      unit: 'kg',
      onChanged: (_) {},
      onToggleComplete: () {},
    )));

    expect(find.text('15kg x 12'), findsOneWidget);
  });

  testWidgets('PREVIOUS shows blank when there is no prior data',
      (tester) async {
    await tester.pumpWidget(host(SetRow(
      setIndex: 0,
      setData: const WorkoutSetState(id: 's1'),
      onChanged: (_) {},
      onToggleComplete: () {},
    )));

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    final emptyTexts = textWidgets.where((t) => t.data == '');
    expect(emptyTexts.length, 1);
  });

  testWidgets('SET column renders the type letter, never a number, for warmup',
      (tester) async {
    await tester.pumpWidget(host(SetRow(
      setIndex: 0, // would be "1" if it were a normal set
      setData: const WorkoutSetState(id: 's1', setType: 'warmup'),
      onChanged: (_) {},
      onToggleComplete: () {},
    )));

    expect(find.text('W'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('normal set shows its 1-based number in the SET column',
      (tester) async {
    await tester.pumpWidget(host(SetRow(
      setIndex: 2,
      setData: const WorkoutSetState(id: 's1'),
      onChanged: (_) {},
      onToggleComplete: () {},
    )));

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no inline "kg" label and no "×" divider on the row',
      (tester) async {
    await tester.pumpWidget(host(SetRow(
      setIndex: 0,
      setData: const WorkoutSetState(id: 's1', weightKg: 30, reps: 10),
      unit: 'kg',
      onChanged: (_) {},
      onToggleComplete: () {},
    )));

    // The unit moved to the column header; the row carries neither the
    // standalone "kg" label nor the multiplication separator.
    expect(find.text('kg'), findsNothing);
    expect(find.text('×'), findsNothing);
  });
}
