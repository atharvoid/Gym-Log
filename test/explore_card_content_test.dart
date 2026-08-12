// Explore card-content specs (review failures #3, #4, #5, #7, #8) plus the
// merged-semantics contract for the fact rows (a11y: one announcement per
// card, not five).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/screens/explore_routines_screen.dart';

import 'explore_widget_test_utils.dart';

Finder _featuredCard() => find.byWidgetPredicate((w) =>
    w is Semantics && (w.properties.label ?? '').startsWith('Featured.'));

void main() {
  testWidgets('featured card mentions each focus muscle exactly once',
      (tester) async {
    await pumpExplore(tester);
    for (final word in ['Hamstrings', 'Glutes', 'Upper Back']) {
      expect(
        find.descendant(
            of: _featuredCard(), matching: find.textContaining(word)),
        findsOneWidget,
        reason: '"$word" should appear exactly once in the featured card '
            '(no duplicated muscle pill)',
      );
    }
  });

  testWidgets('no card title carries an equipment parenthetical',
      (tester) async {
    await pumpExplore(tester);
    expect(find.textContaining('(Gym)'), findsNothing,
        reason: '"(Gym)" must not appear in titles — equipment lives in the '
            'fact-chip row');
    expect(find.textContaining('(Dumbbell Only)'), findsNothing);
    expect(find.textContaining('(No Equipment)'), findsNothing);
  });

  testWidgets('every card CTA is filled with the brand accent', (tester) async {
    await pumpExplore(tester);
    final ctx = tester.element(find.byType(ExploreRoutinesScreen));
    final accent = ctx.accent;
    final filled =
        find.byWidgetPredicate((w) => w is Material && w.color == accent.base);
    expect(filled, findsWidgets,
        reason: 'card "Add" CTAs must be filled accent, not outline');
    expect(find.text('Add'), findsWidgets);
  });

  testWidgets('section headers label their program counts', (tester) async {
    await pumpExplore(tester);
    // First section (PPL) holds 4 programs; the count must carry a label.
    // The chip strips are Scrollables too, so target the outer list
    // explicitly.
    await tester.scrollUntilVisible(
      find.text('PUSH · PULL · LEGS'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('PUSH · PULL · LEGS'), findsOneWidget);
    expect(find.text('4 programs'), findsOneWidget,
        reason: 'section count must read "N programs", not a bare number');
  });

  testWidgets('card fact rows collapse into one semantic label per card',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpExplore(tester);
    expect(
      find.bySemanticsLabel(
          RegExp(r'^Intermediate, ~70 min, 26 exercises, 4-day, Full Gym$')),
      findsOneWidget,
      reason: 'the featured card fact row must expose a single merged '
          'semantic label, not five separate announcements',
    );
    handle.dispose();
  });

  testWidgets(
      'screen builds without overflow at compact width and 1.3 text '
      'scale', (tester) async {
    await pumpExplore(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
