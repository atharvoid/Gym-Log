import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymlog/shared/widgets/bottom_nav_bar.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';

void main() {
  setUpAll(loadSessionFonts);
  final iteration = Platform.environment['SESSION_2_ITERATION'] ?? '1';
  for (final palette in ThemePalette.values) {
    for (final scale in [1.0, 1.6]) {
      for (final name in [
        'chosen',
        'no-choice',
        'deleted-choice',
        'empty-choice',
        'new-user',
        'no-routine',
        'inactive-return',
        'low-data',
        'error',
        'previous-error',
        'choice-error',
        'loading',
        'active-chosen',
        'active-no-choice',
        'active-no-routine',
        'active-error',
        'active-deleted-choice',
        'active-empty-choice',
        'active-choice-error'
      ]) {
        for (final screen in ['home', 'library']) {
          final id = '$screen-$name-${palette.name}-${scale}x-synthetic';
          testWidgets(id, (tester) async {
            tester.view.physicalSize = const ui.Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final state = switch (name) {
              'new-user' || 'active-no-routine' => LaunchState.empty,
              'no-routine' => LaunchState.noRoutine,
              'inactive-return' => LaunchState.inactive,
              'low-data' => LaunchState.lowData,
              'error' || 'active-error' => LaunchState.error,
              _ => LaunchState.returning,
            };
            final Object? chosen = switch (name) {
              'no-choice' ||
              'new-user' ||
              'no-routine' ||
              'active-no-choice' ||
              'active-no-routine' =>
                null,
              'deleted-choice' || 'active-deleted-choice' => 'deleted',
              'choice-error' || 'active-choice-error' => 7,
              'low-data' => 'sample-4',
              _ => 'sample-0',
            };
            SharedPreferences.setMockInitialValues({
              'first_run_tour_step': -1,
              if (chosen != null) 'training_routine:local': chosen
            });
            List<HydratedRoutine>? routines;
            if (name == 'empty-choice' || name == 'active-empty-choice') {
              final plans = sampleRoutines(state);
              routines = [
                HydratedRoutine(
                    routine: plans.first.routine,
                    lastTrained: plans.first.lastTrained,
                    exerciseNames: [],
                    exerciseIds: []),
                ...plans.skip(1)
              ];
            }
            const key = ValueKey('session-2-live-capture');
            await tester.pumpWidget(launchFixtureApp(
                child: currentLaunchScreen(screen),
                palette: palette,
                scale: scale,
                screen: screen,
                fixtureState: state,
                routines: routines,
                previousError: name == 'previous-error',
                routinesLoading: name == 'loading',
                activeWorkout: name.startsWith('active-'),
                captureKey: key));
            if (name == 'loading') {
              await tester.pump(const Duration(milliseconds: 300));
            } else {
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            await _assertVisibleInk(tester, key, screen,
                changeVisible: screen == 'home' && name == 'chosen');
            await expectLater(find.byKey(key),
                matchesGoldenFile('goldens/session-2/$id.png'));
            await _capture(tester, key, 'iteration-$iteration/$id');
            if (name == 'chosen' && screen == 'home') {
              await tester
                  .tap(find.byKey(const ValueKey('change-training-routine')));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final chooserId = 'chooser-${palette.name}-${scale}x-synthetic';
              await expectLater(find.byKey(key),
                  matchesGoldenFile('goldens/session-2/$chooserId.png'));
              await _capture(tester, key, 'iteration-$iteration/$chooserId');
              await tester.enterText(find.byType(TextField), 'Outdoor');
              await tester.pumpAndSettle();
              await _compareCapture(
                  tester,
                  key,
                  'chooser-search-${palette.name}-${scale}x-synthetic',
                  iteration);
              await tester.enterText(
                  find.byType(TextField), 'no matching routine');
              await tester.pumpAndSettle();
              await _compareCapture(
                  tester,
                  key,
                  'chooser-no-results-${palette.name}-${scale}x-synthetic',
                  iteration);
              await tester.enterText(find.byType(TextField), '');
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.byTooltip('More choices'));
              await tester.tap(find.byTooltip('More choices'));
              await tester.pumpAndSettle();
              expect(find.byKey(const ValueKey('choose-sample-4')),
                  findsOneWidget);
              expect(
                  find.byKey(const ValueKey('choose-sample-0')), findsNothing);
              await _compareCapture(
                  tester,
                  key,
                  'chooser-page-2-${palette.name}-${scale}x-synthetic',
                  iteration);
              await tester.tap(find.byTooltip('Close routine chooser'));
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.text('History'));
              await tester.tap(find.text('History'));
              await tester.pumpAndSettle();
              await _compareCapture(
                  tester,
                  key,
                  'home-history-shortcut-${palette.name}-${scale}x-synthetic',
                  iteration);
            } else if (name == 'chosen' && screen == 'library') {
              await tester.scrollUntilVisible(
                  find.text('Standalone routines'), 250);
              await tester.pumpAndSettle();
              await _compareCapture(
                  tester,
                  key,
                  'library-below-fold-${palette.name}-${scale}x-synthetic',
                  iteration);
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          });
        }
      }
    }
  }
}

Future<void> _compareCapture(
    WidgetTester tester, Key key, String id, String iteration) async {
  expect(tester.takeException(), isNull);
  await expectLater(
      find.byKey(key), matchesGoldenFile('goldens/session-2/$id.png'));
  await _capture(tester, key, 'iteration-$iteration/$id');
}

Future<void> _capture(WidgetTester tester, Key key, String id) async {
  if (Platform.environment['SESSION_2_SAVE_AFTER'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file =
        File('docs/upgrade/renders/home-routines-correction/after/$id.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

// Inspect the actual raster: finding a Text widget alone does not prove it
// painted. These regions have a black background and visible foreground ink.
Future<void> _assertVisibleInk(WidgetTester tester, Key key, String screen,
    {required bool changeVisible}) async {
  final regions = <String, Rect>{
    'screen heading': tester
        .getRect(find.text(screen == 'home' ? 'Train' : 'Routines').first),
    for (final label in ['Home', 'Routines', 'Profile'])
      '$label navigation': tester.getRect(find.descendant(
          of: find.byType(BottomNavBar), matching: find.text(label))),
    if (changeVisible)
      'Change control':
          tester.getRect(find.byKey(const ValueKey('change-training-routine'))),
  };
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final raster = await boundary.toImage();
    final bytes =
        (await raster.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    for (final entry in regions.entries) {
      final rect = entry.value.intersect(Rect.fromLTWH(
          0, 0, raster.width.toDouble(), raster.height.toDouble()));
      var ink = 0;
      for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
        for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
          final index = (y * raster.width + x) * 4;
          if (bytes.getUint8(index) > 100 ||
              bytes.getUint8(index + 1) > 100 ||
              bytes.getUint8(index + 2) > 100) {
            ink++;
          }
        }
      }
      expect(ink, greaterThan(10), reason: '${entry.key} has no painted ink');
    }
    raster.dispose();
  });
}
