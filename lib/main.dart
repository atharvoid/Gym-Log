import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/database/database.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/services/premium_service.dart';
import 'shared/widgets/app_error_screen.dart';

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Branded failure surface — release builds must never show the
  //    red/yellow Flutter error screen if a build method throws.
  ErrorWidget.builder = (details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const AppErrorScreen();
  };

  // 3. Set URL strategy for web (use path-based routing, not hash)
  usePathUrlStrategy();

  // 4. Initialize Supabase (auth only — workout data never leaves device).
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
  final db = AppDatabase();
  await db.customSelect('SELECT 1').getSingle(); // Warm-up query

  // 7. Premium entitlements (RevenueCat). Degrades to free mode when keys
  //    are absent or the platform is unsupported — never blocks launch.
  final premiumService = PremiumService(db);
  unawaited(premiumService.initialize(
    userId: Supabase.instance.client.auth.currentUser?.id,
  ));
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (state) => premiumService.setUser(state.session?.user.id),
  );

  // 8. Run app immediately — first frame must not wait on seeding.
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        premiumServiceProvider.overrideWithValue(premiumService),
      ],
      child: const GymLogApp(),
    ),
  );

  // 9. Post-launch maintenance, off the first-frame critical path.
  //    The splash screen provides ample cover on first install, and the
  //    hydration is guarded by a SharedPreferences flag on every other run.
  unawaited(_postLaunchMaintenance(db));
}

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
