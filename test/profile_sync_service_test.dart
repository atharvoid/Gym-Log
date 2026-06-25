// ProfileSyncService behaviour — local-first writes, backend-as-source-of-truth
// hydration, and the silent offline queue/retry — all without a live backend
// (a fake ProfileRemote stands in for Supabase).

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/services/profile_sync_service.dart';
import 'package:gymlog/features/profile/data/profile_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

/// Controllable fake of the remote profile API.
class FakeRemote implements ProfileRemote {
  RemoteProfile? stored;
  bool failNext = false; // simulate offline / table-missing
  int upsertCalls = 0;
  int fetchCalls = 0;

  @override
  Future<RemoteProfile?> fetch(String userId) async {
    fetchCalls++;
    if (failNext) throw Exception('offline');
    return stored;
  }

  @override
  Future<void> upsert({
    required String userId,
    required String displayName,
    String? email,
  }) async {
    upsertCalls++;
    if (failNext) throw Exception('offline');
    stored = RemoteProfile(id: userId, displayName: displayName, email: email);
  }
}

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late ProfileSyncService service;
  const userId = 'user-1';
  const email = 'a@b.com';

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeRemote();
    service = ProfileSyncService(remote: remote, db: db);
  });

  tearDown(() => db.close());

  group('submitDisplayName', () {
    test('writes local immediately and pushes to remote on success', () async {
      await service.submitDisplayName(
          userId: userId, email: email, name: '  Atharva  ');

      final local = await db.userDao.getUserOrNull(userId);
      expect(local?.displayName, 'Atharva'); // trimmed, local-first
      expect(remote.stored?.displayName, 'Atharva'); // delivered
      expect(remote.upsertCalls, 1);
    });

    test('keeps local + queues when remote is offline, retry delivers later',
        () async {
      remote.failNext = true;
      await service.submitDisplayName(
          userId: userId, email: email, name: 'Atharva');

      // Local saved, remote not delivered (queued).
      expect((await db.userDao.getUserOrNull(userId))?.displayName, 'Atharva');
      expect(remote.stored, isNull);

      // Backend recovers; retry flushes the queue exactly once.
      remote.failNext = false;
      await service.retryPending(userId);
      expect(remote.stored?.displayName, 'Atharva');

      // Queue cleared — a second retry is a no-op.
      final before = remote.upsertCalls;
      await service.retryPending(userId);
      expect(remote.upsertCalls, before);
    });
  });

  group('resolveOnLogin', () {
    test('hydrates local from the backend when a remote profile exists',
        () async {
      remote.stored = const RemoteProfile(
          id: userId, displayName: 'Cloud Name', email: email);

      final res = await service.resolveOnLogin(userId: userId, email: email);

      expect(res, ProfileResolution.ready);
      expect((await db.userDao.getUserOrNull(userId))?.displayName,
          'Cloud Name'); // backend won
    });

    test('first-ever user (no remote, no local) needs onboarding', () async {
      final res = await service.resolveOnLogin(userId: userId, email: email);
      expect(res, ProfileResolution.needsOnboarding);
    });

    test('no remote but local exists → ready, and local is pushed up',
        () async {
      await db.userDao
          .upsertProfile(id: userId, email: email, displayName: 'Local Only');

      final res = await service.resolveOnLogin(userId: userId, email: email);

      expect(res, ProfileResolution.ready);
      expect(remote.stored?.displayName, 'Local Only'); // backfilled to backend
    });

    test('backend unreachable falls back to local (ready) and never throws',
        () async {
      await db.userDao
          .upsertProfile(id: userId, email: email, displayName: 'Local Only');
      remote.failNext = true;

      final res = await service.resolveOnLogin(userId: userId, email: email);
      expect(res, ProfileResolution.ready);
    });

    test('backend unreachable with no local → onboarding (never blocks)',
        () async {
      remote.failNext = true;
      final res = await service.resolveOnLogin(userId: userId, email: email);
      expect(res, ProfileResolution.needsOnboarding);
    });

    test('hydration preserves existing local preferences', () async {
      // Seed a local profile with a non-default weight unit.
      await db.userDao
          .upsertProfile(id: userId, email: email, displayName: 'Old');
      await db.userDao.setWeightUnit(userId, 'lbs');

      remote.stored =
          const RemoteProfile(id: userId, displayName: 'New', email: email);
      await service.resolveOnLogin(userId: userId, email: email);

      final local = await db.userDao.getUserOrNull(userId);
      expect(local?.displayName, 'New'); // name updated
      expect(local?.weightUnit, 'lbs'); // preference preserved
    });
  });
}
