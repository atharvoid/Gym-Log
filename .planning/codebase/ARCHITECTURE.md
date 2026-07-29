<!-- refreshed: 2026-07-29 -->
# Architecture

**Analysis Date:** 2026-07-29

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER (Features)                     │
│  ┌────────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐  ┌──────────┐ │
│  │ Auth   │  │ Home     │  │Workout  │  │Routines  │  │ Profile  │ │
│  │Feature │  │Feature   │  │Feature  │  │Feature   │  │ Feature  │ │
│  ├────────┤  ├──────────┤  ├─────────┤  ├──────────┤  ├──────────┤ │
│  │Screens │  │Screens   │  │Screens  │  │Screens   │  │ Screens  │ │
│  │Widgets │  │Widgets   │  │Widgets  │  │Widgets   │  │ Widgets  │ │
│  │Providers│  │Providers │  │Providers│  │Providers │  │ Providers│ │
│  └───┬────┘  └────┬─────┘  └────┬────┘  └────┬─────┘  └────┬─────┘ │
└──────┼────────────┼─────────────┼────────────┼─────────────┼───────┘
       │            │             │            │             │
       ▼            ▼             ▼            ▼             ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    APPLICATION CORE (lib/core/)                        │
│  ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────────┐  │
│  │Database   │  │Router    │  │Services  │  │Theme               │  │
│  │(Drift)    │  │(GoRouter)│  │SyncEngine│  │(AppColors, Palettes)│  │
│  │ DAOs      │  │          │  │DraftStore│  │DynamicAccentTheme   │  │
│  │ Tables    │  │          │  │Export    │  │                    │  │
│  ├───────────┤  ├──────────┤  ├──────────┤  ├────────────────────┤  │
│  │Config    │  │Providers │  │Models    │  │Utils               │  │
│  │(Env)     │  │(DB,Prefs)│  │(PR,Meas) │  │(Formatters)        │  │
│  └───────────┘  └──────────┘  └──────────┘  └────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
       │                                              │
       ▼                                              ▼
┌──────────────────────┐              ┌──────────────────────────┐
│  LOCAL STORE         │              │  CLOUD BACKEND           │
│  SQLite (Drift DB)   │              │  Supabase (Auth + Sync)  │
│  SharedPreferences   │              │  RevenueCat (Premium)    │
│  FlutterSecureStorage│              │  Sentry (Crash Reports)  │
│  (draft persistence) │              │  GIF Bucket (Media)      │
└──────────────────────┘              └──────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Bootstrap | Staged startup: binding, Sentry, DB open/integrity, accent palette, then launch UI; runs post-frame cloud init and commerce | `lib/core/bootstrap/bootstrap.dart` |
| `AppDatabase` | Drift SQLite database: 9 tables, 5 DAOs, schema migration v1→v5, foreign keys + indexes | `lib/core/database/database.dart` |
| DAOs | Data access: `WorkoutsDao` (1449 lines, largest DAO), `ExercisesDao`, `RoutinesDao`, `UserDao`, `SyncOutboxDao` | `lib/core/database/daos/*.dart` |
| Router | GoRouter configuration: auth redirect, StatefulShellRoute for 3-tab nav, top-level routes | `lib/core/router/router.dart` |
| `AuthRepository` | Supabase Google Sign-In (native + web OAuth) | `lib/features/auth/data/auth_repository.dart` |
| `ActiveWorkoutNotifier` | In-memory workout session: start/finish/discard, add/remove/reorder exercises/sets, auto-save draft | `lib/features/workout/presentation/providers/active_workout_provider.dart` |
| `SyncEngine` | "Local source of truth, cloud mirror" — outbox queue, debounced push/pull, quarantined failures | `lib/core/services/sync_engine.dart` |
| `DynamicAccentNotifier` | Runtime accent palette switching (6 palettes), persisted to SharedPreferences | `lib/core/theme/dynamic_accent_theme.dart` |
| `PremiumService` | RevenueCat entitlement check, offline cache fallback in `user_profiles` table | `lib/core/services/premium_service.dart` |
| `WorkoutDraftStore` | Encrypted draft snapshot (crash resilience), persisted via `FlutterSecureStorage` | `lib/core/services/workout_draft_store.dart` |
| `Bootstrap` | Staged startup (Sentry → DB → accent palette → UI → post-frame cloud init) | `lib/core/bootstrap/bootstrap.dart` |

## Pattern Overview

**Overall:** Feature-based modular monolith with a shared core infrastructure layer.

**Key Characteristics:**
- **Feature-first organization** — each domain (`auth`, `exercises`, `home`, `profile`, `routines`, `workout`, `import`) is a self-contained module under `lib/features/`
- **No DI framework** — Riverpod's `Provider`/`overrideWithValue` serves as the dependency injection mechanism
- **Local-first, cloud-mirror architecture** — Drift SQLite is the source of truth; `SyncEngine` pushes/pulls via Supabase with a `sync_outbox` queue
- **Reactive at every layer** — DAOs expose `Stream` queries, providers compose them, widgets rebuild via `ref.watch()`
- **Mixed Riverpod styles** — manual `StateNotifierProvider` (active workout) alongside code-generated `@riverpod` classes (exercise list, timer)

## Layers

**Presentation Layer (Features):**
- Purpose: UI screens, widgets, and feature-scoped providers
- Location: `lib/features/*/presentation/`
- Contains: `screens/`, `widgets/`, `providers/`
- Depends on: Core providers (`databaseProvider`, `authProvider`) and DAOs through `databaseProvider`

**Domain Layer (Feature-scoped):**
- Purpose: Business logic state classes, Freezed models
- Location: `lib/features/*/domain/`
- Contains: Freezed state classes for in-memory business logic
- Depends on: Nothing (pure Dart)
- Used by: Feature providers
- **Note:** Only `workout/` and `import/` have a `domain/` layer currently

**Data Layer (Feature-scoped):**
- Purpose: Repositories, external data adapters
- Location: `lib/features/*/data/`
- Contains: `AuthRepository`, `ProfileRemote`, import CSV codecs
- Depends on: Core services and Supabase client

**Core Infrastructure (`lib/core/`):**
- Purpose: Shared infrastructure — database, router, theme, services, config
- Location: `lib/core/`
- Contains: `database/` (Drift), `router/` (GoRouter), `theme/` (AppColors, palettes), `services/` (sync, draft, export, premium), `config/` (env), `providers/` (DB, premium, settings), `utils/` (formatters)
- Depends on: External packages only

**Shared UI (`lib/shared/`):**
- Purpose: Reusable widgets and layout helpers
- Location: `lib/shared/`
- Contains: `widgets/` (AppShell, BottomNavBar, ActiveWorkoutBar, buttons, cards), `widgets/ui/` (atoms), `widgets/tour/` (onboarding tour), `layout/` (adaptive constraints)
- Used by: All feature presentation layers

## Data Flow

### Primary Request Path: Workout Logging

1. User taps "Start Workout" → `HomeScreen` or `WorkoutScreen` calls `ref.read(activeWorkoutProvider.notifier).startWorkout(...)` (`lib/features/workout/presentation/providers/active_workout_provider.dart:78`)
2. If started from a routine, `ActiveWorkoutNotifier` loads routine days + exercises via `databaseProvider` → `RoutinesDao` (`lib/core/database/daos/routines_dao.dart`)
3. Previous session sets loaded via `WorkoutsDao.getPreviousSessionSetsBatch()` for ghost hints (`lib/core/database/daos/workouts_dao.dart`)
4. `ActiveWorkoutState` (Freezed model) held in memory as `StateNotifier` state (`lib/features/workout/domain/active_workout_state.dart`)
5. Every change persists a draft to `FlutterSecureStorage` via `WorkoutDraftStore.save()` (800ms debounce) (`lib/core/services/workout_draft_store.dart`)
6. User taps "Finish" → `finishWorkout()` opens a Drift transaction: inserts `WorkoutSession`, `WorkoutExercise`, `WorkoutSet` rows, runs `detectAndMarkPrs()`, increments `workoutCompletedSignalProvider` (`lib/features/workout/presentation/providers/active_workout_provider.dart:163`)
7. Post-save: `SyncEngine.enqueueSession()` adds to outbox, `syncNow()` triggers push (`lib/core/services/sync_engine.dart:146`)
8. Signal increment causes `WorkoutHistoryNotifier._reset()` to reload the home feed (`lib/features/home/presentation/providers/home_provider.dart`)

### Secondary Flow: Home Feed Pagination

1. `WorkoutHistoryNotifier` watches `workoutCompletedSignalProvider` (`lib/features/home/presentation/providers/home_provider.dart`)
2. On init or signal change: calls `WorkoutsDao.getSessionPreviews()` with cursor pagination (page size 10, limit+1 for `hasMore`)
3. `HomeScreen` watches `workoutHistoryProvider`, renders `ListView.builder` with QuickStart card, section header, history cards, and footer pagination trigger

### Secondary Flow: Sync Push/Pull

1. Local write → `SyncOutboxDao.enqueue()` (`lib/core/database/daos/sync_outbox_dao.dart`)
2. `watchPendingCount` stream triggers `scheduleSync()` (5s debounce) or immediate `syncNow()` (`lib/core/services/sync_engine.dart:199`)
3. `syncNow()` reads batch from outbox, pushes to `SupabaseSyncRemote.pushBatch()`, acks/conflicts/quarantines results (`lib/core/services/sync_remote.dart:66`)
4. On auth sign-in or pull request: `pull(userId)` fetches from Supabase and applies sessions/routines/preferences locally (`lib/core/services/sync_engine.dart:309`)

**State Management:**
- Riverpod is the single source of reactive state — no `setState` for data beyond widget-local UI
- Providers can be: `Provider` (singleton), `StreamProvider` (reactive DB queries), `StateNotifierProvider` (manual state), `@riverpod` (code-generated)
- `StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>` is the most complex provider — the entire workout session lives in memory
- `sessionTotalsProvider` uses `.select()` to avoid rebuilding on every keystroke in weight/reps fields
- `workoutCompletedSignalProvider` (a `StateProvider<int>`) is used as a cross-provider signal: increment → triggers `WorkoutHistoryNotifier._reset()`

## Navigation Architecture

### Route Tree (GoRouter)

```
SplashRoute:     /splash                  → SplashScreen
AuthRoute:       /auth                    → AuthScreen
OnboardingRoute: /onboarding              → OnboardingScreen
ShellRoute (StatefulShellRoute.indexedStack)
  ├── Branch 0:  /                        → HomeScreen
  ├── Branch 1:  /workout                 → WorkoutScreen
  └── Branch 2:  /profile                 → ProfileScreen
Detail routes (top-level, push over shell):
  /exercises/select                        → ExerciseSelectionScreen
  /exercises/library                       → ExerciseSelectionScreen(browse:true)
  /exercise/detail/:id                     → ExerciseDetailScreen (passes `state.extra as Exercise?`)
  /routines/edit                           → RoutineEditorScreen
  /routines/explore                        → ExploreRoutinesScreen
  /routines/:id                            → RoutineDetailScreen
  /workout/active                          → ActiveWorkoutScreen (fullscreenDialog, custom slide-up transition)
  /workout/detail/:id                      → WorkoutDetailScreen
  /settings                                → SettingsScreen
  /settings/help                           → HelpFeedbackScreen
  /settings/personal                       → PersonalDetailsScreen
  /settings/appearance                     → AppearanceScreen
  /settings/import                         → ImportScreen
  /settings/delete-account                 → DeleteAccountScreen
```

### Auth Redirect Logic

- `_GoRouterRefreshStream` wraps `Supabase.instance.client.auth.onAuthStateChange` as a `ChangeNotifier` (`lib/core/router/router.dart:31`)
- GoRouter's `refreshListenable` re-evaluates `redirect` on every auth state change
- Rules: `/splash` and `/onboarding` always allowed; `!isSignedIn && !isAuthRoute` → `/auth`; `isSignedIn && isAuthRoute` → `/splash`

### Shell Navigation

- `StatefulShellRoute.indexedStack` preserves each tab's navigator state across switches (`lib/core/router/router.dart:89`)
- `AppShell` renders: `Scaffold` → `SafeArea` → `ConstrainedBox(maxWidth: 600)` → navigation shell → `ActiveWorkoutBar` (animated, shown when `activeWorkoutProvider != null`) → `BottomNavBar` (3 tabs: Home/Routines/Profile)
- Re-tapping active tab pops to branch root (`AppShell.onTap`, `initialLocation: true`)

## DI / Service Location

- **No DI container** — Riverpod's `Provider<T>` with `overrideWithValue` is the DI mechanism
- `main.dart` overrides `databaseProvider`, `premiumServiceProvider`, `notificationServiceProvider`, and `initialAccentPaletteProvider` with pre-initialized singletons from `Bootstrap.run()` (`lib/main.dart:14-23`)
- `databaseProvider` (in `lib/core/providers/database_provider.dart`) throws `UnimplementedError` if not overridden — prevents accidental second Drift connection
- `databaseProvider` is the central dependency: all DAOs, services, and features access the DB through it
- `authRepositoryProvider` wraps `Supabase.instance.client`, handles missing initialization gracefully (returns `AuthRepository(null)` for local-only mode)

## Authentication Architecture

**Provider:** Supabase with Google Sign-In (`lib/features/auth/data/auth_repository.dart`)

**Flow:**
- Build-time config from `--dart-define-from-file=.env` (optional — clean checkout works with auth disabled)
- Bootstrap initializes Supabase with bounded timeout (4s) — on timeout/timeout, app runs in local-only mode (`lib/core/bootstrap/bootstrap.dart:265`)
- `AuthRepository` wraps `Supabase.instance.client.auth` with native + web OAuth fallback
- Provider hierarchy: `authRepositoryProvider` → `authStateProvider` (StreamProvider) → `authProvider` (Provider<User?>, derived with Sentry scope sync)
- `WidgetRef.isSignedIn` extension on `authProvider` (`lib/features/auth/presentation/providers/auth_provider.dart:37`)

**Session Management:**
- GoRouter's `_GoRouterRefreshStream` triggers redirect re-evaluation on every auth change
- `GymLogApp._onAuthStateChange` in `lib/app.dart:82` wires sync: on sign-in → `initSession()` + `enqueuePreferences()`; on sign-out → `resetSession()`
- Lifecycle hooks: backgrounding triggers sync flush, resuming schedules debounced sync (`lib/app.dart:50-78`)

**Account Isolation:**
- `WorkoutDraftStore.loadSnapshot()` validates userId match before loading draft (`lib/core/services/workout_draft_store.dart:167`)
- Sync engine remote has ownership checks with quarantine (`lib/core/services/sync_engine.dart:246`)
- `wipeAllData()` in `AppDatabase` deletes all local data on account deletion (`lib/core/database/database.dart:126`)

## Error Handling

**Strategy:** Defensive with graceful degradation — never crash on optional service failures.

**Patterns:**
- Provider error states handled via `.when()`: `data` → render, `loading` → spinner, `error` → red `TrackerCard` (`docs/CONVENTIONS.md:124-133`)
- Bootstrap errors are caught per-stage: DB corruption → recovery screen (`DatabaseRecoveryScreen`), cloud init timeout → local-only mode, commerce init failure → free mode
- Global Flutter errors captured via `FlutterError.onError` → `Sentry.captureException` in `GymLogApp.initState` (`lib/app.dart:40-43`)
- Recovery mode: when `databaseCorrupted` flag is true, renders a separate `MaterialApp` with `DatabaseRecoveryScreen` instead of the router tree (`lib/app.dart:111-117`)
- `ErrorWidget.builder` replaced with `AppErrorScreen` in release mode (`lib/core/bootstrap/bootstrap.dart:75-78`)
- Sentry PII scrubbing: only Supabase UUID attached, no email/IP (`lib/core/bootstrap/bootstrap.dart:179-188`)
- Sync engine has quarantine mechanism for corrupt/conflicting objects (`lib/core/services/sync_engine.dart:279-306`)
- `ActiveWorkoutNotifier.finishWorkout()` has try-catch wrapping the entire transaction; returns empty PR list on failure (`lib/features/workout/presentation/providers/active_workout_provider.dart:255-257`)

## Key Abstractions

**`ActiveWorkoutState` (Freezed):**
- Purpose: In-memory representation of a workout session in progress
- Location: `lib/features/workout/domain/active_workout_state.dart`
- Sub-models: `WorkoutSetState`, `WorkoutExerciseState`
- Pattern: Immutable Freezed data classes with `copyWith` mutations

**`HydratedWorkout` / `HydratedRoutine`:**
- Purpose: Enriched DB models with resolved exercise names, metadata, and previous-set data
- Location: `lib/core/database/daos/workouts_dao.dart`, `lib/core/database/daos/routines_dao.dart`
- Pattern: Data classes (not Freezed) constructed by DAO join queries

**`SyncEngine`:**
- Purpose: "Local source of truth, cloud mirror" — manages outbox queue, push/pull, conflict resolution, quarantine
- Location: `lib/core/services/sync_engine.dart`
- Pattern: Singleton provider with stream-based status reporting
- Remote transport: `SupabaseSyncRemote` implementing `SyncRemote` abstract class (`lib/core/services/sync_remote.dart`)

**`SyncEntitlementGate`:**
- Purpose: Controls whether sync is allowed (free tier may sync, gated by feature flag)
- Location: `lib/core/services/sync_entitlement_gate.dart`

**Theme System:**
- 6 user-selectable accent palettes (Volt, Purple, White, Cyan, Magenta, Orange) defined as `ThemePalette` enum (`lib/core/theme/theme_palette.dart`)
- `DynamicAccentNotifier` manages active palette, persisted to SharedPreferences
- `AccentColors` is a `ThemeExtension` registered on `ThemeData`, readable via `context.accent.base`/`.light`/`.onAccent` etc.
- Surfaces and text follow a dark AMOLED hierarchy (4 surface levels) with optional light surface tokens for White palette (`lib/core/theme/app_colors.dart`)
- Chrome tokens for nav bar, active workout bar, and sheet backgrounds (`lib/core/theme/chrome_tokens.dart`)

## Entry Points

**`main.dart`:**
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: Calls `Bootstrap.run()`, which does staged startup → runs `runApp(ProviderScope(... GymLogApp ...))`

**`GymLogApp`:**
- Location: `lib/app.dart`
- Responsibilities: Root `ConsumerStatefulWidget`; wires auth lifecycle listeners, sync engine init, Sentry error capture; renders `MaterialApp.router` with reactive theme

**`Bootstrap.run()`:**
- Location: `lib/core/bootstrap/bootstrap.dart:68`
- Responsibilities: Flutter binding, image cache bounds, Sentry init, accent palette load, DB open + integrity check, post-frame cloud init + commerce + maintenance

## Architectural Constraints

- **Threading:** Single-threaded (Dart isolates not used beyond Drift's internal `NativeDatabase.createInBackground` for DB I/O)
- **Global state:** `Supabase.instance.client` and `SharedPreferences` instance are module-level singletons; Drift `AppDatabase` is overridden via provider
- **Circular imports:** None detected — feature modules never import other features' internals; cross-feature communication goes through `core/` providers
- **Cross-feature dependency rule:** Features must not import each other's internals — all cross-feature dependencies route through `core/` providers or `databaseProvider`

## Anti-Patterns

### Object passing via `state.extra` in GoRouter

**What happens:** `/exercise/detail/:id` passes the full `Exercise` object via `state.extra as Exercise?` (`lib/core/router/router.dart:121`)
**Why it's wrong:** Architecture directive says pass IDs only — `state.extra` bypasses type safety and can cause null errors
**Do this instead:** Fetch from the DB by path parameter `id` using `exerciseCatalogByIdProvider` or similar

### `Navigator.push` instead of `context.push` for Exercise Selection

**What happens:** `ExerciseSelectionScreen` is launched via `Navigator.push<Exercise>` from `ActiveWorkoutScreen` (returns selected exercise as pop result) per `lib/core/router/router.dart:111`
**Why it's wrong:** Should use `context.push` per architecture directive — using raw Navigator bypasses GoRouter's route hierarchy
**Do this instead:** Use `context.push('/exercises/select')` and pass result via query parameter or shared provider

### Manual `@freezed` vs code-gen inconsistency

**What happens:** Some models use `@freezed` with manual serialization (e.g., `WorkoutDraftStore` has hand-written `_setToJson`/`_setFromJson` for Freezed models) (`lib/core/services/workout_draft_store.dart:239-290`)
**Why it's wrong:** Freezed can generate `toJson`/`fromJson` when combined with `json_serializable` — manual duplication is error-prone maintenance
**Do this instead:** Add `json_serializable` to Freezed models and use the generated serialization

## Cross-Cutting Concerns

**Logging:** `debugPrint()` only — no structured logging framework. Sentry captures errors in production.
**Validation:** No centralized validation layer — field validation is ad-hoc in widgets and providers. Drift type system enforces DB constraints.
**Authentication:** Provider hierarchy: `authRepositoryProvider` → `authStateProvider` → `authProvider`. GoRouter redirect guard. Sync engine auth checks on every push/pull.
**Analytics/Telemetry:** Sentry for crash reporting (release 0.1 sample rate). RevenueCat for purchase analytics. No custom analytics events.

---

*Architecture analysis: 2026-07-29*
