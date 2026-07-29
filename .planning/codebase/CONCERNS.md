# Codebase Concerns

**Analysis Date:** 2026-07-29

## Technical Debt

### Mixed Provider Patterns (Manual StateNotifier vs @riverpod Code-Gen)

**Issue:** The codebase uses two incompatible Riverpod patterns — code-generated `@riverpod` providers and hand-written `StateNotifier`/`Provider` — with no clear boundary rule for when to use which.

**Evidence:**
- Only 2 `@riverpod` code-gen providers exist: `workout_timer_provider.dart` (line 7) and `exercises_provider.dart` (line 27)
- Only 1 `@freezed` model: `active_workout_state.dart` (line 9)
- The majority of providers are hand-written: `active_workout_provider.dart` (StateNotifier, 594 lines), `routines_provider.dart`, `home_provider.dart`, `profile_provider.dart`, `auth_provider.dart`
- `analysis_options.yaml` disables two code-gen lint rules (`missing_provider_scope: false`, `avoid_manual_providers_as_generated_provider_dependency: false`), indicating the tension is acknowledged but unresolved
- Generated `.g.dart` files exist alongside manual providers in the same directory (`lib/features/exercises/presentation/providers/`) with no naming distinction

**Impact:** A developer adding a new feature must guess which pattern to follow. Generated providers get free `.family`/`.autoDispose` variants and parameter support; manual providers require boilerplate. Pattern drift accelerates as both patterns coexist.

**Fix approach:** Adopt a single pattern (recommended: `@riverpod` for new providers, migrate manual StateNotifier wrappers to `Notifier`/`AsyncNotifier` code-gen incrementally). Document the rule in CONVENTIONS.md.

---

### Large Files / Overly Complex Widgets

**Issue:** Several files exceed reasonable complexity thresholds, making maintenance harder and review cycles longer.

**Files > 500 lines (source only, excluding generated code):**
| Lines | File |
|-------|------|
| 1309 | `lib/core/database/daos/workouts_dao.dart` |
| 829 | `lib/features/profile/presentation/screens/settings_screen.dart` |
| 814 | `lib/features/workout/presentation/screens/active_workout_screen.dart` |
| 794 | `lib/features/profile/presentation/screens/profile_screen.dart` |
| 703 | `lib/shared/widgets/premium_paywall.dart` |
| 698 | `lib/features/exercises/presentation/screens/exercise_detail_screen.dart` |
| 672 | `lib/features/exercises/presentation/screens/exercise_selection_screen.dart` |
| 664 | `lib/features/workout/presentation/providers/active_workout_provider.dart` |
| 659 | `lib/shared/widgets/branded_line_chart.dart` |
| 622 | `lib/features/workout/presentation/widgets/set_row.dart` |
| 594 | `lib/core/database/daos/routines_dao.dart` |
| 567 | `lib/features/home/presentation/screens/home_screen.dart` |
| 550 | `lib/core/services/sync_engine.dart` |
| 520 | `lib/features/auth/presentation/screens/auth_screen.dart` |
| 484 | `lib/core/theme/app_text.dart` |

**Impact:** Large files concentrate risk — a single edit has high merge-conflict probability, and reviewers cannot keep the entire file in working memory. The `workouts_dao.dart` file (1309 lines) is particularly risky as it contains embedded SQL, data transformation, and PR detection logic.

**Fix approach:** Split DAOs into domain-specific partials. Extract widget sub-trees from 700+ line screens into separate widget files (CONVENTIONS.md already mandates this pattern). Extract paywall into a dedicated feature module.

---

### Defensive Catch-All Pattern

**Issue:** The codebase uses ~100+ `catch (_)` / `catch (e)` blocks that silently swallow exceptions. While many are justified (noncritical background work, first-launch degradation), the pattern makes debugging failures in production difficult because errors never surface.

**Files with bare `catch (_)` (sample):**
- `lib/core/services/sync_engine.dart` — lines 271, 375
- `lib/core/services/premium_service.dart` — lines 86, 110, 121, 150, 165, 198, 231
- `lib/core/services/sign_out_coordinator.dart` — lines 71, 87, 92
- `lib/core/services/account_deletion_service.dart` — lines 92, 108, 141, 156, 162, 165
- `lib/core/services/profile_image_sync_service.dart` — lines 56, 90, 96, 125, 136
- `lib/features/workout/presentation/providers/active_workout_provider.dart` — lines 255, 320, 347, 429, 468
- `lib/features/workout/presentation/providers/rest_timer_provider.dart` — lines 58, 180, 253
- `lib/features/auth/data/auth_repository.dart` — line 140
- `lib/features/auth/presentation/providers/auth_provider.dart` — line 10
- `lib/features/auth/presentation/screens/auth_screen.dart` — line 129
- `lib/core/dao/routines_dao.dart` — lines 392, 404

**Impact:** Silent failures in sync, premium, profile, and auth flows mean misconfigurations or transient errors are invisible to both developers (Sentry) and users. Debugging production issues requires reproducing the full environment.

**Fix approach:** Route caught exceptions to Sentry (via `Sentry.captureException`) at minimum for noncritical paths. For critical paths, surface a user-visible error. Only use `catch (_)` when there is genuinely nothing to report (e.g., cleanup in `dispose()`).

---

### Cross-Feature Import Leakage

**Issue:** Core-layer files import from feature modules, violating the strict layered architecture documented in CONVENTIONS.md ("Never import a feature's internals from another feature. Cross-feature dependencies go through core/ providers or the shared databaseProvider.").

**Evidence:**
- `lib/core/services/workout_draft_store.dart` imports `lib/features/workout/domain/active_workout_state.dart`
- `lib/core/providers/premium_provider.dart` imports `lib/features/profile/presentation/providers/profile_provider.dart`
- `lib/features/workout/presentation/providers/active_workout_provider.dart` imports `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/shared/widgets/tour/spotlight_tour_overlay.dart` imports `lib/features/auth/presentation/providers/tour_provider.dart`

**Impact:** The architectural boundary between `core/` and `features/` is permeable. As the app grows, refactoring a feature risks breaking core infrastructure. Testing core services in isolation becomes harder when they depend on feature-layer providers.

**Fix approach:** Extract shared state interfaces (e.g., `AuthUser`, `ActiveWorkoutDraft`) into `core/models/` and pass them as parameters rather than importing feature providers. Use Riverpod's `overrideWithValue` in tests to decouple.

---

### TODOs and Incomplete Code

**Issue:** Only 1 TODO comment was found in the entire `lib/` tree:
- `lib/core/exercises/body_map.dart` (line 11): `// TODO(manifest)`

This is unusually low for a codebase of this size (~38,000 lines of Dart). Combined with the prevalence of `catch (_)` blocks, this suggests that incomplete error paths are simply silenced rather than marked for future work.

**Impact:** Silent failures from caught exceptions are effectively invisible TODOs — the code compiles and runs but degrades functionality without any trace. The low TODO count may give a misleading impression of code maturity.

---

## Security Concerns

### Supabase Anon Key Exposure

**Issue:** The Supabase anon key is public by design (protected by RLS server-side), but the `supabaseAnonKey` constant in `lib/core/config/env.dart` (line 35) is compile-time injected via `String.fromEnvironment`. A decompiled binary still exposes the key.

**Current mitigation:** RLS policies on all Supabase tables. The key is never committed to git (injected via `--dart-define-from-file=.env`, which reads from a gitignored `.env` file).

**Recommendation:** Verify RLS policies are restrictive enough for all tables in `supabase/`. Audit that no service_role key is accidentally exposed.

---

### No SQLite Encryption at Rest

**Issue:** The local Drift database at `gymlog_db.sqlite` is stored unencrypted in the app's documents directory (`lib/core/database/database.dart`, line 143). On a rooted/jailbroken device, the database file is readable directly.

**Files:**
- `lib/core/database/database.dart` — `_openConnection()` creates `NativeDatabase.createInBackground(file)`
- `lib/core/services/workout_draft_store.dart` — uses `FlutterSecureStorage` for draft persistence but the full workout history DB is unencrypted

**Risk:** Low for most users. Workout data is not highly sensitive (no PII beyond a display name and email). However, the `user_profiles` table contains `email` and potentially age/gender/experience level. A determined attacker with physical device access could read all logged data.

**Recommendation:** Consider `sqlcipher` or Drift's encryption support if the risk profile changes. For now, this is an accepted architectural tradeoff documented in ARCHITECTURE.md.

---

### Sentry PII Scrubbing Coverage

**Issue:** `lib/core/bootstrap/bootstrap.dart` (lines 179-189) implements a `beforeSend` hook that strips email and IP address from Sentry events. However, custom `debugPrint` calls throughout the codebase (51 occurrences) may still contain PII in log messages.

**Files at risk:**
- `lib/features/auth/data/auth_repository.dart` line 94: logs the `GOOGLE_SERVER_CLIENT_ID` on failure (not sensitive, but not ideal)
- `lib/core/services/account_deletion_service.dart` line 117-120: logs `cloud=$cloudPurged auth=$authUserDeleted` — may contain user ID patterns
- General pattern: many `debugPrint` calls include user IDs (e.g., `[SyncEngine] Quarantined object $objectId`), which are Supabase UUIDs — technically not PII but could be used for correlation

**Mitigation:** `debugPrint` outputs are stripped from release builds by Dart tree-shaking, so they never reach device logs in production.

**Recommendation:** Audit all `debugPrint` calls for accidental PII inclusion. Add a lint rule prohibiting string interpolation with user data in print statements.

---

### RevenueCat Key Exposure

**Issue:** `REVENUECAT_ANDROID_KEY` and `REVENUECAT_IOS_KEY` are injected at compile time via `String.fromEnvironment` in `lib/core/config/env.dart` (lines 64-66). These are public SDK keys that cannot be rotated independently of the app version.

**Current mitigation:** The RevenueCat dashboard enforces that API keys are bound to specific app bundle IDs. A stolen key is useless outside the GymLog app.

**Recommendation:** Document in REVENUECAT_CONFIG.md that these keys are public-by-design and must be restricted server-side via bundle ID binding, not treated as secrets.

---

## Performance Risks

### Code Generation Build Times

**Issue:** The project uses `build_runner` with 4 generators: `drift_dev` (ORM), `riverpod_generator` (state), `freezed` (data classes), `json_serializable` (serialization). Running `build_runner --delete-conflicting-outputs` is required after any schema, provider, or model change.

**Files:**
- `pubspec.yaml` dev_dependencies: `build_runner: ^2.4.0`, `drift_dev: ^2.18.0`, `riverpod_generator: ^2.4.0`, `freezed: ^2.5.0`, `json_serializable: ^6.8.0`
- Generated files: 9 `.g.dart` files (average 1-2s each), 1 `.freezed.dart` file

**Impact:** A full `build_runner` pass takes 15-30 seconds on modern hardware. During iterative development, this friction can lead developers to batch changes rather than making incremental commits. The `--delete-conflicting-outputs` flag is required, indicating the generators occasionally produce conflicting outputs.

---

### Widget Rebuild Efficiency

**Issue:** Several screens rebuild large widget trees frequently due to coarse-grained Riverpod watchers:
- `app.dart` (line 128-129): watches `dynamicAccentThemeProvider` at the root, causing the entire `MaterialApp.router` to rebuild on every accent palette change
- `routerProvider` (line 51 in `router.dart`): watches the Supabase auth stream and recreates the entire router on auth state changes
- Many screens rebuild on every accent token change because they watch context-wide providers

**Risk:** Low for most interactions. However, screens with scrolling lists (home feed, exercise selection at 672 lines, routine detail at 790 lines) may experience jank when rebuilding with accent changes while a scroll animation is in progress.

**Recommendation:** Profile with Flutter DevTools. Consider splitting `dynamicAccentThemeProvider` into a `MaterialApp.theme`-bound provider that doesn't trigger widget rebuilds. Use `select()` filters on Riverpod watchers where only part of the state matters.

---

### Scrollable Content Loading Pattern

**Issue:** Several large screens use `SingleChildScrollView` wrapping a `Column` with all children built eagerly:

**Evidence:**
- `lib/features/workout/presentation/screens/active_workout_screen.dart` (814 lines) — uses `SingleChildScrollView`
- `lib/features/exercises/presentation/screens/exercise_selection_screen.dart` (672 lines) — uses `SingleChildScrollView`
- `lib/features/home/presentation/screens/home_screen.dart` (567 lines)

**Impact:** On these screens, ALL widgets are built immediately, even those below the fold. For a user with 50+ exercises or routine history spanning months, this means unnecessary widget builds and potentially slower first-frame rendering.

**Fix approach:** Use `ListView.builder` for dynamic content lists. Use `SliverList` with `CustomScrollView` for mixed static/dynamic layouts. Only `home_screen.dart` uses `ListView.builder` for history but wraps it in a `SingleChildScrollView` + `Column`.

---

## Maintainability Concerns

### Test Coverage Gaps

**Issue:** While the test suite has 497 tests across 66 files, several critical paths lack coverage:

| Feature | Files | Tests | Coverage |
|---------|-------|-------|----------|
| Auth (sign-in, sign-out, onboarding) | `auth/` | 2 files, ~130 tests? | Partial — golden + account isolation exist |
| Workout (active workout, state management) | `active_workout_*.dart` | 6 test files | Moderate — set_row, header, atomic tests exist |
| Sync (engine, quarantine, remote) | `sync/`, `sync_engine_test.dart` | 2 files, ~300 lines | Good — quarantine + monotonic covered |
| Routines (catalog, editor, reorder) | `routine_*.dart` | 3 files | Moderate — caps, reorder, scrolling |
| Profile (settings, appearance, stats) | `profile/`, `profile_*.dart` | 3 files | Partial |
| Premium paywall / commerce | `premium/` | 1 file, ~211 lines | Good — entitlement verification |
| Import (CSV, Hevy, Strong) | `import/` | 2 files | Partial |
| `workout_draft_store.dart` | `workout_draft_store_test.dart` | 270 lines | Good |
| Golden tests | `golden/` | 4 test files for 6 widgets | Minimal — only 6 widget sets covered |
| Accessibility | `accessibility_*.dart` | 3 files, ~220 lines | Good — core journey + target size |
| E2E / integration | — | None | **Missing** — no device-level E2E tests |
| Notification service | — | None | **Missing** — notification_service.dart has no tests |
| `AppDatabase` migrations | `database_migration_test.dart` | 125 lines | Partial |

**Files with zero test coverage:**
- `lib/core/services/notification_service.dart` (167 lines)
- `lib/core/services/exercise_media_cache_manager.dart`
- `lib/core/database/daos/exercises_dao.dart` (hydration endpoint)
- `lib/features/routines/presentation/data/explore_catalog.dart` (catalog integrity covered by separate test)
- Several screen-level widgets (muscle_split_section, hero_sliver, etc.)
- Tour/walkthrough system (`tour_navigation_orchestrator.dart`, sequencing tests exist but not orchestration)

**Risk:** Regressions in untested paths (notifications, tour, media cache) can ship undetected.

---

### Golden Test Fragility

**Issue:** Golden tests exist for only 6 widget sets: `active_workout_header`, `auth_screen`, `muscle_map`, `nav_bar`, `segmented_control`. Golden tests are inherently platform-dependent — a minor rendering difference between CI runner (Linux) and dev machines (macOS/Windows) can cause false positives.

**Files:**
- `test/golden/active_workout_header_golden_test.dart`
- `test/golden/auth_screen_golden_test.dart`
- `test/golden/muscle_map_golden_test.dart`
- `test/golden/nav_bar_golden_test.dart`
- `test/golden/segmented_control_golden_test.dart`
- `test/golden/golden_test_helpers.dart`

**Impact:** Low for now (only 4 test files), but as golden coverage grows, false failures will erode trust in the CI gate. The `alchemist` package (v0.12.0) used for golden testing must be carefully version-managed.

**Recommendation:** Run golden tests in a CI Docker container with a pinned Flutter/rasterizer version. Increase golden coverage to cover each accent palette on critical screens, as specified in the Definition of Done.

---

### Documentation Completeness

**Issue:** Documentation exists in `docs/` (19 files) and covers architecture, conventions, CI, sync design, and data model. However:

1. **`docs/CONVENTIONS.md`** (216 lines) is thorough but the last-reviewed SHA (`aef17b093`) may be stale — the codebase has evolved 15+ commits past it
2. **`docs/ARCHITECTURE.md`** (229 lines) describes folder structure but does not document the sync engine's quarantine system, the mixed provider pattern decision, or the bootstrap staging design
3. **No onboarding document** exists for new developers — they must piece together context from AGENTS.md, CONVENTIONS.md, and the code itself
4. **`docs/REVENUECAT_CONFIG.md`** exists — gaps unknown without reading
5. **`docs/CI_RUNBOOK.md`** exists — but takes ~30 min to process for a new developer

**Recommendation:** Add a `docs/ONBOARDING.md` that steps through the full dev setup end-to-end. Update docs/ to cover the mixed-provider decision rationale. Add a diagram for the bootstrap sequence.

---

## Dependency Risks

### Supabase Flutter SDK (^2.5.0)

**Risk:** The Supabase Flutter SDK is still in pre-1.0 semver (current major: 2). Breaking changes between minor versions are common. The SDK controls auth (Google Sign-In), database (PostgREST), storage, and realtime — a forced migration could block app updates.

**Files:**
- `pubspec.yaml`: `supabase_flutter: ^2.5.0`
- `lib/core/bootstrap/bootstrap.dart`: `Supabase.initialize()` call
- `lib/features/auth/data/auth_repository.dart`: sign-in with Google OAuth
- `lib/core/services/sync_remote.dart`: SupabaseSyncRemote against `sync_objects` table
- `lib/core/router/router.dart`: auth state listener

**Impact:** High. If Supabase deprecates the current OAuth flow or changes the PostgREST API, the auth, sync, and profile systems all require changes simultaneously.

**Mitigation:** The `SupabaseClient` is abstracted behind `AuthRepository`, `SyncRemote` (abstract class), and `ProfileRemote`. A migration would replace the implementation only. Also, the app degrades gracefully without Supabase config.

---

### RevenueCat purchases_flutter (^10.3.0)

**Risk:** RevenueCat is the single paywall provider — no fallback. If RevenueCat has an outage, premium entitlement checks fail and paying users could temporarily lose access to premium features. The `_syncToLocalCache` fallback mitigates this (offline Drift cache), but first-time unlocks are blocked.

**Files:**
- `pubspec.yaml`: `purchases_flutter: ^10.3.0`
- `lib/core/services/premium_service.dart` (243 lines): wraps RevenueCat SDK
- `lib/core/providers/premium_provider.dart`: reads CustomerInfo stream

**Impact:** Medium. RevenueCat API changes (v10 is current) could require code changes. The SDK is wrapped behind `PremiumService`, so migration impact is contained.

**Recommendation:** Add a RevenueCat health-check monitor. Verify that the offline cache fallback provides seamless degradation during RevenueCat outages.

---

### Code Generation Tooling Version Drift

**Risk:** Four code-gen tools with interdependent version ranges. A breaking change in `build_runner` (currently 2.4.x) or `drift_dev` (2.18.x) could block development across the whole team.

**Files:**
- `pubspec.yaml`: `build_runner: ^2.4.0`, `drift_dev: ^2.18.0`, `riverpod_generator: ^2.4.0`, `freezed: ^2.5.0`

**Impact:** High. All four tools must be upgraded in lockstep with the Flutter SDK version. A `flutter upgrade` that also bumps `build_runner` or `drift_dev` could produce conflicting generated code.

**Mitigation:** `pubspec.lock` pins transitive versions. Upgrades should be tested in a feature branch with a full `build_runner --delete-conflicting-outputs` pass.

---

### Flutter Version Drift

**Risk:** The SDK constraint is `>=3.0.0 <4.0.0` — permissive but risky as Flutter 3.x has already shipped breaking changes. The CI pins to `stable` channel, but automatic updates could introduce regressions.

**Impact:** Medium. Package incompatibilities surface during `flutter pub get` on CI if the stable channel rolls a new Dart SDK before all dependencies have been updated.

**Recommendation:** Pin the Flutter version explicitly in CI (`FLUTTER_CHANNEL: stable` is the current approach — not a version pin). Consider pinning to a specific Flutter version (e.g., `3.24.x`) and upgrading on a monthly cadence.

---

### 21+ Direct Dependencies

**Risk:** The project depends on 21+ third-party packages for features including charts, GIFs, SVG, payments, auth, storage, notifications, sharing, image picking, compression, cropping, fonts, connectivity, and local notifications. Each is a potential source of breakage on Flutter SDK upgrades.

**Files:**
- `pubspec.yaml` dependencies section (lines 12-70)

**Impact:** High. A single incompatible package can block the entire app from building. The `weekly dependency audit` CI job (non-blocking) runs weekly but requires a human to escalate.

**Recommendation:** Audit the dependency list quarterly. Remove packages used for a single narrow purpose (e.g., `crop_your_image`, `flutter_image_compress`) if they can be replaced with simpler solutions.

---

## CI/CD Risks

### Pipeline Reliability

**Issue:** The CI pipeline (`.github/workflows/ci.yml`) runs three sequential jobs:
1. `analyze-test` (20 min timeout) — format check, static analysis, custom_lint, all tests
2. `build-android` (25 min timeout) — release APK with obfuscation
3. `build-ios` (30 min timeout) — release build no-codesign

**Risk points:**
- The pipeline lacks `--dart-define-from-file=.env` on the test job, so Supabase/RevenueCat have no config — this is fine (graceful degradation) but means the CI never runs tests with real secrets
- iOS build on `macos-latest` runner costs GitHub Actions credits (macOS minutes are 10x Linux)
- 75 total minutes of CI time per merge — feedback loop is slow
- No caching between jobs (each `flutter pub get` re-resolves dependencies)
- The `set -o pipefail` on test output (line 67) is fragile — if the tee process fails before the test suite, CI could report false success

**Mitigation:** Already present:
- `concurrency` group cancels superseded runs (line 14-16)
- `actions/upload-artifact@v4` captures test results even on failure
- `actions/cache` is available via `subosito/flutter-action` with `cache: true`

**Recommendation:** Add a `--dart-define-from-file` flag passing a `.env.ci` with test-only keys for Supabase/RevenueCat so integration tests can run against a sandbox.

---

### No Platform-Specific E2E Tests

**Issue:** No E2E test framework (Maestro, Patrol, Detox) is configured. The `ci.yml` pipeline only runs unit/widget tests and compile checks.

**Impact:** Runtime regressions on real devices (navigation flows, keyboard handling, push notification permissions, OAuth redirects) are only caught during manual QA before release.

**Recommendation:** Add Patrol test framework (Flutter-native E2E) for the 3 core journeys: sign-in → start workout → finish workout. Run on CI with Firebase Test Lab or a self-hosted device farm.

---

### Release Build Complexity

**Issue:** The release process (documented in `docs/RELEASE_CHECKLIST.md`) involves 6 phases with ~30 checklist items spanning Sentry, Android keystore, iOS certificates, RevenueCat, and GitHub secrets. The checklist item for Sentry DSN notes that the current `.env` value "is a settings-page URL, not a DSN" (line 7) — indicating a known misconfiguration.

**Files:**
- `docs/RELEASE_CHECKLIST.md` (73 lines)
- `lib/core/config/env.dart` line 72: `sentryAuthToken` is injected as a compile-time env var, but the RELEASE_CHECKLIST mentions it must be a GitHub secret (different mechanism)

**Impact:** High risk of human error during release. The Sentry DSN misconfiguration means error reporting may be broken in production. The checklist relies on a human accurately executing 30 steps.

**Recommendation:** Automate the release checklist into a GitHub Actions `release.yml` workflow that validates env vars, runs golden tests across all accents, uploads Sentry symbols, and builds both platforms. Add a script to verify Sentry DSN format at build time.

---

## UX Robustness

### Error Handling Completeness

**Issue:** While error handling is comprehensive (100+ try/catch blocks), the quality is inconsistent:
- Some paths surface user-facing error states via `AsyncValue.when(error:)` → `AsyncErrorState` widget
- Many paths silently swallow errors with debug-print-only logging
- Several screens show a generic `Center(child: CircularProgressIndicator())` for loading AND a generic error text — not matching the CONVENTIONS.md `TrackerCard` error pattern

**Examples of weak error surfaces:**
- `lib/features/exercises/presentation/screens/exercise_detail_screen.dart`: error branch at line 124 uses `AsyncValue.when` which the convention mandates
- `lib/features/routines/presentation/screens/routine_detail_screen.dart`: error branch at line 239
- Some screens remain unverified whether they use the recommended `AsyncErrorState` widget with retry affordance

**Recommendation:** Audit every screen's `when(error:)` branch to confirm it uses `AsyncErrorState` (or the full-screen `AppNotFoundScreen` for deleted-entity cases). Add a lint rule requiring all `when()` calls to provide named arguments.

---

### Loading/Empty/Error State Coverage

**Issue:** The CONVENTIONS.md mandates `AsyncValue.when(data:, loading:, error:)` with specific widget patterns. However:
- Several screens use `AsyncValue.valueOrNull` for AppBar titles (permitted by convention, line 133) but may also use it for primary content (forbidden)
- Empty states are not consistently handled — some lists show an empty view, others show nothing
- Loading states are uniformly `CircularProgressIndicator` centered — no skeleton/shimmer loading state

**Files where loading/empty/error pattern could be improved:**
- `lib/features/exercises/presentation/screens/exercise_selection_screen.dart`: uses `.when()` correctly at line 390
- `lib/features/workout/presentation/screens/workout_screen.dart`: uses `.when()` at line 174
- `lib/features/profile/presentation/screens/profile_screen.dart`: uses `.when()` at line 146

**Recommendation:** Add a `SkeletonWidget` (tracker_card.dart) that renders a shimmer placeholder matching the final widget shape. Use it as the `loading:` state for all list/detail screens.

---

### Notification Service Resilience

**Issue:** `lib/core/services/notification_service.dart` (167 lines) has no tests and uses silent `catch(_)` blocks in 4 places (lines 22, 113, 160, plus catch at 89, 151). Permission requests are silent (`requestAlertPermission: false`) — the user is never prompted for notification permissions except through implicit OS dialog.

**Impact:** Rest timer notifications may not fire on first install because notification permissions are never explicitly requested. The user has no in-app prompt explaining why notifications are needed.

**Recommendation:** Add an explicit permission request flow during onboarding or first rest timer use. Add unit tests for the notification scheduling logic.

---

### Accessibility Gaps

**Issue:** Three accessibility test files exist (core journey, target size, atomic), but:
1. Only 3 of 7 planned accessibility test files (the `accessibility_atomic_12_test.dart` naming suggests a larger suite)
2. The `Semantics` widget is used in `database_recovery_screen.dart` and `app_error_screen.dart` but may not be used consistently in all button/card widgets
3. Large-text mode is clamped at `maxScaleFactor: 1.4` in `app.dart` (line 142) — this is a deliberate design choice but limits accessibility for users who need >1.4x scaling
4. No voice-over/switch-control testing beyond the core journey

**Files:**
- `lib/app.dart` line 142: `textScaler: mq.textScaler.clamp(maxScaleFactor: 1.4)`
- `test/accessibility_core_journey_test.dart`
- `test/accessibility_target_size_test.dart`
- `test/accessibility_atomic_12_test.dart`

**Recommendation:** Audit all tappable widgets for `Semantics` labels. Increase text scale clamp to 2.0 with an opt-in setting. Add target-size tests for all buttons (current test covers a subset).

---

### Database Resilience

**Issue:** `lib/core/database/database.dart` performs a `PRAGMA quick_check` at startup (line 206) and shows a recovery screen if it fails. However, there is no:
1. Automatic backup of the database file before migration
2. Periodic integrity check (once per launch)
3. Cloud restore path that works without user intervention
4. Graceful degradation when a specific table is corrupt but others are healthy

**Impact:** If the database is corrupted mid-session (e.g., during a write), the user loses all local data on next launch. The recovery screen offers only a full reset — no partial repair option.

**Recommendation:** Implement a daily integrity check that runs in the background. Add a Drift `beforeOpen` backup step that copies the DB file before migration. Provide a "partial recovery" option that exports readable data before reset.

---

*Concerns audit: 2026-07-29*
