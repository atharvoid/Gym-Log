import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/widgets/app_error_screen.dart';
import 'package:gymlog/shared/widgets/body/muscle_load_bar.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';

import 'golden/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProLockPill publishes a single semantic node with its label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester
        .pumpWidget(gymlogApp(ThemePalette.fallback, const ProLockPill()));

    // The wrapper label must be announced exactly once: no second node from
    // the inner 'PRO' Text (docs/a11y-semantics-checklist.md §2).
    expect(
      _labelsOf(tester, 'Premium feature. Double tap to learn more.').length,
      1,
    );
    expect(_labels(tester).any((l) => l == 'PRO'), isFalse);

    handle.dispose();
  });

  testWidgets('TimeRangeFilter publishes one node, not value twice',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      gymlogApp(
        ThemePalette.fallback,
        const TimeRangeFilter(value: '1M', onChanged: _noopRangeChange),
      ),
    );

    expect(_labelsOf(tester, 'Time range filter, currently 1M').length, 1);
    expect(_labels(tester).where((l) => l == '1M'), isEmpty);

    handle.dispose();
  });

  testWidgets('MuscleLoadBar publishes one combined node for its legend',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      gymlogApp(
        ThemePalette.fallback,
        const MuscleLoadBar(
          entries: [
            MuscleLoadEntry('chest', 0.6),
            MuscleLoadEntry('back', 0.3),
            MuscleLoadEntry('biceps', 0.1),
          ],
          primaryGroups: {'chest', 'back'},
          secondaryGroups: {'biceps'},
          gender: 'male',
        ),
      ),
    );

    // One combined node for the whole strip (docs/a11y-semantics-checklist.md
    // §2); chips' own texts must not escape as separate nodes.
    expect(_labels(tester).where((l) => l.startsWith('Muscles worked:')).length,
        1);
    expect(_labels(tester).where((l) => l == 'Chest'), isEmpty);
    expect(_labels(tester).where((l) => l == 'Back'), isEmpty);

    handle.dispose();
  });

  testWidgets('AppErrorScreen error action is a single button node',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      gymlogApp(ThemePalette.fallback, const AppErrorScreen()),
    );

    // 'Restart GymLog' is the retry action; it must be a single button with
    // one label instead of wrapper + inner Text.
    final nodes =
        _semanticsNodes(tester).where((n) => n.label == 'Restart GymLog');
    expect(nodes.length, 1);

    handle.dispose();
  });
}

void _noopRangeChange(String _) {}

List<SemanticsNode> _semanticsNodes(WidgetTester tester) {
  // ignore: deprecated_member_use
  final owner = tester.binding.pipelineOwner.semanticsOwner!;
  final root = owner.rootSemanticsNode;
  return root == null ? const <SemanticsNode>[] : _collect(root);
}

List<SemanticsNode> _collect(SemanticsNode node) {
  final all = [node];
  node.visitChildren((child) {
    all.addAll(_collect(child));
    return true;
  });
  return all;
}

Iterable<String> _labels(WidgetTester tester) =>
    _semanticsNodes(tester).map((n) => n.label).where((l) => l.isNotEmpty);

Iterable<SemanticsNode> _labelsOf(WidgetTester tester, String label) =>
    _semanticsNodes(tester).where((n) => n.label == label);
