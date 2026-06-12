// Regression guard for the "keyboard dismisses on every tap" ship-blocker.
//
// Root cause was hosting SetRow inside a ReorderableListView: a keystroke →
// updateSet → provider rebuild made ReorderableListView's internal per-item
// GlobalKeys collide and stole focus. A keyed SetRow in a plain ListView
// must keep its FocusNode (and entered value) across an ancestor rebuild.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/widgets/set_row.dart';

void main() {
  testWidgets('SetRow keeps focus + value across an ancestor rebuild',
      (tester) async {
    var sets = <WorkoutSetState>[
      const WorkoutSetState(id: 'a'),
      const WorkoutSetState(id: 'b'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  // A sibling whose changes force the list to rebuild —
                  // simulating the per-keystroke provider rebuild.
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('rebuild'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sets.length,
                      itemBuilder: (context, i) => SetRow(
                        key: ValueKey(sets[i].id),
                        setIndex: i,
                        setData: sets[i],
                        onChanged: (updated) => sets[i] = updated,
                        onToggleComplete: () {},
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Focus the first weight field and type a value.
    final weightField = find.byType(TextField).first;
    await tester.tap(weightField);
    await tester.pump();
    await tester.enterText(weightField, '100');
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    // Force an ancestor rebuild — the failure mode dismissed focus here.
    await tester.tap(find.text('rebuild'));
    await tester.pumpAndSettle();

    // Value survived and a field is still focused (keyboard would stay up).
    expect(find.text('100'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
  });
}
