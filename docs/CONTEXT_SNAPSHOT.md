# CONTEXT_SNAPSHOT.md
<!-- AI context primer — paste at start of new session. Dense and precise. -->

## Project Identity

**App:** GymLog — offline-first Flutter workout logger  
**Version:** 0.1.0  
**Stack:** Flutter (Dart), Riverpod, Drift (SQLite), Supabase (auth only), GoRouter  
**DB file:** `gymlog_db.sqlite` in `getApplicationDocumentsDirectory()`  
**Schema version:** 1  
**Theme:** OLED-first dark — `bgBase: #000000`, `bgSurface: #1C1C1E`, `accentPrimary: #8A2BE2`, `textPrimary: #FFFFFF`, `textSecondary: #8E8E93`  
**Font:** Google Fonts Inter exclusively  

---

## Key Dependencies (`pubspec.yaml`)

```yaml
drift: ^2.18.0          # SQLite ORM
flutter_riverpod: ^2.5.0
riverpod_annotation: ^2.3.0
go_router: ^14.0.0
supabase_flutter: ^2.5.0
google_sign_in: ^6.2.0
cached_network_image: ^3.3.0
fl_chart: ^0.68.0
freezed_annotation: ^2.4.0
shared_preferences: ^2.2.0
connectivity_plus: ^7.1.1  # not yet used
vibration: ^3.1.8           # not yet used
url_launcher: ^6.2.0        # not yet used (planned paywall)
```

---

## Folder Structure (condensed)

```
lib/
├── main.dart               # Bootstrap, Supabase init, DB warmup, JSON hydration
├── app.dart                # MaterialApp.router(routerProvider)
├── core/
│   ├── database/
│   │   ├── database.dart   # AppDatabase, 8 tables, 4 DAOs
│   │   ├── tables/         # exercises, routines, routine_days, routine_exercises,
│   │   │                   # user_profiles, workouts (sessions + exercises + sets)
│   │   └── daos/           # ExercisesDao, RoutinesDao, WorkoutsDao, UserDao
│   ├── providers/database_provider.dart  # Provider<AppDatabase>, overridden at root
│   ├── router/router.dart  # routerProvider (GoRouter + auth redirect)
│   ├── theme/app_colors.dart  app_theme.dart
│   └── utils/formatters.dart  # formatWorkoutDuration, getWorkoutNameFallback
├── features/
│   ├── auth/data/auth_repository.dart            # Google Sign-In (native + web)
│   ├── auth/presentation/providers/auth_provider.dart
│   ├── auth/presentation/screens/               # splash, auth, onboarding
│   ├── exercises/presentation/providers/        # exerciseListProvider, exerciseAnalyticsProvider
│   ├── exercises/presentation/screens/          # selection, detail (with fl_chart)
│   ├── home/presentation/providers/recent_workouts_provider.dart
│   ├── home/presentation/screens/home_screen.dart
│   ├── profile/presentation/providers/profile_provider.dart
│   ├── profile/presentation/screens/profile_screen.dart
│   ├── routines/presentation/providers/routines_provider.dart
│   ├── routines/presentation/screens/           # routine_detail, routine_editor (stub)
│   ├── routines/presentation/widgets/routine_card.dart
│   ├── workout/domain/active_workout_state.dart  # @freezed state tree
│   ├── workout/presentation/providers/           # active_workout, workout_detail, workout_timer
│   ├── workout/presentation/screens/             # active_workout, workout (routines tab), workout_detail
│   └── workout/presentation/widgets/             # exercise_block, set_row
└── shared/widgets/
    ├── app_shell.dart, bottom_nav_bar.dart, active_workout_bar.dart, exercise_gif_widget.dart
    └── ui/  primary_button.dart, secondary_button.dart, toggle_pill.dart, tracker_card.dart
```

---

## Database Schema (all 8 tables)

### `user_profiles` — PK: `id` (Supabase UUID)
`email`, `display_name`, `is_premium bool=false`, `premium_expiry datetime?`, `weight_unit text='kg'`, `default_rest_seconds int=90`, `created_at`

### `exercises` — PK: `id` (autoIncrement int)
`exercise_db_id text UNIQUE nullable` (null=custom), `name`, `body_part`, `equipment`, `target`, `gif_url nullable`, `secondary_muscles` (JSON array), `instructions` (JSON array), `is_custom bool=false`, `created_by nullable`, `seeded_at nullable`

### `routines` — PK: `id` (UUID)
`user_id`, `name`, `notes=''`, `created_at`, `updated_at`

### `routine_days` — PK: `id` (UUID), FK: `routine_id → routines`
`name`, `order_index`

### `routine_exercises` — PK: `id` (UUID), FK: `routine_day_id → routine_days`, `exercise_id → exercises`
`order_index`, `default_sets=3`, `default_reps?`, `default_weight_kg?`, `rest_seconds?`

### `workout_sessions` — PK: `id` (UUID clientDefault)
`user_id`, `routine_id?`, `name?`, `started_at`, `ended_at?` (null=active), `notes=''`, `total_volume_kg=0` (denormalized), `synced=false`

### `workout_exercises` — PK: `id` (UUID), FK: `session_id → workout_sessions`, `exercise_id → exercises`
`order_index`, `notes?`

### `workout_sets` — PK: `id` (UUID), FK: `workout_exercise_id → workout_exercises`
`exercise_id` (denormalized — enables history queries without extra JOIN), `order_index`, `set_type='normal'`, `weight_kg`, `reps`, `rpe?`, `is_pr=false` (set by `detectAndMarkPrs()` post-workout), `estimated_1rm?` (written at same time as `is_pr`), `completed_at?`

---

## All Providers

| Provider | Type | Source |
|---|---|---|
| `databaseProvider` | `Provider<AppDatabase>` | `core/providers/database_provider.dart` |
| `routerProvider` | `Provider<GoRouter>` | `core/router/router.dart` |
| `authRepositoryProvider` | `Provider<AuthRepository>` | `auth/presentation/providers/auth_provider.dart` |
| `authStateProvider` | `StreamProvider<AuthState>` | same |
| `authProvider` | `Provider<User?>` | same |
| `activeWorkoutProvider` | `StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>` | `workout/presentation/providers/active_workout_provider.dart` |
| `workoutTimerProvider` | `@riverpod` class → `String` | `workout/presentation/providers/workout_timer_provider.dart` |
| `workoutDetailProvider` | `StreamProvider.family<HydratedWorkout?, String>` | `workout/presentation/providers/workout_detail_provider.dart` |
| `exerciseListProvider` | `@riverpod` class → `AsyncValue<List<Exercise>>` | `exercises/presentation/providers/exercises_provider.dart` |
| `exerciseAnalyticsProvider` | `StreamProvider.family<List<ExerciseHistoryData>, int>` | `exercises/presentation/providers/exercise_analytics_provider.dart` |
| `workoutCompletedSignalProvider` | `StateProvider<int>` | `home/presentation/providers/home_provider.dart` |
| `workoutHistoryProvider` | `StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>` | `home/presentation/providers/home_provider.dart` |
| `hydratedRoutinesProvider` | `StreamProvider<List<HydratedRoutine>>` | `routines/presentation/providers/routines_provider.dart` |
| `routineDetailProvider` | `StreamProvider.family<HydratedRoutine?, String>` | same |
| `workoutCountProvider` | `StreamProvider<int>` | `profile/presentation/providers/profile_provider.dart` |
| `currentUserProfileProvider` | `StreamProvider<UserProfile?>` | same |

---

## Routes

| Path | Screen | Notes |
|---|---|---|
| `/splash` | `SplashScreen` | 2s delay, resolves auth |
| `/auth` | `AuthScreen` | Google Sign-In |
| `/onboarding` | `OnboardingScreen` | First-launch name capture |
| `/` | `HomeScreen` | Shell — workout history |
| `/workout` | `WorkoutScreen` | Shell — routines tab |
| `/profile` | `ProfileScreen` | Shell — stats |
| `/exercises/select` | `ExerciseSelectionScreen` | Also pushed via `Navigator.push` from active workout |
| `/exercise/detail` | `ExerciseDetailScreen` | `state.extra as Exercise` ⚠️ passes object not ID |
| `/routines/edit` | `RoutineEditorScreen` | **STUB** — "Coming Soon" |
| `/routines/:id` | `RoutineDetailScreen` | `pathParameters['id']` |
| `/workout/active` | `ActiveWorkoutScreen` | `fullscreenDialog: true` |
| `/workout/detail/:id` | `WorkoutDetailScreen` | `pathParameters['id']` |

**Auth redirect:** `/splash` and `/onboarding` bypass redirect. Not signed-in → `/auth`. Signed-in on `/auth` → `/`.

---

## In-Memory Workout State (Freezed)

```dart
ActiveWorkoutState { id, startTime, routineId?, exercises: List<WorkoutExerciseState> }
WorkoutExerciseState { exerciseId, name, sets: List<WorkoutSetState> }
WorkoutSetState { id, setType='normal', weightKg, reps, isCompleted }
```

`ActiveWorkoutNotifier` methods: `startWorkout()`, `finishWorkout()`, `discardWorkout()`, `addExercise()`, `addSet()`, `updateSet()`, `removeExercise()`, `replaceExercise()`, `toggleSetCompletion()`

`finishWorkout()` → inserts `WorkoutSession` + all `WorkoutExercise` + all completed `WorkoutSet` rows. Skips exercises with zero completed sets. Computes `totalVolumeKg = Σ(weight × reps)`. Calls `detectAndMarkPrs(sessionId, startTime)` for PR detection. Increments `workoutCompletedSignalProvider` to trigger `WorkoutHistoryNotifier._reset()`.

**PR detection:** `detectAndMarkPrs()` — for each exercise: computes Epley 1RM (`weight × (1 + reps/30)`) per set, finds session best, queries `_getMaxEstimated1rmBefore()` (MAX 1RM from all sessions with `ended_at < sessionStart`). If session best > prior max: marks that one set `is_pr = true`, writes `estimated_1rm`.

---

## Hydrated DAO Types (plain Dart, not Drift rows)

```dart
HydratedWorkout { session: WorkoutSession, exercises: List<HydratedWorkoutExercise> }
HydratedWorkoutExercise { workoutExercise, exerciseMetadata: Exercise, sets: List<WorkoutSet> }
HydratedRoutine { routine: Routine, exerciseNames: List<String>, exerciseIds: List<int> }
ExerciseHistoryData { date, weight, reps, estimated1RM = weight*(1+reps/30), volume = weight*reps }
```

---

## Computed Values

| Value | Formula | Computed Where |
|---|---|---|
| `estimated1RM` | `weight * (1 + reps / 30)` (Epley) | `WorkoutsDao.getExerciseHistory()` |
| `volume` per set | `weight * reps` | `WorkoutsDao.getExerciseHistory()` |
| `totalVolumeKg` | `Σ(weight × reps)` for completed sets | `ActiveWorkoutNotifier.finishWorkout()` |
| Workout name fallback | time-of-day string | `formatters.dart:getWorkoutNameFallback()` |

---

## Key Implementation Patterns

**Screen template:** `ConsumerWidget` or `ConsumerStatefulWidget`, `Scaffold(bgBase)`, `AppBar(GoogleFonts.inter w700 28px)`, `SingleChildScrollView(padding: fromLTRB(16,16,16,120))` or `ListView.builder`

**Async template:** `ref.watch(provider).when(data: ..., loading: () => CircularProgressIndicator(color: accentPrimary), error: ...)`

**Contextual menu:** Always `showModalBottomSheet(backgroundColor: transparent)` → `Container(bgSurface, borderRadius: vertical(top:20))` with drag handle + `ListTile` items

**Shell:** `AppShell(ShellRoute) → Scaffold → SafeArea → ConstrainedBox(maxWidth:600) → child`; `bottomNavigationBar: Column[ActiveWorkoutBar?, BottomNavBar]`

**Exercise seeding:** `hydrateFromJson()` guarded by `SharedPreferences key 'exercises_hydrated_v2'`. Two phases: SQL UPDATE gifUrls, then batch INSERT OR IGNORE chunks of 100.

---

## Known Issues / Anti-Patterns

1. **`/exercise/detail` passes `Exercise` object via `state.extra`** — violates "pass IDs, not objects" rule
2. **`ExerciseSelectionScreen` opened via `Navigator.push`** from `ActiveWorkoutScreen` — not GoRouter
3. **`recentWorkoutsProvider` is `FutureProvider`** — manually invalidated after `finishWorkout()`; should be `StreamProvider` watching `watchSessionsForUser()`
4. **`resetHydration()` called in `main.dart`** — debug utility, must be removed before production
5. **`WorkoutSet.isPr` always false** — PR detection never implemented
6. **Previous set history in `SetRow` always null** — `PREVIOUS` column shows `'-'` always

---

## Incomplete Features (with schema evidence)

| Feature | Schema Evidence | Status |
|---|---|---|
| Premium/paywall | `isPremium`, `premiumExpiry` in `user_profiles`; `url_launcher` dep | Not started |
| Custom exercises | `is_custom`, `created_by` in `exercises` | Not started |
| Supabase sync | `synced` in `workout_sessions`; `connectivity_plus` dep | Not started |
| Body measurements | "Measures" button in ProfileScreen | Not started |
| RPE input | `rpe` in `workout_sets` | Not started |
| Rest timer | `rest_seconds` in `routine_exercises`; `default_rest_seconds` in `user_profiles`; `vibration` dep | Stub commented out |
| Routine editor | `RoutineEditorScreen` exists | "Coming Soon" stub |
| Multi-day routines | `routine_days` table supports N days | Not surfaced in UI |
| Statistics screen | "Statistics" button in ProfileScreen | Not started |
| Calendar view | "Calendar" button in ProfileScreen | Not started |

---

## UI Component Reference

| Component | Props | Behavior |
|---|---|---|
| `PrimaryButton` | `label, onPressed?, isFullWidth=true, icon?` | 48px, `accentPrimary` bg |
| `SecondaryButton` | `label, onPressed?, isFullWidth=true, icon?` | 48px, `bgSurface` bg |
| `TrackerCard` | `child, padding?, onTap?` | `bgSurface` container; `InkWell` if `onTap` |
| `TogglePill` | `label, isActive, onTap?` | `AnimatedContainer` 200ms; active=purple, inactive=borderSubtle |
| `ExerciseGifWidget` | `gifUrl?, width?, height?, fit?, borderRadius?` | `CachedNetworkImage` + fallback icon |
| `ExerciseBlock` | `exerciseIndex, exercise, driftExercise?, onRemove, onReplace, onAddNote, onAddSet, onSetChanged, onToggleSetCompletion` | Exercise container in active workout |
| `SetRow` | `setIndex, setData, previousWeight?, previousReps?, onChanged, onToggleComplete` | Weight/reps inputs, type cycler, checkmark |

---

## `setType` Cycle

`normal → warmup → dropset → failure → normal` (tapping the set number in `SetRow._cycleType()`)  
Display: `warmup` shows `'W'` in warning yellow; others show set number.
