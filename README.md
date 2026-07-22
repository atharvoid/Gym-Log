# GymLog

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

GymLog is an OLED-first, high-density workout logger built with Flutter, Drift (SQLite), Riverpod, and Supabase.

---

## Technical Stack

| Area | Technology |
|---|---|
| Framework | Flutter / Dart |
| Architecture | Feature-first clean state management |
| State Management | Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| Local Database | Drift (SQLite) — 8 tables, 4 DAOs |
| Backend & Auth | Supabase (Google Sign-In via Native + Web OAuth, PostgreSQL sync) |
| In-App Purchases | RevenueCat (`purchases_flutter`) |
| Crash Telemetry | Sentry (`sentry_flutter`) |
| Navigation | GoRouter |
| Code Generation | `build_runner` (Drift, Riverpod, Freezed, JSON serializable) |

---

## Environment Setup & Secrets

Secrets and compile-time configurations are injected via `--dart-define-from-file=.env`. The root `.env` file is **gitignored** and never bundled as a static Flutter asset.

### `.env` Structure

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
REVENUECAT_ANDROID_KEY=goog_your_revenuecat_key
REVENUECAT_IOS_KEY=appl_your_revenuecat_key
SENTRY_DSN=https://your_key@o0.ingest.sentry.io/0
```

---

## Commands

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Code Generation
Run `build_runner` after modifying Drift tables, Riverpod providers, or Freezed models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run Locally
```bash
flutter run --dart-define-from-file=.env
```

### 4. Testing & Verification
Execute unit and widget tests, or run the local CI gate script:
```bash
# Run unit & widget tests
flutter test

# Run full CI gate locally (format, analyze, custom_lint, test)
powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

### 5. Release Build
```bash
$env:SENTRY_AUTH_TOKEN="your_sentry_token"
$env:SENTRY_ORG="your_sentry_org"

flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define-from-file=.env
flutter pub run sentry_dart_plugin
```

---

## Degraded Modes & Resiliency

GymLog operates in a **local-first** paradigm:
- **Offline / Unauthenticated**: Full local workout logging, set tracking, personal records, and exercise search remain 100% functional.
- **Missing Secrets / Keys**: Without `.env` keys, cloud sync and in-app purchase verification degrade gracefully; local operations continue uninterrupted.
- **Sync Failure Isolation**: Deterministic payload or decode errors quarantine bad objects locally without blocking outbox queue processing.

---

## Service Configuration & Support Identity

| Service | Monitored Route / Authority | Policy |
|---|---|---|
| Support Route | `support@gymlog.app` | Canonical support identity for user inquiries and manual account deletion |
| Privacy Policy | `https://atharvoid.github.io/Gym-Log/legal/privacy-policy.html` | Zero ads, local-first data retention |
| Terms of Service | `https://atharvoid.github.io/Gym-Log/legal/terms-of-service.html` | Short, readable terms & subscription terms |
| Account Deletion | `https://atharvoid.github.io/Gym-Log/legal/delete-account.html` | Self-service web deletion portal & in-app Settings deletion |

---

## Data Truth Table

| Data Type | Storage Location | Sync Behavior | Deletion Outcome |
|---|---|---|---|
| Workouts, Sets, Reps, Weights | Local SQLite (Drift) | Compressed RLS mirror in Supabase when signed in | Hard deleted from local DB & Supabase upon account deletion |
| Routines & Templates | Local SQLite (Drift) | Compressed RLS mirror in Supabase when signed in | Hard deleted from local DB & Supabase upon account deletion |
| Preferences & Settings | Local SQLite + SharedPreferences | Synced across user devices when signed in | Erased on sign-out / account deletion |
| User Profile | Supabase Auth + Local SQLite | Synced to user account | Account & profile records permanently deleted |
| Subscription Status | RevenueCat + Local Cache | Validated against `premium` entitlement ID | Subscription canceled via store account |
| Crash Telemetry | Sentry | PII scrubbed; account UUID attached | Subject to Sentry 90-day retention |

---

## Troubleshooting

- **Google Sign-In `ApiException 10`**: Ensure the Android SHA-1 release and debug fingerprints are registered in Google Cloud Console & Supabase Auth settings.
- **Missing `.env` File**: Create `.env` in project root before building. Local features build and function without external keys.
- **Build Runner Conflicts**: Run `flutter pub run build_runner build --delete-conflicting-outputs` to resolve stale generated code.
