import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show CustomerInfo;
import 'package:gymlog/core/services/premium_service.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';

/// Overridden in main.dart with the app-lifetime [PremiumService] instance
/// (it needs the shared database + Supabase auth stream).
final premiumServiceProvider = Provider<PremiumService>((ref) {
  throw UnimplementedError(
    'premiumServiceProvider must be overridden in ProviderScope (see main.dart)',
  );
});

/// Live RevenueCat customer info. Stays in `loading` forever when RC is
/// unconfigured/unsupported — [isPremiumProvider] then falls back to the
/// local Drift cache, preserving offline-first behavior.
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  return ref.watch(premiumServiceProvider).customerInfoStream;
});

/// Single source of truth for premium entitlement.
///
/// Priority:
///   1. RevenueCat `entitlements.active['premium']` (authoritative when live)
///   2. Local `user_profiles.isPremium` + `premiumExpiry` (offline cache,
///      kept in sync by [PremiumService])
///
/// Workout logging is NEVER gated — only deep analytics history.
final isPremiumProvider = Provider<bool>((ref) {
  final info = ref.watch(customerInfoProvider).valueOrNull;
  if (info != null) {
    return info.entitlements.active.containsKey(PremiumService.entitlementId);
  }

  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null || !profile.isPremium) return false;
  final expiry = profile.premiumExpiry;
  return expiry == null || expiry.isAfter(DateTime.now());
});

/// Clips a chart series for free users: the 3 most recent samples stay
/// visible as a teaser, full history unlocks with Pro.
List<T> gateChartSamples<T>(List<T> samples, bool isPremium) {
  if (isPremium || samples.length <= 3) return samples;
  return samples.sublist(samples.length - 3);
}

/// Computes the trend chart lock state banner copy depending on premium status
/// and data volume. Prevents promising free users that "more logging" will
/// unlock the full trend chart when they are capped by the free plan.
String? chartLimitBannerCopy({
  required bool isPremium,
  required int totalLoggedSamples,
  required int visibleSamples,
  int minSamplesForTrend = 4,
}) {
  if (isPremium) {
    if (totalLoggedSamples >= minSamplesForTrend) return null;
    final remaining = minSamplesForTrend - totalLoggedSamples;
    return remaining == 1
        ? 'Log 1 more week to unlock your trend chart'
        : 'Log $remaining more weeks to unlock your trend chart';
  } else {
    // Free user
    if (totalLoggedSamples >= 3) {
      return 'Free plan shows your last 3 weeks. Upgrade to see your full history.';
    }
    final remaining = minSamplesForTrend - totalLoggedSamples;
    return remaining == 1
        ? 'Log 1 more week to unlock your trend chart'
        : 'Log $remaining more weeks to unlock your trend chart';
  }
}


/// Free-tier routine ceiling. Matches Hevy's free cap (4) and beats Strong (3):
/// high enough for Push/Pull/Legs + a Full-Body day, low enough that
/// program-hoppers convert. Pro is unlimited.
///
/// Grandfathering falls out of the simple `count >= kFreeRoutineLimit` gate:
/// a user who already has more (legacy, or downgraded from Pro) keeps them all
/// — they simply cannot create a new one until they drop back under the cap.
const int kFreeRoutineLimit = 4;

/// True when a free user is at/over the routine cap and must upgrade to add
/// another. Pro users are never blocked.
bool isAtFreeRoutineLimit({required bool isPremium, required int routineCount}) =>
    !isPremium && routineCount >= kFreeRoutineLimit;
