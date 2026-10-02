import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_reassurance_fixtures.dart';
import 'session_1_render_test.dart' show loadSessionFonts;

void main() {
  setUpAll(loadSessionFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final phase = Platform.environment['UPGRADE_RENDER_PHASE'] ?? 'after';
  final palettes = phase == 'before'
      ? [ThemePalette.higgsfield, ThemePalette.neonPurple]
      : ThemePalette.values;
  for (final palette in palettes) {
    for (final scale in [1.0, 1.6]) {
      for (final name in [
        'async-error',
        'app-error',
        'detail-error',
        'routine-error',
        'roles',
        'offline',
        'sync-error',
        'storage-free',
        'storage-pro'
      ]) {
        final id = '$name-${palette.name}-${scale}x-synthetic';
        testWidgets(id, (tester) async {
          tester.view.physicalSize = const ui.Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          const key = ValueKey('copy-capture');
          await tester.pumpWidget(
              errorFixtureApp(name, palette, scale, captureKey: key));
          await tester.pumpAndSettle();
          await prepareErrorFixture(tester, name);
          final exception = tester.takeException();
          // Existing Settings sync-title row overflows at 1.6x before this
          // copy-only pass. Preserve/render that defect; require its exact
          // baseline form instead of treating the layout as qualified.
          if (scale == 1.6 &&
              (name == 'offline' ||
                  name == 'sync-error' ||
                  name.startsWith('storage-'))) {
            final pixels = name == 'storage-free' ? 77 : 72;
            expect(
                exception.toString(),
                contains(
                    'A RenderFlex overflowed by $pixels pixels on the right.'));
          } else {
            expect(exception, isNull);
          }
          if (phase == 'before' ||
              Platform.environment['UPGRADE_SAVE_RENDERS'] == '1') {
            await tester.runAsync(() async {
              final boundary =
                  tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
              final image = await boundary.toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  'docs/upgrade/renders/session-1-reassurance/$phase/$id.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (phase == 'after') {
            await expectLater(
                find.byKey(key),
                matchesGoldenFile(
                    '../golden/goldens/session-1-reassurance/$id.png'));
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
