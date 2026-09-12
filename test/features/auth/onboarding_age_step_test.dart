import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_age.dart';

void main() {
  Future<void> pumpAgeStep(
    WidgetTester tester, {
    int? age,
    double textScale = 1.0,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final notifier = OnboardingDraftNotifier();
    if (age != null) notifier.updateAge(age);

    await tester.pumpWidget(
      ProviderScope(
        // UniqueKey forces a fresh container per pump: pumping a second
        // ProviderScope of the same runtimeType reuses the previous override.
        key: UniqueKey(),
        overrides: [
          onboardingDraftProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(textScale)),
                child: const Scaffold(
                  body: StepAge(onNext: _noop),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  IconButton iconButtonOf(WidgetTester tester, IconData icon) =>
      tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(IconButton),
      ));

  group('StepAge', () {
    testWidgets(
        'age renders on a single line for every value (14, 25, 99, 100)',
        (tester) async {
      for (final age in [14, 25, 99, 100]) {
        await pumpAgeStep(tester, age: age);
        final p = paragraphOf(tester, '$age');
        final fontSize = p.text.style!.fontSize!;
        // One line of a 72px metric is ~72-86px tall; a wrapped value
        // ("100" -> "10" + "0") is ~2x that.
        expect(p.size.height, lessThan(fontSize * 1.6),
            reason: 'age $age wrapped onto two lines');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('age 100 stays on one line at every viewport and text scale',
        (tester) async {
      for (final size in [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
      ]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          await pumpAgeStep(tester, age: 100, size: size, textScale: scale);
          final p = paragraphOf(tester, '100');
          final fontSize = p.text.style!.fontSize! * scale;
          expect(p.size.height, lessThan(fontSize * 1.6),
              reason: 'wrapped at $size / scale $scale');
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('tapping + at 99 shows 100 on a single line', (tester) async {
      await pumpAgeStep(tester, age: 99);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
      final p = paragraphOf(tester, '100');
      expect(p.size.height, lessThan(p.text.style!.fontSize! * 1.6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('decrement disabled at 14, increment disabled at 100',
        (tester) async {
      await pumpAgeStep(tester, age: 14);
      final minus = iconButtonOf(tester, Icons.remove_rounded);
      expect(minus.onPressed, isNull);

      await pumpAgeStep(tester, age: 100);
      final plus = iconButtonOf(tester, Icons.add_rounded);
      expect(plus.onPressed, isNull);
    });
  });
}

void _noop() {}
