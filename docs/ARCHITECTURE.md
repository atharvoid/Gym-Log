
# ARCHITECTURE.md

## Folder Structure

```
lib/
├── main.dart                   # Bootstrap: bindings, dotenv, Supabase init, DB warmup, JSON hydration, ProviderScope
├── app.dart                    # Root widget: MaterialApp.router consuming routerProvider
├── core/
│   ├── database/
│   │   ├── database.dart       # AppDatabase (@DriftDatabase), _openConnection → NativeDatabase to getApplicationDocumentsDirectory
│   │   ├── database.g.dart     # Generated Drift code
│   │   ├── tables/             # 6 Table subclasses (one file each)
│   │   └── daos/               # 4 DatabaseAccessor subclasses (one file + .g.dart each)
│   ├── providers/
│   │   └── database_provider.dart   # Provider<AppDatabase> — overridden at root with pre-initialized instance
│   ├── router/
│   │   └── router.dart              # routerProvider → GoRouter with _GoRouterRefreshStream on Supabase auth
│   ├── theme/
│   │   ├── app_colors.dart          # Abstract class, all static Color constants
│   │   └── app_theme.dart           # ThemeData (Material3, dark, Inter font)
│   └── utils/
│       └── formatters.dart          # formatWorkoutDuration(), getWorkoutNameFallback()
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart        # AuthRepository: Google Sign-In (native + web OAuth via Supabase)
│   │   └── presentation/
│   │       ├── providers/auth_provider.dart # authRepositoryProvider, authStateProvider, authProvider
│   │       └── screens/                    # auth_screen, onboarding_screen, splash_screen
│   ├── exercises/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── exercises_provider.dart          # @riverpod ExerciseList notifier (FutureProvider-style with search mutation)
│   │       │   └── exercise_analytics_provider.dart # StreamProvider.family<List<ExerciseHistoryData>, int>
│   │       └── screens/                             # exercise_selection_screen, exercise_detail_screen
│   ├── home/
│   │   └── presentation/
│       ├── providers/home_provider.dart  # workoutCompletedSignalProvider (StateProvider<int>), WorkoutHistoryNotifier, workoutHistoryProvider (StateNotifierProvider, page 10)
│   │       ├── screens/home_screen.dart
│   │       └── widgets/workout_history_card.dart  # WorkoutHistoryCard(preview: WorkoutSessionPreview)
│   ├── profile/
│   │   └── presentation/
│   │       ├── providers/profile_provider.dart  # workoutCountProvider, currentUserProfileProvider
│   │       └── screens/profile_screen.dart
│   ├── routines/
│   │   └── presentation/
│   │       ├── providers/routines_provider.dart  # hydratedRoutinesProvider, routineDetailProvider
│   │       ├── screens/                          # routine_detail_screen, routine_editor_screen
│   │       └── widgets/routine_card.dart
│   └── workout/
│       ├── domain/
│       │   ├── active_workout_state.dart          # @freezed state classes: WorkoutSetState, WorkoutExerciseState, ActiveWorkoutState
│       │   └── active_workout_state.freezed.dart  # Generated
│       └── presentation/
│           ├── providers/
│           │   ├── active_workout_provider.dart    # StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>
│           │   ├── workout_detail_provider.dart    # StreamProvider.family<HydratedWorkout?, String>
│           │   ├── workout_timer_provider.dart     # @riverpod WorkoutTimer notifier (1-second Timer.periodic)
│           │   └── workout_timer_provider.g.dart
│           ├── screens/
│           │   ├── active_workout_screen.dart   # Full-screen modal workout logger
│           │   ├── workout_screen.dart          # "Routines" tab — collapsible routine list
│           │   └── workout_detail_screen.dart   # Post-workout read-only summary
│           └── widgets/
│               ├── exercise_block.dart          # Per-exercise container with set rows and 3-dot menu
│               └── set_row.dart                 # Weight/reps text inputs, type cycler, completion checkmark
└── shared/
    └── widgets/
        ├── active_workout_bar.dart   # Purple resume banner shown above BottomNavBar
        ├── app_shell.dart            # ShellRoute body: maxWidth 600, SafeArea, BottomNavBar stack
        ├── bottom_nav_bar.dart       # 3-tab custom nav (Home / Routines / Profile)
        ├── exercise_gif_widget.dart  # CachedNetworkImage GIF with disk-persistent cache
        └── ui/
            ├── primary_button.dart    # 48px purple ElevatedButton
            ├── secondary_button.dart  # 48px bgSurface ElevatedButton
            ├── toggle_pill.dart       # Animated pill (AnimatedContainer, 200ms)
            └── tracker_card.dart      # bgSurface container, 12px radius, optional InkWell
```

---

## State Management

Riverpod with **mixed styles** — partially migrated to code generation.

| Provider | Type | File | Notes |
|---|---|---|---|
| `databaseProvider` | `Provider<AppDatabase>` | `core/providers/database_provider.dart` | Overridden at root in `main.dart` |
| `routerProvider` | `Provider<GoRouter>` | `core/router/router.dart` | Consumes Supabase auth stream |
| `authRepositoryProvider` | `Provider<AuthRepository>` | `auth/presentation/providers/auth_provider.dart` | Wraps `Supabase.instance.client` |
| `authStateProvider` | `StreamProvider<AuthState>` | `auth/presentation/providers/auth_provider.dart` | Supabase auth state stream |
| `authProvider` | `Provider<User?>` | `auth/presentation/providers/auth_provider.dart` | Derived from `authStateProvider` with `currentUser` fallback |
| `activeWorkoutProvider` | `StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>` | `workout/presentation/providers/active_workout_provider.dart` | Manual (not code-gen); entire session lives in memory until `finishWorkout()` |
| `workoutTimerProvider` | `@riverpod` class | `workout/presentation/providers/workout_timer_provider.dart` | Code-gen; `Timer.periodic` 1s, watches `activeWorkoutProvider` |
| `workoutDetailProvider` | `StreamProvider.family<HydratedWorkout?, String>` | `workout/presentation/providers/workout_detail_provider.dart` | Keyed by `sessionId` |
| `exerciseListProvider` | `@riverpod` class (async notifier) | `exercises/presentation/providers/exercises_provider.dart` | Code-gen; supports `search(query)` mutation |
| `exerciseAnalyticsProvider` | `StreamProvider.family<List<ExerciseHistoryData>, int>` | `exercises/presentation/providers/exercise_analytics_provider.dart` | Keyed by `exerciseId` |
| `workoutCompletedSignalProvider` | `StateProvider<int>` | `home/presentation/providers/home_provider.dart` | Counter incremented by `ActiveWorkoutNotifier.finishWorkout()`; watched by `WorkoutHistoryNotifier` via `ref.listen` to trigger `_reset()` |
| `workoutHistoryProvider` | `StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>` | `home/presentation/providers/home_provider.dart` | Paginated (page size 10, limit+1 for `hasMore`); `fetchNextPage()` appends; auto-resets on signal change |
| `hydratedRoutinesProvider` | `StreamProvider<List<HydratedRoutine>>` | `routines/presentation/providers/routines_provider.dart` | Reactive; returns `Stream.value([])` when user is null |
| `routineDetailProvider` | `StreamProvider.family<HydratedRoutine?, String>` | `routines/presentation/providers/routines_provider.dart` | Keyed by `routineId` |
| `workoutCountProvider` | `StreamProvider<int>` | `profile/presentation/providers/profile_provider.dart` | Count of completed sessions |
| `currentUserProfileProvider` | `StreamProvider<UserProfile?>` | `profile/presentation/providers/profile_provider.dart` | Reactive local profile |

### `ActiveWorkoutNotifier` Methods
`startWorkout()`, `finishWorkout()`, `discardWorkout()`, `addExercise()`, `addSet()`, `updateSet()`, `removeExercise()`, `replaceExercise()`, `toggleSetCompletion()`

`finishWorkout()` performs the full DB write transaction: inserts `WorkoutSession`, `WorkoutExercise` rows, and `WorkoutSet` rows for all completed sets. Skips exercises with zero completed sets. Then calls `WorkoutsDao.detectAndMarkPrs(sessionId, startTime)` for post-workout PR detection (marks `is_pr = true` and writes `estimated_1rm` for the best Epley-1RM set per exercise if it beats all prior sessions). Finally increments `workoutCompletedSignalProvider.notifier.state` to trigger `WorkoutHistoryNotifier._reset()`.

---

## Navigation (GoRouter)

### Auth Redirect Logic

`_GoRouterRefreshStream` wraps `Supabase.instance.client.auth.onAuthStateChange` as a `ChangeNotifier`, so GoRouter re-evaluates the redirect on every auth state change.

**Redirect rules:**
- `/splash` and `/onboarding` → always allowed (no redirect)
- `!isSignedIn && !isAuthRoute` → `/auth`
- `isSignedIn && isAuthRoute` → `/`

### Route Table

| Path | Widget | Type | Params |
|---|---|---|---|
| `/splash` | `SplashScreen` | `GoRoute` | — |
| `/auth` | `AuthScreen` | `GoRoute` | — |
| `/onboarding` | `OnboardingScreen` | `GoRoute` | — |
| `/` | `HomeScreen` (shell) | `ShellRoute` child | — |
| `/workout` | `WorkoutScreen` (shell) | `ShellRoute` child | — |
| `/profile` | `ProfileScreen` (shell) | `ShellRoute` child | — |
| `/exercises/select` | `ExerciseSelectionScreen` | `GoRoute` | — |
| `/exercise/detail` | `ExerciseDetailScreen` | `GoRoute` | `state.extra as Exercise` |
| `/routines/edit` | `RoutineEditorScreen` | `GoRoute` | — |
| `/routines/:id` | `RoutineDetailScreen` | `GoRoute` | `pathParameters['id']` |
| `/workout/active` | `ActiveWorkoutScreen` | `GoRoute` (fullscreenDialog) | — |
| `/workout/detail/:id` | `WorkoutDetailScreen` | `GoRoute` | `pathParameters['id']` |

**Shell:** `AppShell` wraps `/`, `/workout`, `/profile` — provides `BottomNavBar` + optional `ActiveWorkoutBar`.

**Navigation inconsistency:** `ExerciseSelectionScreen` is launched via `Navigator.push<Exercise>` from `ActiveWorkoutScreen` (returns selected exercise as pop result). Should be `context.push` per architecture directive.

**Object passing:** `/exercise/detail` passes `Exercise` object via `state.extra`. Architecture directive says pass IDs only.

---

## Key Widget Tree Patterns

### Shell Screen Structure
```
AppShell (ShellRoute builder)
  └── Scaffold(bgBase)
        ├── body: SafeArea → ConstrainedBox(maxWidth: 600) → child (screen)
        └── bottomNavigationBar: Column
              ├── ActiveWorkoutBar (if activeWorkoutProvider != null)
              └── BottomNavBar
```

### Scrollable Screen Pattern
```
Scaffold(bgBase)
  ├── AppBar (GoogleFonts.inter, w700, 28px, bgBase, elevation 0)
  └── body: SingleChildScrollView(padding: fromLTRB(16, 16, 16, 120))
        └── Column(crossAxisAlignment: start)
              └── [TrackerCard widgets, PrimaryButton, etc.]
```

### List Screen Pattern
```
Scaffold
  └── body: ListView.builder(padding: fromLTRB(16, 16, 16, 120))
        └── itemBuilder: index == lastItem → footer (button), else → content row
```

### HomeScreen Infinite Scroll Pattern
```
ListView.builder(itemCount: 3 + items.length)  // 1 QuickStart + 1 header + N cards + 1 footer
  └── itemBuilder(context, index)
        ├── index 0 → QuickStart TrackerCard (PrimaryButton)
        ├── index 1 → "Workout History" Text section header
        ├── index 2..N+1 → WorkoutHistoryCard(preview: items[index - 2])
        │     └── Pagination trigger: when historyIndex >= totalItems - 3 && hasMore && !isLoadingMore
        │           → Future.microtask(() => notifier.fetchNextPage())
        └── index N+2 (footer)
              ├── isLoadingMore → CircularProgressIndicator(color: accentPrimary)
              ├── items.isEmpty → TrackerCard("No workouts yet")
              └── !hasMore && items.isNotEmpty → Text("All caught up")
```

`WorkoutHistoryCard` wraps in `TrackerCard(onTap: context.push('/workout/detail/\${session.id}'))`. Displays: workout name (left), date · duration (right), top 2 exercises with 52×52 GIF + name + set count, "+ N more" overflow text, divider, stats row (volume, duration, and PRs in `AppColors.warning` if `prCount > 0`).

### Bottom Sheet Menu Pattern (used everywhere for 3-dot menus)
```
showModalBottomSheet(backgroundColor: transparent)
  └── Container(decoration: bgSurface, radius: vertical(top: 20))
        └── Column(mainAxisSize: min)
              ├── SizedBox(h:12) + drag handle Container(w:36, h:4, bgSurface→borderSubtle)
              ├── ListTile items...
              └── SizedBox(h:16)
```

### Active Workout Screen Structure
```
Scaffold(bgBase, no AppBar)
  └── Column
        ├── Header: Container(bgSurface) → SafeArea(bottom:false) → Row [close | timer | Finish]
        └── Expanded: ListView.builder
              ├── ExerciseBlock × N
              └── Footer: SecondaryButton("+ Add Exercise")
```

### ExerciseBlock Structure
```
Container(bgSurface, radius: 12)
  └── Column
        ├── Row [exercise name (tappable → /exercise/detail) | IconButton(more_vert)]
        ├── Column headers row (SET / PREVIOUS / KG / REPS / ✓)
        ├── SetRow × N
        └── SecondaryButton("+ Add Set")
```
