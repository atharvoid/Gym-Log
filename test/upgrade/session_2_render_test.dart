// Captures current widgets and unimplemented design options for owner selection.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';
import 'session_2_options.dart';

void main() {
  setUpAll(loadSessionFonts);
  setUp(() =>
      SharedPreferences.setMockInitialValues({'first_run_tour_step': -1}));
  for (final phase in ['before', ...LaunchOption.values.map((o) => o.name)]) {
    for (final palette in [ThemePalette.higgsfield, ThemePalette.neonPurple]) {
      for (final scale in [1.0, 1.6]) {
        for (final state in LaunchState.values) {
          if (phase != 'before' &&
              palette != ThemePalette.higgsfield &&
              state != LaunchState.returning) {
            continue;
          }
          for (final screen in ['home', 'library']) {
            final id =
                '$screen-${state.name}-${palette.name}-${scale}x-synthetic';
            testWidgets('$phase/$id', (tester) async {
              tester.view.physicalSize = const ui.Size(390, 844);
              tester.view.devicePixelRatio = 1;
              addTearDown(() {
                tester.view.resetPhysicalSize();
                tester.view.resetDevicePixelRatio();
              });
              const key = ValueKey('session-2-capture');
              final child = phase == 'before'
                  ? currentLaunchScreen(screen)
                  : LaunchConcept(
                      option: LaunchOption.values
                          .firstWhere((o) => o.name == phase),
                      screen: screen,
                      fixtureState: state);
              await tester.pumpWidget(launchFixtureApp(
                  child: child,
                  palette: palette,
                  scale: scale,
                  screen: screen,
                  fixtureState: state,
                  captureKey: key));
              await tester.pumpAndSettle();
              final issues = <String>[];
              Object? issue;
              while ((issue = tester.takeException()) != null) {
                issues.add(issue.toString());
              }
              if (phase != 'before') expect(issues, isEmpty);
              final directory = phase == 'before' ? 'before' : 'options/$phase';
              if (Platform.environment['SESSION_2_SAVE_RENDERS'] == '1') {
                await _saveCapture(tester, key, '$directory/$id', issues);
              }
              if (state == LaunchState.returning) {
                await tester.drag(
                    find.byType(Scrollable).first, const Offset(0, -2000));
                await tester.pumpAndSettle();
                final scrollIssues = <String>[];
                while ((issue = tester.takeException()) != null) {
                  scrollIssues.add(issue.toString());
                }
                if (phase != 'before') expect(scrollIssues, isEmpty);
                if (Platform.environment['SESSION_2_SAVE_RENDERS'] == '1') {
                  await _saveCapture(
                      tester, key, '$directory/$id-below-fold', scrollIssues);
                }
              }
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            });
          }
        }
      }
    }
  }
}

Future<void> _saveCapture(
    WidgetTester tester, Key key, String id, List<String> issues) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/upgrade/renders/session-2/$id.png');
    // Keep the recorded pre-build evidence immutable once app implementation starts.
    if (id.startsWith('before/') && file.existsSync()) {
      image.dispose();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    if (issues.isNotEmpty) {
      await File('${file.path}.issues.txt').writeAsString(issues.join('\n\n'));
    }
    image.dispose();
  });
}
