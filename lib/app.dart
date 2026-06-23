import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
import 'core/services/sync_engine.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class GymLogApp extends ConsumerStatefulWidget {
  const GymLogApp({super.key});

  @override
  ConsumerState<GymLogApp> createState() => _GymLogAppState();
}

class _GymLogAppState extends ConsumerState<GymLogApp> {
  late final AppLifecycleListener _lifecycle;

  /// Listens for auth state changes so that the sync engine is initialised
  /// even when GoRouter bypasses SplashScreen (e.g. fresh install: the user
  /// signs in on /auth and is redirected directly to / without SplashScreen
  /// running its _resolveInitialRoute).
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // Capture Flutter framework errors and forward them to Sentry.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Sentry.captureException(details.exception, stackTrace: details.stack);
    };

    // Backgrounding is an explicit sync trigger — flush the queue before the
    // OS may suspend us. Resuming arms a debounced sync (covers the common
    // "came back" case without a connectivity plugin).
    _lifecycle = AppLifecycleListener(
      onHide: _flush,
      onPause: _flush,
      onResume: _onResume,
    );

    // Cover the fresh-install path: GoRouter redirects /auth → / directly on
    // sign-in, so SplashScreen never runs. This listener picks that up.
    // initSession() is idempotent, so calling it here when SplashScreen has
    // already run (cold start) is a safe no-op.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
    );
  }

  String? get _userId => ref.read(authProvider)?.id;

  void _flush() {
    final id = _userId;
    if (id == null) return;
    final engine = ref.read(syncEngineProvider);
    // Snapshot the latest preferences, then flush the whole queue before the
    // OS may suspend us.
    engine
        .enqueuePreferences(id)
        .whenComplete(() => engine.syncNow(id, reason: 'background'));
  }

  void _onResume() {
    final id = _userId;
    if (id != null) ref.read(syncEngineProvider).scheduleSync(id);
  }

  /// Handles auth state transitions emitted by Supabase.
  ///
  /// * `signedIn`  → kick off `initSession` (idempotent; no-op if
  ///                 SplashScreen already ran for this user) and snapshot
  ///                 the latest preferences.
  /// * `signedOut` → reset the engine guard so the next sign-in triggers
  ///                 a fresh pull.
  /// * Everything else (tokenRefreshed, userUpdated, …) → ignored.
  void _onAuthStateChange(AuthState event) {
    final engine = ref.read(syncEngineProvider);

    if (event.event == AuthChangeEvent.signedOut) {
      engine.resetSession();
      return;
    }

    if (event.event != AuthChangeEvent.signedIn) return;

    final userId = event.session?.user.id;
    if (userId == null) return;

    unawaited(engine.initSession(userId));
    unawaited(engine.enqueuePreferences(userId));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'GymLog',
      theme: appTheme,
      // Auto-applied by the framework when the OS "increase contrast" setting
      // is on. Both slots point at the same variant since the app is dark-only.
      highContrastTheme: appHighContrastTheme,
      highContrastDarkTheme: appHighContrastTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Clamp Dynamic Type so extreme OS font scales can't clip CTAs or
      // overflow dense stat rows; users below the cap are unaffected.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.4),
          ),
          child: child!,
        );
      },
    );
  }
}
