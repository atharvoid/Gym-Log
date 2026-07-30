import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/database_integrity_signal.dart';
import 'core/providers/cloud_readiness_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dynamic_accent_theme.dart';
import 'core/router/router.dart';
import 'core/services/sync_engine.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'shared/widgets/database_recovery_screen.dart';
import 'shared/widgets/tour/tour_navigation_orchestrator.dart';

class GymLogApp extends ConsumerStatefulWidget {
  /// When true, the local database failed its integrity check during
  /// [Bootstrap]. The app renders a recovery surface instead of the normal
  /// router tree and skips all sync wiring.
  final bool databaseCorrupted;

  const GymLogApp({super.key, this.databaseCorrupted = false});

  @override
  ConsumerState<GymLogApp> createState() => _GymLogAppState();
}

class _GymLogAppState extends ConsumerState<GymLogApp> {
  AppLifecycleListener? _lifecycle;

  /// Listens for auth state changes so that the sync engine is initialised
  /// even when GoRouter bypasses SplashScreen (e.g. fresh install).
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // Capture Flutter framework errors and forward them to Sentry.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Sentry.captureException(details.exception, stackTrace: details.stack);
    };

    // In recovery mode the database is unusable — do not wire sync at all.
    if (widget.databaseCorrupted) return;

    // Backgrounding is an explicit sync trigger — flush the queue before the
    // OS may suspend us. Resuming arms a debounced sync.
    _lifecycle = AppLifecycleListener(
      onHide: _flush,
      onPause: _flush,
      onResume: _onResume,
    );

    // Supabase.initialize() runs post-first-frame (see Bootstrap), so the
    // singleton does not exist yet — touching Supabase.instance here throws
    // LateInitializationError in release builds and crash-loops the app into
    // AppErrorScreen. Await cloud readiness instead; in local-only mode the
    // listener simply never wires and the app stays fully usable offline.
    unawaited(_wireAuthWhenCloudReady());
  }

  Future<void> _wireAuthWhenCloudReady() async {
    final ready = await ref.read(cloudReadinessProvider);
    if (!ready || !mounted || _authSub != null) return;
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        _onAuthStateChange,
      );
    } catch (_) {
      // Defensive: readiness resolved true but the singleton is still not
      // usable (e.g. abandoned init future after timeout). Stay local-only.
    }
  }

  String? get _userId => ref.read(authProvider)?.id;

  void _flush() {
    final id = _userId;
    if (id == null) return;
    // The gate is checked inside the engine — if sync is not allowed,
    // enqueuePreferences and syncNow are silent no-ops.
    final engine = ref.read(syncEngineProvider);
    engine
        .enqueuePreferences(id)
        .whenComplete(() => engine.syncNow(id, reason: 'background'));
  }

  void _onResume() {
    final id = _userId;
    if (id != null) ref.read(syncEngineProvider).scheduleSync(id);
  }

  /// Handles auth state transitions emitted by Supabase.
  void _onAuthStateChange(AuthState event) {
    final engine = ref.read(syncEngineProvider);

    if (event.event == AuthChangeEvent.signedOut) {
      engine.resetSession();
      return;
    }

    if (event.event != AuthChangeEvent.signedIn) return;

    final userId = event.session?.user.id;
    if (userId == null) return;

    final isPremium = ref.read(isPremiumProvider);
    unawaited(engine.initSession(userId, isPremium: isPremium));
    unawaited(engine.enqueuePreferences(userId));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Corruption has two arrival times. Launch-time corruption is known before
    // runApp and arrives as a constructor flag. Deferred corruption is found
    // by the background integrity scan after the tree is already built, and
    // arrives through [databaseIntegrityFailed]. Both lead to the same place:
    // an explicit, user-owned reset rather than silent data loss.
    return ValueListenableBuilder<bool>(
      valueListenable: databaseIntegrityFailed,
      builder: (context, deferredFailure, _) {
        if (widget.databaseCorrupted || deferredFailure) {
          // Recovery mode: a self-contained MaterialApp with no router/auth
          // deps. Uses the purple-default theme since it renders before (or
          // outside of) normal wiring.
          return MaterialApp(
            title: 'GymLog',
            theme: appTheme,
            debugShowCheckedModeBanner: false,
            home: const DatabaseRecoveryScreen(),
          );
        }
        return _buildApp();
      },
    );
  }

  Widget _buildApp() {
    final router = ref.watch(routerProvider);

    // Rebuild the theme whenever the user switches accent palettes. The active
    // tokens flow into colorScheme, buttons, inputs, switches, and the
    // AccentColors extension consumed via `context.accent`.
    //
    // Task 11: we also watch the palette enum so buildAppTheme can switch
    // brightness/surfaces for the White palette.
    final palette = ref.watch(dynamicAccentThemeProvider);
    final tokens = palette.tokens;

    return MaterialApp.router(
      title: 'GymLog',
      theme: buildAppTheme(tokens, palette: palette),
      highContrastTheme: buildHighContrastTheme(tokens, palette: palette),
      highContrastDarkTheme: buildHighContrastTheme(tokens, palette: palette),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.4),
          ),
          child: TourNavigationOrchestrator(child: child!),
        );
      },
    );
  }
}
