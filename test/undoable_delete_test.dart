import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';

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

    // 4. Rapid double-delete must NOT force-commit the first item. The second
    //    snackbar queues behind the first; the first stays open until its own
    //    window elapses, so its Undo action remains available the whole time.
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // entrance
    expect(find.text('Workout deleted'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // First snackbar is still visible; the second is queued behind it.
    expect(find.text('Workout deleted'), findsOneWidget);
    // The first item was NOT silently finalized by the second delete.
    expect(commitCalledCount, 1);

    // Let the first window elapse: it commits, then the second one shows.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300)); // first exits
    expect(commitCalledCount, 2);
    await tester.pump(const Duration(milliseconds: 300)); // second enters
    expect(find.text('Workout deleted'), findsOneWidget);

    // Let the second window elapse too.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Workout deleted'), findsNothing);
    expect(commitCalledCount, 3);
  });

  testWidgets(
      'showAppSnackBar must not dismiss an in-flight undo snackbar (no silent finalize)',
      (tester) async {
    var undoCalledCount = 0;
    var commitCalledCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
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
                        duration: const Duration(seconds: 5),
                      );
                    },
                    child: const Text('Delete'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showAppSnackBar(context, message: 'Something else saved');
                    },
                    child: const Text('Other toast'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Show the undo snackbar.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Workout deleted'), findsOneWidget);

    // A generic toast fires while the undo window is open.
    await tester.tap(find.text('Other toast'));
    await tester.pump();
    await tester.pumpAndSettle();

    // The undo snackbar must still be visible — clearing it would have
    // silently finalized the pending deletion.
    expect(find.text('Workout deleted'), findsOneWidget);
    expect(commitCalledCount, 0);

    // Undo still works.
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect(undoCalledCount, 1);
    expect(commitCalledCount, 0);

    // The queued generic toast shows only after the undo window closes.
    expect(find.text('Something else saved'), findsOneWidget);
  });
}
