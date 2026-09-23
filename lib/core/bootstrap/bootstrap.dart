import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../database/database.dart';
import '../database/database_integrity_signal.dart';
import '../providers/supabase_client_provider.dart';
import '../services/premium_service.dart';
import '../services/notification_service.dart';
import '../theme/dynamic_accent_theme.dart';
import '../theme/theme_palette.dart';
import '../../shared/widgets/app_error_screen.dart';

import '../services/exercise_media_cache_manager.dart';

enum BootstrapStatus {
  localReady,
  remoteDegraded,
  migrationFailure,
  recoverableError,
}

/// Outcome of the staged startup sequence. Carries the shared singletons the
/// provider scope needs, plus resilience flags the UI may act on.
class BootstrapResult {
  final AppDatabase db;
  final PremiumService premiumService;
  final NotificationService notificationService;
  final bool databaseCorrupted;
  final bool cloudAvailable;
  final ThemePalette accentPalette;
  final Future<bool> cloudReady;
  final BootstrapStatus status;
  final bool recoverableError;

  const BootstrapResult({
    required this.db,
    required this.premiumService,
    required this.notificationService,
    required this.databaseCorrupted,
    required this.cloudAvailable,
    required this.accentPalette,
    required this.cloudReady,
    this.status = BootstrapStatus.localReady,
    this.recoverableError = false,
  });
}

/// Staged, recoverable application startup.
///
/// Each stage is independent: a cloud failure never blocks local launch, and a
/// corrupt database surfaces a user-facing reset path rather than a black
/// screen.
abstract final class Bootstrap {
  /// Upper bound on cloud (Supabase) initialisation before we proceed in
  /// local-only mode.
  static const cloudInitTimeout = Duration(seconds: 4);

  /// Absolute deadline for the cloud-readiness gate to resolve by ANY path.
  ///
  /// Deliberately larger than [cloudInitTimeout]: on the healthy path the
  /// gate resolves well inside the init timeout, so this only ever fires when
  /// the post-frame callback that owns the gate never ran at all.
  static const cloudReadyWatchdog = Duration(seconds: 12);

  /// Upper bound on the cheap pre-runApp database probe. This is a single-row
  /// read, so anything approaching this bound means the file is unhealthy.
  static const dbOpenProbeTimeout = Duration(seconds: 5);

  /// Upper bound on the deferred full-file integrity scan. Generous, because
  /// nothing is waiting on it; a timeout here means the scan is reported as
  /// inconclusive rather than as a failure.
  static const integrityCheckTimeout = Duration(seconds: 30);

  /// How many times [_initCommerce] re-resolves the Supabase client before
  /// concluding that cloud really is unavailable for this process, and how
  /// long it waits between attempts. Sized to comfortably outlast a cold
  /// start that merely ran slow (~30s total) without holding a retry timer
  /// alive for the session.
  static const _commerceAuthRetries = 6;
  static const _commerceAuthRetryDelay = Duration(seconds: 5);

  static const _dbFileName = 'gymlog_db.sqlite';

  /// The auth-state subscription that keeps RevenueCat's identity in step with
  /// Supabase. Held for the lifetime of the process (both [PremiumService] and
  /// the Supabase client are app-lifetime singletons), but stored rather than
  /// discarded so [_initCommerce]'s retry path can never leave two live
  /// subscriptions delivering duplicate identity changes.
  static StreamSubscription<AuthState>? _authSubscription;

  /// Runs nonblocking startup. Block ONLY on Flutter binding, local config,
  /// and a cheap database open probe before calling [runApp].
  static Future<void> run(
    Widget Function(BootstrapResult result) appBuilder,
  ) async {
    // ── Stage 1: Framework binding & image-cache guardrails ──────────────
    WidgetsFlutterBinding.ensureInitialized();
    _boundImageCache();

    ErrorWidget.builder = (details) {
      if (kDebugMode) return ErrorWidget(details.exception);
      return const AppErrorScreen();
    };

    usePathUrlStrategy();

    // ── Stage 2: Sentry initialization ────────────────────────────
    final cloudReady = Completer<bool>();
    await SentryFlutter.init(
      _configureSentry,
      appRunner: () async {
        // ── Stage 3: Essential local configuration (accent palette & DB) ─
        //
        // These are the ONLY two app-owned awaits on the blocking path before
        // runApp, and they are independent: a preferences read and a database
        // open. Run them concurrently so the cost is the slower of the two
        // rather than their sum.
        final (accentPalette, dbStage) = await (
          _initAccentPalette(),
          _initDatabase(),
        ).wait;

        final db = dbStage.db;
        final notificationService = NotificationService();
        final premiumService = PremiumService(db);

        final bool migrationFailure = dbStage.corrupted;
        final status = migrationFailure
            ? BootstrapStatus.migrationFailure
            : BootstrapStatus.localReady;

        final result = BootstrapResult(
          db: db,
          premiumService: premiumService,
          notificationService: notificationService,
          databaseCorrupted: migrationFailure,
          cloudAvailable: false, // Set asynchronously post-frame
          accentPalette: accentPalette,
          cloudReady: cloudReady.future,
          status: status,
          recoverableError: migrationFailure,
        );

        // ── Stage 4: Launch UI IMMEDIATELY after local ready ─────────────
        runApp(appBuilder(result));

        // ── Stage 5: Move noncritical work post-first-frame ───────────────
        if (!migrationFailure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_postLaunchBackgroundWork(
              db: db,
              premiumService: premiumService,
              notificationService: notificationService,
              cloudReady: cloudReady,
            ));
          });
          _armCloudReadyWatchdog(cloudReady);
        } else {
          cloudReady.complete(false);
        }
      },
    );
  }

  /// Liveness guarantee for the cloud-readiness gate.
  ///
  /// The gate is completed from exactly one place: [_postLaunchBackgroundWork],
  /// which is scheduled from a post-frame callback. That callback is not
  /// guaranteed to run. a launch straight into the background, or a throw
  /// during the first build, leaves it pending indefinitely. Every surface
  /// awaiting the gate (SplashScreen first) would then wait forever.
  ///
  /// A gate that can never resolve is worse than a gate that resolves
  /// pessimistically: local-only mode is fully usable, an infinite spinner is
  /// not.
  static void _armCloudReadyWatchdog(Completer<bool> cloudReady) {
    Timer(cloudReadyWatchdog, () {
      if (cloudReady.isCompleted) return;
      if (kDebugMode) {
        debugPrint('[Bootstrap] cloud readiness watchdog fired after '
            '${cloudReadyWatchdog.inSeconds}s. the post-frame callback never '
            'completed the gate. Continuing in local-only mode.');
      }
      unawaited(Sentry.captureMessage(
        'Cloud readiness watchdog fired. post-frame bootstrap never resolved',
        level: SentryLevel.warning,
      ));
      cloudReady.complete(false);
    });
  }

  /// Work deferred past the first frame.
  ///
  /// ORDER MATTERS, for two different reasons.
  ///
  /// Cloud init is first because SplashScreen gates its first route on
  /// `cloudReadinessProvider`, so time-to-cloud-ready is the splash's critical
  /// path.
  ///
  /// Catalog hydration is ordered BEFORE integrity verification because both
  /// hit the same [AppDatabase], which runs on a single background isolate
  /// with a single connection (`NativeDatabase.createInBackground`). They do
  /// not run in parallel. they interleave on one worker. Hydration gates the
  /// exercise library being usable; integrity verification has no deadline and
  /// no UI waiting on it, so it yields.
  static Future<void> _postLaunchBackgroundWork({
    required AppDatabase db,
    required PremiumService premiumService,
    required NotificationService notificationService,
    required Completer<bool> cloudReady,
  }) async {
    try {
      // 1. Cloud readiness. the splash is blocked on this. Bounded timeout.
      final cloudOk = await _initCloud();
      // Guarded: the watchdog may have already resolved the gate, and
      // completing a completed Completer throws StateError.
      if (!cloudReady.isCompleted) cloudReady.complete(cloudOk);

      // 2. Local notifications initialization (fire-and-forget). C36-F2
      //    found requestPermissions() existed but had no call site anywhere
      //    in the app, so notification permission was never actually
      //    requested and the rest-timer background notification could never
      //    fire in production; chaining requestPermissions() after init()
      //    fixed that. D42 revisits the resulting cold-start timing: asking
      //    before the user has ever started a single set gives the one-shot
      //    OS prompt zero context, and a denial here is permanent on both
      //    platforms. The channel setup in init() still has to happen at
      //    cold start. rest-timer notifications need somewhere to land the
      //    moment they're needed. but the permission REQUEST itself has
      //    moved to RestTimerNotifier.start(), the first moment the user is
      //    actually using the feature the permission exists for.
      unawaited(notificationService.init());

      // 3. Media cache maintenance (fire-and-forget, no database access)
      unawaited(ExerciseMediaCacheManager().performMaintenance());

      // 4. Commerce readiness (RevenueCat refresh). Fire-and-forget: on the
      //    slow-cloud path this schedules bounded re-resolve attempts (see
      //    [_initCommerce]) and must not hold up hydration or the scan.
      unawaited(_initCommerce(premiumService));

      // 5. Catalog hydration & orphan cleanup. Owns the database worker first
      //    because the exercise library is unusable until this completes.
      await _postLaunchMaintenance(db);

      // 6. Deep integrity verification. Last on purpose: it walks every page
      //    in the file and nothing is waiting on its result.
      await _verifyIntegrityInBackground(db);
    } catch (e, st) {
      // Everything below the failure point is abandoned: the user gets a
      // silently degraded app that still looks fine. debugPrint runs in every
      // build mode (release included) but nobody is watching a production
      // device's console, so Sentry.captureException below is what actually
      // surfaces this failure in practice. the local debugPrint is dev-
      // console convenience only and is gated so it does not also write raw
      // exception text to the release-build system log (see C38).
      if (kDebugMode) {
        debugPrint('[Bootstrap] postLaunchBackgroundWork failed: $e');
      }
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (!cloudReady.isCompleted) cloudReady.complete(false);
    }
  }

  // ── Stage 1 helpers ───────────────────────────────────────

  /// Bound the in-memory image cache. GymLog streams animated exercise GIFs
  /// (each frame is a separate decoded bitmap), so the framework default
  /// (1000 entries / 100 MiB) can spike on a long library scroll.
  static void _boundImageCache() {
    PaintingBinding.instance.imageCache
      ..maximumSize = 256
      ..maximumSizeBytes = 80 << 20; // 80 MiB
  }

  // ── Stage 2 helper ─────────────────────────────────────

  /// Sentry options. NOTE: `SentryFlutter.init` wraps `runApp`, so everything
  /// configured here is paid on the launch path and on every frame after it.
  /// Debug rates are deliberately NOT 1.0: full-rate tracing plus the Dart
  /// isolate profiler plus verbose SDK logging measurably degrades the very
  /// frame timings we are trying to observe.
  static FutureOr<void> _configureSentry(SentryFlutterOptions options) {
    options.dsn = Env.sentryDsn;
    // Auto-infers release from pubspec.yaml. do NOT hardcode.
    options.environment = kReleaseMode ? 'production' : 'development';
    options.tracesSampleRate = kReleaseMode ? 0.1 : 0.2;
    // Profiling samples the isolate on a timer; keep it off outside release.
    // ignore: experimental_member_use
    options.profilesSampleRate = kReleaseMode ? 0.1 : 0.0;
    options.attachScreenshot = false;
    options.enableAppHangTracking = true; // iOS ANR-like detection

    // Verbose SDK logging formats and prints every breadcrumb synchronously.
    options.debug = false;
    options.diagnosticLevel = SentryLevel.warning;

    // Scrub PII before sending. only the Supabase UUID is ever attached.
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
      if (kDebugMode) {
        debugPrint(
            '[Bootstrap] No SENTRY_DSN in this build. Sentry will initialize but '
            'events will not be sent. Build with --dart-define-from-file=.env '
            'to enable crash reporting.');
      }
    }
  }

  // ── Stage 4 helper ─────────────────────────────────────

  /// Opens the database and performs a CHEAP liveness probe. Returns the handle
  /// plus a `corrupted` flag; never throws.
  ///
  /// This intentionally does NOT run `PRAGMA quick_check`. quick_check walks
  /// every page in the file, so its cost scales with the user's logged history
  ///. the users with the most data paid the longest blank-window wait, and on
  /// a large database it can exceed the platform ANR budget. A single-row read
  /// still surfaces the failures that genuinely block launch (unopenable file,
  /// corrupt header, failed or half-applied migration), because Drift opens the
  /// file and runs pending migrations on first query. Deep verification happens
  /// post-first-frame in [_verifyIntegrityInBackground].
  static Future<({AppDatabase db, bool corrupted})> _initDatabase() async {
    final db = AppDatabase();
    try {
      await db.customSelect('SELECT 1').getSingle().timeout(dbOpenProbeTimeout);
      return (db: db, corrupted: false);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Bootstrap] database open probe failed: $e');
      }
      unawaited(Sentry.captureException(e, stackTrace: st));
      return (db: db, corrupted: true);
    }
  }

  /// Full page-level integrity scan, run after the first frame so it never
  /// delays launch.
  ///
  /// A failure here is a real, user-affecting condition, so it does two
  /// things: reports to Sentry for us, and raises [databaseIntegrityFailed] so
  /// `GymLogApp` swaps in `DatabaseRecoveryScreen` for the user. Detecting
  /// corruption without telling the user is worse than not checking, because
  /// it buys the appearance of safety.
  ///
  /// A thrown exception (including a timeout) is NOT treated as corruption —
  /// only an explicit non-`ok` result is. An inconclusive scan must not
  /// present the user with a destructive reset prompt.
  static Future<void> _verifyIntegrityInBackground(AppDatabase db) async {
    try {
      final rows = await db
          .customSelect('PRAGMA quick_check')
          .get()
          .timeout(integrityCheckTimeout);
      final ok = rows.isNotEmpty &&
          rows.first.data.values.first.toString().toLowerCase() == 'ok';
      if (!ok) {
        if (kDebugMode) {
          debugPrint('[Bootstrap] deferred quick_check did not return ok');
        }
        unawaited(Sentry.captureMessage(
          'Deferred database quick_check failed',
          level: SentryLevel.error,
        ));
        databaseIntegrityFailed.value = true;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Bootstrap] deferred integrity check failed: $e');
      }
      unawaited(Sentry.captureException(e, stackTrace: st));
    }
  }

  /// Deletes the on-disk database file so a fresh, empty database is created on
  /// the next launch. Invoked by the recovery screen after user confirmation.
  static Future<void> resetDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _dbFileName));
    if (await file.exists()) await file.delete();
  }

  // ── Stage 4b helper ───────────────────────────────────

  /// Reads the user's saved accent palette. Never throws. any failure falls
  /// back to the default accent ([ThemePalette.fallback], Volt) so startup is
  /// never blocked by preferences.
  static Future<ThemePalette> _initAccentPalette() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const seedFlagV1 = 'accent_default_migrated_v1';
      const resetFlagV2 = 'accent_default_volt_v2';
      if (!prefs.containsKey(resetFlagV2)) {
        final stored = prefs.getString(kAccentPaletteKey);
        if (prefs.getBool(seedFlagV1) == true &&
            stored == ThemePalette.neonPurple.storageKey) {
          await prefs.remove(kAccentPaletteKey);
        }
        await prefs.setBool(resetFlagV2, true);
      }
      return ThemePalette.fromStorage(prefs.getString(kAccentPaletteKey));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[Bootstrap] accent palette load failed. default accent: $e');
      }
      return ThemePalette.fallback;
    }
  }

  // ── Stage 5 helper ───────────────────────────────────

  /// Initialises Supabase auth. Config arrives at compile time; a build without
  /// it must not crash. The call is bounded by [cloudInitTimeout]; on timeout
  /// we proceed in local-only mode. We always attempt initialize so the
  /// `Supabase.instance` singleton exists for the rest of the app.
  ///
  /// IMPORTANT: `.timeout()` is a BOUND, not a CANCELLATION. Returning false
  /// here means "cloud was not ready in time", NOT "cloud will never be
  /// ready". `Supabase.initialize()` keeps running and may succeed moments
  /// later. Any consumer that resolves the client exactly once off the back of
  /// this result will be permanently wrong on a merely-slow launch. See
  /// [_initCommerce] for the re-resolve pattern.
  static Future<bool> _initCloud() async {
    if (!Env.hasSupabaseConfig) {
      if (kDebugMode) {
        debugPrint(
            '[Bootstrap] No Supabase config. auth unavailable; local logging '
            'still works.');
      }
    }
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      ).timeout(cloudInitTimeout);
      return Env.hasSupabaseConfig;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint(
            '[Bootstrap] Supabase init timed out. continuing in local-only mode.');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Bootstrap] Supabase init failed. local-only mode: $e');
      }
      return false;
    }
  }

  // ── Stage 6 helper ───────────────────────────────────

  /// Configures premium entitlements (RevenueCat) on the SAME [PremiumService]
  /// instance the provider scope exposes. Degrades to free mode when keys are
  /// absent or the platform is unsupported. never blocks launch.
  ///
  /// DO NOT CONSTRUCT A SERVICE HERE. This helper previously did
  /// `PremiumService(db)`, initialised that local instance, wired the auth
  /// listener to it, and returned it. while the call site discarded the
  /// return value. The instance actually exposed through
  /// `premiumServiceProvider` was therefore never initialised: `_configured`
  /// stayed false, `offerings()` returned null, and the paywall permanently
  /// showed "Pricing unavailable. Tap to retry." even with valid keys.
  ///
  /// Uses [supabaseClientOrNull] rather than touching `Supabase.instance`
  /// directly. the ONLY seam every other cloud consumer in this codebase
  /// goes through. This function used to bypass it with ad hoc try/catch,
  /// which was safe only by accident of call order in
  /// [_postLaunchBackgroundWork]; nothing enforced that ordering.
  ///
  /// DO NOT RESOLVE THE CLIENT ONLY ONCE. [_initCloud] bounds
  /// `Supabase.initialize()` with a timeout, and a timeout is not a
  /// cancellation: initialisation keeps running and can complete seconds after
  /// the bound elapses. A single resolve meant that a launch which merely ran
  /// slow saw `null`, made `client?.auth.onAuthStateChange.listen(...)` a
  /// no-op, and left the process with NO auth listener at all. Supabase then
  /// finished initialising, the user signed in, and nothing ever told
  /// RevenueCat: `PremiumService._userId` stayed null, `_syncToLocalCache()`
  /// early-returned on it, and a paying user's entitlement was never mirrored
  /// into the Drift offline cache until the next cold start. So we re-resolve
  /// on a bounded schedule before concluding cloud is genuinely absent.
  static Future<void> _initCommerce(PremiumService premiumService) async {
    var client = supabaseClientOrNull();

    // Configure immediately with whatever identity we can see now, so a
    // healthy launch pays no extra latency. The retry loop below only ever
    // adds work on the degraded path.
    unawaited(premiumService.initialize(userId: client?.auth.currentUser?.id));

    for (var attempt = 0;
        client == null && attempt < _commerceAuthRetries;
        attempt++) {
      await Future<void>.delayed(_commerceAuthRetryDelay);
      client = supabaseClientOrNull();
    }

    // Genuinely local-only for this process: no client will ever appear, so
    // there is no auth to track. PremiumService stays in its free/cached mode.
    if (client == null) return;

    // Late resolution means the identity we configured with above may be
    // stale. Re-assert it. but only when non-null, because setUser(null) on a
    // configured SDK issues a pointless Purchases.logOut() for a user who was
    // never logged in.
    final resolvedUser = client.auth.currentUser;
    if (resolvedUser != null) {
      unawaited(premiumService.setUser(
        resolvedUser.id,
        email: resolvedUser.email,
        displayName: resolvedUser.userMetadata?['full_name'] as String? ??
            resolvedUser.userMetadata?['name'] as String?,
      ));
    }

    // Idempotent by construction: the retry path must never leave two live
    // subscriptions delivering duplicate identity changes to RevenueCat.
    unawaited(_authSubscription?.cancel());
    _authSubscription = client.auth.onAuthStateChange.listen(
      (state) {
        final user = state.session?.user;
        unawaited(premiumService.setUser(
          user?.id,
          email: user?.email,
          displayName: user?.userMetadata?['full_name'] as String? ??
              user?.userMetadata?['name'] as String?,
        ));
      },
      // onAuthStateChange is a broadcast stream and can emit AuthException —
      // a failed token refresh is the common case. Without a handler that
      // surfaced as an unhandled async error in the root zone, invisible in
      // release and untraceable in Sentry.
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[Bootstrap] auth state stream error: $e');
        }
        unawaited(Sentry.captureException(e, stackTrace: st));
      },
    );
  }

  // ── Stage 7 helper ───────────────────────────────────

  static Future<void> _postLaunchMaintenance(AppDatabase db) async {
    try {
      await db.exercisesDao.hydrateFromJson(); // One-time JSON seed

      final user = supabaseClientOrNull()?.auth.currentUser;
      if (user != null) {
        await db.workoutsDao.deleteOrphanedSessions(user.id);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Bootstrap] post-launch maintenance failed: $e');
      }
      unawaited(Sentry.captureException(e, stackTrace: st));
    }
  }
}
