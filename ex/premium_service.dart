// Location: lib/core/services/premium_service.dart
//
// CHANGES FROM ORIGINAL:
//   C3  added isEligibleForTrial() — checks real per-user trial
//       eligibility instead of relying on product metadata alone
//   M7  offerings() now caches for 5 minutes and serves stale data on
//       a failed refresh instead of falling back to "pricing unavailable"

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/env.dart';
import '../database/database.dart';

class PremiumService with WidgetsBindingObserver {
  PremiumService(this._db);

  static const entitlementId = 'premium';

  final AppDatabase _db;

  bool _configured = false;
  String? _userId;

  // FIX (M7): cache so the paywall sheet doesn't hit the network every
  // single time it's opened. Serves stale data on a failed refresh
  // rather than forcing the "pricing unavailable" fallback UI.
  Offerings? _cachedOfferings;
  DateTime? _offeringsFetchedAt;
  static const _offeringsCacheTtl = Duration(minutes: 5);

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  bool get isConfigured => _configured;

  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String? get _apiKey => defaultTargetPlatform == TargetPlatform.android
      ? Env.revenueCatAndroidKey
      : Env.revenueCatIosKey;

  Future<void> initialize({String? userId}) async {
    _userId = userId;
    if (!platformSupported) return;

    final key = _apiKey;
    if (key == null || key.isEmpty) {
      debugPrint('[PremiumService] No RevenueCat key — running in free mode.');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.warn : LogLevel.error);
      await Purchases.configure(
        PurchasesConfiguration(key)..appUserID = userId,
      );
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      WidgetsBinding.instance.addObserver(this);
      unawaited(refresh());
    } catch (e) {
      debugPrint('[PremiumService] configure failed: $e');
      _configured = false;
    }
  }

  Future<void> setUser(String? userId) async {
    final previous = _userId;
    _userId = userId;

    if (!_configured) {
      if (userId != null && previous == null) await initialize(userId: userId);
      return;
    }

    try {
      if (userId == null) {
        await Purchases.logOut();
      } else if (userId != previous) {
        final result = await Purchases.logIn(userId);
        _onCustomerInfo(result.customerInfo);
      }
    } catch (e) {
      debugPrint('[PremiumService] setUser failed: $e');
    }
  }

  Future<void> refresh() async {
    if (!_configured) return;
    try {
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('[PremiumService] refresh failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// FIX (M7): cached with a short TTL. Pass forceRefresh: true if you
  /// need a guaranteed-fresh fetch (e.g. after a known offering change).
  Future<Offerings?> offerings({bool forceRefresh = false}) async {
    if (!_configured) return null;

    final cached = _cachedOfferings;
    final fetchedAt = _offeringsFetchedAt;
    if (!forceRefresh &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _offeringsCacheTtl) {
      return cached;
    }

    try {
      final result = await Purchases.getOfferings();
      _cachedOfferings = result;
      _offeringsFetchedAt = DateTime.now();
      return result;
    } catch (e) {
      debugPrint('[PremiumService] offerings failed: $e');
      // Serve stale cache rather than nothing, if we have it.
      return cached;
    }
  }

  /// FIX (C3): "Start Free Trial" must never be shown to a user who
  /// isn't actually eligible — that's how you end up charging someone
  /// who thought they were getting a trial. Defaults to false (no
  /// trial promised) on any error or ambiguity, never the reverse.
  ///
  /// NOTE: verify `checkTrialOrIntroductoryPriceEligibility` and
  /// `IntroEligibilityStatus` against your installed purchases_flutter
  /// version — the RevenueCat Flutter SDK's exact API surface has
  /// shifted across major versions.
  Future<bool> isEligibleForTrial(String productId) async {
    if (!_configured) return false;
    try {
      final result =
          await Purchases.checkTrialOrIntroductoryPriceEligibility([productId]);
      final status = result[productId]?.status;
      return status == IntroEligibilityStatus.eligible;
    } catch (e) {
      debugPrint('[PremiumService] eligibility check failed: $e');
      return false;
    }
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      _onCustomerInfo(info);
      return info;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      rethrow;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    final info = await Purchases.restorePurchases();
    _onCustomerInfo(info);
    return info;
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    if (!_customerInfoController.isClosed) _customerInfoController.add(info);
    unawaited(_syncToLocalCache(info));
  }

  Future<void> _syncToLocalCache(CustomerInfo info) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final entitlement = info.entitlements.active[entitlementId];
      final isPremium = entitlement != null;
      final expiry = entitlement?.expirationDate != null
          ? DateTime.tryParse(entitlement!.expirationDate!)
          : null;

      final profile = await _db.userDao.getUserOrNull(userId);
      if (profile == null) return;
      if (profile.isPremium == isPremium && profile.premiumExpiry == expiry) {
        return;
      }

      await _db.userDao.setPremiumStatus(
        userId,
        isPremium: isPremium,
        premiumExpiry: expiry,
      );
    } catch (e) {
      debugPrint('[PremiumService] local sync failed: $e');
    }
  }

  void dispose() {
    if (_configured) {
      Purchases.removeCustomerInfoUpdateListener(_onCustomerInfo);
      WidgetsBinding.instance.removeObserver(this);
    }
    _customerInfoController.close();
  }
}
