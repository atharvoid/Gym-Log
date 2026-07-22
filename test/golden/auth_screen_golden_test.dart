import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/screens/auth_screen.dart';
import 'package:drift/native.dart';

class GoldenFakeAuthRepository extends AuthRepository {
  GoldenFakeAuthRepository() : super(null);

  Object? errorToThrow;
  Future<void>? delayFuture;

  @override
  Future<void> signInWithGoogle() async {
    if (delayFuture != null) {
      await delayFuture;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

void main() {
  late AppDatabase db;
  late GoldenFakeAuthRepository fakeRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeRepo = GoldenFakeAuthRepository();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildScenario({
    required ThemePalette palette,
    double textScale = 1.0,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(palette.tokens, palette: palette),
        home: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: disableAnimations,
              ),
              child: const Material(
                color: Colors.black,
                child: AuthScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  group('AuthScreen Golden Tests', () {
    // Helper to configure viewport size in tests
    Future<void> setViewport(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 3.0; // scale factor
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('1. Dark Purple Palette 390x844', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonPurple));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_purple.png'),
      );
    });

    testWidgets('2. Dark Cyan Palette 390x844', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonCyan));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_cyan.png'),
      );
    });

    testWidgets('3. Dark Magenta Palette 390x844', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonMagenta));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_magenta.png'),
      );
    });

    testWidgets('4. Electric Indigo Palette 390x844', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.blazeOrange));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_orange.png'),
      );
    });

    testWidgets('5. Higgsfield Palette 390x844', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.higgsfield));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_higgsfield.png'),
      );
    });

    testWidgets('6. White Palette 390x844', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.white));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_white.png'),
      );
    });

    testWidgets('7. Small Viewport 320x568', (tester) async {
      await setViewport(tester, const Size(320, 568));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonPurple));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_small.png'),
      );
    });

    testWidgets('8. Landscape 844x390', (tester) async {
      await setViewport(tester, const Size(844, 390));
      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonPurple));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_landscape.png'),
      );
    });

    testWidgets('9. Text Scale 1.3', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
          buildScenario(palette: ThemePalette.neonPurple, textScale: 1.3));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_text_scale_1_3.png'),
      );
    });

    testWidgets('10. Text Scale 2.0', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
          buildScenario(palette: ThemePalette.neonPurple, textScale: 2.0));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_text_scale_2_0.png'),
      );
    });

    testWidgets('11. Loading State', (tester) async {
      await setViewport(tester, const Size(390, 844));
      final delayCompleter = Completer<void>();
      fakeRepo.delayFuture = delayCompleter.future;

      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonPurple));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Enter loading state

      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_loading.png'),
      );

      delayCompleter.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('12. Reduced Motion Final Frame', (tester) async {
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(buildScenario(
          palette: ThemePalette.neonPurple, disableAnimations: true));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_reduced_motion.png'),
      );
    });

    testWidgets('13. Offline Snackbar', (tester) async {
      await setViewport(tester, const Size(390, 844));
      fakeRepo.errorToThrow = const AuthNetworkFailure();

      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonPurple));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_offline_snackbar.png'),
      );
    });

    testWidgets('14. Configuration-error Snackbar', (tester) async {
      await setViewport(tester, const Size(390, 844));
      fakeRepo.errorToThrow = const AuthConfigurationFailure(
        diagnosticCode: 'google_android_configuration',
      );

      await tester.pumpWidget(buildScenario(palette: ThemePalette.neonPurple));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('goldens/auth_screen_config_error_snackbar.png'),
      );
    });
  });
}
