// Explore search specs: a discovery library screen must filter live, show an
// honest empty state, and restore the full catalog on clear.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'explore_widget_test_utils.dart';

void main() {
  testWidgets('search narrows the catalog to matching programs',
      (tester) async {
    await pumpExplore(tester);

    await tester.enterText(find.byType(TextField), 'dumbbell');
    await tester.pumpAndSettle();

    expect(find.textContaining('Linear Strength Builder'), findsNothing,
        reason: 'gym-only program must not match a "dumbbell" query');
    expect(find.textContaining('Push / Pull / Legs - 6 Days/Week · Dumbbell'),
        findsOneWidget,
        reason: 'the dumbbell-only PPL must be the only "6-Day" PPL shown');
    expect(find.textContaining('Upper & Lower Body - 4 Days/Week · Dumbbell'),
        findsOneWidget);
    expect(find.text('FEATURED'), findsNothing,
        reason: 'featured card is suppressed while searching');
  });

  testWidgets(
      'empty results show a no-match state and clear restores the '
      'catalog', (tester) async {
    await pumpExplore(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No programs match'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('FEATURED'), findsOneWidget,
        reason: 'clearing the query must restore the full catalog');
  });
}
