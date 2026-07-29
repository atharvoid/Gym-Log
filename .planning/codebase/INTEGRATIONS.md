# External Integrations

**Analysis Date:** 2026-07-29

## APIs & External Services

### Supabase (Backend/Auth/Storage)

**Provider:** supabase_flutter ^2.5.0 (`pubspec.yaml` line 24)

**Authentication — Google Sign-In:**
- **Mobile:** Native Google Sign-In via `google_sign_in` ^6.2.0 (`lib/features/auth/data/auth_repository.dart` lines 77-105)
  - Uses `GoogleSignIn(serverClientId: Env.googleServerClientId)` to mint an idToken
  - Exchanges idToken via `client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken, accessToken: accessToken)`
- **Web:** OAuth redirect flow (`auth_repository.dart` lines 67-71)
  - `client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'http://127.0.0.1:8080/')`
- **Auth state:** Wired to GoRouter via `_GoRouterRefreshStream` (`lib/core/router/router.dart` lines 31-44) — listens to `Supabase.instance.client.auth.onAuthStateChange`
- **Session persistence:** Handled by `supabase_flutter` internally; tokens stored via `flutter_secure_storage` ^9.0.0
- **Keys:** `SUPABASE_URL`, `SUPABASE_ANON_KEY` injected via `--dart-define-from-file=.env`

**Configuration:**
```dart
// lib/core/bootstrap/bootstrap.dart, lines 265-285
await Supabase.initialize(
  url: Env.supabaseUrl,
  publishableKey: Env.supabaseAnonKey,
).timeout(cloudInitTimeout);
```
- Timeout: 4 seconds (`cloudInitTimeout`). On timeout or failure, app proceeds in local-only mode.
- Guarded by `Env.hasSupabaseConfig` — empty keys are no-ops.

**Supabase Client Singleton:**
- Accessed via `Supabase.instance.client` throughout the app
- Reused across auth, sync remote, storage
- Auth state stream subscribed in both `router.dart` (for redirects) and `app.dart` (for sync lifecycle)

**Sync Backend (`lib/core/services/sync_remote.dart`):**
- `SupabaseSyncRemote` implements `SyncRemote` abstract class
- Talks to a `sync_objects` table (`_table = 'sync_objects'`, line 63)
- **Push:** `pushBatch()` — upserts per-row with monotonic revision tracking, conflict detection, duplicate operation detection
- **Pull:** `pull(userId)` — fetches all rows for a user via `SELECT ... .eq('user_id', userId).order('updated_at')`
- RLS guarantees own-rows-only access (assumes Postgres Row-Level Security is configured on the `sync_objects` table)
- Three sync entity types: `'session'`, `'routine'`, `'preferences'`

**Storage (Exercise GIFs):**
- Public bucket at Supabase storage: `supabase.co/storage/v1/object/public/excercises` (note: the "excercises" typo is preserved — `lib/core/config/env.dart` line 49)
- GIF URLs are constructed as `$_kGifBase/$id.gif` in `ExercisesDao.hydrateFromJson()` (`lib/core/database/daos/exercises_dao.dart` line 218)
- Base URL overridable via `--dart-define GIF_BUCKET_BASE`; default is a hardcoded Supabase project URL

**Realtime subscriptions:** Not used. The sync engine uses a poll-based pull model (debounced push + explicit pull on session init).

---

### RevenueCat (Premium/Paywall)

**Provider:** purchases_flutter ^10.3.0 (`pubspec.yaml` line 41)

**Implementation:** `lib/core/services/premium_service.dart`

**Configuration:**
- Keys: `REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY` injected via `.env`
- Initialized in bootstrap post-frame (`PremiumService(db)`) and `initialize(userId: ...)` called asynchronously
- `PurchasesConfiguration(key)` with optional `appUserID` — anonymous when no user is signed in

**Entitlement Setup:**
- **Entitlement ID:** `'premium'` (`PremiumService.entitlementId`, line 32)
- **Products:** `gymlog_premium_monthly`, `gymlog_premium_yearly` (from RevenueCat dashboard)
- **Verification:** `info.entitlements.active.containsKey(PremiumService.entitlementId)` — must NOT use `.isNotEmpty` (documented in `docs/REVENUECAT_CONFIG.md`)

**Identity Management:**
- `setUser(String? userId)` called on auth state change (`bootstrap.dart` lines 291-308)
- `Purchases.logIn(userId)` on sign-in, `Purchases.logOut()` on sign-out
- Offline cache: Drift `user_profiles.isPremium` + `premiumExpiry` columns synced via `_syncToLocalCache()` (lines 209-233)

**Platform Support:**
- Android + iOS only (`PremiumService.platformSupported`, line 56-58)
- Web and desktop degrade to free mode
- Graceful degradation: if keys are absent or RevenueCat is unreachable, all methods are no-ops returning null/false

**Integration Points:**
- `premiumServiceProvider` in `lib/core/providers/premium_provider.dart` — overridden in main.dart
- `isPremiumProvider` — sync or async, falls back to Drift cache
- `customerInfoProvider` — stream of `CustomerInfo` from RevenueCat
- Paywall widget: `lib/shared/widgets/premium_paywall.dart`

---

### Sentry (Error Tracking)

**Provider:** sentry_flutter ^8.14.0 (`pubspec.yaml` line 67)

**Implementation:** `lib/core/bootstrap/bootstrap.dart` lines 83-197

**Configuration:**
- DSN: `SENTRY_DSN` injected via `.env` (`Env.sentryDsn`)
- Environment: `kReleaseMode ? 'production' : 'development'`
- Traces sample rate: 0.1 (release), 1.0 (debug)
- Profiles sample rate: 0.1 (release), 1.0 (debug)
- `options.attachScreenshot = false`
- `options.enableAppHangTracking = true`
- PII scrubbing via `beforeSend` filter — only the Supabase user UUID is attached (`bootstrap.dart` lines 179-189)

**Error Capture:**
- Flutter framework errors forwarded via `FlutterError.onError` (`lib/app.dart` lines 40-43)
- GoRouter navigation tracked via `SentryNavigatorObserver()` (`lib/core/router/router.dart` line 62)
- Auth state updates Sentry scope with user ID (`lib/features/auth/presentation/providers/auth_provider.dart` lines 25-33)
- Uncaught exceptions in bootstrap maintenance tasks (`Sentry.captureException` in `_initDatabase` line 221)

**Source Maps & Symbols:**
- `sentry_dart_plugin` ^3.4.0 in `pubspec.yaml` (line 84) + Sentry config section (lines 103-109):
  - `upload_debug_symbols: true`
  - `upload_source_maps: true`
  - `upload_sources: true`
  - `project: gymlog`
  - `org: env.SENTRY_ORG`
  - `auth_token: env.SENTRY_AUTH_TOKEN`
- `SENTRY_AUTH_TOKEN`, `SENTRY_ORG` injected as GitHub secrets in CI (see `docs/ops/sentry_ci_setup.md`)

---

## Data Storage

**Local — Primary Database:**
- **Engine:** SQLite via Drift ORM
- **Client:** `drift` ^2.18.0, `sqlite3_flutter_libs` ^0.5.42
- **File:** `gymlog_db.sqlite` in `getApplicationDocumentsDirectory()` (`lib/core/database/database.dart` line 143)
- **Testing:** In-memory SQLite via `sqlite3` ^2.4.0 host-VM backend

**Local — Preferences:**
- **Tool:** `shared_preferences` ^2.2.0
- **Uses:** Accent palette choice, sync toggle, exercise hydration flags, cached last-synced timestamp, weekly goal, unit overrides

**Remote — Supabase:**
- **Auth:** User sessions, Google OAuth tokens
- **Sync:** `sync_objects` table for cross-device data mirroring
- **Storage:** Exercise GIFs in public bucket

**Caching:**
- **Image cache:** `cached_network_image` ^3.3.0 for exercise thumbnails and GIFs
- **Media cache manager:** `flutter_cache_manager` ^3.4.1 with custom `ExerciseMediaCacheManager` (`lib/core/services/exercise_media_cache_manager.dart`)
- **Image cache bounds:** Flutter `PaintingBinding` image cache capped at 256 entries / 80 MiB (`lib/core/bootstrap/bootstrap.dart` lines 157-161)
- **RevenueCat offerings cache:** 5-minute TTL (`PremiumService._offeringsCacheTtl`, line 45)
- **Exercise catalog:** Hydrated from `assets/db/exercises.json` (822 entries) into Drift, guarded by SharedPreferences flag

---

## Authentication & Identity

**Auth Provider:**
- **Service:** Supabase Auth (Google Sign-In only)
- **Flow (multi-platform):**
  - Android/iOS: `google_sign_in` plugin → native account picker → idToken exchange → Supabase session
  - Web: OAuth redirect flow
- **Client IDs:** `GOOGLE_SERVER_CLIENT_ID` — overridable via `--dart-define`, default baked into `Env` (`lib/core/config/env.dart` lines 39-43)
- **Secure storage:** `flutter_secure_storage` ^9.0.0 for session persistence
- **Sign-out:** Clears workout draft store, then `Supabase.instance.client.auth.signOut()` (`lib/features/auth/data/auth_repository.dart` lines 134-141)

**Auth Implementation Files:**
- Repository: `lib/features/auth/data/auth_repository.dart`
- Providers: `lib/features/auth/presentation/providers/auth_provider.dart`
- Screens: `lib/features/auth/presentation/screens/splash_screen.dart`, `auth_screen.dart`, `onboarding_screen.dart`

---

## Monitoring & Observability

**Error Tracking:**
- **Service:** Sentry (sentry_flutter)
- **CI:** Symbol upload via sentry_dart_plugin, auth token set as GitHub secret
- **Navigation tracking:** SentryNavigatorObserver on GoRouter

**Logging:**
- **Approach:** `debugPrint()` throughout — no structured logging framework
- **Notable debug log prefixes:** `[Bootstrap]`, `[SyncEngine]`, `[PremiumService]`, `[GoogleSignIn]`, `[ExercisesDao]`, `[NotificationService]`, `[ActiveWorkoutNotifier]`, `[finishWorkout]`
- **Sentry events:** Only for crashes, errors, and database integrity failures — not for routine debug logs

**Performance Monitoring:**
- Sentry traces with 10% sample rate in production
- App hang tracking enabled for iOS ANR-like detection

---

## CI/CD & Deployment

**Hosting:**
- **App Stores:** Google Play Store (Android), Apple App Store (iOS)
- **Static page:** GitHub Pages for account deletion page (`docs/legal/delete-account.html`)
- **No backend hosting** — Supabase manages all cloud infrastructure

**CI Pipeline (`.github/workflows/ci.yml`):**
- **Trigger:** Push/PR to `main` or `remediation/**` branches
- **Concurrency:** Cancel in-progress runs on same branch
- **Jobs:**
  1. **Analyze & Test** (`ubuntu-latest`, 20-min timeout):
     - `actions/checkout@v4`
     - `subosito/flutter-action@v2` with `channel: stable`, `cache: true`
     - Install `libsqlite3-dev` for DAO tests
     - `flutter pub get`
     - `dart format --output=none --set-exit-if-changed .`
     - `flutter analyze --fatal-infos --fatal-warnings`
     - `dart run custom_lint`
     - `flutter test --machine` → uploads `test-results.json` artifact
  2. **Build Android (release)** (`ubuntu-latest`, 25-min timeout, needs analyze-test):
     - `actions/setup-java@v4` with Temurin JDK 17
     - `flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols`
     - Uploads obfuscation symbols artifact
  3. **Build iOS (release, no codesign)** (`macos-latest`, 30-min timeout, needs analyze-test):
     - `flutter build ios --release --no-codesign`
  4. **CI Gate** (aggregate pass/fail check)

**Dependency Audit (`.github/workflows/dependency-audit.yml`):**
- **Trigger:** Weekly cron (Monday 09:00 UTC) + manual dispatch
- **Jobs:**
  1. **Outdated packages** — `flutter pub outdated` report
  2. **Security advisories** — `google/osv-scanner-action@v1` on `pubspec.lock` (continue-on-error: true)

**Sentry CI Setup (`docs/ops/sentry_ci_setup.md`):**
- `SENTRY_AUTH_TOKEN` stored as GitHub Actions secret
- Injected as env variable to the release build step
- Verifies via Sentry dashboard debug files upload

---

## Environment Configuration

**Required env vars (all injected at compile time):**

| Var | Purpose | Optional? |
|-----|---------|-----------|
| `SUPABASE_URL` | Supabase project URL | Yes (auth disabled) |
| `SUPABASE_ANON_KEY` | Supabase anon/publishable key | Yes (auth disabled) |
| `GOOGLE_SERVER_CLIENT_ID` | Google OAuth server client ID | No (baked default exists) |
| `GIF_BUCKET_BASE` | Supabase storage bucket for exercise GIFs | No (baked default exists) |
| `REVENUECAT_ANDROID_KEY` | RevenueCat Android SDK key | Yes (free mode) |
| `REVENUECAT_IOS_KEY` | RevenueCat iOS SDK key | Yes (free mode) |
| `SENTRY_DSN` | Sentry project DSN | Yes (no crash reporting) |
| `SENTRY_AUTH_TOKEN` | Sentry auth token for symbol upload | Yes (no CI symbols) |
| `SENTRY_ORG` | Sentry org slug | Yes |
| `SENTRY_PROJECT` | Sentry project slug | Yes |
| `ACCOUNT_DELETION_URL` | Web account deletion page URL | No (baked default exists) |

**Secrets location:**
- Local development: `.env` file in repo root (gitignored)
- CI: GitHub Actions secrets (`SENTRY_AUTH_TOKEN`) + `.env` equivalent via repo secret or manual injection
- **Never** bundled as Flutter assets — read at compile time via `--dart-define-from-file=.env`

---

## Webhooks & Callbacks

**Incoming:**
- None implemented. The app is client-only with Supabase as backend; no webhook endpoints exist.

**Outgoing:**
- **RevenueCat webhooks:** Configured in RevenueCat dashboard but no server-side processing exists in this repo. RevenueCat handles subscription lifecycle server-side and surfaces changes via the SDK's `CustomerInfo` stream.

---

## File Import/Export

**CSV Import:**
- Hevy and Strong app CSV format via `file_picker` ^8.1.2
- Implementation: `lib/features/import/` directory
- Exercise name matching against bundled catalog; creates custom exercises for unmatched names

**CSV Export:**
- Workout history export via `share_plus` ^12.0.2
- Implementation: `lib/core/services/workout_export_service.dart`

**Profile Picture:**
- Upload via `image_picker` ^1.1.2, compress via `flutter_image_compress` ^2.3.0, crop via `crop_your_image` ^2.0.0
- Sync via `profile_image_sync_service.dart`

---

## Integration Architecture Summary

```text
┌─────────────────────────────────────────────────────────┐
│                    GymLog App                            │
├─────────────────────────────────────────────────────────┤
│  UI Layer (Flutter Widgets, GoRouter)                   │
│  State Layer (Riverpod — StateNotifier + @riverpod)     │
│  Service Layer (Sync, Premium, Auth, Notification)       │
│  Data Layer (Drift DAOs — SQLite)                        │
├────────────┬────────────┬────────────┬───────────────────┤
│  Supabase  │ RevenueCat │   Sentry   │  File System      │
│  Auth      │  Paywall   │  Errors    │  Preferences      │
│  Sync      │  Entitle   │  Perf      │  DB file          │
│  Storage   │  ments     │  Tracking  │  Media cache      │
└────────────┴────────────┴────────────┴───────────────────┘
```

---

*Integration audit: 2026-07-29*
