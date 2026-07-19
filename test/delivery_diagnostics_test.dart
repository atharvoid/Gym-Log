import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/profile/presentation/screens/settings_screen.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Tapping Version AppActionRow 5 times throws controlled StateError',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Pump settings screen inside a ProviderScope and MaterialApp
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWithValue(false),
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(UserProfile(
                    id: 'user-1',
                    email: 'a@b.com',
                    displayName: 'User 1',
                    isPremium: false,
                    premiumExpiry: null,
                    weightUnit: 'kg',
                    defaultRestSeconds: 90,
                    createdAt: DateTime.now(),
                    onboardingComplete: true,
                  ))),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SettingsScreen(),
          ),
        ),
      ),
    );

    // Wait for the asynchronous UserProfile stream to emit and rebuild the screen
    await tester.pumpAndSettle();

    // Find the text 'Version' directly
    final versionTextFinder = find.text('Version');

    // Scroll down the settings ListView until the Version row is visible
    await tester.scrollUntilVisible(
      versionTextFinder,
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(versionTextFinder, findsOneWidget);

    // Tap 4 times — should not throw (advancing clock by 650ms to pass tapGuard)
    for (int i = 0; i < 4; i++) {
      await tester.tap(versionTextFinder);
      sleep(const Duration(milliseconds: 650));
      await tester.pump();
    }

    // The 5th tap must throw the Sentry diagnostic error caught by the gesture framework
    await tester.tap(versionTextFinder);

    final exception = tester.takeException();
    expect(
      exception,
      isA<StateError>().having((e) => e.message, 'message',
          'Sentry Diagnostic Controlled Test Error'),
    );
  });
}
