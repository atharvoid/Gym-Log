import 'package:supabase_flutter/supabase_flutter.dart';

/// A profile as stored on the backend (the cross-device source of truth).
class RemoteProfile {
  final String id;
  final String displayName;
  final String? email;

  const RemoteProfile({
    required this.id,
    required this.displayName,
    this.email,
  });
}

/// Authenticated remote profile API. Implementations talk to the backend on
/// behalf of the signed-in user; callers (ProfileSyncService) are responsible
/// for catching failures and queueing retries — these methods may throw.
abstract class ProfileRemote {
  /// The current user's profile, or null if they have none yet.
  Future<RemoteProfile?> fetch(String userId);

  /// Create or overwrite the current user's profile.
  Future<void> upsert({
    required String userId,
    required String displayName,
    String? email,
  });
}

/// Supabase-backed implementation, hitting the `profiles` table through
/// PostgREST with the user's auth JWT (RLS enforces ownership server-side).
/// See docs/supabase/profiles.sql for the schema this expects.
class SupabaseProfileRemote implements ProfileRemote {
  SupabaseProfileRemote(this._client);

  final SupabaseClient _client;

  static const _table = 'profiles';

  @override
  Future<RemoteProfile?> fetch(String userId) async {
    final row = await _client
        .from(_table)
        .select('id, display_name, email')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return RemoteProfile(
      id: row['id'] as String,
      displayName: (row['display_name'] as String?) ?? '',
      email: row['email'] as String?,
    );
  }

  @override
  Future<void> upsert({
    required String userId,
    required String displayName,
    String? email,
  }) async {
    await _client.from(_table).upsert({
      'id': userId,
      'display_name': displayName,
      if (email != null) 'email': email,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
