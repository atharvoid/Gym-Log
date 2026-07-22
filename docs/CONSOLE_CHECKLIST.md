# GymLog Console Release Readiness Checklist

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

---

## Pre-Release Verification Steps

- [ ] **Local Verification Script**: Run `powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1` locally. Must pass format, analyze, custom_lint, and all tests.
- [ ] **Version Synchronization**: Verify version in `pubspec.yaml` (`1.0.0+1`) matches `lib/core/providers/app_info_provider.dart` and release notes.
- [ ] **Google Auth Fingerprints**: Ensure release App Bundle SHA-1 fingerprint is registered in Google Cloud Console OAuth 2.0 client credentials and Supabase Auth configuration.
- [ ] **RevenueCat Entitlement Match**: Confirm RevenueCat dashboard defines canonical entitlement ID `premium` matching `PremiumService.entitlementId`.
- [ ] **Sentry Symbol Upload**: Confirm `SENTRY_AUTH_TOKEN` and `SENTRY_ORG` environment variables are present prior to running `flutter build appbundle --release`.

---

## Google Play Console Checklist

- [ ] App Bundle (`.aab`) uploaded to Release track with obfuscation symbol map (`build/app/outputs/symbols`).
- [ ] Store Listing metadata configured with `support@gymlog.app` and privacy links.
- [ ] Data Safety Questionnaire completed matching [PRIVACY_POLICY.md](legal/PRIVACY_POLICY.md):
  - User Account / Identifiers (Google Sign-In)
  - Health / Fitness data (Local/Synced workout logs)
  - App Functionality & Analytics (Sentry crash reports, no ads)
- [ ] Account Deletion URL configured: `https://atharvoid.github.io/Gym-Log/legal/delete-account.html`.

---

## Apple App Store Connect Checklist

- [ ] iOS release build completed (`flutter build ios --release`).
- [ ] App Privacy details submitted matching [PRIVACY_POLICY.md](legal/PRIVACY_POLICY.md).
- [ ] In-App Purchases & Subscriptions configured for `premium` entitlement package.
- [ ] Account Deletion link and Support email set to `support@gymlog.app`.
