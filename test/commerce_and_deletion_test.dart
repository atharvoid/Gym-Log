import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/services/account_deletion_service.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// CONTROLLABLE FAKE CLIENTS

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeGoTrueClient _auth = FakeGoTrueClient();

  @override
  GoTrueClient get auth => _auth;
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  User? _currentUser;
  final StreamController<AuthState> _authController =
      StreamController<AuthState>.broadcast();

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _authController.stream;

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    _currentUser = null;
    _authController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  void login(User user) {
    _currentUser = user;
    _authController.add(AuthState(
      AuthChangeEvent.signedIn,
      Session(
        accessToken: 'mock',
        tokenType: 'Bearer',
        user: user,
      ),
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeSupabaseClient supabase;

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    supabase = FakeSupabaseClient();
  });

  tearDown(() => db.close());

  group('Account Deletion Service & UI Guidance', () {
    test(
        'Idempotency — wipes local storage and finishes safely even when user is null (signed out)',
        () async {
      final service = AccountDeletionService(db, supabase);
      final outcome = await service.deleteAccount();

      expect(outcome.localWiped, isTrue);
      expect(outcome.cloudPurged, isFalse);
      expect(outcome.authUserDeleted, isFalse);
    });

    test('Wipes local databases, secure preferences and settings on deletion',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sync_enabled', true);
      await prefs.setString('weight_unit', 'lbs');

      // Populate some fake user profile info in SQLite
      await db.userDao.setPremiumStatus('user-A', isPremium: true);

      final service = AccountDeletionService(db, supabase);
      final outcome = await service.deleteAccount();

      expect(outcome.localWiped, isTrue);

      // Verify preferences are wiped
      expect(prefs.getBool('sync_enabled'), isNull);
      expect(prefs.getString('weight_unit'), isNull);

      // Verify database profiles are wiped
      final profile = await db.userDao.getUserOrNull('user-A');
      expect(profile, isNull);
    });
  });

  group('Premium Service Entitlements & Caching', () {
    test('isPremiumProvider returns false when no user is signed in', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
          customerInfoProvider
              .overrideWith((ref) => Stream.value(null as dynamic)),
        ],
      );

      final isPremium = container.read(isPremiumProvider);
      expect(isPremium, isFalse);
    });

    test(
        'isPremiumProvider falls back to local user profile when CustomerInfo stream has no value (offline launch)',
        () async {
      final mockProfile = UserProfile(
        id: 'user-A',
        email: 'a@b.com',
        displayName: 'User A',
        isPremium: true,
        premiumExpiry: DateTime.now().add(const Duration(days: 30)),
        weightUnit: 'kg',
        defaultRestSeconds: 90,
        createdAt: DateTime.now(),
        onboardingComplete: true,
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(mockProfile)),
          customerInfoProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );

      await container.read(currentUserProfileProvider.future);

      final isPremium = container.read(isPremiumProvider);
      expect(isPremium, isTrue);
    });

    test(
        'isPremiumProvider respects active entitlements from CustomerInfo over local SQLite profile',
        () async {
      final mockProfile = UserProfile(
        id: 'user-A',
        email: 'a@b.com',
        displayName: 'User A',
        isPremium: true,
        premiumExpiry: DateTime.now()
            .subtract(const Duration(days: 1)), // Expired offline cache
        weightUnit: 'kg',
        defaultRestSeconds: 90,
        createdAt: DateTime.now(),
        onboardingComplete: true,
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(mockProfile)),
          customerInfoProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );

      await container.read(currentUserProfileProvider.future);

      // Offline cache expired
      expect(container.read(isPremiumProvider), isFalse);
    });
  });
}
