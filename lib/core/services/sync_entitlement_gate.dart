import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/premium_provider.dart';

/// Single source of truth for whether cloud sync is allowed.
///
/// The gate reads two inputs:
///   1. [isPremiumProvider] — the live RevenueCat / local-cache entitlement.
///   2. A SharedPreferences boolean (`sync_enabled`) — the user's privacy
///      toggle. Default is `true` so a first-time Pro user syncs immediately.
///
/// Free users: `isSyncAllowed` is **always** `false` — the engine stays
/// dormant and physically cannot enqueue outbox rows.
///
/// Pro users: `isSyncAllowed` is `true` unless the user has explicitly turned
/// the toggle off in Settings.
///
/// This is the **only** chokepoint. No widget, provider, or DAO may decide
/// to sync on its own — all sync decisions flow through this gate.

typedef SyncEnabledState = ({
  bool isSyncAllowed,
  bool isPremium,
  bool syncEnabled
});

const _kSyncEnabledKey = 'sync_enabled';

class SyncEntitlementGate {
  SyncEntitlementGate(this._readPrefs);

  final Future<SharedPreferences> Function() _readPrefs;

  /// Returns the live gate state derived from the entitlement and the
  /// persisted user toggle.
  ///
  /// [isPremium] is injected from [isPremiumProvider]; [syncEnabled] is
  /// read from SharedPreferences (defaulting to `true` when unset).
  Future<SyncEnabledState> resolve({required bool isPremium}) async {
    final prefs = await _readPrefs();
    final stored = prefs.getBool(_kSyncEnabledKey);
    // Default is ON — a first-time Pro user syncs without fiddling settings.
    final syncEnabled = stored ?? true;
    final isSyncAllowed = isPremium && syncEnabled;
    return (
      isSyncAllowed: isSyncAllowed,
      isPremium: isPremium,
      syncEnabled: syncEnabled
    );
  }

  /// Writes the user toggle. Only meaningful for Pro users.
  Future<void> setSyncEnabled(bool value) async {
    final prefs = await _readPrefs();
    await prefs.setBool(_kSyncEnabledKey, value);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final syncEntitlementGateProvider = Provider<SyncEntitlementGate>((ref) {
  return SyncEntitlementGate(SharedPreferences.getInstance);
});

/// Convenience: a synchronous snapshot of the gate state.
///
/// Because `isPremiumProvider` is synchronous and the prefs read is async,
/// this provider exposes only the premium-derived portion synchronously:
/// a free user is never allowed, even before prefs load. The full async
/// resolution (including the user toggle) happens inside `SyncEngine`
/// and the Settings UI via [SyncEntitlementGate.resolve].
///
/// Widgets that need a quick "should I show sync UI?" check can read this.
final isSyncAllowedProvider = FutureProvider<bool>((ref) async {
  final isPremium = ref.watch(isPremiumProvider);
  if (!isPremium) return false;
  final gate = ref.read(syncEntitlementGateProvider);
  final state = await gate.resolve(isPremium: isPremium);
  return state.isSyncAllowed;
});

/// The SharedPreferences key, exposed for the Settings UI and tests.
const kSyncEnabledKey = _kSyncEnabledKey;
