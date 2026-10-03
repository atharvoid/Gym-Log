import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_reassurance_fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final name in ['async-error', 'app-error', 'detail-error']) {
    testWidgets('$name does not guarantee storage integrity on an error',
        (tester) async {
      await tester
          .pumpWidget(errorFixtureApp(name, ThemePalette.higgsfield, 1));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp('data is safe', caseSensitive: false)),
          findsNothing);
      expect(find.textContaining(RegExp('wrong|load')), findsWidgets);
      if (name != 'app-error') {
        expect(find.text('Try again'), findsOneWidget);
      } else {
        expect(find.text('Restart Delt'), findsOneWidget);
        expect(find.text('Go Home'), findsOneWidget);
      }
    });
  }
  testWidgets(
      'offline sync status does not claim a completed save or guaranteed backup',
      (tester) async {
    await tester
        .pumpWidget(errorFixtureApp('offline', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    await prepareErrorFixture(tester, 'offline');
    expect(find.textContaining('Your workouts are saved'), findsNothing);
    expect(find.textContaining('will sync when'), findsNothing);
    expect(find.text('Offline. Cloud sync is paused.'), findsOneWidget);
  });
  for (final name in ['storage-free', 'storage-pro']) {
    testWidgets(
        '$name describes successful saves without instant/guaranteed backup claims',
        (tester) async {
      await tester
          .pumpWidget(errorFixtureApp(name, ThemePalette.higgsfield, 1));
      await tester.pumpAndSettle();
      await prepareErrorFixture(tester, name);
      expect(find.textContaining('Every workout is saved instantly'),
          findsNothing);
      expect(find.textContaining('so your history survives'), findsNothing);
      expect(find.textContaining('after a successful save'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  testWidgets('sync error does not promise an automatic retry', (tester) async {
    await tester
        .pumpWidget(errorFixtureApp('sync-error', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    await prepareErrorFixture(tester, 'sync-error');
    expect(find.textContaining('Will retry automatically'), findsNothing);
    expect(find.text("Couldn't sync. Check your connection."), findsOneWidget);
  });
  testWidgets('Pro storage heading does not assert an existing cloud backup',
      (tester) async {
    await tester
        .pumpWidget(errorFixtureApp('storage-pro', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    await prepareErrorFixture(tester, 'storage-pro');
    expect(find.text('Local-first, cloud-backed'), findsNothing);
    expect(find.text('Local storage and cloud sync'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
