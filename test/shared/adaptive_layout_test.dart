import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/layout/adaptive.dart';

/// Test widget that captures the [AdaptiveTokens] from a build context so we
/// can assert their values without pulling in the full app chrome.
class _AdaptiveReader extends StatefulWidget {
  const _AdaptiveReader();
  @override
  State<_AdaptiveReader> createState() => _AdaptiveReaderState();
}

class _AdaptiveReaderState extends State<_AdaptiveReader> {
  AdaptiveTokens? tokens;
  @override
  Widget build(BuildContext context) {
    tokens = context.adaptive;
    return const SizedBox.shrink();
  }
}

void main() {
  group('AdaptiveContext', () {
    testWidgets('compact screen (<360) returns compact class', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: _AdaptiveReader()),
      );
      await tester.pump();

      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens, isNotNull);
      expect(state.tokens!.screenClass, ScreenClass.compact);
      expect(state.tokens!.horizontalInset, 12);
      expect(state.tokens!.contentMaxWidth, 296); // 320 - 12*2
    });

    testWidgets('medium screen (360-600) returns medium class', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: _AdaptiveReader()),
      );
      await tester.pump();

      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens!.screenClass, ScreenClass.medium);
      expect(state.tokens!.horizontalInset, 16);
      expect(state.tokens!.contentMaxWidth, 568); // 600 - 16*2
    });

    testWidgets('expanded screen (>600) returns expanded class',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 1024 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: _AdaptiveReader()),
      );
      await tester.pump();

      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens!.screenClass, ScreenClass.expanded);
      expect(state.tokens!.horizontalInset, 24);
      expect(state.tokens!.contentMaxWidth, 752); // 800 - 24*2
    });

    /// Helper that pumps an [_AdaptiveReader] wrapped in [MediaQuery] with the
    /// given [textScaleFactor], so we don't rely on deprecated APIs.
    Future<void> pumpWithScale(
      WidgetTester tester, {
      double textScaleFactor = 1.0,
      double width = 390,
      double height = 844,
    }) async {
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: const MaterialApp(home: _AdaptiveReader()),
        ),
      );
      await tester.pump();
    }

    testWidgets('text scale 1.0 is passed through unchanged', (tester) async {
      await pumpWithScale(tester, textScaleFactor: 1.0);
      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens!.textScaleFactor, 1.0);
    });

    testWidgets('text scale 1.3 is passed through', (tester) async {
      await pumpWithScale(tester, textScaleFactor: 1.3);
      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens!.textScaleFactor, 1.3);
    });

    testWidgets('text scale 2.0 passes through (clamp removed per UX‑95‑02)', (tester) async {
      await pumpWithScale(tester, textScaleFactor: 2.0);
      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens!.textScaleFactor, 2.0);
    });

    testWidgets('text scale 0.8 passes through (clamp removed per UX‑95‑02)', (tester) async {
      await pumpWithScale(tester, textScaleFactor: 0.8);
      final state = tester.state<_AdaptiveReaderState>(
        find.byType(_AdaptiveReader),
      );
      expect(state.tokens!.textScaleFactor, 0.8);
    });
  });
}
