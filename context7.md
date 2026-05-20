# GymLog Architecture Context (context7)
*Last Updated: 2026-05-19 16:27 UTC+05:30*

## 1. Tech Stack & Environment
- **Framework:** Flutter (Web/Mobile)
- **State Management:** Riverpod (Code Generation via `@riverpod` annotation)
- **Local DB:** Drift (SQLite) + WebAssembly Workers (`drift_flutter`)
- **Backend Auth:** Supabase (Google OAuth)
- **Routing:** GoRouter (Path Strategy via `flutter_web_plugins`)
- **UI Libraries:** Google Fonts, Custom Theme (`AppColors` + `app_theme.dart`), `fl_chart` (analytics charts), `intl` (date formatting)

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

### DAOs
- **`ExercisesDao`** — `getAllExercises`, `getExerciseById`, `searchExercises`, `filterByBodyPart`, `filterByEquipment`, `insertExercise`, `insertExercises`, `getExerciseCount`, **`seedDefaultExercises`** (batch-inserts 10 fundamental exercises if DB is empty)
- **`WorkoutsDao`** — `getSession`, `getSessionsForUser`, `insertSession`, `updateSession`, `getExercisesForSession`, `insertWorkoutExercise`, `deleteWorkoutExercise`, `getSetsForExercise`, `insertSet`, `updateSet`, `deleteSet`, **`getExerciseHistory(int exerciseId)`** (raw SQL join across `workout_sets` + `workout_exercises` + `workout_sessions`, returns `List<ExerciseHistoryData>` with date/weight/reps/estimated1RM/volume), **`getHydratedWorkout(String sessionId)`** (fetches session → exercises → sets + exercise metadata, returns `HydratedWorkout` with nested `HydratedWorkoutExercise` objects containing `WorkoutExercise`, `Exercise`, and `List<WorkoutSet>`)
- **`RoutinesDao`** — `getRoutinesForUser`, `getRoutine`, `insertRoutine`, `updateRoutine`, `deleteRoutine`, `getDaysForRoutine`, `insertDay`, `deleteDay`, `getExercisesForDay`, `insertRoutineExercise`, `deleteRoutineExercise`
- **`UserDao`** — `getUser`, `insertUser`, `updateUser`, `deleteUser`

## 3. Global State (Riverpod)

| Provider | Type | autoDispose | Data Held |
|---|---|---|---|
| `authRepositoryProvider` | `Provider<AuthRepository>` | No | Singleton auth repository wrapping `SupabaseClient` |
| `authStateProvider` | `StreamProvider<AuthState>` | No | Real-time Supabase auth state stream |
| `authProvider` | `Provider<User?>` | No | Current signed-in user (or `null`) |
| `databaseProvider` | `Provider<AppDatabase>` | No | Singleton Drift database instance |
| `routerProvider` | `Provider<GoRouter>` | No | GoRouter configuration with redirect logic |
| `activeWorkoutProvider` | `StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>` | No | In-memory active workout state (exercises, sets, start time, volume) |
| `workoutTimerProvider` | `@riverpod class WorkoutTimer` | Yes (generated) | Formatted elapsed time string (`HH:MM:SS`) derived from `activeWorkoutProvider` |
| `exerciseListProvider` | `@riverpod class ExerciseList` | Yes (generated) | `AsyncValue<List<Exercise>>` with `search(String query)` method for filtering |
| `exerciseAnalyticsProvider` | `FutureProvider<List<ExerciseHistoryData>>` | No | Historical set data for a specific `exerciseId` via `WorkoutsDao.getExerciseHistory()` |
| `recentWorkoutsProvider` | `FutureProvider<List<WorkoutSession>>` | No | Last 5 workout sessions for current user, sorted by date descending |
| `workoutDetailProvider` | `FutureProvider<HydratedWorkout?>` | No | Fully hydrated workout (session + exercises + sets + exercise metadata) for a given `sessionId` |

### ActiveWorkoutNotifier Methods
- `startWorkout({routineId, initialExercises})`
- `finishWorkout()` → persists session/exercises/sets to Drift, invalidates `recentWorkoutsProvider` cache, then clears state
- `discardWorkout()` → clears state without persisting
- `addExercise(exerciseId, name)`
- `addSet(exerciseIndex)`
- `updateSet(exerciseIndex, setIndex, {weight, reps, type})`
- `toggleSetCompletion(exerciseIndex, setIndex)`
- `replaceExercise(exerciseIndex, exerciseId, name)` → swaps exercise at index, resets sets
- `removeExercise(exerciseIndex)` → removes exercise from list

## 4. Navigation Map

| Route | Screen | Notes |
|---|---|---|
| `/splash` | `SplashScreen` | 2-second delay, then navigates based on auth state |
| `/auth` | `AuthScreen` | Google OAuth sign-in |
| `/` | `HomeScreen` | Dashboard inside `AppShell`; dynamic recent activity feed from `recentWorkoutsProvider` |
| `/workout` | `WorkoutScreen` | Routines list inside `AppShell` (tab renamed to "Routines") |
| `/profile` | `ProfileScreen` | User profile inside `AppShell` |
| `/exercises/select` | `ExerciseSelectionScreen` | Searchable exercise picker; returns `Exercise` via `Navigator.pop` |
| `/exercise/detail` | `ExerciseDetailScreen` | Analytics view with `fl_chart` line chart, stat toggles, time-range filter, and personal records; receives `Exercise` via `state.extra` |
| `/routines/edit` | `RoutineEditorScreen` | Stub routine builder screen; receives optional `{'name', 'exercises'}` via `state.extra` |
| `/workout/active` | `ActiveWorkoutScreen` | Fullscreen dialog; live timer, editable sets, finish/discard, "+ Add Exercise" wired to exercise picker |
| `/workout/detail/:id` | `WorkoutDetailScreen` | Hevy-clone historical workout view; stats header (time/volume/sets), exercise blocks with set tables; 3-dot menu opens `ModalBottomSheet` with Save/Copy/Edit/Delete actions |

### ShellRoute
All routes except `/splash`, `/auth`, `/exercises/select`, `/exercise/detail`, `/routines/edit`, `/workout/active`, and `/workout/detail/:id` are wrapped in `AppShell` (bottom navigation).

## 5. Changelog / Latest Upgrade

### Previous State
Basic Flutter app with Drift database schema, Supabase auth stub, a broken SplashScreen (deadlock), OAuth redirect loops on web, and unoptimized UI widgets scattered with missing `const` constructors.

### Track 1–4: Foundation & UI Polish
- **Startup Pipeline Hardened:** `main.dart` now follows strict async sequence: Flutter bindings → URL strategy → Drift warm-up query + seed → run app.
- **OAuth Redirect Fixed:** `signInWithGoogle` uses `kIsWeb` to set `redirectTo` to `http://127.0.0.1:8080/` on web, `gymlog://auth-callback` on mobile.
- **Drift Web Support:** `_openConnection` uses `driftDatabase` with `DriftWebOptions` pointing to `sqlite3.wasm` and `drift_worker.dart.js`.
- **SplashScreen Fixed:** Converted to `ConsumerStatefulWidget` with a 2-second `Future.delayed`, then navigates via GoRouter based on auth state.
- **Router Redirect Logic:** Splash screen bypasses redirect entirely; auth/unauth redirects are loop-free.
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

### Pending/Next Steps
- **Track 9: ExerciseDB Hydration.** Build a robust JSON asset parser and a Drift batch-insert bootstrapper to safely load 1,500+ real exercises from ExerciseDB on first launch without blocking the UI thread. Replace the 10 seed exercises with the full library.
- **Routine Builder / Routine Detail Screen:** Wire `RoutineCard` tap to a detail screen where users can view/edit days and exercises via `RoutinesDao`.
- **Bottom Sheet Actions:** Implement "Save as Routine", "Copy Workout", "Edit Workout", and "Delete Workout" logic in `WorkoutDetailScreen`.
