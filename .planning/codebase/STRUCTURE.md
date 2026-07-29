# Codebase Structure

**Analysis Date:** 2026-07-29

## Directory Layout

```
gymlog/
├── lib/                          # Application source code (Dart)
│   ├── main.dart                 # Entry point — Bootstrap → ProviderScope → GymLogApp
│   ├── app.dart                  # Root widget — MaterialApp.router + lifecycle wiring
│   ├── core/                     # Shared infrastructure layer
│   │   ├── bootstrap/            # Staged application startup
│   │   ├── config/               # Compile-time env config + legal links
│   │   ├── database/             # Drift SQLite — tables/, daos/, database.dart
│   │   ├── exercises/            # Exercise taxonomy, muscle map data
│   │   ├── models/               # Shared value objects (measurement, PR, rest, metrics)
│   │   ├── providers/            # Infrastructure-level Riverpod providers
│   │   ├── router/               # GoRouter configuration + auth redirect logic
│   │   ├── services/             # Sync engine, draft store, export, premium, notifications
│   │   ├── theme/                # AppColors, ThemePalettes, accent system, typography
│   │   └── utils/                # Pure utility functions (formatters, time, units)
│   ├── features/                 # Feature modules
│   │   ├── auth/                 # Authentication (Supabase Google Sign-In)
│   │   ├── exercises/            # Exercise catalog, selection, detail screens
│   │   ├── home/                 # Home screen — workout history feed, quick start
│   │   ├── import/               # CSV import (Hevy/Strong)
│   │   ├── profile/              # User profile, settings, export
│   │   ├── routines/             # Routine CRUD, detail, editor
│   │   └── workout/              # Active workout, workout history, timer
│   └── shared/                   # Reusable widgets, layout, shared providers
│       ├── layout/               # Adaptive layout constraints
│       ├── providers/            # Cross-feature providers (GIF cache)
│       └── widgets/              # Shared UI components
├── test/                         # Test suite (66 files, ~497 tests)
│   ├── golden/                   # Golden file tests (active_workout_header, nav_bar, auth_screen...)
│   ├── analytics/                # Analytics-specific tests
│   ├── auth/                     # Auth-related tests
│   ├── import/                   # Import feature tests
│   ├── performance/              # Performance regression tests
│   ├── premium/                  # Premium/gating tests
│   ├── profile/                  # Profile feature tests
│   ├── shared/                   # Shared widget tests
│   ├── sync/                     # Sync engine tests
│   └── *.dart                    # Top-level integration + feature tests
├── assets/                       # Static assets
│   ├── body/                     # SVG body maps (front/back, male/female) + part defs
│   ├── db/                       # Bundled exercise catalog (exercises.db, exercises.json)
│   ├── google_fonts/             # Google Fonts cache
│   └── icons/                    # App icons
├── docs/                         # Project documentation
│   ├── audit/                    # Audit reports
│   ├── legal/                    # Legal pages (privacy, account deletion)
│   ├── ops/                      # Operations runbooks
│   ├── supabase/                 # Supabase schema + RLS docs
│   └── *.md                      # Architecture, conventions, design north star, etc.
├── scripts/                      # Build and verification scripts
│   ├── seed_exercises.py         # Exercise catalog seeder
│   ├── verify.ps1                # Windows verification (format, analyze, lint, test)
│   └── verify.sh                 # Linux/macOS verification
├── .github/                      # CI/CD
│   └── workflows/
│       └── ci.yml                # Zero-tolerance CI gate (analyze → test → build Android/iOS)
├── supabase/                     # Supabase CLI config (migrations, seed, config.toml)
├── android/                      # Android platform project
├── ios/                          # iOS platform project
├── web/                          # Web platform
├── linux/                        # Linux platform
├── macos/                        # macOS platform
├── windows/                      # Windows platform
├── pubspec.yaml                  # Dart package manifest + dependencies
├── analysis_options.yaml         # Lint rules (flutter_lints + custom_lint)
├── AGENTS.md                     # Agent context file
└── CLAUDE.md                     # Claude integration instructions
```

## Directory Purposes

### `lib/` — Application Source

**`lib/main.dart`:**
- Purpose: Entry point — calls `Bootstrap.run()` then launches `ProviderScope` with overridden singletons
- Key wiring: `databaseProvider`, `premiumServiceProvider`, `notificationServiceProvider`, `initialAccentPaletteProvider`

**`lib/app.dart`:**
- Purpose: Root widget `GymLogApp` — `ConsumerStatefulWidget` that wires auth lifecycle listeners, sync engine init, Sentry error capture, and renders `MaterialApp.router` with reactive theme

**`lib/core/`:**
- Purpose: Shared infrastructure — everything not owned by a single feature
- Contains: Database, router, theme, services, config, models, utils, infrastructure providers
- Key constraint: Cross-feature dependencies must go through `core/` — features must not import each other

**`lib/core/bootstrap/`:**
- `bootstrap.dart` (324 lines): Staged startup: Flutter binding → Sentry init → accent palette load → DB open + SQLite integrity check (`PRAGMA quick_check`) → `runApp` with result → post-frame cloud init (`Supabase.initialize` with 4s timeout), commerce (`PremiumService`), catalog hydration, orphan cleanup
- `BootstrapResult` carries `db`, `premiumService`, `notificationService`, `accentPalette`, `databaseCorrupted` flag

**`lib/core/config/`:**
- `env.dart`: All compile-time config from `--dart-define` / `--dart-define-from-file=.env` — `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_SERVER_CLIENT_ID`, `GIF_BUCKET_BASE`, `SENTRY_DSN`, `REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY`. Safe defaults for public values. Has guards like `hasSupabaseConfig`, `hasSentryConfig`
- `legal_links.dart`: Privacy policy, terms, account deletion URLs

**`lib/core/database/`:**
- `database.dart` (147 lines): `AppDatabase` — `@DriftDatabase` with 9 tables, 5 DAOs, schema version 5, migration strategy v1→v5, SQLite integrity/performance indexes, `wipeAllData()`, `_openConnection()` using `LazyDatabase` + `NativeDatabase.createInBackground`
- `database.g.dart`: Generated Drift code
- `tables/`: 7 table definition files:
  - `exercises_table.dart` — bundled + user-custom exercises
  - `routines_table.dart` — user-created routines
  - `routine_days_table.dart` — day splits within routines
  - `routine_exercises_table.dart` — exercises within days with default set/reps/weight
  - `workouts_table.dart` — `WorkoutSessions`, `WorkoutExercises`, `WorkoutSets` (3 tables in one file)
  - `user_profiles_table.dart` — user profile + premium expiry
  - `sync_outbox_table.dart` — pending sync queue + quarantined failures
- `daos/`: 5 DAO files (each with `.g.dart` generated):
  - `exercises_dao.dart` — catalog hydration from JSON, search, custom exercise CRUD
  - `routines_dao.dart` — routine CRUD, `HydratedRoutine` / `HydratedRoutineDetail` join queries, JSON import/export
  - `workouts_dao.dart` (1449 lines, largest file) — session CRUD, `HydratedWorkout` joins, paginated previews, PR detection (Epley 1RM), CSV export, previous-set lookups, orphan cleanup
  - `user_dao.dart` — profile CRUD, weight unit, rest seconds, premium flag
  - `sync_outbox_dao.dart` — queue enqueue/delete, pending/ quarantined counts, nextBatch for sync

**`lib/core/models/`:**
- `measurement_type.dart`: Exercise measurement types (weight_and_reps, reps_only, duration, etc.)
- `personal_record.dart`: PR data class from Epley formula
- `rest_preference.dart`: Rest timer duration enums and normalization
- `workout_metric_summary.dart`: Summary metrics for workout history display

**`lib/core/providers/`:**
- `database_provider.dart`: `Provider<AppDatabase>` — must be overridden at root
- `premium_provider.dart`: `premiumServiceProvider`, `customerInfoProvider`, `isPremiumProvider`, `kFreeRoutineLimit`, `chartLimitBannerCopy`, `gateChartSamples`
- `settings_provider.dart`: Default rest seconds provider
- `app_info_provider.dart`: Package info provider

**`lib/core/router/`:**
- `router.dart` (204 lines): `routerProvider` → GoRouter with `_GoRouterRefreshStream` on Supabase auth, auth redirect logic, `StatefulShellRoute.indexedStack` for 3 tabs, 16 routes total

**`lib/core/services/`:**
- `sync_engine.dart` (445 lines): `SyncEngine` class — outbox-based push/pull with debounce, connectivity watch, cron-like auto-sync, quarantine, status stream. Providers: `syncEngineProvider`, `syncRemoteProvider`, `pendingSyncCountProvider`, `quarantinedSyncCountProvider`
- `sync_remote.dart` (176 lines): `SyncRemote` abstract class + `SupabaseSyncRemote` implementation with per-object conflict detection, monotonic revision tracking
- `sync_codec.dart`: Payload encoding/decoding
- `sync_entitlement_gate.dart`: Controls sync availability per user
- `sync_failure.dart`: Failure reason enum + quarantine record
- `sync_status_provider.dart` / `.g.dart`: Riverpod-code-gen status provider
- `workout_draft_store.dart` (290 lines): Encrypted draft persistence via `FlutterSecureStorage` — v2 format with user isolation, stale checking (>24h), rest timer snapshot
- `workout_export_service.dart`: CSV export for workout data
- `premium_service.dart`: RevenueCat integration with offline fallback in user_profiles table
- `notification_service.dart`: Flutter local notifications setup
- `profile_sync_service.dart`, `profile_image_sync_service.dart`: Profile data sync with cloud
- `account_deletion_service.dart`: Full account deletion orchestration
- `sign_out_coordinator.dart`: Coordinated sign-out (clear sync, clear drafts, navigate)
- `exercise_media_cache_manager.dart`: GIF media cache maintenance
- `muscle_color_service.dart`: Muscle group → color mapping

**`lib/core/theme/`:**
- `app_colors.dart` (312 lines): Abstract class with ALL static color constants — AMOLED dark hierarchy (4 surface levels), light hierarchy (White palette), semantic accents (success/info/warning/reward), text opacity scale, chart colors. `SurfaceTokens` class + `SurfaceContextX` extension for context-aware dark/light surface selection. BuildContext extension `context.surface.bgBase`
- `app_theme.dart` (262 lines): `buildAppTheme(tokens, palette)` — Material3 dark ThemeData with Google Fonts Inter, `AccentColors` ThemeExtension, platform-specific page transitions. `appTheme` fallback constant. `buildHighContrastTheme` for OS high-contrast mode
- `app_text.dart`: TextStyle factory functions with Inter font + tabular figures
- `dynamic_accent_theme.dart` (170 lines): `DynamicAccentNotifier` — runtime accent palette state. `AccentColors` ThemeExtension with base/light/dark/muted/glow/onAccent tokens + saturation helpers. `context.accent` extension
- `theme_palette.dart` (260 lines): 6 `ThemePalette` enum values (higgsfield/Volt, neonPurple, white, neonCyan, neonMagenta, blazeOrange) with `ThemePaletteTokens` (6-color tokens per palette). Legacy palette migration `fromStorage()`. Saturation discipline documented
- `chrome_tokens.dart` (53 lines): Chrome-specific surface tokens for nav shell (`context.chrome.*`)
- `set_type.dart`: Set type definitions (normal, warmup, dropset, failure)
- `radius_token.dart`: Consistent border radius tokens

**`lib/core/exercises/`:**
- `body_map.dart`: Body part ↔ muscle group mapping data
- `muscle_taxonomy.dart`: Muscle hierarchy taxonomy

**`lib/core/utils/`:**
- `formatters.dart`: `formatWorkoutDuration()`, `getWorkoutNameFallback()`
- `relative_time.dart`: Human-readable relative time strings
- `tap_guard.dart`: Debounce guard for rapid taps
- `units.dart`: Unit conversion helpers

### `lib/features/` — Feature Modules

Each feature follows this structure where applicable:
- `data/` — Repositories, remote data sources
- `domain/` — Business logic state (Freezed models) — only workout and import use this
- `presentation/` — UI layer
  - `providers/` — Riverpod providers
  - `screens/` — Full-page widgets (snake_case_screen.dart)
  - `widgets/` — Feature-scoped reusable widgets

**`lib/features/auth/`:**
- `data/auth_repository.dart`: `AuthRepository` — wraps `Supabase.instance.client.auth`, Google Sign-In (native + web OAuth), `signInWithGoogle()`, `signOut()`, `currentUser`, `authStateChanges`
- `presentation/providers/auth_provider.dart`: `authRepositoryProvider`, `authStateProvider`, `authProvider` — derived with Sentry scope sync
- `presentation/screens/`: `splash_screen.dart`, `auth_screen.dart`, `onboarding_screen.dart`
- `presentation/widgets/`: Auth-related widgets

**`lib/features/exercises/`:**
- `presentation/providers/exercises_provider.dart`: `exerciseCatalogByIdProvider` (O(1) lookup map), `@riverpod ExerciseList` (searchable with epoch-based stale check)
- `presentation/providers/exercise_analytics_provider.dart`: `StreamProvider.family<List<ExerciseHistoryData>, int>` — keyed by exercise ID
- `presentation/screens/`: `exercise_selection_screen.dart`, `exercise_detail_screen.dart`

**`lib/features/home/`:**
- `presentation/providers/home_provider.dart`: `WorkoutHistoryState` (paginated state with initialLoad/error/isLoadingMore), `WorkoutHistoryNotifier` (pagination, reset on signal), `workoutCompletedSignalProvider` (StateProvider<int>)
- `presentation/screens/`: `home_screen.dart` — infinite scroll with QuickStart + history cards
- `presentation/widgets/`: `workout_history_card.dart`

**`lib/features/import/`:**
- `data/`: `workout_csv_parser.dart`, `csv_codec.dart`, `exercise_matcher.dart`, `workout_import_service.dart`
- `domain/`: `import_models.dart` — import-specific data classes
- `presentation/providers/`: Import workflow providers
- `presentation/screens/`: `import_screen.dart`

**`lib/features/profile/`:**
- `data/profile_remote.dart`: Supabase profile fetch/upload
- `presentation/providers/profile_provider.dart`: `workoutCountProvider`, `currentUserProfileProvider`
- `presentation/screens/`: `profile_screen.dart`, `settings_screen.dart`, `help_feedback_screen.dart`, `personal_details_screen.dart`, `appearance_screen.dart`, `delete_account_screen.dart`
- `presentation/widgets/`: Profile-specific widgets

**`lib/features/routines/`:**
- `presentation/providers/routines_provider.dart`: `hydratedRoutinesProvider`, `routineDetailProvider`, `routineDailyVolumeProvider`, `routineLastSetsProvider`
- `presentation/screens/`: `routine_detail_screen.dart`, `routine_editor_screen.dart`, `explore_routines_screen.dart`
- `presentation/widgets/`: `routine_card.dart`

**`lib/features/workout/`:**
- `domain/active_workout_state.dart` (130 lines): `@freezed` — `WorkoutSetState`, `WorkoutExerciseState`, `ActiveWorkoutState`. `seedExercisesFromRoutine()` helper
- `presentation/providers/`: 8 providers:
  - `active_workout_provider.dart` (664 lines): `ActiveWorkoutNotifier` — start/finish/discard/add/remove/reorder, draft persistence, PR detection, edit mode
  - `workout_timer_provider.dart`: `@riverpod` WorkoutTimer — 1-second `Timer.periodic`
  - `rest_timer_provider.dart`: Rest timer state provider
  - `workout_detail_provider.dart`: `StreamProvider.family<HydratedWorkout?, String>` — keyed by sessionId
  - `previous_session_provider.dart`: Previous session data for ghost hints
  - `workout_event_provider.dart`: Event bus for workout-level events (set removed, etc.)
  - `workout_actions_provider.dart`: Workout action dispatch (edit, delete, export, share)
  - `session_totals_provider.dart` (in `active_workout_provider.dart`): Derived provider with `.select()` for volume + set count
- `presentation/screens/`: `workout_screen.dart` (routines tab), `active_workout_screen.dart` (full-screen modal logger), `workout_detail_screen.dart` (post-workout summary)
- `presentation/widgets/`: `exercise_block.dart`, `set_row.dart`

### `lib/shared/` — Shared Widgets & Layout

**`lib/shared/widgets/`:**
- `app_shell.dart`: ShellRoute builder — Scaffold with SafeArea, maxWidth 600, ActiveWorkoutBar, BottomNavBar, resume-draft sheet
- `bottom_nav_bar.dart`: 3-tab custom navigation bar
- `active_workout_bar.dart`: Purple resume banner shown above nav bar when workout is active
- `exercise_gif_widget.dart`, `exercise_hero_image.dart`, `exercise_hero_thumb.dart`: GIF/image widgets
- `app_error_screen.dart`: Global crash screen
- `async_error_state.dart`: Standard error state widget
- `branded_line_chart.dart`: Chart component with accent-aware theming
- `database_recovery_screen.dart`: DB corruption recovery UI
- `premium_paywall.dart`: Premium upsell screen
- `body/`: Body map interactive widgets
- `feedback/`: Feedback/rating widgets
- `motion/`: Motion/animation widgets
- `tour/`: Onboarding tour orchestration and pages
- `ui/`: Design system atoms:
  - `primary_button.dart`: 52px purple ElevatedButton
  - `secondary_button.dart`: 52px bgSurface ElevatedButton
  - `toggle_pill.dart`: Animated metric selector pill
  - `tracker_card.dart`: Standard card container (12px radius, bgSurface, optional InkWell)

**`lib/shared/layout/`:**
- `adaptive.dart`: Adaptive layout constraints (contentMaxWidth, breakpoints)

**`lib/shared/providers/`:**
- `gif_last_frame_provider.dart`: GIF last-frame cache for list thumbnails

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App entry point — Bootstrap → ProviderScope → runApp
- `lib/app.dart`: Root widget — MaterialApp.router, auth/sync lifecycle

**Configuration:**
- `pubspec.yaml`: Package manifest — all dependencies declared
- `analysis_options.yaml`: Lint rules — includes `flutter_lints`, custom_lint, `use_build_context_synchronously: error`
- `lib/core/config/env.dart`: All compile-time env vars with safe defaults
- `.env`: Gitignored local secrets file for `--dart-define-from-file`

**Core Logic:**
- `lib/core/database/database.dart`: Drift DB definition, migrations, indexes
- `lib/core/database/daos/workouts_dao.dart`: Largest DAO (1449 lines) — session CRUD, PR detection, pagination, export
- `lib/core/services/sync_engine.dart`: Sync orchestration (445 lines)
- `lib/core/router/router.dart`: GoRouter setup (204 lines)
- `lib/features/workout/presentation/providers/active_workout_provider.dart`: Active workout state machine (664 lines)
- `lib/core/theme/app_colors.dart`: Color system (312 lines)
- `lib/core/theme/app_theme.dart`: ThemeData factory (262 lines)
- `lib/core/theme/theme_palette.dart`: 6 palettes with tokens (260 lines)

**Testing:**
- `test/dao_integration_test.dart`: DAO integration tests (host SQLite via ffi)
- `test/sync_engine_test.dart`: Sync engine tests
- `test/golden/`: 6 golden test files
- `test/shared/`: Shared widget tests
- `test/profile/`, `test/auth/`, `test/import/`, `test/sync/`: Feature-specific tests
- `test/compile_surface_test.dart`: Compile-surface smoke test

## Naming Conventions

**Files:**
- `snake_case.dart`: All Dart source files — `active_workout_provider.dart`, `exercise_gif_widget.dart`
- `*_screen.dart`: Screen widgets — `home_screen.dart`, `active_workout_screen.dart`
- `*_provider.dart`: Riverpod providers — `auth_provider.dart`, `routines_provider.dart`
- `*_dao.dart`: Drift DAOs — `workouts_dao.dart`, `exercises_dao.dart`
- `*_table.dart`: Drift table definitions — `workouts_table.dart`, `exercises_table.dart`
- `*.g.dart`: Generated Drift code
- `*.freezed.dart`: Generated Freezed code (for `*.g.dart` with Riverpod code-gen too)
- `*_test.dart`: Test files — `active_workout_start_test.dart`, `sync_engine_test.dart`

**Directories:**
- `snake_case/`: All directories — `features/auth/presentation/screens/`
- Feature internal structure: `data/`, `domain/`, `presentation/` (where applicable)
- Presentation subdirectories: `providers/`, `screens/`, `widgets/`

## Where to Add New Code

**New Feature:**
- Primary code: `lib/features/<feature_name>/presentation/` — screens, widgets, providers
- Feature data layer: `lib/features/<feature_name>/data/` — repositories, remote adapters
- Feature domain layer: `lib/features/<feature_name>/domain/` — Freezed state models (if needed)
- Tests: `test/<feature_name>/` — co-located by feature in test directory

**New Core Service:**
- Implementation: `lib/core/services/`
- Provider: `lib/core/providers/` (or inline in the service file)
- Tests: `test/` (top-level, or dedicated subdirectory if multiple test files)

**New Database Table/DAO:**
- Table definition: `lib/core/database/tables/<name>_table.dart`
- DAO: `lib/core/database/daos/<name>_dao.dart`
- Register in: `lib/core/database/database.dart` — add table to `@DriftDatabase()` annotation
- Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**New Screen:**
- Implementation: `lib/features/<feature>/presentation/screens/<name>_screen.dart`
- Route: Register in `lib/core/router/router.dart`
- Convention: `ConsumerWidget` extending `ConsumerStatefulWidget` if state needed

**New Shared Widget:**
- Atom (button, card, input): `lib/shared/widgets/ui/<name>.dart`
- Composite widget: `lib/shared/widgets/<name>.dart`

**New Theme Color/Palette:**
- Fixed colors: `lib/core/theme/app_colors.dart` — add static const
- New palette: `lib/core/theme/theme_palette.dart` — add enum value + tokens
- Registration: DynamicAccentNotifier picks it up automatically

## Test Structure

**`test/`** — 66 test files:
- Feature-specific subdirectories: `auth/`, `profile/`, `import/`, `sync/`, `analytics/`, `premium/`, `performance/`
- `shared/`: Shared widget tests
- `golden/`: Golden file tests (6 files) — `active_workout_header_golden_test.dart`, `auth_screen_golden_test.dart`, `muscle_map_golden_test.dart`, `nav_bar_golden_test.dart`, `segmented_control_golden_test.dart`, `golden_test_helpers.dart`
- Top-level integration tests: `dao_integration_test.dart`, `sync_engine_test.dart`, `compile_surface_test.dart`, `widget_test.dart`, and various feature-level integration tests

**Run commands:**
```bash
flutter test                                          # All tests
flutter test --update-goldens                         # Update golden files
.\scripts\verify.ps1                                  # Full CI gate (format + analyze + custom_lint + test)
```

## Special Directories

**`assets/db/`:**
- Purpose: Bundled exercise catalog data — `exercises.json` (seed data), `exercises.db` (pre-built SQLite for fast first hydration)
- Generated: `exercises.db` is generated from `exercises.json`
- Committed: Yes

**`assets/body/`:**
- Purpose: SVG body map illustrations — `body_front.svg`, `body_back.svg`, `body_front_female.svg`, `body_back_female.svg` + `parts/` subdirectory with individual muscle part SVGs
- Committed: Yes

**`scripts/`:**
- `verify.ps1` / `verify.sh`: CI verification — `dart format` → `flutter analyze --fatal-infos --fatal-warnings` → `dart run custom_lint` → `flutter test`
- `seed_exercises.py`: Python script for generating exercise catalog JSON

**`docs/`:**
- `ARCHITECTURE.md`: Full architecture specification (this document's predecessor)
- `CONVENTIONS.md`: Code and architectural conventions (naming, patterns, color/typography rules)
- `DATA_MODEL.md`: Database schema documentation
- `DESIGN_NORTH_STAR.md`: Visual design principles and north star
- `SYNC_DESIGN.md`: Sync engine design document
- `CI_RUNBOOK.md`: CI pipeline details
- `RELEASE_CHECKLIST.md`: Release process steps
- `REVENUECAT_CONFIG.md`: RevenueCat configuration
- `STORE_LISTING.md`: App store listing copy
- `IMPORT.md`: Import feature design (CSV import from Hevy/Strong)
- `LOOP_LOG.md`: Regression tracking
- `ACCOUNT_ISOLATION.md`: Multi-user account isolation design
- `CONSOLE_CHECKLIST.md`: Debug console checklist
- `supabase/`: Supabase schema, RLS policies, migration docs
- `legal/`: Privacy policy, terms of service, account deletion HTML page
- `audit/`, `ops/`: Audit reports and operations runbooks

**`.planning/`:**
- Purpose: GSD planning artifacts — roadmaps, plans, phase directories, codebase maps
- Generated: Yes (by GSD workflow tools)
- Committed: Yes (project management context)

---

*Structure analysis: 2026-07-29*
