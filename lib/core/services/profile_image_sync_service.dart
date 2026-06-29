import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Silent cloud sync for profile images.
///
/// All users can pick and store a profile image locally. Pro users
/// additionally get an automatic, invisible cloud backup (Supabase Storage)
/// that restores on login/reinstall. This is completely invisible to the
/// user: no paywall, no UI prompt, no visible difference. The backend simply
/// syncs when entitled and stays local-only otherwise. The user id is
/// resolved internally from the active Supabase session.
class ProfileImageSyncService {
  ProfileImageSyncService({
    required SupabaseClient client,
    required Future<SharedPreferences> Function() prefs,
  })  : _client = client,
        _prefs = prefs;

  final SupabaseClient _client;
  final Future<SharedPreferences> Function() _prefs;

  static const _bucket = 'profile-images';
  static const _pendingUploadKey = 'pending_profile_image_upload';

  String? get _userId => _client.auth.currentUser?.id;

  String _objectPath(String userId) => '$userId/profile.jpg';

  /// Upload the local profile image to Supabase Storage.
  /// Silently no-ops when the user is not Pro or not signed in — no error,
  /// no paywall. Called right after the user picks/crops a new image.
  Future<void> uploadIfEntitled({
    required bool isPremium,
    required String localPath,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final file = File(localPath);
      if (!await file.exists()) return;

      await _client.storage.from(_bucket).upload(
            _objectPath(userId),
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } catch (_) {
      // Queue for retry — the user never sees a failure.
      final prefs = await _prefs();
      await prefs.setString(_pendingUploadKey, localPath);
    }
  }

  /// Download the profile image from Supabase Storage if one exists.
  /// Called on login/restore when no local image is present.
  /// Returns the local file path, or null if nothing was downloaded.
  Future<String?> downloadIfEntitled({required bool isPremium}) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final listing = await _client.storage.from(_bucket).list(path: userId);
      if (!listing.any((f) => f.name == 'profile.jpg')) return null;

      final bytes =
          await _client.storage.from(_bucket).download(_objectPath(userId));

      final docDir = await path_provider.getApplicationDocumentsDirectory();

      // Clean up any old files starting with profile_ and ending with .jpg
      try {
        final List<FileSystemEntity> entities = docDir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final name = p.basename(entity.path);
            if (name.startsWith('profile_') && name.endsWith('.jpg')) {
              await entity.delete();
            }
          }
        }
      } catch (_) {}

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final localPath = p.join(docDir.path, 'profile_$timestamp.jpg');
      await File(localPath).writeAsBytes(bytes);
      return localPath;
    } catch (_) {
      return null;
    }
  }

  /// Attempt any queued upload (e.g. from the splash/auth listener).
  Future<void> retryPendingUpload({required bool isPremium}) async {
    final userId = _userId;
    if (userId == null) return;

    final prefs = await _prefs();
    final queued = prefs.getString(_pendingUploadKey);
    if (queued == null) return;

    try {
      final file = File(queued);
      if (!await file.exists()) {
        await prefs.remove(_pendingUploadKey);
        return;
      }
      await _client.storage.from(_bucket).upload(
            _objectPath(userId),
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      await prefs.remove(_pendingUploadKey);
    } catch (_) {
      // Keep queued; will retry on next launch.
    }
  }

  /// Delete the remote copy (e.g. when the user removes their photo).
  Future<void> deleteRemoteIfEntitled({required bool isPremium}) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.storage.from(_bucket).remove([_objectPath(userId)]);
    } catch (_) {
      // Best-effort; never surface to the user.
    }
  }
}

final profileImageSyncProvider = Provider<ProfileImageSyncService>((ref) {
  return ProfileImageSyncService(
    client: Supabase.instance.client,
    prefs: SharedPreferences.getInstance,
  );
});
