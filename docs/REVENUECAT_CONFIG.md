# RevenueCat Configuration & Entitlement Policy

## 1. Environment & API Keys

Compile-time injection via `.env` (`--dart-define-from-file=.env`):
- `REVENUECAT_ANDROID_KEY`: Android public API key from RevenueCat dashboard.
- `REVENUECAT_IOS_KEY`: iOS public API key from RevenueCat dashboard.

Builds compiled without RevenueCat API keys run cleanly in free mode without crashing.

## 2. Canonical Entitlement Setup

- **Entitlement Identifier**: `PremiumService.entitlementId` (`'premium'`).
- **Products**: `gymlog_premium_monthly` & `gymlog_premium_yearly`.
- Both products MUST be attached to the single entitlement `premium` in the RevenueCat dashboard.
- **Rule**: Never duplicate string literals for the entitlement ID elsewhere in the codebase. Always reference `PremiumService.entitlementId`.

## 3. Strict Purchase Verification Algorithm

Purchases and restores MUST strictly verify active inclusion of `PremiumService.entitlementId`:

```dart
bool hasPremium(CustomerInfo info) {
  return info.entitlements.active.containsKey(
    PremiumService.entitlementId,
  );
}
```

*Forbidden*: `info.entitlements.active.isNotEmpty` (must NOT unlock if an unrelated entitlement is returned).

If a purchase returns a valid `CustomerInfo` object that does NOT contain `PremiumService.entitlementId` (e.g. pending App Store verification or mismatch):
- Display: `"Purchase completed, but Premium is still being verified. Try Restore Purchases."`
- Log a privacy-safe diagnostic message (`[PremiumPaywall] Purchase completed for package "...", but entitlement "premium" is not active. Active entitlements: ...`).
- Do NOT unlock Pro features.

## 4. Identity & Account Transition Rules

- **Anonymous Startup**: App startup without an authenticated user initializes RevenueCat with an anonymous identity (`$RCAnonymousID:...`).
- **Sign In**: Supabase auth sign-in triggers `setUser(userId)` which calls `Purchases.logIn(userId)`.
- **Sign Out**: Sign-out triggers `setUser(null)` which calls `Purchases.logOut()`.
- **Account Switching**: Switching from Account A (pro) to Account B (free) instantly updates `CustomerInfo` via `logIn(accountB)` and syncs `isPremium = false` into Account B's local Drift profile. Account B never retains Account A's entitlement.

## 5. Offline & Local Cache Policy

- Local Drift table `user_profiles` stores `isPremium` (bool) and `premiumExpiry` (DateTime?).
- When RevenueCat SDK stream is unavailable, `isPremiumProvider` falls back to the local Drift profile.
- **Stale Cache Expiration**: Stale cached Pro status automatically expires when `premiumExpiry` is non-null and `premiumExpiry.isBefore(DateTime.now())`.
