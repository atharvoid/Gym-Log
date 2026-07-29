import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymlog/core/services/notification_service.dart';
import 'app.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/providers/cloud_readiness_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/theme/dynamic_accent_theme.dart';

/// Entry point. All staged, recoverable initialisation lives in [Bootstrap];
/// `main` only wires the resulting singletons into the Riverpod scope.
Future<void> main() async {
  await Bootstrap.run(
    (result) => ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(result.db),
        premiumServiceProvider.overrideWithValue(result.premiumService),
        notificationServiceProvider
            .overrideWithValue(result.notificationService),
        // Seed the accent palette read from disk before the first frame so the
        // app paints in the user's chosen accent immediately.
        initialAccentPaletteProvider.overrideWithValue(result.accentPalette),
        // Cloud readiness future — consumers of Supabase.instance must
        // await this instead of touching the singleton blindly. Resolves
        // true once Supabase.initialize() completes (post-first-frame).
        cloudReadinessProvider.overrideWithValue(result.cloudReady),
      ],
      child: GymLogApp(databaseCorrupted: result.databaseCorrupted),
    ),
  );
}
