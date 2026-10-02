import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_1_fixtures.dart';

Future<void> loadSessionFonts() async {
  final inter = FontLoader('Inter');
  for (final name in ['Regular', 'SemiBold', 'Bold']) {
    inter.addFont(Future.value(ByteData.sublistView(
        await File('assets/google_fonts/Inter-$name.ttf').readAsBytes())));
  }
  await inter.load();
  final config = File('.dart_tool/package_config.json');
  final packages = (jsonDecode(await config.readAsString())
      as Map<String, dynamic>)['packages'] as List;
  final rootValue = (packages.firstWhere((p) => p['name'] == 'flutter')
      as Map)['rootUri'] as String;
  final root = config.absolute.uri
      .resolve(rootValue.endsWith('/') ? rootValue : '$rootValue/');
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(await File.fromUri(root.resolve(
            '../../bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'))
        .readAsBytes())));
  await icons.load();
}

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
        'header-weighted',
        'header-reps',
        'header-timed',
        'header-distance',
        'header-empty',
        'finish-weighted',
        'finish-reps',
        'finish-timed',
        'finish-distance',
        'pr',
        'pr-pace',
        'share-monument',
        'share-technical',
        'share-sticker',
        'share-duration-monument',
        'share-duration-technical',
        'share-duration-sticker',
        'share-distance-monument',
        'share-distance-technical',
        'share-distance-sticker',
        'share-pace-monument',
        'share-pace-technical',
        'share-pace-sticker',
        'detail',
        'detail-error',
        'detail-empty',
        'exercise',
        'exercise-no-estimate',
        'progress',
        'progress-low',
        'progress-empty',
        'roles'
      ]) {
        final id = '$name-${palette.name}-${scale}x-synthetic';
        testWidgets(id, (tester) async {
          tester.view.physicalSize = const ui.Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          const key = ValueKey('capture');
          await tester
              .pumpWidget(fixtureApp(name, palette, scale, captureKey: key));
          await tester.pumpAndSettle();
          if (name.startsWith('finish-')) {
            // Capture the sheet without synthesizing pointer events during
            // route teardown (Flutter 3.44 RawTooltip lazy-ticker limitation).
            tester
                .widget<TextButton>(
                    find.widgetWithText(TextButton, 'Open summary'))
                .onPressed!();
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          if (phase == 'before' ||
              Platform.environment['UPGRADE_SAVE_RENDERS'] == '1') {
            await tester.runAsync(() async {
              final boundary =
                  tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
              final image = await boundary.toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file =
                  File('docs/upgrade/renders/session-1/$phase/$id.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (phase == 'after') {
            await expectLater(find.byKey(key),
                matchesGoldenFile('../golden/goldens/session-1/$id.png'));
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
