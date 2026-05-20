# GymLog — Technical Context & Architecture Reference

**Last Updated**: 2025-01-20  
**Version**: Track 8.9 Complete  
**Status**: Production-ready core features. Tracks 9 & 10 pending.

---

## 0. PURPOSE OF THIS DOCUMENT

This is the **Single Source of Truth** for the GymLog codebase architecture. It describes:
- What is **already implemented and working**
- What is **NOT yet built** (pending tracks)
- The exact database schema, routing structure, and state management patterns in use
- Design system tokens and UI primitives currently deployed

**Use this document to:**
- Understand what exists before proposing changes
- Avoid re-implementing features that are already complete
- Maintain consistency with established patterns

---

## 1. PROJECT OVERVIEW

**GymLog** is an offline-first, high-performance workout tracking app built with Flutter. It uses **Riverpod** for state management, **Drift** (SQLite) for local persistence, and **Supabase** for authentication. The design follows a "High-Density Tracker" aesthetic: OLED-first, zero shadows, 12px border radius, data-over-decoration.

### Tech Stack (Locked)
- **Framework**: Flutter (SDK >=3.0.0)
- **State**: Riverpod (`flutter_riverpod: ^2.5.0`, `riverpod_annotation: ^2.3.0`)
- **Database**: Drift (`drift: ^2.18.0`) with native SQLite (`sqlite3_flutter_libs: ^0.5.42`)
- **Auth**: Supabase (`supabase_flutter: ^2.5.0`) + Google Sign-In (`google_sign_in: ^6.2.0`)
- **Routing**: GoRouter (`go_router: ^14.0.0`)
- **Charts**: fl_chart (`fl_chart: ^0.68.0`)
- **Typography**: Google Fonts (`google_fonts: ^6.2.0`) — **Inter** everywhere

### Android Build Matrix (DO NOT ALTER)
- Package: `com.drifs.gymlog`
- Java: 17
- Gradle: 8.4
- AGP: 8.3.2
- Kotlin: 1.9.24

---

## 2. DESIGN SYSTEM: "HIGH-DENSITY TRACKER"

### Color Tokens (`lib/core/theme/app_colors.dart`)
```dart
bgBase         = #000000  // Pure Black (OLED scaffold)
bgSurface      = #1C1C1E  // Dark Grey (cards, inputs, sheets)
accentPrimary  = #8A2BE2  // Electric Purple (primary actions)
textPrimary    = #FFFFFF  // Pure White
textSecondary  = #8E8E93  // Muted Grey
borderSubtle   = #2C2C2E  // Internal dividers
error          = #FF5449
success        = #34C759
warning        = #FFCC00
```

### Typography (`lib/core/theme/app_theme.dart`)
- **Font**: Inter (via `google_fonts`)
- **Headers**: Bold (700), -0.5 letterSpacing, 24-32px
- **Data Points**: Semi-bold (600), 14-16px
- **Body**: Regular (400), 14-16px
- **Subtext**: Regular (400), 11-12px, `textSecondary`

### Geometry Rules
- **Border Radius**: STRICT 12px for all cards, buttons, inputs
- **Shadows**: ZERO (OLED-first philosophy)
- **Interactive Hit-box**: Minimum 48x48 logical pixels ("Fat Finger Rule")
- **Text Containers**: NEVER hardcode `height:`. Use vertical padding for accessibility scaling.

### UI Primitives (Already Built)
**Location**: `lib/shared/widgets/ui/`

| Component | Purpose | Key Props |
|-----------|---------|-----------|
| `TrackerCard` | Solid dark grey card, 12px radius | `child`, `padding`, `onTap` |
| `PrimaryButton` | Electric purple, 48px height, bold | `label`, `onPressed`, `icon`, `isFullWidth` |
| `SecondaryButton` | Dark grey bg, white text | `label`, `onPressed`, `icon`, `isFullWidth` |
| `TogglePill` | Pill-shaped toggle (active=purple) | `label`, `isActive`, `onTap` |

**Context Menus**: ALWAYS use `showModalBottomSheet` with 20px top radius. NEVER use `PopupMenuButton`.

---

## 3. DATABASE SCHEMA (DRIFT)

**Location**: `lib/core/database/`

### Tables (Normalized)

#### `user_profiles`
```dart
id: String (PK)           // Supabase User ID
email: String
displayName: String
isPremium: Boolean        // Default: false
premiumExpiry: DateTime?
weightUnit: String        // Default: 'kg'
defaultRestSeconds: Int   // Default: 90
createdAt: DateTime
```

#### `exercises`
```dart
id: Integer (PK, autoincrement)
exerciseDbId: String? (unique)  // From ExerciseDB hydration
name: String
bodyPart: String
equipment: String
target: String
gifUrl: String?
secondaryMuscles: String?
instructions: String?
isCustom: Boolean         // Default: false
createdBy: String?        // User ID for custom exercises
seededAt: DateTime?
```

#### `routines`
```dart
id: String (PK, UUID)
userId: String
name: String
notes: String             // Default: ''
createdAt: DateTime
updatedAt: DateTime
```

#### `routine_days`
```dart
id: String (PK, UUID)
routineId: String (FK -> routines.id)
name: String              // e.g., "Push Day"
orderIndex: Integer
```

#### `routine_exercises`
```dart
id: String (PK, UUID)
routineDayId: String (FK -> routine_days.id)
exerciseId: Integer (FK -> exercises.id)
orderIndex: Integer
defaultSets: Integer      // Default: 3
defaultReps: Integer?
defaultWeightKg: Real?
restSeconds: Integer?
```

#### `workout_sessions`
```dart
id: String (PK, UUID)
userId: String
routineId: String?
name: String?
startedAt: DateTime
endedAt: DateTime?
notes: String             // Default: ''
totalVolumeKg: Real       // Default: 0.0
synced: Boolean           // Default: false
```

#### `workout_exercises`
```dart
id: String (PK, UUID)
sessionId: String (FK -> workout_sessions.id)
exerciseId: Integer (FK -> exercises.id)
orderIndex: Integer
notes: String?
```

#### `workout_sets`
```dart
id: String (PK, UUID)
workoutExerciseId: String (FK -> workout_exercises.id)
exerciseId: Integer       // Denormalized for fast history queries
orderIndex: Integer
setType: String           // Default: 'normal' (warmup, dropset, failure)
weightKg: Real
reps: Integer
rpe: Real?
isPr: Boolean             // Default: false
estimated1rm: Real?
completedAt: DateTime?
```

### DAOs (Data Access Objects)

**Location**: `lib/core/database/daos/`

| DAO | Responsibilities |
|-----|------------------|
| `UserDao` | CRUD for user profiles |
| `ExercisesDao` | Exercise queries, seeding, search |
| `WorkoutsDao` | Session/Exercise/Set CRUD, history queries, hydrated workout joins |
| `RoutinesDao` | Routine CRUD, save workout as routine |

**Key Methods**:
- `ExercisesDao.seedDefaultExercises()`: Inserts 10 core exercises on first launch
- `WorkoutsDao.getExerciseHistory(exerciseId)`: Returns `List<ExerciseHistoryData>` for analytics
- `WorkoutsDao.getHydratedWorkout(sessionId)`: Multi-table join returning `HydratedWorkout`
- `RoutinesDao.saveWorkoutAsRoutine()`: Converts completed workout to reusable routine

---

## 4. ROUTING & NAVIGATION

**Location**: `lib/core/router/router.dart`

### Router Structure (`GoRouter`)
```dart
/splash                           // 2-second delay, redirects to /auth or /
/auth                             // Google OAuth screen
  
ShellRoute (AppShell with bottom nav):
  /                               // Home (workout history)
  /workout                        // Routines list
  /profile                        // Profile (stats, calendar placeholders)

/workout/active                   // Active workout (fullscreen dialog)
/workout/detail/:id               // Workout detail (read-only)
/exercises/select                 // Exercise picker
/exercise/detail                  // Exercise analytics (fl_chart)
/routines/edit                    // Routine builder (stub)
```

### Auth Guard Logic
- Splash screen checks `authProvider`
- Unauthenticated users → `/auth`
- Authenticated users attempting `/auth` → `/`
- All ShellRoute paths require authentication

### Bottom Navigation (`AppShell`)
**Location**: `lib/shared/widgets/app_shell.dart`

3 tabs:
1. **Home** (`/`) - Recent workouts, quick start
2. **Routines** (`/workout`) - Browse/start routines
3. **Profile** (`/profile`) - Stats, settings

**Active Workout Bar**: Purple bar shown above bottom nav when `activeWorkoutProvider != null`

---

## 5. STATE MANAGEMENT (RIVERPOD)

### Authentication
**Location**: `lib/features/auth/presentation/providers/auth_provider.dart`

```dart
authRepositoryProvider       // AuthRepository (Supabase client wrapper)
authStateProvider            // StreamProvider (Supabase onAuthStateChange)
authProvider                 // Provider<User?> (current user or null)
```

**Native Google Sign-In Flow**:
- Web: `signInWithOAuth(OAuthProvider.google)`
- Mobile: `google_sign_in` → `idToken` → `signInWithIdToken`

### Active Workout
**Location**: `lib/features/workout/presentation/providers/active_workout_provider.dart`

```dart
activeWorkoutProvider: StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>
```

**State Model** (`lib/features/workout/domain/active_workout_state.dart`):
```dart
ActiveWorkoutState {
  String id
  DateTime startTime
  String? routineId
  List<WorkoutExerciseState> exercises
}

WorkoutExerciseState {
  int exerciseId
  String name
  List<WorkoutSetState> sets
}

WorkoutSetState {
  String id (UUID)
  String setType ('normal', 'warmup', 'dropset', 'failure')
  double weightKg
  int reps
  bool isCompleted
}
```

**Key Actions**:
- `startWorkout({routineId, initialExercises})`: Initializes state
- `addExercise(exerciseId, name)`: Appends exercise with 1 empty set
- `addSet(exerciseIndex)`: Appends set to exercise
- `updateSet(exerciseIndex, setIndex, {weight, reps, type})`: Updates set data
- `toggleSetCompletion(exerciseIndex, setIndex)`: Marks set as complete/incomplete
- `finishWorkout()`: Batch inserts to Drift, calculates totalVolume, invalidates history
- `discardWorkout()`: Clears state

### Workout Timer
**Location**: `lib/features/workout/presentation/providers/workout_timer_provider.dart`

```dart
workoutTimerProvider: @riverpod (auto-generated)
```
- Reactive `Timer.periodic(Duration(seconds: 1))`
- Returns formatted string `"HH:MM:SS"`
- Auto-disposes when `activeWorkoutProvider` is null

### Exercise List & Search
**Location**: `lib/features/exercises/presentation/providers/exercises_provider.dart`

```dart
exerciseListProvider: @riverpod
- build(): Returns all exercises from Drift
- search(query): Updates state with filtered results
```

### Exercise Analytics
**Location**: `lib/features/exercises/presentation/providers/exercise_analytics_provider.dart`

```dart
exerciseAnalyticsProvider: StreamProvider.family<List<ExerciseHistoryData>, int>
- Watches `workoutsDao.watchExerciseHistory(exerciseId)`
- Reactive to set insertions during active workout
```

### Workout History
**Location**: `lib/features/home/presentation/providers/recent_workouts_provider.dart`

```dart
recentWorkoutsProvider: FutureProvider<List<WorkoutSession>>
- Returns last 5 sessions sorted by `startedAt DESC`
- Invalidated by `finishWorkout()`
```

### Workout Detail
**Location**: `lib/features/workout/presentation/providers/workout_detail_provider.dart`

```dart
workoutDetailProvider: StreamProvider.family<HydratedWorkout?, String>
- Watches `workoutsDao.watchHydratedWorkout(sessionId)`
- Returns joined data: session + exercises + sets + exercise metadata
```

---

## 6. FEATURES (DETAILED STATUS)

### ✅ TRACK 0-8: COMPLETE

#### ✅ Authentication (Track 1)
- **Screen**: `lib/features/auth/presentation/screens/auth_screen.dart`
- Splash → Auth Guard → Google OAuth (native mobile, web fallback)
- User profile NOT auto-created (to be added in Track 10)
- **Limitation**: No user profile sync to `user_profiles` table yet

#### ✅ Exercise Data (Track 2)
- **Seeding**: 10 core exercises via `ExercisesDao.seedDefaultExercises()`
- **Search**: Live search in `ExerciseSelectionScreen`
- **Pending**: Full ExerciseDB JSON hydration (Track 9)

#### ✅ Active Workout (Track 3)
- **Screen**: `lib/features/workout/presentation/screens/active_workout_screen.dart`
- Start empty or with routine
- Add/remove/replace exercises
- Add/remove sets
- Set type cycling (normal → warmup → dropset → failure)
- "Fat Finger" checkmark: 48x48 touch target
- Timer overlay (HH:MM:SS)
- Finish → batch insert to Drift (calculates totalVolume)

**Active Workout UI Components**:
- `ExerciseBlock`: Exercise card with sets table and 3-dot menu
- `SetRow`: Set input row (weight, reps, checkmark)
- `ActiveWorkoutBar`: Purple resume bar above bottom nav

#### ✅ Exercise Detail & Analytics (Track 4)
- **Screen**: `lib/features/exercises/presentation/screens/exercise_detail_screen.dart`
- Interactive `fl_chart` line charts
- Time filters: 1M, 3M, 6M, 1Y, All Time
- Metric toggles: Heaviest Weight, One Rep Max, Best Set, Best Volume
- Personal Records table (Heaviest, 1RM, Volume, Max Reps)
- Real-time updates via `StreamProvider`

#### ✅ Workout History (Track 5)
- **Home Screen**: Last 5 workouts with volume + date
- **Detail Screen**: `WorkoutDetailScreen` (read-only Hevy clone)
  - Session stats: Time, Volume, Sets
  - Exercise blocks with all sets
  - Actions: Save as Routine, Edit (stub), Delete

#### ✅ Routines (Track 6 — Partial)
- **Screen**: `lib/features/workout/presentation/screens/workout_screen.dart`
- Hardcoded mock routines (Push, Pull, Legs)
- Start routine → pre-loads exercises into active workout
- **Editor**: Stub screen (`RoutineEditorScreen`)
- **Pending**: Full CRUD connected to Drift `RoutinesDao`

#### ✅ UI/UX Polish (Track 8)
- Bottom navigation: Home, Routines, Profile
- Layout bounded by `Center + ConstrainedBox(maxWidth: 600)` for web
- Modal bottom sheets for context menus (20px top radius)
- Adaptive spinners/dialogs

#### ✅ Profile Screen (Track 8 — Stub)
- **Screen**: `lib/features/profile/presentation/screens/profile_screen.dart`
- Username + workout count (hardcoded mock)
- Chart placeholder
- Metric toggles (Duration, Volume, Reps)
- Action buttons: Statistics, Exercises, Measures, Calendar

---

### ❌ TRACK 9: PENDING — ExerciseDB Hydration

**Goal**: Bundle 1,500+ exercises from ExerciseDB JSON into app assets and batch-insert to Drift on first launch.

**Steps**:
1. Download ExerciseDB JSON (open-source, free)
2. Place in `assets/db/exercises.json`
3. Update `pubspec.yaml` assets section
4. Create `ExercisesDao.hydrateFromJson()` method
5. Call from `main.dart` after warm-up query, check if already seeded

**Drift Query**:
```dart
Future<void> hydrateFromJson() async {
  final count = await getExerciseCount();
  if (count > 10) return; // Already hydrated
  
  final jsonString = await rootBundle.loadString('assets/db/exercises.json');
  final List<dynamic> data = jsonDecode(jsonString);
  
  final companions = data.map((e) => ExercisesCompanion.insert(
    exerciseDbId: Value(e['id']),
    name: e['name'],
    bodyPart: e['bodyPart'],
    equipment: e['equipment'],
    target: e['target'],
    gifUrl: Value(e['gifUrl']),
    secondaryMuscles: Value(jsonEncode(e['secondaryMuscles'])),
    instructions: Value(jsonEncode(e['instructions'])),
  )).toList();
  
  await insertExercises(companions);
}
```

---

### ❌ TRACK 10: PENDING — Calendar & User Profile Sync

**Goal 1**: Build visual calendar grid in Profile tab showing workout history.

**Implementation**:
- Use `table_calendar` package or custom `GridView`
- Query `WorkoutSessions` by month
- Show colored dots on days with workouts
- Tap day → navigate to `/workout/detail/:id`

**Goal 2**: Sync Supabase user to `user_profiles` table.

**Implementation**:
```dart
// In authRepositoryProvider or splash screen
Future<void> syncUserProfile(User user) async {
  final db = ref.read(databaseProvider);
  try {
    await db.userDao.getUser(user.id);
  } catch (_) {
    // User doesn't exist, create profile
    await db.userDao.insertUser(UserProfilesCompanion.insert(
      id: Value(user.id),
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'] ?? 'User',
      createdAt: DateTime.now(),
    ));
  }
}
```

---

## 7. KNOWN LIMITATIONS & TECHNICAL DEBT

1. **No User Profile Sync**: Supabase `User` not stored in `user_profiles` table
2. **Mock Routines**: Workout screen uses hardcoded routines, not Drift data
3. **No Routine Editor**: CRUD UI not implemented (stub screen exists)
4. **No Custom Exercises**: UI not wired to `isCustom` flag
5. **No Rest Timer**: UI commented out in `ExerciseBlock`
6. **No Edit Workout**: Detail screen has "Edit" button (no-op)
7. **No Freemium Gates**: `isPremium` flag exists but unused
8. **No Supabase Sync**: `synced` flag in `workout_sessions` unused
9. **Web Performance**: Large Drift queries may lag on web (consider pagination)

---

## 8. FILE STRUCTURE (ACTUAL)

```
lib/
├── app.dart                                    // MaterialApp.router wrapper
├── main.dart                                   // Entry point, database init
│
├── core/
│   ├── database/
│   │   ├── database.dart                       // Drift database class
│   │   ├── database.g.dart                     // Generated
│   │   ├── tables/                             // Table schemas
│   │   │   ├── user_profiles_table.dart
│   │   │   ├── exercises_table.dart
│   │   │   ├── routines_table.dart
│   │   │   ├── routine_days_table.dart
│   │   │   ├── routine_exercises_table.dart
│   │   │   └── workouts_table.dart             // 3 tables: sessions, exercises, sets
│   │   └── daos/                               // Data access objects
│   │       ├── user_dao.dart
│   │       ├── exercises_dao.dart
│   │       ├── workouts_dao.dart
│   │       └── routines_dao.dart
│   ├── providers/
│   │   └── database_provider.dart              // AppDatabase singleton
│   ├── router/
│   │   └── router.dart                         // GoRouter config
│   ├── theme/
│   │   ├── app_colors.dart                     // Color tokens
│   │   └── app_theme.dart                      // ThemeData
│   └── utils/
│       └── formatters.dart                     // Date/duration helpers
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart            // Supabase wrapper
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart          // authProvider, authStateProvider
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           └── auth_screen.dart
│   │
│   ├── exercises/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── exercises_provider.dart     // exerciseListProvider
│   │       │   └── exercise_analytics_provider.dart
│   │       └── screens/
│   │           ├── exercise_selection_screen.dart
│   │           └── exercise_detail_screen.dart // fl_chart analytics
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── recent_workouts_provider.dart
│   │       └── screens/
│   │           └── home_screen.dart
│   │
│   ├── workout/
│   │   ├── domain/
│   │   │   └── active_workout_state.dart       // Freezed models
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── active_workout_provider.dart
│   │       │   ├── workout_timer_provider.dart
│   │       │   └── workout_detail_provider.dart
│   │       ├── screens/
│   │       │   ├── workout_screen.dart         // Routines list
│   │       │   ├── active_workout_screen.dart  // Live workout
│   │       │   └── workout_detail_screen.dart  // History detail
│   │       └── widgets/
│   │           ├── exercise_block.dart
│   │           └── set_row.dart
│   │
│   ├── routines/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── routine_editor_screen.dart  // Stub
│   │       └── widgets/
│   │           └── routine_card.dart
│   │
│   └── profile/
│       └── presentation/
│           └── screens/
│               └── profile_screen.dart          // Stats placeholder
│
└── shared/
    └── widgets/
        ├── app_shell.dart                      // Bottom nav wrapper
        ├── bottom_nav_bar.dart
        ├── active_workout_bar.dart             // Purple resume bar
        └── ui/
            ├── tracker_card.dart
            ├── primary_button.dart
            ├── secondary_button.dart
            └── toggle_pill.dart
```

---

## 9. DEVELOPMENT GUIDELINES

### Code Quality Rules (NON-NEGOTIABLE)

1. **State Management**: ONLY Riverpod. No `setState` or `ValueNotifier` in production code.
2. **Database Queries**: ALWAYS use Drift DAOs. No raw SQL outside DAOs.
3. **Navigation**: ONLY `context.go()` or `context.push()`. No `Navigator.of(context).push()`.
4. **Reactive Data**: Prefer `StreamProvider` over `FutureProvider` when connecting to Drift `.watch()`.
5. **UI Consistency**: Use existing primitives (`PrimaryButton`, `TrackerCard`, etc.). Do NOT create new button styles.
6. **Border Radius**: STRICT 12px. Do NOT use 8px, 16px, or other values.
7. **Color Palette**: Use ONLY tokens from `AppColors`. Do NOT hardcode hex values.
8. **Typography**: Use ONLY `google_fonts.inter()`. Do NOT use default Material fonts.
9. **Context Menus**: ALWAYS `showModalBottomSheet`. NEVER `PopupMenuButton`.
10. **Hit Targets**: Ensure 48x48 minimum for all interactive areas.

### Performance Best Practices

- **Database Warm-up**: `main.dart` runs `SELECT 1` before first frame
- **Batch Inserts**: `finishWorkout()` uses Drift `transaction()` for atomicity
- **Indexed Queries**: `exerciseId` is present in `workout_sets` for fast history lookups
- **Reactive Queries**: Use `.watch()` streams when UI must react to background changes
- **Web Constraints**: `ConstrainedBox(maxWidth: 600)` prevents layout overflow

### Testing Strategy (Future)

- Unit tests: DAO methods (mocked database)
- Widget tests: UI primitives (button states, card layout)
- Integration tests: Active workout flow (start → add set → finish)

---

## 10. NEXT STEPS (PRIORITY ORDER)

### Immediate (Track 9)
1. Download ExerciseDB JSON (~1,300 exercises)
2. Add to `assets/db/exercises.json`
3. Implement `ExercisesDao.hydrateFromJson()`
4. Call from `main.dart` after seeding check

### Short-term (Track 10)
1. Build calendar widget in Profile screen
2. Wire to `WorkoutSessions` query
3. Add user profile sync in splash screen
4. Display real username + workout count

### Medium-term
1. Full Routine CRUD (replace mock routines)
2. Custom exercise creator
3. Rest timer implementation
4. Edit workout functionality

### Long-term (Not Scoped)
1. Freemium gates + paywall
2. Supabase sync for multi-device
3. Social features (sharing PRs)
4. Advanced analytics (volume trends, muscle group splits)

---

## 11. ACKNOWLEDGEMENT FOR AI AGENTS

**If you are an AI agent reading this document**:

1. **DO NOT** suggest implementing features that are marked ✅ (already complete).
2. **DO NOT** propose alternative state management (e.g., BLoC, GetX). We use Riverpod.
3. **DO NOT** suggest UI redesigns that violate the 12px border radius rule.
4. **DO NOT** recommend Firebase, Hive, or other databases. We use Drift + Supabase.
5. **DO** check this document before writing code to understand existing patterns.
6. **DO** ask clarifying questions if a feature's implementation status is unclear.
7. **DO** follow the "High-Density Tracker" design system strictly.

---

**End of Context Document**

**Version Control**: This file must be updated whenever:
- A new feature track is completed
- A breaking change is made to database schema
- A new design system token is added
- A major architectural decision is made

**Maintainer**: Principal Staff Engineer (Human + AI Collaboration)
