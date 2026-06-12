import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

/// Single shared [AppDatabase] instance. `main.dart` overrides this with the
/// pre-warmed connection; constructing a second instance here would silently
/// open a second SQLite connection and split stream notifications.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope (see main.dart)',
  );
});
