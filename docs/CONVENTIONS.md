# CONVENTIONS.md

## File Naming

| Pattern | Convention | Examples |
|---|---|---|
| Dart files | `snake_case.dart` | `active_workout_provider.dart`, `exercise_gif_widget.dart` |
| Generated Drift | `*.g.dart` | `database.g.dart`, `exercises_dao.g.dart` |
| Generated Freezed | `*.freezed.dart` | `active_workout_state.freezed.dart` |
| Generated Riverpod | `*.g.dart` | `exercises_provider.g.dart`, `workout_timer_provider.g.dart` |
| Screens | `*_screen.dart` | `home_screen.dart`, `active_workout_screen.dart` |
| Providers | `*_provider.dart` | `auth_provider.dart`, `routines_provider.dart` |
| DAOs | `*_dao.dart` | `workouts_dao.dart`, `exercises_dao.dart` |
| Tables | `*_table.dart` | `workouts_table.dart`, `exercises_table.dart` |
| Feature widgets | descriptive | `exercise_block.dart`, `set_row.dart`, `routine_card.dart` |
| Shared widgets | descriptive | `tracker_card.dart`, `primary_button.dart`, `toggle_pill.dart` |

---

## Class Naming

| Category | Convention | Examples |
|---|---|---|
| Screens | `PascalCase` + `Screen` | `HomeScreen`, `ActiveWorkoutScreen`, `RoutineDetailScreen` |
| Notifiers | `PascalCase` + `Notifier` | `ActiveWorkoutNotifier`, `ExerciseList` (code-gen exception) |
| DAOs | `PascalCase` + `Dao` | `WorkoutsDao`, `ExercisesDao`, `RoutinesDao` |
| Drift Table definitions | Plural `PascalCase` | `WorkoutSessions`, `RoutineExercises` |
| Drift data classes | Singular `PascalCase` | `WorkoutSession`, `Exercise`, `Routine` |
| Hydrated wrappers | `Hydrated` + singular | `HydratedWorkout`, `HydratedRoutine` |
| State classes (Freezed) | `PascalCase` + `State` | `ActiveWorkoutState`, `WorkoutExerciseState`, `WorkoutSetState` |
| Repositories | `PascalCase` + `Repository` | `AuthRepository` |
| Theme/color classes | `App` prefix | `AppColors`, `AppTheme` (via `appTheme` constant) |
| Private helpers | `_PascalCase` or `_camelCase` | `_GoRouterRefreshStream`, `_NavItem`, `_NavButton` |

---

## Provider Naming

| Pattern | Convention | Examples |
|---|---|---|
| Manual `Provider<T>` | `camelCase` + `Provider` | `databaseProvider`, `authProvider`, `routerProvider` |
| `StreamProvider` | `camelCase` + `Provider` | `hydratedRoutinesProvider`, `workoutCountProvider` |
| `FutureProvider` | `camelCase` + `Provider` | `recentWorkoutsProvider` |
| `StateNotifierProvider` | `camelCase` + `Provider` | `activeWorkoutProvider` |
| Code-gen `@riverpod` | accessed as `camelCase` + `Provider` | `exerciseListProvider`, `workoutTimerProvider` |
| `.family` variants | `camelCase` + `Provider(param)` at call site | `routineDetailProvider(routineId)`, `workoutDetailProvider(sessionId)`, `exerciseAnalyticsProvider(exerciseId)` |
| Notifier access | `ref.read(xyzProvider.notifier)` | `ref.read(activeWorkoutProvider.notifier)` |

---

## Folder Structure Rules

```
lib/
├── core/           # Infrastructure: DB, router, theme, utils, providers
│   ├── database/   # Single AppDatabase + tables/ + daos/
│   ├── providers/  # Infrastructure-level providers (databaseProvider)
│   ├── router/     # routerProvider only
│   ├── theme/      # AppColors + appTheme
│   └── utils/      # Pure functions (no state, no widgets)
├── features/       # Feature slices, each self-contained
│   └── <feature>/
│       ├── data/           # Repositories, external data adapters
│       ├── domain/         # Business logic state (Freezed models) — only workout has this
│       └── presentation/
│           ├── providers/  # Riverpod providers for this feature
│           ├── screens/    # Full-page widgets
│           └── widgets/    # Feature-scoped reusable widgets
└── shared/
    └── widgets/
        ├── ui/             # Atom-level design system components
        └── *.dart          # App-level shared widgets (AppShell, BottomNavBar, etc.)
```

**Rules:**
- Only `workout` has a `domain/` layer. Other features put Freezed models in `domain/` if/when they have in-memory business logic.
- DAOs live in `core/database/daos/`, not in feature folders. All features access them through `databaseProvider`.
- Repositories (e.g., `AuthRepository`) live in `features/<feature>/data/`.
- Never import a feature's internals from another feature. Cross-feature dependencies go through `core/` providers or the shared `databaseProvider`.

---

## Screen Structure Pattern

All screen widgets follow this structure:

```dart
class XyzScreen extends ConsumerWidget {       // or ConsumerStatefulWidget
  const XyzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(                          // always present unless fullscreen modal
        title: Text('Title', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28)),
      ),
      body: SingleChildScrollView(            // or ListView.builder for long lists
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),  // 120px bottom = nav bar clearance
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...]),
      ),
    );
  }
}
```

**Non-AppBar screens** (auth, onboarding, splash, profile) use `SafeArea` as the body wrapper.

**Modal/fullscreen screens** (active workout) omit AppBar; use custom header inside the body column.

---

## Async State Pattern

All provider-driven data uses `.when()`:

```dart
ref.watch(someProvider).when(
  data: (value) => Widget(...),
  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
  error: (e, _) => TrackerCard(child: Text('Error message', style: GoogleFonts.inter(color: AppColors.error))),
);
```

- Loading state: `CircularProgressIndicator(color: AppColors.accentPrimary)` centered
- Error state: `TrackerCard` with red `AppColors.error` text
- Never use `AsyncValue.valueOrNull` for primary content rendering (only for AppBar titles)

---

## Bottom Sheet Menu Pattern

All 3-dot / contextual menus use `showModalBottomSheet` — never `PopupMenuButton`. Consistent structure:

```dart
showModalBottomSheet(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (ctx) => Container(
    decoration: const BoxDecoration(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      // Drag handle:
      Container(width: 36, height: 4,
        decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      // Items: ListTile with leading Icon and GoogleFonts.inter title
      // Destructive items: color: AppColors.error on both icon and text
      const SizedBox(height: 16),
    ]),
  ),
);
```

---

## Color Usage Rules

- All colors from `AppColors` static constants — never `Colors.xxx` (except `Colors.transparent`)
- Background layers: `bgBase` (screen scaffold), `bgSurface` (cards, sheets, inputs)
- Text: `textPrimary` (white) for content, `textSecondary` (grey #8E8E93) for labels/metadata
- Accent: `accentPrimary` (purple) for primary actions, active states, and exercise names
- Status: `error` (red) for destructive actions and error states, `success` (green) for completed sets, `warning` (yellow) for warmup sets
- Semi-transparent: use `.withValues(alpha: x)` not `.withOpacity(x)` (project uses the newer API)

---

## Typography Rules

- All text uses `GoogleFonts.inter(...)` explicitly — never rely on `Theme.of(context).textTheme`
- Font weights used: `w400` (body), `w500` (labels), `w600` (secondary buttons), `w700` (headings, primary buttons), `w800` (hero text)
- AppBar title: `fontSize: 28, fontWeight: w700, letterSpacing: -0.5`
- Screen section headers: `fontSize: 20, fontWeight: w700`
- Card titles: `fontSize: 18, fontWeight: w700`
- Body / list items: `fontSize: 16, fontWeight: w600`
- Metadata / timestamps: `fontSize: 12–13, fontWeight: w400, color: textSecondary`

---

## Shared UI Component Usage

| Component | Use case |
|---|---|
| `PrimaryButton` | Primary CTA (Start Workout, Finish, Get Started, Save) — 48px, purple |
| `SecondaryButton` | Secondary action (New Routine, + Add Exercise, + Add Set) — 48px, bgSurface |
| `TrackerCard` | Any card container. Pass `onTap` to make it tappable via InkWell |
| `TogglePill` | Horizontal scrollable metric selector (Duration / Volume / Reps) |
| `ExerciseGifWidget` | Any place an exercise GIF is needed — handles null URL, loading, error |
| `ActiveWorkoutBar` | Rendered by `AppShell` automatically when `activeWorkoutProvider != null` |

---

## Spacing Constants

No named spacing constants — all inline:

| Usage | Value |
|---|---|
| Screen horizontal padding | `16.0` |
| Screen bottom padding | `120.0` (clears nav bar + active workout bar) |
| Card padding | `16.0` (TrackerCard default) |
| Between sections | `16.0` or `24.0` |
| Between items in lists | `8.0` or `12.0` |
| Between icon and text in buttons | `8.0` |
| Bottom sheet drag handle height | `4.0`, width `36.0` |
