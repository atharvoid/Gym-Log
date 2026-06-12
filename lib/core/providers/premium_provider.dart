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
