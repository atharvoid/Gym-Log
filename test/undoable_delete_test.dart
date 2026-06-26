import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';

void main() {
  testWidgets(
      'showUndoableDelete shows snackbar, handles Undo, and commits on expire/hide',
      (tester) async {
    var undoCalledCount = 0;
    var commitCalledCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showUndoableDelete(
                    messenger: ScaffoldMessenger.of(context),
                    label: 'Workout deleted',
                    onUndo: () {
                      undoCalledCount++;
                    },
                    onCommitDelete: () {
                      commitCalledCount++;
                    },
                    duration: const Duration(seconds: 1),
                  );
                },
                child: const Text('Delete'),
              );
            },
          ),
        ),
      ),
    );

    // 1. Show snackbar
    await tester.tap(find.text('Delete'));
    await tester.pump(); // Start entry animation
    await tester
        .pumpAndSettle(); // Wait for entry animation to complete and settle
    expect(find.text('Workout deleted'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsOneWidget);

    // 2. Press Undo
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle(); // Settle closing animation
    expect(undoCalledCount, 1);
    expect(commitCalledCount, 0); // Not committed since Undo was pressed

    // 3. Show and let it expire
    await tester.tap(find.text('Delete'));
    await tester.pump(); // Start entry animation
    await tester.pumpAndSettle(); // entry animation completes
    expect(find.text('Workout deleted'), findsOneWidget);

    // Wait for it to expire (1 second duration)
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Workout deleted'), findsNothing);
    expect(commitCalledCount, 1); // Committed on expire

    // 4. Rapid double-delete (hides first, triggers commit on first, shows second)
    await tester.tap(find.text('Delete'));
    await tester.pump(); // Start entry animation
    await tester.pumpAndSettle();
    expect(find.text('Workout deleted'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump(); // Start entry animation
    await tester.pumpAndSettle();
    expect(find.text('Workout deleted'), findsOneWidget);
    // The first one should have been hidden and triggered commit
    expect(commitCalledCount, 2);
  });
}
