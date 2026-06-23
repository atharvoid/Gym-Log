import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../database/database.dart';
import '../services/premium_service.dart';
import '../../shared/widgets/app_error_screen.dart';

/// Outcome of the staged startup sequence. Carries the shared singletons the
/// provider scope needs, plus resilience flags the UI may act on.
class BootstrapResult {
  final AppDatabase db;
  final PremiumService premiumService;

  /// True when the local database failed its integrity check. The app shows a
  /// recovery prompt instead of crashing.
  final bool databaseCorrupted;

  /// True when the build carries real Supabase config AND init completed within
  /// the timeout. When false, the app runs local-only until the next launch.
  final bool cloudAvailable;

  const BootstrapResult({
    required this.db,
    required this.premiumService,
    required this.databaseCorrupted,
    required this.cloudAvailable,
  });
}

/// Staged, recoverable application startup.
///
/// Each stage is independent: a cloud failure never blocks local launch, and a
/// corrupt database surfaces a user-facing reset path rather than a black
/// screen. The happy-path flow is identical to the previous inline `main()`.
abstract final class Bootstrap {
  /// Upper bound on cloud (Supabase) initialisation before we proceed in
  /// local-only mode.
  static const cloudInitTimeout = Duration(seconds: 8);

  static const _dbFileName = 'gymlog_db.sqlite';

  /// Runs the full staged startup inside the Sentry zone and launches the app
  /// built by [appBuilder] from the [BootstrapResult].
  static Future<void> run(
    Widget Function(BootstrapResult result) appBuilder,
  ) async {
    // ── Stage 1: framework binding + image-cache guardrails ──────────────
    WidgetsFlutterBinding.ensureInitialized();
    _boundImageCache();

    // Branded failure surface — release builds must never show the red/yellow
    // Flutter error screen if a build method throws.
    ErrorWidget.builder = (details) {
      if (kDebugMode) return ErrorWidget(details.exception);
      return const AppErrorScreen();
    };

    // ── Stage 2: crash reporting wraps the entire startup ────────────────
    await SentryFlutter.init(
      _configureSentry,
      appRunner: () async {
        // ── Stage 3: navigation strategy (web path-based routing) ────────
        usePathUrlStrategy();

        // ── Stage 4: local database readiness (+ integrity check) ────────
        final dbStage = await _initDatabase();

        // ── Stage 5: cloud auth readiness (bounded; local-only on failure)
        final cloudAvailable = await _initCloud();

        // ── Stage 6: commerce readiness (never blocks launch) ────────────
        final premiumService = _initCommerce(dbStage.db);

        final result = BootstrapResult(
          db: dbStage.db,
          premiumService: premiumService,
          databaseCorrupted: dbStage.corrupted,
          cloudAvailable: cloudAvailable,
        );

        runApp(appBuilder(result));

        // ── Stage 7: post-launch maintenance, off the first-frame path ───
        if (!dbStage.corrupted) {
          unawaited(_postLaunchMaintenance(dbStage.db));
        }
      },
    );
  }

  // ── Stage 1 helpers ────────────────────────────────────────────────────

  /// Bound the in-memory image cache. GymLog streams animated exercise GIFs
  /// (each frame is a separate decoded bitmap), so the framework default
  /// (1000 entries / 100 MiB) can spike on a long library scroll.
  static void _boundImageCache() {
    PaintingBinding.instance.imageCache
      ..maximumSize = 256
      ..maximumSizeBytes = 80 << 20; // 80 MiB
  }

  // ── Stage 2 helper ─────────────────────────────────────────────────────

  static FutureOr<void> _configureSentry(SentryFlutterOptions options) {
    options.dsn = Env.sentryDsn;
    // Auto-infers release from pubspec.yaml — do NOT hardcode.
    options.environment = kReleaseMode ? 'production' : 'development';
    options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
    // ignore: experimental_member_use
    options.profilesSampleRate = kReleaseMode ? 0.1 : 1.0;
    options.attachScreenshot = false;
    options.enableAppHangTracking = true; // iOS ANR-like detection

    options.debug = kDebugMode;
    options.diagnosticLevel = SentryLevel.debug;

    // Scrub PII before sending — only the Supabase UUID is ever attached.
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
          '[Bootstrap] No SENTRY_DSN in this build — Sentry will initialize but '
          'events will not be sent. Build with --dart-define-from-file=.env '
          'to enable crash reporting.');
    }
  }

  // ── Stage 4 helper ─────────────────────────────────────────────────────

  /// Opens the database and verifies integrity. Returns the handle plus a
  /// `corrupted` flag; never throws.
  static Future<({AppDatabase db, bool corrupted})> _initDatabase() async {
    final db = AppDatabase();
    try {
      final rows = await db
          .customSelect('PRAGMA quick_check')
          .get()
          .timeout(const Duration(seconds: 10));
      final ok = rows.isNotEmpty &&
          rows.first.data.values.first.toString().toLowerCase() == 'ok';
      if (!ok) {
        debugPrint('[Bootstrap] database quick_check did not return ok');
        return (db: db, corrupted: true);
      }
      // Warm-up query preserves the original first-frame behaviour.
      await db.customSelect('SELECT 1').getSingle();
      return (db: db, corrupted: false);
    } catch (e, st) {
      debugPrint('[Bootstrap] database integrity check failed: $e');
      unawaited(Sentry.captureException(e, stackTrace: st));
      return (db: db, corrupted: true);
    }
  }

  /// Deletes the on-disk database file so a fresh, empty database is created on
  /// the next launch. Invoked by the recovery screen after user confirmation.
  static Future<void> resetDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _dbFileName));
    if (await file.exists()) await file.delete();
  }

  // ── Stage 5 helper ─────────────────────────────────────────────────────

  /// Initialises Supabase auth. Config arrives at compile time; a build without
  /// it must not crash. The call is bounded by [cloudInitTimeout]; on timeout
  /// we proceed in local-only mode. We always attempt initialize so the
  /// `Supabase.instance` singleton exists for the rest of the app.
  static Future<bool> _initCloud() async {
    if (!Env.hasSupabaseConfig) {
      debugPrint(
          '[Bootstrap] No Supabase config — auth unavailable; local logging '
          'still works.');
    }
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      ).timeout(cloudInitTimeout);
      return Env.hasSupabaseConfig;
    } on TimeoutException {
      debugPrint(
          '[Bootstrap] Supabase init timed out — continuing in local-only mode.');
      return false;
    } catch (e) {
      debugPrint('[Bootstrap] Supabase init failed — local-only mode: $e');
      return false;
    }
  }

  // ── Stage 6 helper ─────────────────────────────────────────────────────

  /// Configures premium entitlements (RevenueCat). Degrades to free mode when
  /// keys are absent or the platform is unsupported — never blocks launch.
  static PremiumService _initCommerce(AppDatabase db) {
    final premiumService = PremiumService(db);
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase instance not ready — premium stays in free mode.
    }
    unawaited(premiumService.initialize(userId: userId));
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (state) => premiumService.setUser(state.session?.user.id),
      );
    } catch (_) {
      // No auth stream available — entitlement stays on the local cache.
    }
    return premiumService;
  }

  // ── Stage 7 helper ─────────────────────────────────────────────────────

  static Future<void> _postLaunchMaintenance(AppDatabase db) async {
    try {
      await db.exercisesDao.hydrateFromJson(); // One-time JSON seed

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await db.workoutsDao.deleteOrphanedSessions(user.id);
      }
    } catch (e) {
      debugPrint('[Bootstrap] post-launch maintenance failed: $e');
    }
  }
}
