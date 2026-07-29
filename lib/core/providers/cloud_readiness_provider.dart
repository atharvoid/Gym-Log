import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves when cloud (Supabase) initialisation has been attempted during
/// [Bootstrap]. `true` = `Supabase.instance` is safe to use; `false` =
/// local-only mode (no config, timeout, or init failure). Never errors.
///
/// Overridden in `main.dart` with the real bootstrap future. The default is
/// "unavailable" so tests and the database-recovery shell never touch
/// Supabase.
final cloudReadinessProvider = Provider<Future<bool>>((ref) {
  return Future.value(false);
});
