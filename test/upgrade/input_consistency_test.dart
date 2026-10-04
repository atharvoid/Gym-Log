// Actual production widgets and theme; synthetic data and illustrative keyboard.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/routines/presentation/providers/ai_routine_import_provider.dart';
import 'package:gymlog/features/routines/presentation/screens/ai_routine_import_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_routines_implemented_render_test.dart' show IllustrativeKeyboard;
import 'session_1_render_test.dart' show loadSessionFonts;
import 'session_2_fixtures.dart';

const roundedInput = BorderRadius.all(Radius.circular(10));

void main() {
  setUpAll(loadSessionFonts);
  for (final palette in ThemePalette.values) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final screen in ['chooser', 'ai-paste']) {
        final name = '$screen-${palette.name}-${scale}x';
        testWidgets(name, (tester) async {
          prepareView(tester);
          SharedPreferences.setMockInitialValues({
            'first_run_tour_step': -1,
            'training_routine:local': 'sample-0',
          });
          final key = ValueKey(name);
          if (screen == 'chooser') {
            await tester.pumpWidget(launchFixtureApp(
              child: currentLaunchScreen('home'),
              palette: palette,
              scale: scale,
              screen: 'home',
              fixtureState: LaunchState.returning,
              keyboardOverlay: const IllustrativeKeyboard(),
              captureKey: key,
            ));
            await tester.pumpAndSettle();
            await tester
                .tap(find.byKey(const ValueKey('change-training-routine')));
            await tester.pumpAndSettle();
          } else {
            await tester.pumpWidget(inputApp(
              palette,
              scale,
              key,
              const AiRoutineImportScreen(),
            ));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Paste Text'));
            await tester.pumpAndSettle();
            // Check the original large-text overflow before scrolling it away.
            expect(tester.takeException(), isNull);
          }
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          final text = screen == 'chooser'
              ? 'Pull'
              : 'Push Day A:\nBench Press 3x8\nCable Row 3x10';
          await tester.enterText(find.byType(TextField), text);
          await tester.ensureVisible(find.byType(TextField));
          await tester.pumpAndSettle();
          if (screen == 'chooser') {
            await tester
                .ensureVisible(find.byKey(const ValueKey('choose-sample-1')));
            await tester.pumpAndSettle();
            expect(find.text('Pull A').hitTestable(), findsOneWidget);
            expect(tester.getRect(find.byType(TextField)).bottom,
                lessThanOrEqualTo(564));
          } else {
            final context = tester.element(find.byType(TextField));
            expect(
                ProviderScope.containerOf(context)
                    .read(aiRoutineImportProvider)
                    .textInput,
                text);
            await tester.ensureVisible(find.text('Paste'));
            await tester.pumpAndSettle();
            expect(find.text('Paste').hitTestable(), findsOneWidget);
          }
          expectRounded(tester);
          expect(tester.takeException(), isNull);
          await captureInput(tester, key, name);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
    testWidgets('input-states-${palette.name}', (tester) async {
      prepareView(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      final key = ValueKey('input-states-${palette.name}');
      await tester.pumpWidget(inputApp(
        palette,
        1,
        key,
        const Scaffold(
          body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                TextField(decoration: InputDecoration(hintText: 'Ready')),
                SizedBox(height: 16),
                TextField(
                    enabled: false,
                    decoration: InputDecoration(hintText: 'Disabled')),
                SizedBox(height: 16),
                TextField(
                    decoration: InputDecoration(
                        hintText: 'Error', errorText: 'Enter a name')),
                SizedBox(height: 16),
                TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                        hintText: 'Focused error', errorText: 'Enter a name')),
              ])),
        ),
      ));
      await tester.pumpAndSettle();
      expectRounded(tester);
      expect(tester.takeException(), isNull);
      await captureInput(tester, key, 'input-states-${palette.name}');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}

void prepareView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Widget inputApp(ThemePalette palette, double scale, Key key, Widget child,
        {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(palette.tokens, palette: palette),
            home: child,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Stack(children: [
                child!,
                if (MediaQuery.viewInsetsOf(context).bottom > 0)
                  const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IllustrativeKeyboard()),
              ]),
            ),
          )),
    );

void expectRounded(WidgetTester tester) {
  for (final decorator
      in tester.widgetList<InputDecorator>(find.byType(InputDecorator))) {
    final decoration = decorator.decoration;
    for (final border in [
      decoration.border,
      decoration.enabledBorder,
      decoration.focusedBorder,
      decoration.disabledBorder,
      decoration.errorBorder,
      decoration.focusedErrorBorder
    ]) {
      if (border == null) continue;
      expect(border, isA<OutlineInputBorder>());
      expect((border as OutlineInputBorder).borderRadius, roundedInput);
    }
  }
}

Future<void> captureInput(WidgetTester tester, Key key, String name) async {
  await expectLater(find.byKey(key),
      matchesGoldenFile('goldens/input-consistency/$name.png'));
  if (const bool.fromEnvironment('EXPORT_INPUT_RENDERS')) {
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final capture = await boundary.toImage(pixelRatio: 2);
      final bytes = await capture.toByteData(format: ui.ImageByteFormat.png);
      capture.dispose();
      final target =
          File('docs/upgrade/renders/input-consistency/after/$name.png');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }
}
