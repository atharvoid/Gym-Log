import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/personal_record.dart';
import 'package:gymlog/features/workout/presentation/widgets/pr_celebration_overlay.dart';

List<PrRecord> buildPrs(int count) => List.generate(
      count,
      (i) => PersonalRecord(
        type: PersonalRecordType.estimatedOneRepMax,
        exerciseId: i,
        exerciseName: 'Exercise ${i + 1}',
        value: 100 + i.toDouble(),
        unit: 'kg',
        setId: 's$i',
        previousValue: i == 0 ? null : 90 + i.toDouble(),
      ),
    );

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required List<PrRecord> prs,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    double bottomInset = 0,
  }) async {
    tester.view.physicalSize = size * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(textScale),
                viewPadding: mq.viewPadding.copyWith(bottom: bottomInset),
              ),
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showPrCelebration(context, prs),
                    child: const Text('open'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // entrance
    await tester.pump(const Duration(milliseconds: 2600)); // confetti done
  }

  group('PR celebration overlay', () {
    testWidgets(
        'Keep Going stays fully on-screen on a short viewport '
        'with large text and many PRs', (tester) async {
      await pumpOverlay(
        tester,
        prs: buildPrs(8),
        size: const Size(320, 568),
        textScale: 2.0,
      );
      final rect = tester.getRect(find.text('Keep Going'));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(568),
          reason: 'Keep Going clipped below viewport: $rect');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Keep Going respects the bottom system inset '
        '(3-button nav edge-to-edge)', (tester) async {
      const bottomInset = 24.0;
      await pumpOverlay(
        tester,
        prs: buildPrs(8),
        size: const Size(320, 568),
        textScale: 2.0,
        bottomInset: bottomInset,
      );
      final rect = tester.getRect(find.text('Keep Going'));
      expect(rect.bottom, lessThanOrEqualTo(568 - bottomInset),
          reason: 'Keep Going overlaps the system nav bar: $rect');
      expect(tester.takeException(), isNull);
    });

    testWidgets('normal viewport unchanged: CTA visible', (tester) async {
      await pumpOverlay(tester, prs: buildPrs(2));
      final rect = tester.getRect(find.text('Keep Going'));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Keep Going dismisses the celebration', (tester) async {
      await pumpOverlay(tester, prs: buildPrs(1));
      await tester.tap(find.text('Keep Going'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Keep Going'), findsNothing);
      expect(find.text('New Personal Record!'), findsNothing);
    });
  });
}
