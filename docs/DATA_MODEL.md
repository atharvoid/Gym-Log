# GymLog Data Model & Schema Specification

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

## Drift Tables

Schema version: **5** (`AppDatabase.schemaVersion`)  
DB file: `gymlog_db.sqlite` in `getApplicationDocumentsDirectory()`

### `user_profiles` (`UserProfiles` / `UserProfile`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK (Supabase auth UUID) |
| `email` | `TextColumn` | `String` | NOT NULL |
| `display_name` | `TextColumn` | `String` | NOT NULL |
| `is_premium` | `BoolColumn` | `bool` | DEFAULT false |
| `premium_expiry` | `DateTimeColumn` | `DateTime?` | nullable |
| `weight_unit` | `TextColumn` | `String` | DEFAULT `'kg'` |
| `default_rest_seconds` | `IntColumn` | `int` | DEFAULT 90 |
| `created_at` | `DateTimeColumn` | `DateTime` | NOT NULL |

---

### `exercises` (`Exercises` / `Exercise`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `IntColumn` | `int` | PK, autoIncrement |
| `exercise_db_id` | `TextColumn` | `String?` | UNIQUE, nullable (null for custom) |
| `name` | `TextColumn` | `String` | NOT NULL |
| `body_part` | `TextColumn` | `String` | NOT NULL, lowercase |
| `equipment` | `TextColumn` | `String` | NOT NULL, lowercase |
| `target` | `TextColumn` | `String` | NOT NULL, lowercase |
| `gif_url` | `TextColumn` | `String?` | nullable, Supabase storage URL |
| `secondary_muscles` | `TextColumn` | `String?` | nullable, JSON-encoded `List<String>` |
| `instructions` | `TextColumn` | `String?` | nullable, JSON-encoded `List<String>` |
| `is_custom` | `BoolColumn` | `bool` | DEFAULT false |
| `created_by` | `TextColumn` | `String?` | nullable, userId for user-created exercises |
| `seeded_at` | `DateTimeColumn` | `DateTime?` | nullable |

**GIF URL format:** `https://otcfigaprxfknickyrdh.supabase.co/storage/v1/object/public/excercises/{exercise_db_id}.gif`

---

### `routines` (`Routines` / `Routine`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK, UUID v4 |
| `user_id` | `TextColumn` | `String` | NOT NULL |
| `name` | `TextColumn` | `String` | NOT NULL |
| `notes` | `TextColumn` | `String` | DEFAULT `''` |
| `created_at` | `DateTimeColumn` | `DateTime` | NOT NULL |
| `updated_at` | `DateTimeColumn` | `DateTime` | NOT NULL |

---

### `routine_days` (`RoutineDays` / `RoutineDay`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK, UUID v4 |
| `routine_id` | `TextColumn` | `String` | FK → `routines.id` |
| `name` | `TextColumn` | `String` | NOT NULL |
| `order_index` | `IntColumn` | `int` | NOT NULL |

---

### `routine_exercises` (`RoutineExercises` / `RoutineExercise`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK, UUID v4 |
| `routine_day_id` | `TextColumn` | `String` | FK → `routine_days.id` |
| `exercise_id` | `IntColumn` | `int` | FK → `exercises.id` |
| `order_index` | `IntColumn` | `int` | NOT NULL |
| `default_sets` | `IntColumn` | `int` | DEFAULT 3 |
| `default_reps` | `IntColumn` | `int?` | nullable |
| `default_weight_kg` | `RealColumn` | `double?` | nullable |
| `rest_seconds` | `IntColumn` | `int?` | nullable |

---

### `workout_sessions` (`WorkoutSessions` / `WorkoutSession`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK, UUID v4 (`clientDefault`) |
| `user_id` | `TextColumn` | `String` | NOT NULL |
| `routine_id` | `TextColumn` | `String?` | nullable — set when started from a routine |
| `name` | `TextColumn` | `String?` | nullable |
| `started_at` | `DateTimeColumn` | `DateTime` | NOT NULL |
| `ended_at` | `DateTimeColumn` | `DateTime?` | nullable — null while session is active |
| `notes` | `TextColumn` | `String` | DEFAULT `''` |
| `total_volume_kg` | `RealColumn` | `double` | DEFAULT 0.0 — **denormalized** |
| `synced` | `BoolColumn` | `bool` | DEFAULT false — cloud sync flag (unused) |

---

### `workout_exercises` (`WorkoutExercises` / `WorkoutExercise`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK, UUID v4 |
| `session_id` | `TextColumn` | `String` | FK → `workout_sessions.id` |
| `exercise_id` | `IntColumn` | `int` | FK → `exercises.id` |
| `order_index` | `IntColumn` | `int` | NOT NULL |
| `notes` | `TextColumn` | `String?` | nullable |

---

### `workout_sets` (`WorkoutSets` / `WorkoutSet`)

| Column | Drift Type | Dart Type | Constraints |
|---|---|---|---|
| `id` | `TextColumn` | `String` | PK, UUID v4 |
| `workout_exercise_id` | `TextColumn` | `String` | FK → `workout_exercises.id` |
| `exercise_id` | `IntColumn` | `int` | **denormalized** (not FK-constrained in Drift) |
| `order_index` | `IntColumn` | `int` | NOT NULL |
| `set_type` | `TextColumn` | `String` | DEFAULT `'normal'` |
| `weight_kg` | `RealColumn` | `double` | NOT NULL |
| `reps` | `IntColumn` | `int` | NOT NULL |
| `rpe` | `RealColumn` | `double?` | nullable, no UI yet |
| `is_pr` | `BoolColumn` | `bool` | DEFAULT false — written `true` by `WorkoutsDao.detectAndMarkPrs()` post-workout |
| `estimated_1rm` | `RealColumn` | `double?` | nullable — written by `detectAndMarkPrs()` for the PR set (Epley: `weight_kg * (1 + reps / 30.0)`) |
| `completed_at` | `DateTimeColumn` | `DateTime?` | nullable |

---

## Entity Relationships

```
user_profiles (1) ──< (N) routines
routines (1) ──< (N) routine_days
routine_days (1) ──< (N) routine_exercises >──(N:1) exercises

user_profiles (1) ──< (N) workout_sessions
workout_sessions (1) ──< (N) workout_exercises >──(N:1) exercises
workout_exercises (1) ──< (N) workout_sets
```

---

## Hydrated DAO Data Classes

These are plain Dart classes (not Drift rows) assembled in DAOs via multi-table queries.

### `HydratedWorkout` (in `workouts_dao.dart`)

```dart
class HydratedWorkout {
  final WorkoutSession session;
  final List<HydratedWorkoutExercise> exercises;
}

class HydratedWorkoutExercise {
  final WorkoutExercise workoutExercise;
  final Exercise exerciseMetadata;
  final List<WorkoutSet> sets;
}
```

Assembly method: `getHydratedWorkout(sessionId)` — iterates exercises, fetches metadata + sets per exercise. Reactive variant: `watchHydratedWorkout(sessionId)` — uses `customSelect('SELECT 1 ...')` to trigger on any table change, then calls `getHydratedWorkout` via `asyncMap`.

### `HydratedRoutine` (in `routines_dao.dart`)

```dart
class HydratedRoutine {
  final Routine routine;
  final List<String> exerciseNames;
  final List<int> exerciseIds;
}
```

Assembly: `_hydrateRoutine(routine)` — fetches all `RoutineDay`s, then all `RoutineExercise`s per day, then resolves each `exerciseId` to a name via `ExercisesDao.getExerciseById`. Parallel lists (names[i] corresponds to ids[i]).

### `ExerciseHistoryData` (in `workouts_dao.dart`)

```dart
class ExerciseHistoryData {
  final DateTime date;
  final double weight;
  final int reps;
  final double estimated1RM;  // computed
  final double volume;         // computed
}
```

### `ExercisePreviewItem` and `WorkoutSessionPreview` (in `workouts_dao.dart`)

```dart
class ExercisePreviewItem {
  final String exerciseName;
  final String? gifUrl;
  final int setCount;
}

class WorkoutSessionPreview {
  final WorkoutSession session;
  final Duration duration;          // ended_at - started_at
  final double totalVolumeKg;       // from denormalized column
  final int prCount;                // count of sets where is_pr = true in session
  final List<ExercisePreviewItem> topExercises;   // first 2 exercises only
  final int totalExerciseCount;     // total distinct exercises in session
}
```

Assembly method: `getSessionPreviewsForUser(userId, {int limit = 10, int offset = 0})` — paginated `Future` query. JOINs `workout_sessions → workout_exercises → exercises → workout_sets`. Internally queries `limit + 1` rows (limit+1 trick): if result length > limit, trims last item and `hasMore = true`. Returns `List<WorkoutSessionPreview>` (caller receives the trimmed list and a boolean).

---

## Freezed In-Memory State Classes

Live only in `ActiveWorkoutNotifier` state. **Not persisted until `finishWorkout()` is called.**

### `ActiveWorkoutState` (`active_workout_state.dart`)

```dart
@freezed
class ActiveWorkoutState with _$ActiveWorkoutState {
  const factory ActiveWorkoutState({
    required String id,          // UUID — becomes WorkoutSession.id on save
    required DateTime startTime,
    String? routineId,
    @Default([]) List<WorkoutExerciseState> exercises,
  }) = _ActiveWorkoutState;
}

@freezed
class WorkoutExerciseState with _$WorkoutExerciseState {
  const factory WorkoutExerciseState({
    required int exerciseId,
    required String name,
    @Default([]) List<WorkoutSetState> sets,
  }) = _WorkoutExerciseState;
}

@freezed
class WorkoutSetState with _$WorkoutSetState {
  const factory WorkoutSetState({
    @Default('') String id,          // UUID, used as widget key
    @Default('normal') String setType,
    @Default(0.0) double weightKg,
    @Default(0) int reps,
    @Default(false) bool isCompleted,
  }) = _WorkoutSetState;
}
```

---

## Enums and Constants

### `setType` String Enum (no Dart enum — raw strings)

| Value | UI Label | Color |
|---|---|---|
| `'normal'` | Set number | `textPrimary` |
| `'warmup'` | `'W'` | `warning` (#FFCC00) |
| `'dropset'` | Set number | `textPrimary` |
| `'failure'` | Set number | `textPrimary` |

Cycled in `SetRow._cycleType()`: normal → warmup → dropset → failure → normal

### `weightUnit` String Enum (UserProfiles)

| Value | Notes |
|---|---|
| `'kg'` | Default |
| `'lbs'` | Schema allows it; no UI toggle exists yet |

### SharedPreferences Keys

| Key | Type | Purpose |
|---|---|---|
| `'exercises_hydrated_v2'` | `bool` | Guards JSON hydration re-runs. Cleared by `resetHydration()`. Bump version string to force re-hydration on all installs. |
| `'exercises_hydrated_v1'` | `bool` | Old key; also cleared by `resetHydration()` for migration. |

### Supabase Storage

| Constant | Value |
|---|---|
| `_kGifBase` | `'https://otcfigaprxfknickyrdh.supabase.co/storage/v1/object/public/excercises'` |
| URL format | `$_kGifBase/{exerciseDbId}.gif` |

---

## Auto-Computed Fields

### `estimated1RM` (Epley Formula)

```
estimated1RM = weight × (1 + reps / 30)
```

- **Computed in:** `WorkoutsDao.getExerciseHistory()` and `watchExerciseHistory()` from raw SQL result rows.
- **Displayed in:** `ExerciseDetailScreen` analytics chart (toggle index 1).
- **`WorkoutSet.estimated_1rm` column:** Exists in schema but is **never written** at `finishWorkout()` time. Column is vestigial.

### `volume` (Per Set)

```
volume = weight × reps
```

- **Computed in:** `WorkoutsDao.getExerciseHistory()` for `ExerciseHistoryData.volume`.
- **Displayed in:** `ExerciseDetailScreen` analytics chart (toggle index 3 = "Best Volume").

### `totalVolumeKg` (Per Session — Denormalized)

```
totalVolumeKg = Σ (weightKg × reps) for all isCompleted sets
```

- **Computed in:** `ActiveWorkoutNotifier.finishWorkout()` before inserting the `WorkoutSession` row.
- **Displayed in:** `HomeScreen` workout history cards and `WorkoutDetailScreen` stats row.

### `getWorkoutNameFallback(DateTime start, String? name)`

Time-of-day name for sessions without an explicit name:

| Hour range | Name |
|---|---|
| 05:00–11:59 | `'Morning Workout'` |
| 12:00–16:59 | `'Afternoon Workout'` |
| 17:00–20:59 | `'Evening Workout'` |
| 21:00–04:59 | `'Night Workout'` |

### `WorkoutSet.isPr` / `WorkoutSet.estimated_1rm` — `detectAndMarkPrs(sessionId, sessionStart)`

Called by `ActiveWorkoutNotifier.finishWorkout()` immediately after all rows are inserted. Runs per-exercise within the session.

**Algorithm:**
1. Raw SQL: find the set with `MAX(weight_kg * (1 + reps / 30.0))` for the given `sessionId` and `exerciseId` (best Epley 1RM in this session).
2. Raw SQL via `_getMaxEstimated1rmBefore(exerciseId, sessionStart)`: `MAX(weight_kg * (1 + reps / 30.0))` across all prior `workout_sets` WHERE `exercise_id = ? AND completed_at < sessionStart`.
3. If session-best > prior max (or prior max is null — first time doing this exercise): updates that single set row — `is_pr = true`, `estimated_1rm = sessionBest1RM`.
4. **Only one set per exercise per session is ever marked as PR.**

**Epley formula:**
```
estimated_1RM = weight_kg × (1 + reps / 30.0)
```

**Helper:** `_getMaxEstimated1rmBefore(exerciseId, before)` — private method, raw SQL `customSelect` returning `MAX(weight_kg * (1 + reps / 30.0))` on `workout_sets` WHERE `exercise_id = ? AND completed_at < ?`.

---

## Exercise JSON Hydration Pipeline

Source: `assets/db/exercises.json` → key `exercises` → array of objects.

Each JSON object shape:
```json
{ "id": "<exerciseDbId>", "name": "...", "bodyPart": "...", "equipment": "...", "target": "...", "secondaryMuscles": [...], "instructions": [...] }
```

Two-phase hydration in `ExercisesDao.hydrateFromJson()`:
1. **Phase 1 (UPDATE):** `UPDATE exercises SET gif_url = '{base}/{exercise_db_id}.gif' WHERE exercise_db_id IS NOT NULL` — patches any stale URLs without touching PKs or FK references.
2. **Phase 2 (INSERT OR IGNORE):** Batch insert in chunks of 100. Skips rows where `exerciseDbId` already exists (due to UNIQUE constraint).

Fallback: `seedDefaultExercises()` — inserts 10 hardcoded exercises if JSON hydration throws.
