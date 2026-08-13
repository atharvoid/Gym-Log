// Explore filter-bar layout specs (updated for bottom-sheet filter pickers):
//
// 1. Filter bar must render two pill buttons: Level and Equipment.
// 2. Tapping Level opens a bottom sheet with all 4 level options.
// 3. Tapping Equipment opens a bottom sheet with all 4 equipment options.
// 4. Active filter pills show the selected label and an accent-tinted fill.
// 5. Filter pills must meet the 36pt minimum height.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  testWidgets('filter bar renders Level and Equipment pills', (tester) async {
    await pumpExplore(tester);
    expect(find.text('Level'), findsOneWidget,
        reason: 'Level filter pill must be visible in the filter bar');
    expect(find.text('Equipment'), findsOneWidget,
        reason: 'Equipment filter pill must be visible in the filter bar');
  });

  testWidgets('tapping Level pill opens sheet with all level options',
      (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Level'));
    await tester.pumpAndSettle();
    for (final label in _levelLabels) {
      expect(find.text(label), findsWidgets,
          reason: '"$label" must appear in the level filter sheet');
    }
  });

  testWidgets('tapping Equipment pill opens sheet with all equipment options',
      (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    for (final label in _equipmentLabels) {
      expect(find.text(label), findsWidgets,
          reason: '"$label" must appear in the equipment filter sheet');
    }
  });

  testWidgets('selecting a level updates the filter pill label',
      (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Intermediate').last);
    await tester.pumpAndSettle();
    expect(find.text('Intermediate'), findsOneWidget,
        reason: 'Active level filter pill must show selected label');
    expect(find.text('Level'), findsNothing,
        reason: 'Idle Level label must be replaced when a filter is active');
  });

  testWidgets('selecting an equipment filter updates the pill label',
      (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full gym').last);
    await tester.pumpAndSettle();
    expect(find.text('Full gym'), findsOneWidget,
        reason: 'Active equipment filter pill must show selected label');
    expect(find.text('Equipment'), findsNothing,
        reason:
            'Idle Equipment label must be replaced when a filter is active');
  });

  testWidgets('active filter pill uses accent.muted fill', (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beginner').last);
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(ExploreRoutinesScreen));
    final accent = ctx.accent;
    final pill = tester.widget<Material>(
      find
          .ancestor(of: find.text('Beginner'), matching: find.byType(Material))
          .first,
    );
    expect(pill.color, accent.muted,
        reason: 'Active filter pill must use accent.muted fill');
    final shape = pill.shape! as RoundedRectangleBorder;
    expect(shape.side.color, accent.selectionBorder,
        reason: 'Active filter pill must carry accent.selectionBorder');
  });

  testWidgets('filter pills meet 36pt minimum height', (tester) async {
    await pumpExplore(tester);
    for (final label in ['Level', 'Equipment']) {
      final pill = find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first;
      final height = tester.getSize(pill).height;
      expect(height, greaterThanOrEqualTo(36),
          reason: '"$label" pill is ${height}pt — below the 36pt minimum');
    }
  });

  testWidgets('selecting All in level sheet resets to idle pill label',
      (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.text('Level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced').last);
    await tester.pumpAndSettle();
    // Re-open and reset to All
    await tester.tap(find.text('Advanced')); // active pill
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').last);
    await tester.pumpAndSettle();
    expect(find.text('Level'), findsOneWidget,
        reason: 'Pill must revert to "Level" label when All is selected');
  });
}
