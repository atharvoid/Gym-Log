import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/profile/presentation/screens/help_feedback_screen.dart';
import 'package:gymlog/core/theme/app_theme.dart';

Widget wrapWithApp(Widget child, {double textScaleFactor = 1.0}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(ThemePalette.neonPurple.tokens,
        palette: ThemePalette.neonPurple),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: Material(
        color: Colors.black,
        child: SafeArea(child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX-95-03 — Adaptive Help report', () {
    testWidgets('form renders fields at default text scale', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          const ReportProblemForm(
            appVersion: '1.0.0+1',
            dbSchemaVersion: 1,
            catalogVersion: 1,
            osName: 'Android',
            opRef: 'op-test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('Bug / Crash'), findsOneWidget);
      expect(find.text('SHORT DESCRIPTION'), findsOneWidget);
      expect(find.text('REPRODUCTION STEPS (OPTIONAL)'), findsOneWidget);
      expect(find.text('SYSTEM METADATA (INCLUDED)'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
    });

    testWidgets('form renders at max text scale in scrollable container',
        (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          const SingleChildScrollView(
            child: ReportProblemForm(
              appVersion: '1.0.0+1',
              dbSchemaVersion: 1,
              catalogVersion: 1,
              osName: 'Android',
              opRef: 'op-test',
            ),
          ),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('SHORT DESCRIPTION'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
