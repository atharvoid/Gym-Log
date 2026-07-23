import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/env.dart';
import '../database/database.dart';

/// Thin, crash-proof wrapper around RevenueCat.
///
/// Design rules (offline-first app):
///   * GymLog must behave identically whether RevenueCat is reachable,
///     unconfigured (no API keys in .env), or unsupported (web/desktop).
///   * The local Drift `user_profiles.isPremium` / `premiumExpiry` columns
///     are the OFFLINE CACHE — every CustomerInfo update is mirrored there,
///     and `isPremiumProvider` falls back to them when RC has no answer.
///   * No RC types leak into widgets except through [customerInfoStream]
///     and the paywall (which needs Offerings/Package for live pricing).
///
/// Expected compile-time config (via --dart-define-from-file=.env,
/// never hardcoded, never committed — see lib/core/config/env.dart):
///   REVENUECAT_ANDROID_KEY / REVENUECAT_IOS_KEY
///
/// Expected dashboard setup (manual):
///   products `gymlog_premium_monthly` + `gymlog_premium_yearly`,
///   both attached to a single entitlement named `premium`.
class PremiumService with WidgetsBindingObserver {
  PremiumService(this._db);

  static const entitlementId = 'premium';

  static bool hasPremium(CustomerInfo info) {
    return info.entitlements.active.containsKey(entitlementId);
  }

  final AppDatabase _db;

  bool _configured = false;
  String? _userId;

  Offerings? _cachedOfferings;
  DateTime? _offeringsFetchedAt;
  static const _offeringsCacheTtl = Duration(minutes: 5);

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Live entitlement updates (purchase, renewal, expiration, restore).
  /// Never emits when RevenueCat is unavailable — consumers must fall back
  /// to the local Drift cache.
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  bool get isConfigured => _configured;

  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String? get _apiKey => defaultTargetPlatform == TargetPlatform.android
      ? Env.revenueCatAndroidKey
      : Env.revenueCatIosKey;

  /// Configures the SDK. Safe to call on any platform — degrades to a no-op
  /// when unsupported or when API keys are absent.
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

  /// Keeps the RC identity in sync with Supabase auth.
  Future<void> setUser(String? userId) async {
    final previous = _userId;
    _userId = userId;

    if (!_configured) {
      // First sign-in on a key-equipped build that started signed-out.
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

  /// Re-fetch entitlements — called on app foreground so a subscription
  /// bought/cancelled outside the app reflects without a restart.
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

  /// Current offerings, or null when RC is unavailable. The paywall renders
  /// a graceful "pricing unavailable" state on null — it must never crash.
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

  /// Checks if the user is eligible for a trial or introductory price for a product.
  Future<bool> isEligibleForTrial(String productId) async {
    if (!_configured) return false;
    try {
      final result =
          await Purchases.checkTrialOrIntroductoryPriceEligibility([productId]);
      final status = result[productId]?.status;
      return status == IntroEligibilityStatus.introEligibilityStatusEligible;
    } catch (e) {
      debugPrint('[PremiumService] eligibility check failed: $e');
      return false;
    }
  }

  /// Returns updated CustomerInfo on success, null on user-cancel.
  /// Rethrows real failures so the paywall can surface them.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      _onCustomerInfo(result.customerInfo);
      return result.customerInfo;
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

  /// Mirrors the entitlement into Drift so offline launches keep Pro.
  Future<void> _syncToLocalCache(CustomerInfo info) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final isPremium = hasPremium(info);
      final entitlement = info.entitlements.active[entitlementId];
      final expiry = entitlement?.expirationDate != null
          ? DateTime.tryParse(entitlement!.expirationDate!)
          : null;

      final profile = await _db.userDao.getUserOrNull(userId);
      if (profile == null) return;
      if (profile.isPremium == isPremium && profile.premiumExpiry == expiry) {
        return; // no-op — avoid useless stream churn
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
