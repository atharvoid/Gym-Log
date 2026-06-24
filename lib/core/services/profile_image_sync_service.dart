import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/premium_provider.dart';

/// Silent cloud sync for profile images.
///
/// All users can pick and store a profile image locally. Pro users get
/// automatic cloud backup — the image is uploaded to Supabase Storage
/// and restored on login/reinstall. This is completely invisible to the
/// user: no paywall, no UI prompt, no visible difference. The backend
/// simply syncs when entitled and stays local-only when not.
class ProfileImageSyncService {
  ProfileImageSyncService({
    required SupabaseClient client,
    required AppDatabase db,
    required Future<SharedPreferences> Function() prefs,
  })  : _client = client,
        _db = db,
        _prefs = prefs;

  final SupabaseClient _client;
  final AppDatabase _db;
  final Future<SharedPreferences> Function() _prefs;

  static const _bucket = 'profile-images';
  static const _pendingUploadKey = 'pending_profile_image_upload';
  static const _pendingDownloadKey = 'pending_profile_image_download';

  /// Upload the local profile image to Supabase Storage.
  /// Silently no-ops when the user is not Pro — no error, no paywall.
  /// Called right after the user picks/crops a new image.
  Future<void> uploadIfEntitled({
    required String userId,
    required bool isPremium,
    required String localPath,
  }) async {
    if (!isPremium) return;

    try {
      final file = File(localPath);
      if (!await file.exists()) return;

      final storagePath = '$userId/profile.jpg';
      await _client.storage.from(_bucket).upload(
        storagePath,
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
  Future<String?> downloadIfEntitled({
    required String userId,
    required bool isPremium,
  }) async {
    if (!isPremium) return null;

    try {
      final storagePath = '$userId/profile.jpg';
      final exists = await _client.storage
          .from(_bucket)
          .list(path: userId);
      if (!exists.any((f) => f.name == 'profile.jpg')) return null;

      final bytes = await _client.storage
          .from(_bucket)
          .download(storagePath);

      // Write to the app documents directory.
      final dir = await _getDocumentsDir();
      final localPath = '${dir.path}/profile_image.jpg';
      final file = File(localPath);
      await file.writeAsBytes(bytes);
      return localPath;
    } catch (_) {
      return null;
    }
  }

  /// Called from the auth listener or splash to attempt any queued upload.
  Future<void> retryPendingUpload({
    required String userId,
    required bool isPremium,
  }) async {
    if (!isPremium) return;
    final prefs = await _prefs();
    final queued = prefs.getString(_pendingUploadKey);
    if (queued == null) return;

    try {
      final file = File(queued);
      if (!await file.exists()) {
        await prefs.remove(_pendingUploadKey);
        return;
      }
      final storagePath = '$userId/profile.jpg';
      await _client.storage.from(_bucket).upload(
        storagePath,
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

  /// Check if the uploaded image should be deleted (e.g. on image removal).
  Future<void> deleteRemoteIfEntitled({
    required String userId,
    required bool isPremium,
  }) async {
    if (!isPremium) return;
    try {
      await _client.storage.from(_bucket).remove(['$userId/profile.jpg']);
    } catch (_) {
      // Best-effort; never surface to the user.
    }
  }

  Future<Directory> _getDocumentsDir() async {
    // Lazy import to avoid pulling path_provider at module scope.
    return await path_provider.getApplicationDocumentsDirectory();
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io' show Directory;

final profileImageSyncProvider = Provider<ProfileImageSyncService>((ref) {
  return ProfileImageSyncService(
    client: Supabase.instance.client,
    db: ref.read(databaseProvider),
    prefs: SharedPreferences.getInstance,
  );
});
