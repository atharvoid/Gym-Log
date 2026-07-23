import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/services/premium_service.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';

CustomerInfo _createCustomerInfoWithEntitlements(
    Map<String, Map<String, dynamic>> activeEntitlements) {
  final activeJson = <String, dynamic>{};
  final allJson = <String, dynamic>{};

  activeEntitlements.forEach((key, map) {
    final ent = {
      'identifier': key,
      'isActive': true,
      'willRenew': true,
      'periodType': 'NORMAL',
      'latestPurchaseDate': '2026-07-21T00:00:00.000Z',
      'latestPurchaseDateMillis': 1784592000000,
      'originalPurchaseDate': '2026-07-21T00:00:00.000Z',
      'originalPurchaseDateMillis': 1784592000000,
      'expirationDate': map['expirationDate'] ?? '2027-07-21T00:00:00.000Z',
      'expirationDateMillis': 1816156800000,
      'store': 'APP_STORE',
      'productIdentifier': 'gymlog_premium_yearly',
      'productPlanIdentifier': null,
      'isSandbox': false,
      'unsubscribeDetectedAt': null,
      'unsubscribeDetectedAtMillis': null,
      'billingIssueDetectedAt': null,
      'billingIssueDetectedAtMillis': null,
      'ownershipType': 'PURCHASED',
      'verification': 'NOT_REQUESTED',
    };
    activeJson[key] = ent;
    allJson[key] = ent;
  });

  return CustomerInfo.fromJson({
    'entitlements': {
      'all': allJson,
      'active': activeJson,
      'verification': 'NOT_REQUESTED',
    },
    'activeSubscriptions': const ['gymlog_premium_yearly'],
    'allPurchasedProductIdentifiers': const ['gymlog_premium_yearly'],
    'firstSeen': '2026-07-21T00:00:00.000Z',
    'firstSeenMillis': 1784592000000,
    'originalAppUserId': 'user123',
    'requestDate': '2026-07-21T00:00:00.000Z',
    'requestDateMillis': 1784592000000,
    'allExpirationDates': const {},
    'allPurchaseDates': const {},
    'originalApplicationVersion': '1.0.0',
    'managementURL': null,
    'originalPurchaseDate': null,
    'originalPurchaseDateMillis': null,
    'nonSubscriptionTransactions': const [],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ATOMIC-08: Strict Premium Entitlement Verification', () {
    test('1. Required entitlement ("premium") active returns true', () {
      final info = _createCustomerInfoWithEntitlements({
        PremiumService.entitlementId: {
          'expirationDate': '2027-07-21T00:00:00Z'
        },
      });

      expect(hasPremium(info), isTrue);
      expect(PremiumService.hasPremium(info), isTrue);
    });

    test('2. Unrelated entitlement ("gold" or "pro_tier") active returns false',
        () {
      final info1 = _createCustomerInfoWithEntitlements({
        'gold': {'expirationDate': '2027-07-21T00:00:00Z'},
      });
      final info2 = _createCustomerInfoWithEntitlements({
        'pro_tier': {'expirationDate': '2027-07-21T00:00:00Z'},
      });

      expect(hasPremium(info1), isFalse);
      expect(hasPremium(info2), isFalse);
    });

    test('3. Empty entitlement map returns false', () {
      final info = _createCustomerInfoWithEntitlements({});
      expect(hasPremium(info), isFalse);
    });

    test(
        '4. Expiration check in isPremiumProvider rejects expired profile cache',
        () async {
      const userId = 'user-expired';
      await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              id: userId,
              email: 'expired@gymlog.app',
              displayName: 'Expired User',
              isPremium: const Value(true),
              premiumExpiry:
                  Value(DateTime.now().subtract(const Duration(days: 1))),
              createdAt: DateTime.now(),
            ),
          );

      final profile = await db.userDao.getUserOrNull(userId);

      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(profile)),
        ],
      );

      await container.read(currentUserProfileProvider.future);

      final isPremium = container.read(isPremiumProvider);
      expect(isPremium, isFalse);
    });

    test(
        '5. Valid unexpired profile cache returns true when RevenueCat unavailable',
        () async {
      const userId = 'user-valid';
      await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              id: userId,
              email: 'valid@gymlog.app',
              displayName: 'Valid User',
              isPremium: const Value(true),
              premiumExpiry:
                  Value(DateTime.now().add(const Duration(days: 30))),
              createdAt: DateTime.now(),
            ),
          );

      final profile = await db.userDao.getUserOrNull(userId);

      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(profile)),
        ],
      );

      await container.read(currentUserProfileProvider.future);
      expect(container.read(isPremiumProvider), isTrue);
    });

    test(
        '6. Account A (premium) to Account B (free) transition does not leak entitlement',
        () async {
      const accountA = 'user-account-A';
      const accountB = 'user-account-B';

      await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              id: accountA,
              email: 'a@gymlog.app',
              displayName: 'Account A',
              isPremium: const Value(true),
              premiumExpiry:
                  Value(DateTime.now().add(const Duration(days: 30))),
              createdAt: DateTime.now(),
            ),
          );
      await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              id: accountB,
              email: 'b@gymlog.app',
              displayName: 'Account B',
              isPremium: const Value(false),
              createdAt: DateTime.now(),
            ),
          );

      // Verify Account A is Pro
      final profileA = await db.userDao.getUserOrNull(accountA);
      expect(profileA!.isPremium, isTrue);

      // Verify Account B is Free
      final profileB = await db.userDao.getUserOrNull(accountB);
      expect(profileB!.isPremium, isFalse);

      final containerB = ProviderContainer(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(profileB)),
        ],
      );

      await containerB.read(currentUserProfileProvider.future);
      expect(containerB.read(isPremiumProvider), isFalse);
    });

    test(
        '7. Stale local cache with null expiry but isPremium=false is rejected',
        () async {
      const userId = 'user-free';
      await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              id: userId,
              email: 'free@gymlog.app',
              displayName: 'Free User',
              isPremium: const Value(false),
              createdAt: DateTime.now(),
            ),
          );

      final profile = await db.userDao.getUserOrNull(userId);

      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(profile)),
        ],
      );

      await container.read(currentUserProfileProvider.future);
      expect(container.read(isPremiumProvider), isFalse);
    });
  });
}
