// Explore filter-row layout specs (review failures #1, #2, #6):
//
// 1. No chip label may wrap mid-word at compact width — each label must fit
//    its chip on a single line.
// 2. The equipment row must be scrollable so every option is reachable.
// 3. Selection must be neutral-raised + accent-bordered (never accent.muted,
//    which collides with the muscle-group accent pills that used the same
//    token pair).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/screens/explore_routines_screen.dart';

import 'explore_widget_test_utils.dart';

const _levelLabels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
const _equipmentLabels = [
  'Any equipment',
  'Full gym',
  'Dumbbell only',
  'Bodyweight',
];

void _expectLabelFits(WidgetTester tester, Finder row, String label) {
  final textFinder = find.descendant(of: row, matching: find.text(label));
  expect(textFinder, findsOneWidget, reason: '"$label" chip missing from row');
  final text = tester.widget<Text>(textFinder);
  final textBox = tester.getSize(textFinder);
  final painter = TextPainter(
    text: TextSpan(text: text.data, style: text.style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  expect(
    painter.width,
    lessThanOrEqualTo(textBox.width + 0.5),
    reason: '"$label" wraps inside its chip at compact width',
  );
}

void main() {
  testWidgets('level chips fit their labels on one line at compact width',
      (tester) async {
    await pumpExplore(tester);
    final row = find.byKey(const Key('level-filter-row'));
    for (final label in _levelLabels) {
      _expectLabelFits(tester, row, label);
    }
  });

  testWidgets('equipment chips fit their labels on one line at compact width',
      (tester) async {
    await pumpExplore(tester);
    final row = find.byKey(const Key('equipment-filter-row'));
    final rowScrollable = find.descendant(
      of: row,
      matching: find.byType(Scrollable),
    );
    // The strip is a lazy horizontal ListView: a chip only exists once it is
    // scrolled into view, so reveal each label before measuring it.
    for (final label in _equipmentLabels) {
      if (find
          .descendant(of: row, matching: find.text(label))
          .evaluate()
          .isEmpty) {
        await tester.dragUntilVisible(
          find.text(label),
          rowScrollable,
          const Offset(-60, 0),
        );
      }
      _expectLabelFits(tester, row, label);
    }
  });

  testWidgets('equipment row scrolls to reveal off-screen chips',
      (tester) async {
    await pumpExplore(tester);
    final rowScrollable = find.descendant(
      of: find.byKey(const Key('equipment-filter-row')),
      matching: find.byType(Scrollable),
    );
    await tester.dragUntilVisible(
      find.text('Bodyweight'),
      rowScrollable,
      const Offset(-80, 0),
    );
    expect(find.text('Bodyweight'), findsOneWidget);
  });

  testWidgets('selected equipment chip is neutral fill with accent border',
      (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Full gym'));
    await tester.pump();

    final ctx = tester.element(find.byType(ExploreRoutinesScreen));
    final accent = ctx.accent;
    final surface = ctx.surface;
    final selectedMaterial = tester.widget<Material>(
      find
          .ancestor(of: find.text('Full gym'), matching: find.byType(Material))
          .first,
    );
    expect(selectedMaterial.color, surface.surface4,
        reason: 'selected equipment chip must be neutral-raised, not '
            'accent.muted (color collision with muscle tags)');
    final shape = selectedMaterial.shape! as RoundedRectangleBorder;
    expect(shape.side.color, accent.selectionBorder,
        reason: 'selected equipment chip must carry the accent selection '
            'border token');
  });

  testWidgets('no filter surface uses accent.muted anywhere', (tester) async {
    await pumpExplore(tester);
    final ctx = tester.element(find.byType(ExploreRoutinesScreen));
    final accent = ctx.accent;
    final materials = tester.widgetList<Material>(find.byType(Material));
    for (final m in materials) {
      expect(m.color, isNot(accent.muted),
          reason: 'accent.muted must not appear as a control fill — it is '
              'reserved for content tinting only');
    }
  });

  testWidgets('selected level chip is neutral-raised', (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.descendant(
      of: find.byKey(const Key('level-filter-row')),
      matching: find.text('Intermediate'),
    ));
    await tester.pump();

    final ctx = tester.element(find.byType(ExploreRoutinesScreen));
    final material = tester.widget<Material>(
      find
          .ancestor(
              of: find.text('Intermediate'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, ctx.surface.surface4);
  });
}
