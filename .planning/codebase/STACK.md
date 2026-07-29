# Technology Stack

**Analysis Date:** 2026-07-29

## Languages

**Primary:**
- **Dart** >=3.0.0 <4.0.0 — All application code, domain models, providers, DAOs, tests, and build scripts. The SDK constraint is specified in `pubspec.yaml` line 6.
- **SQL** — Embedded in Drift DAOs and `SyncRemote` for direct queries against the SQLite database and the Supabase `sync_objects` table.

**Platform build tooling:**
- **Kotlin** (Android) — `android/app/build.gradle.kts` with R8 ProGuard rules.
- **Swift** (iOS) — iOS native Podfile and Xcode project config.
- **Shell/PowerShell** — `scripts/verify.ps1`, `scripts/verify.sh`, CI workflow YAML.

## Runtime

**Framework:**
- **Flutter** (stable channel, pinned in `.github/workflows/ci.yml` line 24 via `FLUTTER_CHANNEL: stable`) — cross-platform UI framework targeting Android, iOS, Web, macOS, Linux, Windows.

**Package Manager:**
- **pub** (Dart's built-in package manager)
- Lockfile: `pubspec.lock` present and committed.

## Frameworks

**Core:**
| Framework | Version | Purpose |
|-----------|---------|---------|
| Flutter | stable (3.x) | UI framework, Material Design 3 |
| `flutter_riverpod` | ^2.5.0 | State management — the app's reactivity backbone |
| `riverpod_annotation` | ^2.3.0 | Code-generated Riverpod providers (`@riverpod` annotation) |

**State Management (`lib/core/providers/`, `lib/features/*/presentation/providers/`):**
- **Mixed patterns**: Both manual `StateNotifier` (e.g. `ActiveWorkoutNotifier` in `lib/features/workout/presentation/providers/active_workout_provider.dart`, `DynamicAccentNotifier` in `lib/core/theme/dynamic_accent_theme.dart`) and `@riverpod` code-generated providers (e.g. `sync_status_provider.g.dart` in `lib/core/services/`).
- Key providers:
  - `databaseProvider` — single shared `AppDatabase` instance (`lib/core/providers/database_provider.dart`)
  - `premiumServiceProvider` / `isPremiumProvider` — RevenueCat entitlement (`lib/core/providers/premium_provider.dart`)
  - `authProvider` / `authStateProvider` — Supabase auth (`lib/features/auth/presentation/providers/auth_provider.dart`)
  - `syncEngineProvider` / `syncRemoteProvider` — cloud sync (`lib/core/services/sync_engine.dart`)
  - `routerProvider` — GoRouter config (`lib/core/router/router.dart`)
  - `dynamicAccentThemeProvider` / `accentTokensProvider` — theme palette (`lib/core/theme/dynamic_accent_theme.dart`)
  - `activeWorkoutProvider` — current workout session (`lib/features/workout/presentation/providers/active_workout_provider.dart`)

**Testing:**
| Framework | Version | Purpose |
|-----------|---------|---------|
| `flutter_test` | SDK | Standard test runner, assertions |
| `alchemist` | ^0.12.0 | Golden/visual regression testing |
| `sqlite3` | ^2.4.0 | Host-VM SQLite for DAO integration tests (uses dart:ffi) |

**Code Generation:**
| Package | Version | Purpose |
|---------|---------|---------|
| `build_runner` | ^2.4.0 | Orchestrator for all code generation |
| `drift_dev` | ^2.18.0 | Drift table/DAO code generation |
| `riverpod_generator` | ^2.4.0 | Riverpod `@riverpod` annotation processing |
| `freezed` | ^2.5.0 | Immutable data classes with union types |
| `json_serializable` | ^6.8.0 | JSON serialization for data models |
| `sentry_dart_plugin` | ^3.4.0 | Sentry debug symbol upload post-build |

**Linting:**
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^4.0.0 | Baseline lint rules from Flutter team |
| `custom_lint` | ^0.6.0 | Custom lint runner (hosts riverpod_lint) |
| `riverpod_lint` | ^2.3.0 | Riverpod-specific lint rules |

**Build/Dev:**
| Tool | Purpose |
|------|---------|
| `dart format` | Code formatting (enforced in CI via `--set-exit-if-changed`) |
| `flutter analyze --fatal-infos --fatal-warnings` | Static analysis gate |
| `dart run custom_lint` | Riverpod-specific lint checks |
| `flutter test --machine` | Machine-readable test output for CI |

## Key Dependencies

**Critical — Core App:**
| Package | Version | Why it matters |
|---------|---------|----------------|
| `drift` | ^2.18.0 | Local SQLite ORM — the offline-first data layer. All 9 tables and 5 DAOs depend on it. |
| `supabase_flutter` | ^2.5.0 | Auth provider (Google Sign-In) + backend sync transport (`sync_objects` table RPC). |
| `flutter_riverpod` | ^2.5.0 | Entire app state architecture. |
| `go_router` | ^14.0.0 | Declarative routing with auth guards and stateful tab navigation. |
| `purchases_flutter` | ^10.3.0 | RevenueCat SDK — premium entitlements and paywall. |

**Infrastructure:**
| Package | Version | Purpose |
|---------|---------|---------|
| `sentry_flutter` | ^8.14.0 | Crash/error reporting with native integration |
| `google_sign_in` | ^6.2.0 | Native Google Sign-In for mobile auth |
| `flutter_secure_storage` | ^9.0.0 | Secure token storage for Supabase sessions |
| `shared_preferences` | ^2.2.0 | Key-value preferences (accent palette, sync toggle, hydration flags) |
| `connectivity_plus` | ^7.1.1 | Network state detection for sync engine |
| `flutter_local_notifications` | ^22.1.0 | Rest timer local notifications |
| `timezone` | ^0.11.1 | Timezone data for scheduled notifications |
| `path_provider` | ^2.1.0 | Application documents directory for SQLite database |

**UI & Media:**
| Package | Version | Purpose |
|---------|---------|---------|
| `google_fonts` | ^6.2.0 | Inter typeface for all typography |
| `flutter_svg` | ^2.0.10 | Muscle group SVG glyphs on routine cards |
| `cached_network_image` | ^3.3.0 | Exercise GIF/thumbnail caching |
| `gif_view` | ^0.4.0 | Animated exercise GIF playback |
| `fl_chart` | ^0.68.0 | Workout analytics charts (weekly bar, progress) |
| `flutter_cache_manager` | ^3.4.1 | Media cache management |

**Data & Utilities:**
| Package | Version | Purpose |
|---------|---------|---------|
| `freezed_annotation` | ^2.4.0 | Immutable data classes |
| `json_annotation` | ^4.9.0 | JSON serialization annotations |
| `uuid` | ^4.4.0 | UUID generation for all entities (workouts, sets, sessions) |
| `intl` | ^0.19.0 | Date/number formatting |
| `collection` | ^1.18.0 | Collection utilities |
| `path` | ^1.9.1 | File path manipulation |

**Import/Export:**
| Package | Version | Purpose |
|---------|---------|---------|
| `share_plus` | ^12.0.2 | CSV workout export sharing |
| `file_picker` | ^8.1.2 | CSV import from Hevy/Strong |
| `image_picker` | ^1.1.2 | Profile picture upload |
| `flutter_image_compress` | ^2.3.0 | Profile picture image compression |
| `crop_your_image` | ^2.0.0 | In-app profile picture cropping |
| `url_launcher` | ^6.2.0 | Opening external URLs (paywall, store, legal) |
| `package_info_plus` | ^8.0.0 | App version info for settings/about |

## Database

**Engine:** SQLite via Drift ORM.

**Connection:** `NativeDatabase.createInBackground()` via `LazyDatabase` (`lib/core/database/database.dart` line 140-146). File stored at `getApplicationDocumentsDirectory()/gymlog_db.sqlite`.

**Tables (9 total in `lib/core/database/tables/`):**
| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `UserProfiles` | User identity, premium status, preferences | `id`, `email`, `displayName`, `isPremium`, `premiumExpiry`, `weightUnit` |
| `Exercises` | Exercise catalog (bundled + custom) | `id` (int auto-increment), `exerciseDbId`, `name`, `bodyPart`, `equipment` |
| `Routines` | User workout routines | `id`, `userId`, `name`, `notes`, `createdAt` |
| `RoutineDays` | Days within a routine (Push/Pull/Legs) | `id`, `routineId`, `name`, `orderIndex` |
| `RoutineExercises` | Exercises assigned to a day | `id`, `routineDayId`, `exerciseId`, `defaultSets`, `defaultReps` |
| `WorkoutSessions` | Logged workout sessions | `id`, `userId`, `routineId`, `startedAt`, `endedAt`, `totalVolumeKg` |
| `WorkoutExercises` | Exercises within a session | `id`, `sessionId`, `exerciseId`, `orderIndex` |
| `WorkoutSets` | Individual sets within an exercise | `id`, `workoutExerciseId`, `weightKg`, `reps`, `setType`, `completedAt` |
| `SyncOutbox` | Local-first change queue for cloud sync | `id`, `entityType`, `entityId`, `userId`, `payload`, `op` |

**DAOs (5 in `lib/core/database/daos/`):**
- `UserDao` — profile CRUD, premium status sync
- `ExercisesDao` — exercise catalog, search, filter, JSON hydration
- `WorkoutsDao` — session CRUD, PR detection, orphan cleanup, import/export
- `RoutinesDao` — routine + day + exercise CRUD
- `SyncOutboxDao` — queue management, quarantine

**Schema version:** 5 (defined at `lib/core/database/database.dart` line 36).

**Migrations (`database.dart` lines 48-118):**
- v1→v2: Creates `sync_outbox` table
- v2→v3: Adds `age`, `experienceLevel`, `onboardingComplete` to `user_profiles`
- v3→v4: Adds `gender` column to `user_profiles`
- v4→v5: Adds `measurementType` column to `exercises`, alters `workout_sets` table

**Indexes:** 10 `CREATE INDEX IF NOT EXISTS` statements in `beforeOpen` for hot-path queries (sessions, workouts, exercises, sync queue). Plus a `sync_failures` table for quarantine records.

**Testing:** `AppDatabase.forTesting()` constructor (`database.dart` line 42) accepts an in-memory executor for unit/integration tests.

## Configuration

**Environment:**
- All secrets/keys injected at **compile time** via `--dart-define-from-file=.env`
- Config read from `lib/core/config/env.dart` — `String.fromEnvironment()` for each key
- All keys optional — app degrades gracefully (auth disabled, free mode, no crash reporting)
- Key vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_SERVER_CLIENT_ID`, `GIF_BUCKET_BASE`, `REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY`, `SENTRY_DSN`, `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`, `ACCOUNT_DELETION_URL`

**Build:**
- Code generation: `dart run build_runner build --delete-conflicting-outputs`
- Verification: `.\scripts\verify.ps1` (Windows) or `scripts/verify.sh` (Unix) — runs format, analyze, custom_lint, test
- Release: `flutter build appbundle --release --obfuscate --split-debug-info=... --dart-define-from-file=.env`

**Build config files:**
- `analysis_options.yaml` — analyzer configuration, lint rules, custom_lint settings
- `pubspec.yaml` — dependencies, assets, Sentry plugin config
- `android/app/build.gradle.kts` — R8/ProGuard, compile SDK

## Platform Requirements

**Development:**
- Flutter SDK (stable channel)
- Android Studio / Xcode for platform builds
- Dart SDK >=3.0.0
- `libsqlite3-dev` (Linux) for DAO integration tests
- `.env` file in repo root with service keys (optional for compilation)

**Production:**
- **Android:** API 21+ (Flutter default), R8 shrink + Dart obfuscation
- **iOS:** iOS 12+ (Flutter default), release build with `--no-codesign` in CI
- **Web:** Web OAuth for Google Sign-In (via `kIsWeb` branch in `auth_repository.dart`)
- **Desktop (macOS/Linux/Windows):** Supported by Flutter but auth/purchases degrade gracefully — primarily a mobile app

**CI/CD:**
- GitHub Actions with three machine types:
  - `ubuntu-latest` for analyze, test, and Android build
  - `macos-latest` for iOS build
  - Weekly dependency audit on `ubuntu-latest`
- Sentry symbol upload via `sentry_dart_plugin` (runs post-release-build)

---

*Stack analysis: 2026-07-29*
