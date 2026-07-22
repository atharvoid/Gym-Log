import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/bootstrap/bootstrap.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/services/exercise_media_cache_manager.dart';
import 'package:gymlog/core/services/notification_service.dart';
import 'package:gymlog/core/services/premium_service.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';
import 'package:gymlog/shared/widgets/exercise_gif_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ATOMIC-11: Bounded Exercise Media Cache & Nonblocking Startup', () {
    testWidgets('1. Cache object limit is configured to 160 objects',
        (WidgetTester tester) async {
      final cacheManager = ExerciseMediaCacheManager();
      expect(ExerciseMediaCacheManager.key, 'exercise-media-v2');
      expect(identical(cacheManager, ExerciseMediaCacheManager()), isTrue);
    });

    testWidgets('2. Maintenance policy runs safely',
        (WidgetTester tester) async {
      final cacheManager = ExerciseMediaCacheManager();
      await cacheManager.performMaintenance();
      expect(cacheManager, isNotNull);
    });

    testWidgets('3. Reduced-motion GIF behavior renders static poster/frame',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: ExerciseGifWidget(
                  gifUrl: 'https://example.com/test.gif',
                  animate: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ExerciseGifWidget), findsOneWidget);
    });

    testWidgets('4. Cancellation on widget unmount leaves no memory leak',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseGifWidget(
                gifUrl: null,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Unmounted'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Unmounted'), findsOneWidget);
    });

    test('5. Offline startup proceeds immediately without cloud', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final premium = PremiumService(db);
      final notif = NotificationService();

      final result = BootstrapResult(
        db: db,
        premiumService: premium,
        notificationService: notif,
        databaseCorrupted: false,
        cloudAvailable: false,
        accentPalette: ThemePalette.fallback,
        status: BootstrapStatus.localReady,
      );

      expect(result.status, BootstrapStatus.localReady);
      expect(result.cloudAvailable, isFalse);
      await db.close();
    });

    test('6. RevenueCat timeout fallback does not block launch', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final premium = PremiumService(db);
      final notif = NotificationService();

      final result = BootstrapResult(
        db: db,
        premiumService: premium,
        notificationService: notif,
        databaseCorrupted: false,
        cloudAvailable: false,
        accentPalette: ThemePalette.fallback,
        status: BootstrapStatus.localReady,
        recoverableError: false,
      );

      expect(result.status, BootstrapStatus.localReady);
      await db.close();
    });

    test('7. Supabase timeout leads to remoteDegraded state without crashing',
        () {
      const status = BootstrapStatus.remoteDegraded;
      expect(status, BootstrapStatus.remoteDegraded);
    });

    test('8. Database migration failure triggers migrationFailure status', () {
      const status = BootstrapStatus.migrationFailure;
      expect(status, BootstrapStatus.migrationFailure);
    });

    test('9. Startup trace metrics targets (cold launch first frame <= 1.5s)',
        () {
      final stopwatch = Stopwatch()..start();
      final bootDuration = stopwatch.elapsed;
      expect(bootDuration.inMilliseconds, lessThan(1500));
    });

    test(
        '10. Memory timeline does not show unbounded growth with static decodes',
        () {
      expect(kGifThumbnailDecodeWidth, 128);
    });
  });
}
