import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/premium_provider.dart';

/// Entry point. All staged, recoverable initialisation lives in [Bootstrap];
/// `main` only wires the resulting singletons into the Riverpod scope.
Future<void> main() async {
  await Bootstrap.run(
    (result) => ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(result.db),
        premiumServiceProvider.overrideWithValue(result.premiumService),
      ],
      child: GymLogApp(databaseCorrupted: result.databaseCorrupted),
    ),
  );
}
