# PROGRESS.md

## Fully Implemented

### Auth Flow
- [x] `SplashScreen` — 2s brand screen, resolves auth state → routes to `/auth`, `/onboarding`, or `/`
- [x] `AuthScreen` — Google Sign-In via native `google_sign_in` + Supabase `signInWithIdToken`
- [x] `OnboardingScreen` — first-launch name capture; pre-fills from Google display name; writes `UserProfile` to Drift
- [x] GoRouter auth redirect guard (`_GoRouterRefreshStream` on Supabase auth stream)
- [x] `AuthRepository` (web OAuth path + native path)

### Exercise Library
- [x] JSON hydration from `assets/db/exercises.json` (two-phase UPDATE + INSERT OR IGNORE)
- [x] `ExercisesDao.hydrateFromJson()` with SharedPreferences guard key `exercises_hydrated_v2`
- [x] `ExercisesDao.seedDefaultExercises()` fallback (10 hardcoded exercises)
- [x] `ExerciseSelectionScreen` — search by name, list all, returns selected `Exercise` via `Navigator.pop`
- [x] `ExerciseDetailScreen` — GIF, metadata, analytics chart (fl_chart), time-range filter (1M/3M/6M/1Y/All Time), stat toggles (Heaviest Weight / One Rep Max / Best Set / Best Volume), personal records table, instructions
- [x] `exerciseAnalyticsProvider` — `StreamProvider.family` → `WorkoutsDao.watchExerciseHistory()`
- [x] Epley 1RM formula in `WorkoutsDao.getExerciseHistory()` / `watchExerciseHistory()`
- [x] `ExerciseGifWidget` — `CachedNetworkImage`, disk-persistent, fallback icon, `memCacheWidth: 400`

### Active Workout Session
- [x] `ActiveWorkoutNotifier` — full state machine in memory (Freezed)
- [x] Start empty workout from `HomeScreen`
- [x] Start routine workout from `WorkoutScreen` / `RoutineDetailScreen`
- [x] `ActiveWorkoutScreen` — header with timer + Finish/Discard, `ListView.builder` of `ExerciseBlock`s
- [x] `WorkoutTimerProvider` — live `HH:MM:SS` elapsed timer (1-second `Timer.periodic`)
- [x] `ExerciseBlock` — exercise name (tappable → detail), column headers, set rows, + Add Set footer, 3-dot menu (Replace/Remove)
- [x] `SetRow` — set number display, warmup 'W' indicator, type cycling (normal→warmup→dropset→failure), weight/reps text inputs, completion checkmark with green highlight
- [x] Add exercise to active workout (via `Navigator.push` → `ExerciseSelectionScreen`)
- [x] Replace exercise in active workout
- [x] Remove exercise from active workout
- [x] `finishWorkout()` — persists `WorkoutSession` + `WorkoutExercise` + `WorkoutSet` rows; skips exercises with zero completed sets; computes and stores `totalVolumeKg`
- [x] `discardWorkout()` — clears in-memory state, no DB writes
- [x] Confirm-discard dialog (`AlertDialog`)
- [x] `ActiveWorkoutBar` — persistent purple banner above bottom nav when workout is active; taps to resume

### Workout History
- [x] `workoutHistoryProvider` (`StateNotifierProvider`) — paginated, page size 10, limit+1 hasMore detection; auto-resets via `workoutCompletedSignalProvider` signal after every `finishWorkout()`
- [x] `WorkoutHistoryCard` — exercise GIF thumbnails (52×52), exercise names + set counts, stats row (volume / duration / PRs), `TrackerCard` with tap → detail
- [x] `HomeScreen` — `ListView.builder` infinite scroll feed; pagination trigger at index `N-3`; footer states (loading spinner, empty state, "All caught up")
- [x] PR detection at persist time — `WorkoutsDao.detectAndMarkPrs()`: for each exercise in a session, finds best Epley-1RM set, compares to historical max via `_getMaxEstimated1rmBefore()`, marks `is_pr = true` and writes `estimated_1rm`
- [x] `getSessionPreviewsForUser()` — paginated preview query with stats JOIN and top-2 exercise resolution
- [x] `WorkoutDetailScreen` — stats row (time/volume/sets), per-exercise breakdown with set table, 3-dot actions menu
- [x] `workoutDetailProvider` — `StreamProvider.family` → `WorkoutsDao.watchHydratedWorkout()`
- [x] Save workout as routine (from `WorkoutDetailScreen` actions menu → `RoutinesDao.saveWorkoutAsRoutine()`)
- [x] Delete workout (from `WorkoutDetailScreen` actions menu)
- [x] `formatWorkoutDuration()` — human-readable duration (`Xh Ym`, `Xm`, `Xs`)
- [x] `getWorkoutNameFallback()` — time-of-day naming for unnamed sessions

### Routines
- [x] `hydratedRoutinesProvider` — reactive `StreamProvider` of all user routines with resolved exercise names
- [x] `WorkoutScreen` (Routines tab) — collapsible routine list, "New Routine" and "Explore" buttons
- [x] `RoutineCard` — name, exercise preview (up to 3 names + "..."), Start Routine button, 3-dot menu (Edit/Delete stubs)
- [x] `RoutineDetailScreen` — numbered exercise list + "Start Workout" CTA
- [x] `routineDetailProvider` — reactive single-routine stream

### Profile
- [x] `ProfileScreen` — display name (from local DB), workout count (live `StreamProvider`)
- [x] `workoutCountProvider` — `StreamProvider<int>` → `WorkoutsDao.watchWorkoutCountForUser()`
- [x] `currentUserProfileProvider` — `StreamProvider<UserProfile?>` → `UserDao.watchUser()`
- [x] Metric toggle pills (Duration / Volume / Reps) — local `setState`, not wired to data

### Infrastructure
- [x] `AppDatabase` — 8-table Drift schema, `NativeDatabase.createInBackground`, file in `getApplicationDocumentsDirectory()`
- [x] `databaseProvider` — `Provider<AppDatabase>` overridden at root with pre-initialized instance
- [x] `AppColors` — 8 color constants, OLED-first dark
- [x] `appTheme` — Material3 dark, Inter font, all component themes
- [x] `AppShell` — `ShellRoute` wrapper, `maxWidth: 600`, `BottomNavBar` + optional `ActiveWorkoutBar`
- [x] `BottomNavBar` — 3-tab custom nav, active state via `GoRouterState.matchedLocation`

---

## Partially Implemented / Known TODOs

### `WorkoutSet` Fields

| Field | Status | Notes |
|---|---|---|
| `isPr` | ✅ Implemented | Written by `detectAndMarkPrs()` after `finishWorkout()`. One set per exercise per session marked. |
| `estimated_1rm` | ✅ Implemented | Written alongside `is_pr = true` at PR detection time. |
| `rpe` | Column exists, no UI | Rate of perceived exertion — schema-ready but no input widget. |

### `SetRow` Previous Set History

`SetRow` accepts `previousWeight` and `previousReps` props but `ExerciseBlock` always passes `null`. The "PREVIOUS" column in the active workout UI always shows `'-'`. The `ExercisesDao` has `getExerciseHistory()` available; wiring is missing.

### Rest Timer

Rest timer code is **commented out** in `ExerciseBlock`:
```gymlog/lib/features/workout/widgets/exercise_block.dart#L1-1
// Rest Timer Row (temporarily removed)
// ...
// Text('Rest Timer: 1min 0s', ...)
```
`RoutineExercises.restSeconds` column and `UserProfiles.defaultRestSeconds` exist in the schema.

### `RoutineEditorScreen`

Stub screen — displays "Routine Builder — Coming Soon". No form, no save logic.

### Routine Card Delete Action

`RoutineCard._showOptions()` "Delete Routine" `onTap`:
```gymlog/lib/features/workout/widgets/routine_card.dart#L1-1
onTap: () {
  Navigator.pop(ctx);
  // TODO: Wire to RoutinesDao.deleteRoutine
},
```

### Profile Chart

`ProfileScreen` chart area is a placeholder:
```gymlog/lib/features/profile/screens/profile_screen.dart#L1-1
Container(height: 200, child: Text('Chart — Track 10'))
```
`fl_chart` is already a dependency.

### Profile Action Buttons

All four buttons in `ProfileScreen` have empty callbacks:
- Statistics → `onPressed: () {}`
- Exercises → `onPressed: () {}`
- Measures → `onPressed: () {}`
- Calendar → `onPressed: () {}`

### Workout Detail Edit Action

`WorkoutDetailScreen._showWorkoutActions()` "Edit Workout":
```gymlog/lib/features/workout/screens/workout_detail_screen.dart#L1-1
onTap: () {
  Navigator.pop(ctx);
  // no navigation, no edit logic
},
```

### Explore Button (`WorkoutScreen`)

```gymlog/lib/features/workout/screens/workout_screen.dart#L1-1
SecondaryButton(label: 'Explore', onPressed: () {})
```

### `resetHydration()` in `main.dart`

```gymlog/lib/main.dart#L1-1
// TODO: Remove the resetHydration() call after one successful run.
await db.exercisesDao.resetHydration();
```
This is a debug utility that clears the hydration flag on every launch. It must be removed before production release.

### Supabase Sync

`WorkoutSession.synced` column (`BoolColumn`, DEFAULT false) exists but is never set to `true`. No sync logic implemented.

---

## Planned / Not Started

Inferred from schema columns, dependencies, and existing UI stubs:

### Premium / Paywall
- `UserProfile.isPremium` (bool) and `UserProfile.premiumExpiry` (datetime) columns exist
- `url_launcher: ^6.2.0` in `pubspec.yaml` — likely for a payment/subscription flow
- No paywall screen, no premium gate on any feature

### Custom Exercises
- `Exercise.isCustom` (bool, DEFAULT false) and `Exercise.createdBy` (text nullable) columns exist
- No UI to create custom exercises
- No route for it

### Body Measurements
- "Measures" button in `ProfileScreen` exists (empty callback)
- No table in the schema for measurements

### Calendar View
- "Calendar" button in `ProfileScreen` exists (empty callback)
- No implementation

### Statistics Screen
- "Statistics" button in `ProfileScreen` exists (empty callback)
- `fl_chart` is available

### RPE Input UI
- `WorkoutSet.rpe` column exists
- No input in `SetRow`

### Rest Timer Countdown
- `RoutineExercises.restSeconds` and `UserProfiles.defaultRestSeconds` schema-ready
- Countdown widget commented out in `ExerciseBlock`
- `vibration: ^3.1.8` in `pubspec.yaml` — likely for rest-timer completion haptics

### Offline / Online Sync
- `WorkoutSession.synced` flag exists
- `connectivity_plus: ^7.1.1` in `pubspec.yaml`
- `flutter_secure_storage: ^9.0.0` in `pubspec.yaml` — likely for secure token storage during sync

### Multi-Day Routine Building
- `RoutineDays` table supports multi-day structures (`orderIndex`, `name`)
- `RoutineEditorScreen` is a stub — full form with day management not built

### `ExerciseListProvider` Reactivity
- Currently a `FutureProvider`-style notifier (fetches once, mutates via `search()`)
- Not reactive to new custom exercises being inserted; would not auto-update if custom exercises are added

### Routine Exercises Default Values in Workout
- `RoutineExercise.defaultSets`, `defaultReps`, `defaultWeightKg` columns exist
- When starting from a routine, only 1 blank set is created per exercise (default values ignored)
