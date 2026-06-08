# GymLog Architecture Context (context7)
*Last Updated: 2026-05-23 17:58 UTC+05:30*

## 1. Tech Stack & Environment
- **Framework:** Flutter (Web/Mobile)
- **State Management:** Riverpod (Code Generation via `@riverpod` annotation)
- **Local DB:** Drift (SQLite) + `NativeDatabase.createInBackground` via `path_provider`
- **Backend Auth:** Supabase (Native Google Sign-In via `google_sign_in` package)
- **Routing:** GoRouter (Path Strategy via `flutter_web_plugins`)
- **UI Libraries:** Google Fonts, Custom Theme (`AppColors` + `app_theme.dart`), `fl_chart` (analytics charts), `intl` (date formatting), `cached_network_image`, `gif_view`

## 2. Database Schema (Drift)

### Tables
- **`UserProfiles`** — `id` (PK), `email`, `displayName`, `isPremium`, `premiumExpiry`, `weightUnit`, `defaultRestSeconds`, `createdAt`
- **`Exercises`** — `id` (PK, autoIncrement), `exerciseDbId` (unique), `name`, `bodyPart`, `equipment`, `target`, `gifUrl`, `secondaryMuscles`, `instructions`, `isCustom`, `createdBy`, `seededAt`
- **`Routines`** — `id` (PK, UUID), `userId`, `name`, `notes`, `createdAt`, `updatedAt`
- **`RoutineDays`** — `id` (PK, UUID), `routineId` (FK → Routines), `name`, `orderIndex`
- **`RoutineExercises`** — `id` (PK, UUID), `routineDayId` (FK → RoutineDays), `exerciseId` (FK → Exercises), `orderIndex`, `defaultSets`, `defaultReps`, `defaultWeightKg`, `restSeconds`
- **`WorkoutSessions`** — `id` (PK, UUID), `userId`, `routineId`, `name`, `startedAt`, `endedAt`, `notes`, `totalVolumeKg`, `synced`
- **`WorkoutExercises`** — `id` (PK, UUID), `sessionId` (FK → WorkoutSessions), `exerciseId` (FK → Exercises), `orderIndex`, `notes`
- **`WorkoutSets`** — `id` (PK, UUID), `workoutExerciseId` (FK → WorkoutExercises), `exerciseId`, `orderIndex`, `setType`, `weightKg`, `reps`, `rpe`, `isPr`, `estimated1rm`, `completedAt`

### Database Connection (`database.dart`)
- Removed broken `drift_flutter` dependency (caused Windows build failures).
- `_openConnection()` uses `LazyDatabase` + `NativeDatabase.createInBackground(File(...))` via `path_provider`.
- Works on Android, iOS, macOS, Windows, Linux. Web uses standard Drift web worker (if configured).

### DAOs

#### `ExercisesDao`
- `getAllExercises`, `getExerciseById`, `searchExercises`, `filterByBodyPart`, `filterByEquipment`
- `insertExercise`, `insertExercises` (batch with `InsertMode.insertOrIgnore`)
- **`hydrateFromJson()`** — One-time bulk seed from `assets/db/exercises.json`. Two-phase: (1) UPDATE patches stale `gifUrl`s on existing rows, (2) `INSERT OR IGNORE` adds new rows. Guarded by SharedPreferences flag (`exercises_hydrated_v2`). Chunks inserts in batches of 100.
- **`resetHydration()`** — Debug utility to clear the hydration flag so `hydrateFromJson()` re-runs on next launch.
- **`seedDefaultExercises()`** — Fallback: inserts 10 hardcoded fundamental exercises only when JSON hydration fails or DB is empty.

#### `WorkoutsDao`
- Standard CRUD: `getSession`, `getSessionsForUser`, `insertSession`, `updateSession`, `deleteSession`
- `getExercisesForSession`, `insertWorkoutExercise`, `deleteWorkoutExercise`
- `getSetsForExercise`, `insertSet`, `updateSet`, `deleteSet`
- **`getExerciseHistory(int exerciseId)`** / **`watchExerciseHistory(int exerciseId)`** — Raw SQL join across `workout_sets` + `workout_exercises` + `workout_sessions`. Returns `List<ExerciseHistoryData>` (date, weight, reps, estimated1RM via Epley formula, volume). Both sync and stream variants.
- **`getPreviousSessionSets(int exerciseId, String currentSessionId)`** — Returns the ordered `List<WorkoutSet>` from the most recent *other* completed session for the given exercise. Two-step bounded query (not N+1): (1) find latest prior `session_id` via raw SQL JOIN with `LIMIT 1`; (2) fetch its `workout_exercise` row then its sets. Returns `[]` on first appearance — callers hide the "VS PREV" column in that case.
- **`getHydratedWorkout(String sessionId)`** / **`watchHydratedWorkout(String sessionId)`** — Fetches session → exercises → sets + exercise metadata + `previousSets` (via `getPreviousSessionSets`). Returns `HydratedWorkout` with nested `HydratedWorkoutExercise` objects.
- **`getSessionPreviewsForUser(userId, limit, offset)`** — Paginated denormalized session summaries for HomeScreen infinite scroll. Returns `List<WorkoutSessionPreview>` with duration, total volume, PR count, top 2 exercises with GIFs, and total exercise count.
- **`detectAndMarkPrs(sessionId, sessionStart)`** — Marks the best Epley 1RM set per exercise as a PR if it exceeds historical max before that session. Uses `estimated1rm = weight × (1 + reps / 30)`.
- **`watchWorkoutCountForUser(userId)`** — Reactive stream of completed session count.

#### `RoutinesDao`
- Standard CRUD: `getRoutinesForUser`, `getRoutine`, `insertRoutine`, `updateRoutine`, `deleteRoutine`
- `getDaysForRoutine`, `insertDay`, `deleteDay`
- `getExercisesForDay`, `insertRoutineExercise`, `deleteRoutineExercise`
- **`watchHydratedRoutinesForUser(userId)`** — Reactive stream of `List<HydratedRoutine>` with resolved exercise names/IDs.
- **`watchHydratedRoutine(routineId)`** — Reactive single-routine detail with resolved exercises.
- **`saveWorkoutAsRoutine(userId, routineName, exerciseIds)`** — Transaction: creates `Routine` → `RoutineDay` ("Day 1") → `RoutineExercise` rows for each exercise ID.

#### `UserDao`
- `getUser`, `insertUser`, `updateUser`, `deleteUser`
- `watchUser(userId)` — Reactive stream of user profile row.

## 3. Global State (Riverpod)

| Provider | Type | autoDispose | Data Held |
|---|---|---|---|
| `authRepositoryProvider` | `Provider<AuthRepository>` | No | Singleton auth repository wrapping `SupabaseClient` |
| `authStateProvider` | `StreamProvider<AuthState>` | No | Real-time Supabase auth state stream |
| `authProvider` | `Provider<User?>` | No | Current signed-in user (or `null`). Extension `AuthProviderX.isSignedIn` |
| `databaseProvider` | `Provider<AppDatabase>` | No | Singleton Drift database instance (overridden in `main.dart`) |
| `routerProvider` | `Provider<GoRouter>` | No | GoRouter with `_GoRouterRefreshStream` wired to Supabase auth state |
| `activeWorkoutProvider` | `StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>` | No | In-memory active workout state (exercises, sets, start time, volume) |
| `workoutTimerProvider` | `@riverpod class WorkoutTimer` | Yes (generated) | Formatted elapsed time string (`HH:MM:SS`) derived from `activeWorkoutProvider` |
| `exerciseListProvider` | `@riverpod class ExerciseList` | Yes (generated) | `AsyncValue<List<Exercise>>` with `search(String query)` method |
| `exerciseAnalyticsProvider` | `StreamProvider.family<List<ExerciseHistoryData>, int>` | No | **Reactive** historical set data for a specific `exerciseId` via `WorkoutsDao.watchExerciseHistory()` |
| `workoutDetailProvider` | `StreamProvider.family<HydratedWorkout?, String>` | No | **Reactive** fully hydrated workout for a given `sessionId` |
| `workoutHistoryProvider` | `StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>` | No | Paginated workout history (page size 10). `fetchNextPage()` appends. Auto-resets when `workoutCompletedSignalProvider` increments |
| `workoutCompletedSignalProvider` | `StateProvider<int>` | No | Incremented by `ActiveWorkoutNotifier.finishWorkout()` to signal HomeScreen to reset pagination |
| `hydratedRoutinesProvider` | `StreamProvider<List<HydratedRoutine>>` | No | Reactive list of all user routines with resolved exercise names |
| `routineDetailProvider` | `StreamProvider.family<HydratedRoutine?, String>` | No | Reactive single-routine detail keyed by `routineId` |
| `workoutCountProvider` | `StreamProvider<int>` | No | Live count of completed sessions for current user |
| `currentUserProfileProvider` | `StreamProvider<UserProfile?>` | No | Live profile row for current user from local DB |
| `gifLastFrameProvider` | `FutureProvider.family<MemoryImage?, String>` | No | Decodes last frame of exercise GIF from cache for static preview |

### ActiveWorkoutNotifier Methods
- `startWorkout({routineId, initialExercises})`
- `finishWorkout()` → persists session/exercises/sets to Drift, **strips phantom exercises** (zero completed sets), runs PR detection, increments `workoutCompletedSignalProvider`, then clears state
- `discardWorkout()` → clears state without persisting
- `addExercise(exerciseId, name)`
- `addSet(exerciseIndex)`
- `updateSet(exerciseIndex, setIndex, {weight, reps, type})`
- `toggleSetCompletion(exerciseIndex, setIndex)`
- `replaceExercise(exerciseIndex, exerciseId, name)` → swaps exercise at index, resets sets
- `removeExercise(exerciseIndex)` → removes exercise from list

**Duration Validation (UI layer — `ActiveWorkoutScreen._finish()`):**
Before calling `finishWorkout()`, if `completedSets >= 10 && durationMinutes < 5`, an `AlertDialog` is shown with:
- Title: `"Short Workout"`
- Body: `"This workout was very short. Are you sure ?"`
- Actions: `"Go Back"` (cancels) / `"Finish Anyway"` (proceeds)
This rule flags physically implausible sessions (e.g., timer not started). Validation lives in the UI layer — the Notifier remains pure business logic.

### WorkoutHistoryNotifier Methods
- `_loadPage(offset, {replace})` — fetches `pageSize + 1` to detect `hasMore`
- `fetchNextPage()` — appends next page. No-op if loading or no more pages
- `_reset()` — called when `workoutCompletedSignalProvider` changes; clears and reloads from page 0

## 4. Navigation Map

| Route | Screen | Notes |
|---|---|---|
| `/splash` | `SplashScreen` | 2-second delay, then navigates based on auth state |
| `/onboarding` | `OnboardingScreen` | First-time user onboarding flow |
| `/auth` | `AuthScreen` | Native Google Sign-In (mobile) / web OAuth (web) |
| `/` | `HomeScreen` | Dashboard inside `AppShell`; paginated workout history feed via `workoutHistoryProvider` |
| `/workout` | `WorkoutScreen` | Routines list inside `AppShell` (tab renamed to "Routines") |
| `/profile` | `ProfileScreen` | User profile inside `AppShell` |
| `/exercises/select` | `ExerciseSelectionScreen` | Searchable exercise picker; returns `Exercise` via `Navigator.pop` |
| `/exercise/detail` | `ExerciseDetailScreen` | Analytics view with `fl_chart` line chart, stat toggles, time-range filter, and live PRs; receives `Exercise` via `state.extra` |
| `/routines/edit` | `RoutineEditorScreen` | Routine builder screen |
| `/routines/:id` | `RoutineDetailScreen` | Routine detail view with exercises |
| `/workout/active` | `ActiveWorkoutScreen` | Fullscreen dialog; live timer, editable sets, finish/discard, "+ Add Exercise" wired to exercise picker |
| `/workout/detail/:id` | `WorkoutDetailScreen` | Hevy-clone historical workout view; stats header (time/volume/sets), exercise blocks with set tables; bottom sheet with Save/Copy/Edit/Delete |

### ShellRoute
All routes except `/splash`, `/onboarding`, `/auth`, `/exercises/select`, `/exercise/detail`, `/routines/edit`, `/workout/active`, `/workout/detail/:id`, and `/routines/:id` are wrapped in `AppShell` (bottom navigation: Home / Routines / Profile).

### Router Refresh Logic
- `_GoRouterRefreshStream` wraps `Supabase.instance.client.auth.onAuthStateChange` as a `ChangeNotifier` so GoRouter re-evaluates redirects on login/logout.

## 5. Changelog / Latest Upgrade

### Previous State
Basic Flutter app with Drift database schema, Supabase auth stub, a broken SplashScreen (deadlock), OAuth redirect loops on web, and unoptimized UI widgets scattered with missing `const` constructors.

### Track 1–4: Foundation & UI Polish
- **Startup Pipeline Hardened:** `main.dart` now follows strict async sequence: Flutter bindings → URL strategy → dotenv → Supabase → Drift warm-up query + seed → run app.
- **OAuth Redirect Fixed:** `signInWithGoogle` uses `kIsWeb` to set `redirectTo` to `http://127.0.0.1:8080/` on web, `gymlog://auth-callback` on mobile.
- **SplashScreen Fixed:** Converted to `ConsumerStatefulWidget` with a 2-second `Future.delayed`, then navigates via GoRouter based on auth state.
- **Router Redirect Logic:** Splash and onboarding bypass redirect entirely; auth/unauth redirects are loop-free.
- **Timer Memory Leak Fixed:** `workoutTimerProvider` now calls `ref.onDispose(() => _timer?.cancel())`.
- **UI Const Optimizations:** Applied `const` to static `Icon`, `SizedBox`, `EdgeInsets`, `BoxDecoration`, and `SnackBar` widgets across `active_workout_screen.dart` and `exercise_block.dart`.
- **Double Plus Sign Removed:** `WorkoutScreen` button label now reads `"Start Empty Workout"` (icon provides the `+`).
- **PREVIOUS Text Wrap Fixed:** Wrapped `Text('PREVIOUS')` in `FittedBox(fit: BoxFit.scaleDown)`.
- **TextField Cursor Jump Fixed:** `SetRow.didUpdateWidget` now updates controller text via `controller.value.copyWith(text: ..., selection: TextSelection.collapsed(offset: newText.length))` to preserve cursor position and prevent reversed typing.

### Track 5: Exercise Library & Selection Flow
- **Database Seeding:** `ExercisesDao.seedDefaultExercises()` batch-inserts 10 fundamental exercises (Bench Press, Squat, Deadlift, Pull-up, OHP, Lateral Raise, Tricep Pushdown, Bicep Curl, Leg Press, RDL) with body part, equipment, and target muscle metadata. Called from `main.dart` after Drift warm-up.
- **Exercise Provider:** `@riverpod class ExerciseList` — `AsyncNotifier` fetching all exercises on build, with `search(String query)` delegating to `ExercisesDao.searchExercises()`.
- **Exercise Selection Screen:** `ExerciseSelectionScreen` — search bar with `Icons.search`, `ListView.builder` rendering `ListTile` items (name + `target • equipment` subtitle), `Navigator.pop(context, exercise)` on tap.
- **Workout Integration:** "+ Add Exercise" button in `ActiveWorkoutScreen` pushes `ExerciseSelectionScreen`, awaits the selected `Exercise`, and calls `notifier.addExercise(selected.id, selected.name)`.
- **New Route:** `/exercises/select` → `ExerciseSelectionScreen` added to GoRouter.

### Track 6: Exercise Detail Screen (Hevy Clone Analytics)
- **Exercise Detail Screen:** `ExerciseDetailScreen` — `Scaffold` with `ListView` containing: media placeholder (grey container + `Icons.image`), exercise name + `target • equipment` metadata, `LineChart` from `fl_chart` with 6 mock data points (gradient fill, hidden top/right axes, touch tooltips), horizontal pill-shaped stat toggles ("Heaviest Weight" active, "One Rep Max", "Best Set", "Best Volume"), and "Personal Records" section with trophy icon and 4 hardcoded PR rows.
- **Route:** `/exercise/detail` → `ExerciseDetailScreen` using `state.extra as Exercise` to receive the Drift object.
- **Navigation Trigger:** Exercise name in `ExerciseBlock` wrapped in `GestureDetector` — on tap pushes `/exercise/detail` with `extra: driftExercise`.

### Track 7: Global Action Wiring & Data Pipeline
- **Router Fix:** Added `/routines/edit` → `RoutineEditorScreen` stub route.
- **Home Screen "Start Empty Workout":** Now calls `ref.read(activeWorkoutProvider.notifier).startWorkout()` then `context.push('/workout/active')`.
- **ExerciseBlock Menu Actions:** Replace navigates to `ExerciseSelectionScreen`, returns selected exercise, calls `notifier.replaceExercise()`. Remove calls `notifier.removeExercise(index)`.
- **ActiveWorkoutNotifier:** Added `replaceExercise(int exerciseIndex, int exerciseId, String name)` and `removeExercise(int exerciseIndex)` methods.
- **Finish Button:** `_finish()` awaits `finishWorkout()` then calls `context.go('/')` to return to dashboard.
- **Home Screen Recent Activity:** Created `recentWorkoutsProvider` (`FutureProvider` fetching last 5 sessions via `WorkoutsDao.getSessionsForUser`). Replaced static placeholders with dynamic `.when()` pattern showing session name, formatted date, and total volume.

### Track 7.5: State Invalidation & Routing Bug Fixes
- **Tab Renaming:** Bottom nav second tab label changed from "Workout" → "Routines". `WorkoutScreen` AppBar title changed to "Routines". Removed redundant "Start Empty Workout" button from `WorkoutScreen`.
- **Routine Card 3-Dots Menu:** Replaced static `more_vert` icon with `PopupMenuButton<_RoutineAction>` containing "Edit" and "Delete" items with `switch` statement placeholders.
- **Null-safe Exercise Routing:** Replaced `exerciseMap[exercise.exerciseId]` (could return `null` before async load) with `exerciseList.firstWhere((e) => e.id == exercise.exerciseId, orElse: ...)` that constructs a valid `Exercise` fallback with `isCustom: false`.
- **Cache Invalidation:** Added `_ref.invalidate(recentWorkoutsProvider)` at end of `finishWorkout()` before `state = null`, forcing Home Screen to re-fetch fresh data after every workout save.

### Track 8: Analytics Data Injection (Live History)
- **Exercise Analytics Provider:** `exerciseAnalyticsProvider(exerciseId)` — `FutureProvider` calling `WorkoutsDao.getExerciseHistory(exerciseId)`, a raw SQL join across `workout_sets` + `workout_exercises` + `workout_sessions` returning `List<ExerciseHistoryData>` with date, weight, reps, estimated 1RM, and volume.
- **Live Chart Data:** `ExerciseDetailScreen` now consumes `exerciseAnalyticsProvider` via `ref.watch`. Chart `FlSpot` points mapped from real history (`index → FlSpot(i, metric)`). Stat toggles recompute chart on tap. PR section calculates max weight, 1RM, volume, and reps from live data.

### Track 8.5: Production UI Hardening & Historical Hydration
- **Mobile UI First-Principles:**
  - `AppShell` body wrapped in `Center` + `ConstrainedBox(maxWidth: 600)` for infinite-canvas mobile viewport.
  - `SetRow` checkmark hit-box expanded to 48×48 (fat finger), set type indicator height made flexible (rubber band fix).
  - `HomeScreen` and `WorkoutScreen` `SingleChildScrollView` padding extended to `bottom: 120` for nav bar clearance.
  - Rest timer row commented out in `exercise_block.dart`.
  - "Recent Activity" renamed to "Workout History" in `home_screen.dart`.
- **Hydrated Workout DAO:** `WorkoutsDao.getHydratedWorkout(sessionId)` fetches session → exercises → sets + exercise metadata. `HydratedWorkout` contains `WorkoutSession` + `List<HydratedWorkoutExercise>`, each holding `WorkoutExercise`, `Exercise`, and `List<WorkoutSet>` (native Drift data classes).
- **Workout Detail Provider:** `workoutDetailProvider(sessionId)` — `FutureProvider<HydratedWorkout?>` wrapping `getHydratedWorkout`.
- **Workout Detail Screen (Hevy Clone):** `/workout/detail/:id` — `SafeArea` + `ListView.builder` with stats header (time/volume/sets), exercise blocks with icon + name + equipment, set table (SET | WEIGHT & REPS), and `bottom: 120` padding.
- **Navigation Wiring:** Home screen history cards wrapped in `InkWell` → `context.push('/workout/detail/${session.id}')`. Routine card "Edit" menu item → `context.push('/routines/edit', extra: {'name', 'exercises'})`.

### Track 8.75: Premium UI Polish & Interactive Analytics
- **Advanced Chart Mechanics (`fl_chart` Overhaul):**
  - X-axis titles display formatted dates via `intl` (`DateFormat('MMM d')` → "Apr 15"), spaced with `_bottomLabelInterval()` to prevent crowding (max 4–5 labels).
  - Y-axis titles display weight with unit (`"X kg"`).
  - Touch tooltips show `"weight kg \n date"` with vertical dashed indicator line + dot highlight via `getTouchedSpotIndicator`.
  - Grid: horizontal lines only, subtle low-opacity grey.
- **Time Filter Engine:**
  - `_selectedTimeRange` state variable with options: 1M, 3M, 6M, 1Y, All Time.
  - `_filteredHistory()` applies date-based filtering before chart and PR rendering.
  - UI: `PopupMenuButton<String>` with rounded shape, active option highlighted in accent color.
- **Premium Bottom Sheets (3-Dots Fix):**
  - `WorkoutDetailScreen` AppBar `PopupMenuButton` replaced with `IconButton(Icons.more_horiz)` → `showModalBottomSheet`.
  - Bottom sheet: transparent background, `BorderRadius.vertical(top: Radius.circular(20))`, grey drag-handle pill, 4 `ListTile` action rows (Save as Routine / Copy / Edit / Delete) with icons and destructive red styling for Delete.
  - All `onTap` callbacks are `// TODO` stubs.

### Track 8.9: Full System Overhaul — Persistence, Reactivity, Routing, UI Unification
- **Reactive Streams Migration:** Converted `exerciseAnalyticsProvider` and `workoutDetailProvider` from `FutureProvider` to **`StreamProvider.family`** for real-time UI updates when underlying data changes.
- **HomeScreen Pagination:** Replaced `recentWorkoutsProvider` with `workoutHistoryProvider` (`StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>`). Implements infinite scroll with 10-item page size. `fetchNextPage()` appends. Auto-resets to page 1 via `workoutCompletedSignalProvider` when a new workout is saved.
- **WorkoutSessionPreview Denormalization:** `WorkoutsDao.getSessionPreviewsForUser()` assembles rich preview objects with duration, volume, PR count, top 2 exercises with GIF URLs, and total exercise count — all in a single paginated query.
- **Routine Hydration:** `RoutinesDao` now has `watchHydratedRoutinesForUser()` and `watchHydratedRoutine(routineId)` that resolve exercise names/IDs reactively.
- **Routines Provider:** `hydratedRoutinesProvider` (StreamProvider) and `routineDetailProvider` (StreamProvider.family) for reactive routine UI.
- **Profile Providers:** `workoutCountProvider` (StreamProvider<int>) and `currentUserProfileProvider` (StreamProvider<UserProfile?>) for live profile data.
- **Save Workout as Routine:** `RoutinesDao.saveWorkoutAsRoutine()` transactional method creates Routine → RoutineDay → RoutineExercises from a list of exercise IDs.
- **PR Detection Engine:** `WorkoutsDao.detectAndMarkPrs(sessionId, sessionStart)` uses Epley formula (`weight × (1 + reps / 30)`) to find and flag the best 1RM set per exercise if it exceeds all prior history.
- **Bottom Sheet Action Wiring:** `WorkoutDetailScreen` "Save as Routine" bottom sheet action now calls `RoutinesDao.saveWorkoutAsRoutine()` with the current session's exercise IDs. "Delete Workout" calls `WorkoutsDao.deleteSession()` with cascading navigation.
- **Unified Bottom Sheets:** `RoutineCard` and `ExerciseBlock` 3-dot menus converted from `PopupMenuButton` to `showModalBottomSheet` with consistent Hevy-style styling (rounded top corners, drag handle, icon + text rows).
- **Workout Naming:** Added `formatters.dart` with `getWorkoutNameFallback(start, existingName)` (Morning/Afternoon/Evening/Night) and `formatWorkoutDuration(start, end)`.
- **Routing Bug Fix (Bench Press Bug):** `ActiveWorkoutScreen` now uses `exerciseList.firstWhere((e) => e.id == exercise.exerciseId, orElse: ...)` with a valid fallback `Exercise` instead of `exerciseMap[exercise.exerciseId]` which could return null and cause wrong exercise routing.
- **Onboarding Screen:** Added `/onboarding` route with `OnboardingScreen` for first-time user experience.
- **Routine Detail Screen:** Added `/routines/:id` → `RoutineDetailScreen` for viewing individual routines.

### Track 8.91: Remove Broken `drift_flutter` — Native SQLite Hardwire
- **Problem:** `drift_flutter` package caused Windows build failures (unresolved `driftWorkerMain` symbol).
- **Solution:** Removed `drift_flutter` from `pubspec.yaml` dependencies.
- **Connection Refactor:** `database.dart` `_openConnection()` now uses `LazyDatabase(() async { ... NativeDatabase.createInBackground(File(...)) })` via `path_provider` and `path` packages. No more conditional web/native logic — `drift/native.dart` handles all platforms.
- **Import Cleanup:** Removed invalid `package:drift_flutter/drift_flutter.dart` and `package:flutter/foundation.dart` imports from `database.dart`.
- **Validation:** `flutter analyze` passes with zero errors from our code (warnings only in generated `.g.dart` files).

### Track 8.92: Native Google Sign-In (Android/iOS)
- **Problem:** Web OAuth flow on mobile opened browser with `localhost:3000` redirect, breaking mobile UX.
- **Solution:** Implemented platform-specific auth in `AuthRepository.signInWithGoogle()`:
  - **Web:** Continues using `signInWithOAuth` with `redirectTo: 'http://127.0.0.1:8080/'`.
  - **Mobile (Android/iOS):** Uses `GoogleSignIn` package → `googleUser.authentication` → `Supabase.auth.signInWithIdToken(provider: google, idToken: ..., accessToken: ...)`.
- **Dependencies:** Added `google_sign_in: ^6.2.0` to `pubspec.yaml`.
- **iOS Deep Linking:** Added `CFBundleURLTypes` to `ios/Runner/Info.plist` with `com.googleusercontent.apps.YOUR_IOS_CLIENT_ID` URL scheme for Google Sign-In callback handling.
- **Server Client ID:** `GoogleSignIn` configured with hardcoded Web Client ID for token exchange with Supabase.
- **Required External Setup (NOT in code):**
  1. Google Cloud Console: Create Android Client ID, iOS Client ID, and Web Client ID.
  2. Supabase Dashboard: Add Web Client ID and Secret to Auth → Providers → Google.
  3. `ios/Runner/Info.plist`: Replace `YOUR_IOS_CLIENT_ID` with reversed iOS Client ID.

## 6. File Architecture

```
lib/
├── main.dart                              # App bootstrap: bindings → dotenv → Supabase → DB warm-up → seed → runApp
├── app.dart                               # GymLogApp widget with ProviderScope
├── core/
│   ├── database/
│   │   ├── database.dart                  # AppDatabase + NativeDatabase connection
│   │   ├── tables/                        # Drift table definitions (8 tables)
│   │   └── daos/
│   │       ├── exercises_dao.dart         # Exercise queries + JSON hydration engine
│   │       ├── workouts_dao.dart          # Workout CRUD + history + hydration + PRs + pagination
│   │       ├── routines_dao.dart          # Routine CRUD + hydrated routines + saveWorkoutAsRoutine
│   │       └── user_dao.dart              # User profile queries
│   ├── providers/
│   │   └── database_provider.dart         # Riverpod Provider<AppDatabase>
│   ├── router/
│   │   └── router.dart                    # GoRouter with auth-aware redirects + _GoRouterRefreshStream
│   ├── theme/
│   │   ├── app_theme.dart                 # Material 3 theme with custom colors
│   │   └── app_colors.dart                # Color constants
│   └── utils/
│       └── formatters.dart                # formatWorkoutDuration, getWorkoutNameFallback
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart       # signInWithGoogle (native + web), signOut
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart     # authRepositoryProvider, authStateProvider, authProvider
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           ├── auth_screen.dart
│   │           └── onboarding_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── home_provider.dart       # workoutHistoryProvider, workoutCompletedSignalProvider
│   │       └── screens/
│   │           └── home_screen.dart         # Dashboard with paginated workout history
│   ├── workout/
│   │   ├── domain/
│   │   │   └── active_workout_state.dart    # ActiveWorkoutState, WorkoutExerciseState, WorkoutSetState
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── active_workout_provider.dart    # ActiveWorkoutNotifier
│   │       │   ├── workout_timer_provider.dart     # @riverpod WorkoutTimer
│   │       │   └── workout_detail_provider.dart    # StreamProvider.family<HydratedWorkout?>
│   │       ├── screens/
│   │       │   ├── workout_screen.dart
│   │       │   ├── active_workout_screen.dart
│   │       │   └── workout_detail_screen.dart
│   │       └── widgets/
│   │           ├── set_row.dart
│   │           └── exercise_block.dart
│   ├── exercises/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── exercises_provider.dart         # @riverpod ExerciseList
│   │       │   └── exercise_analytics_provider.dart # StreamProvider.family for history
│   │       └── screens/
│   │           ├── exercise_selection_screen.dart
│   │           └── exercise_detail_screen.dart
│   ├── routines/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── routines_provider.dart          # hydratedRoutinesProvider, routineDetailProvider
│   │       ├── screens/
│   │       │   ├── routine_editor_screen.dart
│   │       │   └── routine_detail_screen.dart
│   │       └── widgets/
│   │           └── routine_card.dart
│   └── profile/
│       └── presentation/
│           ├── providers/
│           │   └── profile_provider.dart           # workoutCountProvider, currentUserProfileProvider
│           └── screens/
│               └── profile_screen.dart
└── shared/
    ├── widgets/
    │   └── app_shell.dart                   # Bottom nav shell with Center + ConstrainedBox(600)
    └── providers/
        └── gif_last_frame_provider.dart     # FutureProvider.family for GIF last-frame extraction
```

## 7. Data Flow Patterns

### Workout Creation Flow
1. User taps "Start Empty Workout" → `activeWorkoutNotifier.startWorkout()`
2. User adds exercises via `ExerciseSelectionScreen` → `addExercise(id, name)`
3. User logs sets → `updateSet()` / `toggleSetCompletion()`
4. User taps Finish → `finishWorkout()`:
   - Calculates total volume from completed sets
   - Inserts `WorkoutSession` → `WorkoutExercise` rows → `WorkoutSet` rows (only completed sets)
   - Strips phantom exercises (zero completed sets)
   - Runs `detectAndMarkPrs()` to flag PRs
   - Increments `workoutCompletedSignalProvider`
   - Clears `activeWorkoutProvider` state
5. `workoutHistoryProvider` auto-resets and reloads page 1
6. `HomeScreen` displays the new session in the feed

### Exercise Analytics Flow
1. User taps exercise name in `ActiveWorkoutScreen` or `ExerciseBlock`
2. `context.push('/exercise/detail', extra: exercise)`
3. `ExerciseDetailScreen` watches `exerciseAnalyticsProvider(exerciseId)`
4. `WorkoutsDao.watchExerciseHistory()` streams raw SQL join results
5. Screen maps to `FlSpot` points, renders `LineChart` with date axes
6. Time filter and stat toggles recompute displayed data reactively

### Routine Creation Flow (from Workout)
1. User views workout detail → taps 3-dot menu → "Save as Routine"
2. Bottom sheet calls `RoutinesDao.saveWorkoutAsRoutine(userId, name, exerciseIds)`
3. Transaction: `Routine` → `RoutineDay` ("Day 1") → `RoutineExercise` rows
4. `hydratedRoutinesProvider` stream updates → `WorkoutScreen` re-renders

## 8. Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Framework |
| `drift` | ^2.18.0 | ORM / SQLite |
| `sqlite3_flutter_libs` | ^0.5.42 | Native SQLite binaries |
| `flutter_riverpod` | ^2.5.0 | State management |
| `go_router` | ^14.0.0 | Navigation |
| `supabase_flutter` | ^2.5.0 | Backend auth |
| `google_sign_in` | ^6.2.0 | Native Google auth (mobile) |
| `flutter_secure_storage` | ^9.0.0 | Secure token storage |
| `fl_chart` | ^0.68.0 | Analytics charts |
| `cached_network_image` | ^3.3.0 | Exercise GIF caching |
| `gif_view` | ^0.4.0 | GIF animation display |
| `google_fonts` | ^6.2.0 | Typography |
| `intl` | ^0.19.0 | Date/number formatting |
| `uuid` | ^4.4.0 | UUID generation |
| `path_provider` | ^2.1.0 | App documents directory for DB |
| `path` | ^1.9.1 | Path joining |
| `shared_preferences` | ^2.2.0 | Hydration flags |
| `flutter_dotenv` | ^6.0.1 | Environment variables |

### Track 9: Workout Log V2 — VS PREV, Header Layering, Duration Validation
- **VS PREV (Cross-Session):** `WorkoutsDao.getPreviousSessionSets(exerciseId, currentSessionId)` — two-step bounded query returning the ordered sets from the most recent prior completed session. `HydratedWorkoutExercise` gains a `previousSets: List<WorkoutSet>` field (default `[]`). `getHydratedWorkout` populates it for every exercise in the loop.
- **Detail Screen VS PREV Wiring:** `_DetailExerciseCard` reads `hydratedExercise.previousSets`. Column is hidden entirely when `previousSets.isEmpty` (first-ever appearance). Each `_DetailSetRow` receives `prevSet: previousSets[idx]` (or null if prior session had fewer sets) and computes `_crossSessionDelta = set.weightKg - prevSet.weightKg`. Null delta renders a `—` dash; non-null renders `_DeltaChip`.
- **Header Scroll Layering Fix:** `SliverAppBar` gains `forceElevated: true` + `scrolledUnderElevation: 0.8`. Prevents list content from bleeding through the pinned bar. A subtle depth cue appears when the bar is fully collapsed.
- **Duration Validation Update:** `ActiveWorkoutScreen._finish()` threshold changed to `completedSets >= 10 && durationMinutes < 5`. Alert body now reads exactly `"This workout was very short. Are you sure ?"` per spec. Validation remains in the UI layer.

## 9. Pending / Next Steps
- **Google Cloud Console Setup:** Create Android/iOS/Web OAuth Client IDs and configure Supabase Auth provider.
- **iOS URL Scheme:** Replace `YOUR_IOS_CLIENT_ID` placeholder in `Info.plist` with reversed iOS Client ID.
- **ExerciseDB JSON Hydration:** Verify `assets/db/exercises.json` exists and contains valid ExerciseDB data. `main.dart` currently calls `resetHydration()` — remove this call after one successful re-run.
- **Routine Detail Screen:** Wire editing capabilities (add/remove exercises, reorder days).
- **Workout Edit/Copy:** Implement "Edit Workout" and "Copy Workout" bottom sheet actions in `WorkoutDetailScreen`.
- **Premium Features:** Gate analytics charts and advanced stats behind `isPremium` check.
- **Offline Sync:** Implement `synced` flag on `WorkoutSessions` for eventual cloud sync.
- **Weight Unit Toggle:** Support lbs/kg conversion across all weight inputs and displays.
