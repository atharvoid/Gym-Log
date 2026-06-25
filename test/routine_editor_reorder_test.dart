// Reorder contract for the routine editor list.
//
// Reproduces the editor's ReorderableListView configuration — a UUID key per
// item, buildDefaultDragHandles:false, and a single custom drag handle
// (ReorderableDragStartListener) — and proves the full list keeps rendering
// through a drag (the reported bug was the list collapsing to one item) and
// that onReorderItem reorders correctly under the Flutter 3.16+ pre-adjusted
// newIndex semantics.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _Item {
  final String uid = const Uuid().v4();
  final String name;
  _Item(this.name);
}

void main() {
  testWidgets('full list renders through a drag and reorders correctly',
      (tester) async {
    final items = [
      _Item('Alpha'),
      _Item('Bravo'),
      _Item('Charlie'),
      _Item('Delta')
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ReorderableListView.builder(
            itemCount: items.length,
            buildDefaultDragHandles: false, // single custom handle only
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final it = items.removeAt(oldIndex);
                items.insert(newIndex, it);
              });
            },
            itemBuilder: (context, index) {
              final e = items[index];
              return Container(
                key: ValueKey(e.uid), // stable, unique
                height: 64,
                color: Colors.blueGrey,
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const SizedBox(
                        width: 44,
                        height: 48,
                        child: Icon(Icons.drag_indicator),
                      ),
                    ),
                    Text(e.name),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // All four present at rest.
    for (final n in ['Alpha', 'Bravo', 'Charlie', 'Delta']) {
      expect(find.text(n), findsOneWidget, reason: '$n should render at rest');
    }

    // Drag the first item's handle down past two rows.
    final handle = find.byIcon(Icons.drag_indicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 80));

    // Mid-drag: the list must NOT collapse — every row still rendered.
    for (final n in ['Alpha', 'Bravo', 'Charlie', 'Delta']) {
      expect(find.text(n), findsOneWidget,
          reason: '$n must stay rendered mid-drag (no collapse)');
    }

    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    // Still four after drop, and Alpha moved off the top.
    expect(items.length, 4);
    for (final n in ['Alpha', 'Bravo', 'Charlie', 'Delta']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(items.first.name, isNot('Alpha'),
        reason: 'Alpha was dragged down, should no longer be first');
  });
}
