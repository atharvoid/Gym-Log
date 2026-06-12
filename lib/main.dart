import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/database/database.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/services/premium_service.dart';
import 'shared/widgets/app_error_screen.dart';

Future<void> main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wrap the entire startup in Sentry so crashes during init are captured.
  await SentryFlutter.init(
    (options) async {
      options.dsn = Env.sentryDsn;
      // Auto-infers release from pubspec.yaml — do NOT hardcode
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.profilesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.attachScreenshot = false; // Enable only if you want UX replay
      options.enableAppHangTracking = true; // iOS ANR-like detection

      // Verbose Sentry internal logs in debug builds. Look for:
      //   "Sentry: Envelope was sent successfully"
      //   "Sentry: DSN is empty" / "Sentry: Event dropped"
      options.debug = kDebugMode;
      options.diagnosticLevel = SentryLevel.debug;

      // Scrub PII before sending. We only ever set the Supabase UUID as the
      // user id, but defensively rebuild the user object to strip any email/IP
      // the SDK may have inferred. Returning null here would drop the event.
      options.beforeSend = (event, hint) {
        return event.copyWith(
          user: event.user == null
              ? null
              : SentryUser(
                  id: event.user!.id,
                  email: null,
                  ipAddress: null,
                ),
        );
      };

      if (!Env.hasSentryConfig) {
        debugPrint(
            '[main] No SENTRY_DSN in this build — Sentry will initialize but '
            'events will not be sent. Build with --dart-define-from-file=.env '
            'to enable crash reporting.');
      }

      // 3. Branded failure surface — release builds must never show the
      //    red/yellow Flutter error screen if a build method throws.
      ErrorWidget.builder = (details) {
        if (kDebugMode) return ErrorWidget(details.exception);
        return const AppErrorScreen();
      };

      // 4. Set URL strategy for web (use path-based routing, not hash)
      usePathUrlStrategy();

      // 5. Initialize Supabase (auth only — workout data never leaves device).
      //    Config arrives at compile time via --dart-define-from-file=.env; a
      //    build without it (fresh clone, CI) must not crash — auth degrades,
      //    local workout data still works.
      if (!Env.hasSupabaseConfig) {
        debugPrint(
            '[main] No Supabase config in this build — auth will be unavailable. '
            'Build with --dart-define-from-file=.env to enable sign-in.');
      }
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );

      // 6. Pre-initialize database
      db = AppDatabase();
      await db.customSelect('SELECT 1').getSingle(); // Warm-up query

      // 7. Premium entitlements (RevenueCat). Degrades to free mode when keys
      //    are absent or the platform is unsupported — never blocks launch.
      premiumService = PremiumService(db);
      unawaited(premiumService.initialize(
        userId: Supabase.instance.client.auth.currentUser?.id,
      ));
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (state) => premiumService.setUser(state.session?.user.id),
      );
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          premiumServiceProvider.overrideWithValue(premiumService),
        ],
        child: const GymLogApp(),
      ),
    ),
  );

  // 8. Post-launch maintenance, off the first-frame critical path.
  //    The splash screen provides ample cover on first install, and the
  //    hydration is guarded by a SharedPreferences flag on every other run.
  unawaited(_postLaunchMaintenance(db));
}

/// Shared instances wired into the provider scope. These are assigned inside
/// [SentryFlutter.init] before [appRunner] is invoked.
late final AppDatabase db;
late final PremiumService premiumService;

Future<void> _postLaunchMaintenance(AppDatabase db) async {
  try {
    await db.exercisesDao.hydrateFromJson(); // One-time JSON seed

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await db.workoutsDao.deleteOrphanedSessions(user.id);
    }
  } catch (e) {
    debugPrint('[main] post-launch maintenance failed: $e');
  }
}
