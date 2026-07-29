# Coding Conventions

**Analysis Date:** 2026-07-29

## Naming Patterns

**Files:**
- Dart source files: `snake_case.dart` — e.g., `active_workout_provider.dart`, `exercise_gif_widget.dart`
- Screens: `*_screen.dart` — e.g., `home_screen.dart`, `active_workout_screen.dart`
- Providers: `*_provider.dart` — e.g., `auth_provider.dart`, `routines_provider.dart`
- DAOs: `*_dao.dart` — e.g., `workouts_dao.dart`, `exercises_dao.dart`
- Drift Tables: `*_table.dart` — e.g., `workouts_table.dart`, `exercises_table.dart`
- Generated Drift: `*.g.dart` — e.g., `database.g.dart`, `exercises_dao.g.dart`
- Generated Freezed: `*.freezed.dart` — e.g., `active_workout_state.freezed.dart`
- Generated Riverpod: `*.g.dart` from `@riverpod` — e.g., `exercises_provider.g.dart`, `workout_timer_provider.g.dart`
- Shared widgets: descriptive names — `tracker_card.dart`, `primary_button.dart`, `toggle_pill.dart`
- Feature widgets: descriptive names — `exercise_block.dart`, `set_row.dart`, `routine_card.dart`

**Classes:**
- Screens: `PascalCase` + `Screen` — `HomeScreen`, `ActiveWorkoutScreen`, `RoutineDetailScreen`
- Notifiers: `PascalCase` + `Notifier` — `ActiveWorkoutNotifier`, `ExerciseList` (code-gen exception, class name without Notifier suffix)
- DAOs: `PascalCase` + `Dao` — `WorkoutsDao`, `ExercisesDao`, `RoutinesDao`
- Drift Table definitions: Plural `PascalCase` — `WorkoutSessions`, `RoutineExercises`
- Drift data classes: Singular `PascalCase` — `WorkoutSession`, `Exercise`, `Routine` (via `@DataClassName`)
- Hydrated wrappers: `Hydrated` + singular — `HydratedWorkout`, `HydratedRoutine`
- State classes (Freezed): `PascalCase` + `State` — `ActiveWorkoutState`, `WorkoutExerciseState`, `WorkoutSetState`
- Repositories: `PascalCase` + `Repository` — `AuthRepository`
- Theme/color classes: `App` prefix — `AppColors`, `AppTheme` (via `appTheme` constant), `AppText`
- Private helpers: `_PascalCase` or `_camelCase` — `_GoRouterRefreshStream`, `_NavItem`, `_NavButton`

**Functions:**
- `camelCase` for all functions and methods — `saveDraftNow()`, `_updateElapsed()`, `wipeAllData()`

**Variables & Constants:**
- `camelCase` for local variables and fields — `final accent`, `lastAppDatabase`
- `lowerCamelCase` for const values in `AppColors` — `accentPrimary`, `bgBase`
- `k` prefix for module-level constants — `kSetColW`, `kCheckColW`, `kRewardGold`, `kFreeRoutineLimit`, `kRestTileHeight`

**Types:**
- `PascalCase` for all types — `WorkoutSetState`, `HydratedWorkout`, `WeeklyAggregate`
- Private types use `_PascalCase` — `_DummyQueryExecutorUser`

## Import Organization

**Order:**
1. Dart SDK imports (`dart:async`, `dart:ffi`, `dart:io`)
2. Flutter SDK imports (`package:flutter/material.dart`, `package:flutter_test/flutter_test.dart`)
3. External package imports (alphabetical) — `package:drift/...`, `package:flutter_riverpod/...`, `package:freezed_annotation/...`
4. Project imports (`package:gymlog/...`) — grouped by layer: core → features → shared
5. Part declarations (`part '...'`)

**Path Aliases:**
- All imports use `package:gymlog/...` — no relative imports in lib/ source (relative imports like `../../../../` appear in some older files)
- Barrel files: Not used. Each file imports exactly what it needs.

## Code Style

**Formatting:**
- Tool: `dart format` (enforced in CI via `--set-exit-if-changed`)
- Enforced by CI gate in `.github/workflows/ci.yml`

**Linting:**
- Tool: `flutter analyze --fatal-infos --fatal-warnings` (zero tolerance)
- Base config: `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`
- Plugin: `custom_lint` with `riverpod_lint` activated
- Custom lint rules disabled:
  - `missing_provider_scope: false` — allows scoped ProviderScope overrides for testing
  - `avoid_manual_providers_as_generated_provider_dependency: false` — allows mixed manual + code-gen providers
- `use_build_context_synchronously: error` — promoted to hard error
- Generated files excluded: `**/*.g.dart`, `**/*.freezed.dart`

**Additional verification in `scripts/verify.ps1`:**
- Inline `GoogleFonts.inter()` calls prohibited outside `app_text.dart` and `app_theme.dart`
- Non-semantic `AppColors.*` usages prohibited in migrated screen files (only `error`, `success`, `warning`, `rewardGold`, `cardGradient` allowed)

## Riverpod Provider Conventions

**Two patterns are used — manual and code-generated:**

### Manual Providers (older pattern)

```dart
// ActiveWorkoutNotifier — manual StateNotifier (lib/features/workout/presentation/providers/active_workout_provider.dart)
class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref _ref;

  ActiveWorkoutNotifier(this._ref) : super(null) {
    addListener(_persistDraftOnChange, fireImmediately: false);
  }
  // ...
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>((ref) {
  return ActiveWorkoutNotifier(ref);
});
```

- Manual `Provider<T>`, `StreamProvider`, `FutureProvider`, `StateNotifierProvider` for infrastructure and older features
- Used for `databaseProvider`, `authProvider`, `routerProvider`, `activeWorkoutProvider`, `homeProvider`
- Notifier classes receive `Ref` in constructor and store as `_ref`

### Code-Gen `@riverpod` (newer pattern)

```dart
// WorkoutTimer (lib/features/workout/presentation/providers/workout_timer_provider.dart)
part 'workout_timer_provider.g.dart';

@riverpod
class WorkoutTimer extends _$WorkoutTimer {
  Timer? _timer;

  @override
  String build() {
    final workout = ref.watch(activeWorkoutProvider);
    // ...
    return state;
  }
}
```

```dart
// ExerciseList (lib/features/exercises/presentation/providers/exercises_provider.dart)
part 'exercises_provider.g.dart';

@riverpod
class ExerciseList extends _$ExerciseList {
  @override
  Future<List<Exercise>> build() async {
    final db = ref.watch(databaseProvider);
    return db.exercisesDao.getAllExercises();
  }

  Future<void> search(String query) async { /* mutate state */ }
}
```

- Use `@riverpod` annotation on class extending `_$YourProvider`
- Override `build()` method (synchronous or async)
- Access generated provider as `ref.watch(exerciseListProvider)`
- `.family` variants via `StreamProvider.family` manually for now

### Provider Naming (access patterns)

| Pattern | Access | Example |
|---------|--------|---------|
| Manual `Provider<T>` | `ref.watch(databaseProvider)` | `databaseProvider` |
| Manual `StateNotifierProvider` | `ref.watch(activeWorkoutProvider)` | `activeWorkoutProvider` |
| Code-gen `@riverpod` | `ref.watch(workoutTimerProvider)` | `workoutTimerProvider` |
| `.family` variants | `ref.watch(routineDetailProvider(routineId))` | `routineDetailProvider` |
| Notifier access | `ref.read(xyzProvider.notifier)` | `ref.read(activeWorkoutProvider.notifier)` |

### Provider Guidelines

- All providers use `camelCase` naming with `Provider` suffix
- Infrastructure providers in `lib/core/providers/` — `databaseProvider`, `settingsProvider`, `premiumProvider`
- Feature providers in `lib/features/<feature>/presentation/providers/`
- `databaseProvider` must be overridden in `ProviderScope` (throws `UnimplementedError` by default)
- Use `ref.invalidate(provider)` for refresh, not manual state mutation

## Widget Conventions

**Screen Pattern:**
- All screens extend `ConsumerWidget` or `ConsumerStatefulWidget` — never plain `StatelessWidget`/`StatefulWidget`
- Use `ConsumerWidget` for read-only screens, `ConsumerStatefulWidget` only when local state or lifecycle is needed

```dart
class XyzScreen extends ConsumerWidget {
  const XyzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text('Title', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...]),
      ),
    );
  }
}
```

- AppBar always present unless fullscreen modal (active workout, auth, splash)
- Body padding bottom: `120.0` to clear nav bar + active workout bar
- Non-app bar screens (auth, onboarding, splash, profile) use `SafeArea` as body wrapper
- Modal/fullscreen screens (active workout) omit AppBar; use custom header

**Shared Widgets:**
- Atom-level components in `lib/shared/widgets/ui/` — `PrimaryButton`, `SecondaryButton`, `TrackerCard`, `TogglePill`
- App-level shared widgets at `lib/shared/widgets/` — `AppShell`, `BottomNavBar`, `ExerciseGifWidget`
- Motion widgets in `lib/shared/widgets/motion/` — `PressableScale`, `EntranceFade`, `AppMotion`
- Feedback widgets in `lib/shared/widgets/feedback/` — `UndoableDelete`
- All shared widgets are `StatelessWidget` or `StatefulWidget` (not ConsumerWidget, they receive data via constructor)
- Shared widgets access accent via `context.accent` extension, not provider watching

**Async State Pattern:**
- All provider-driven data uses `.when()`:

```dart
ref.watch(someProvider).when(
  data: (value) => Widget(...),
  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
  error: (e, _) => TrackerCard(child: Text('Error message', style: GoogleFonts.inter(color: AppColors.error))),
);
```

- Loading: `CircularProgressIndicator(color: AppColors.accentPrimary)` centered
- Error: `TrackerCard` with red `AppColors.error` text
- Never use `AsyncValue.valueOrNull` for primary content rendering (only for AppBar titles)

**Bottom Sheet Pattern:**
- All contextual menus use `showModalBottomSheet` — never `PopupMenuButton`
- Consistent structure: translucent background, 20px top radius, drag handle, `ListTile` items

## Drift / Database Conventions

**Table Definitions (`lib/core/database/tables/*_table.dart`):**

```dart
// workouts_table.dart
@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- Tables are plural `PascalCase` (Drift convention)
- Data classes are singular via `@DataClassName('WorkoutSession')`
- UUID generation at client side via `clientDefault(() => const Uuid().v4())`
- Foreign keys via `.references(OtherTable, #id)` syntax
- `primaryKey` override always returns `{id}`

**DAOs (`lib/core/database/daos/*_dao.dart`):**

```dart
part 'workouts_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions, WorkoutExercises, WorkoutSets])
class WorkoutsDao extends DatabaseAccessor<AppDatabase> with _$WorkoutsDaoMixin {
  WorkoutsDao(AppDatabase db) : super(db);
  // Query methods use Drift's type-safe select/insert/update/delete
}
```

- DAOs extend `DatabaseAccessor<AppDatabase>` with generated mixin
- All DAOs registered in `@DriftDatabase` annotation on `AppDatabase`
- `AppDatabase.forTesting(NativeDatabase.memory())` used for tests

**Migrations:**
- Defined in `AppDatabase.migration.onUpgrade` in `database.dart`
- Each version jump is explicit (`if (from < N)`)
- Schema version tracked via `kDatabaseSchemaVersion` constant
- Indexes created idempotently in `beforeOpen` via `CREATE INDEX IF NOT EXISTS`
- `PRAGMA foreign_keys = ON` enforced in `beforeOpen`

**`wipeAllData()`:**
- Ordered child→parent deletion for account cleanup
- Used by account deletion flow, followed by catalog re-seeding

## Theme Conventions

**Color Architecture — Two Layers:**

1. **Brand Accent (reactive)** — user-pickable hue via `ThemePalette`. Read via `context.accent.*`:
   - `context.accent.base` — primary CTA fill, active states, selected borders (100% saturation)
   - `context.accent.light` — accent text/hairlines (WCAG-safe on black)
   - `context.accent.dark` — pressed/depressed states
   - `context.accent.muted` / `tint` — 14% alpha for tinted fills
   - `context.accent.glow` — 12% alpha for atmospheric effects
   - `context.accent.onAccent` — text/icon on full-saturation base
   - `context.accent.selectionBorder` — 35% alpha for selected borders

2. **Semantic colors (fixed)** — never change with accent:
   - `AppColors.error` — red (#FF3B30), destructive actions/errors
   - `AppColors.accentSuccess` — green (#34C759), completed sets
   - `AppColors.accentWarning` — amber (#FF9F0A), warmup sets
   - `AppColors.accentReward` — gold (#E6C84A), PR celebrations
   - `AppColors.accentInfo` — cyan (#00D9FF), rest timer

**Surface Hierarchy (AMOLED-first):**
- `AppColors.bgBase` — #000000 (pure black void)
- `AppColors.bgSurface` — #0D0D0D (default card)
- `AppColors.surface2` — #141414 (elevated cards)
- `AppColors.surface3` — #1C1C1C (inputs, secondary buttons)
- `AppColors.surface4` — #242424 (menus, action sheets)
- Access via `context.surface.bgBase` / `.surface2` / etc. (switches between dark/light based on palette)

**Color Usage Rules:**
- All colors from `AppColors` static constants — never `Colors.xxx` (except `Colors.transparent`)
- Use `.withValues(alpha: x)` not `.withOpacity(x)` (newer API)
- Every palette uses `Brightness.dark` and `ColorScheme.dark` — "White" is a white accent on dark canvas
- Typography: all via `GoogleFonts.inter(...)` — never `Theme.of(context).textTheme` directly
- Font weights: `w400` body, `w500` labels, `w600` secondary buttons, `w700` headings, `w800` hero text

## Freezed & Code Generation Conventions

**Freezed Models (state classes):**

```dart
// active_workout_state.dart
@freezed
class WorkoutSetState with _$WorkoutSetState {
  @Assert("id != ''", 'Set ID must not be empty')
  const factory WorkoutSetState({
    required String id,
    @Default('normal') String setType,
    double? weightKg,
    @Default(0) int reps,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
  }) = _WorkoutSetState;
}
```

- Freezed for in-memory business logic state (only `workout` feature has a `domain/` layer)
- `@Default(value)` for optional fields with defaults
- `@Assert()` for validation assertions
- Private implementation class `_WorkoutSetState`
- Use `factory` constructors for custom creation (`WorkoutSetState.create()`)

**What requires `build_runner`:**
- Drift tables/DAOs → `*.g.dart`
- Freezed models → `*.freezed.dart`
- Riverpod `@riverpod` providers → `*.g.dart`
- `json_serializable` → `*.g.dart`

**Run command:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Module Design

**Exports:**
- No barrel files — each file imports exactly what it needs
- Files may re-export at the feature boundary implicitly through imports

**Feature Structure:**

```
lib/features/<feature>/
├── data/           # Repositories, external data adapters
├── domain/         # Freezed business-logic models (only workout has this)
└── presentation/
    ├── providers/  # Riverpod providers for this feature
    ├── screens/    # Full-page ConsumerWidget widgets
    └── widgets/    # Feature-scoped reusable widgets
```

**Cross-Feature Dependency Rules:**
- Never import a feature's internals from another feature
- Cross-feature dependencies go through `core/` providers or `databaseProvider`
- DAOs live in `core/database/daos/`, not in feature folders

## Commit Conventions

Examined from git log (conventional commit style):

```
feat(workout): extract ActiveWorkoutHeader widget with large-text goldens
fix(adaptive): complete large-text layout integration
docs(planning): align roadmap and state with canonical UX-95 program
test(ui): add UI-P0-01 device acceptance and geometry suite
chore: apply delivery verification diagnostic hooks
build(android): configure native library stripping and packaging options
perf(media): bound exercise cache and defer optional startup work
```

**Pattern:** `type(scope): description` — lowercase, imperative mood, no period.
- Types observed: `feat`, `fix`, `docs`, `test`, `chore`, `build`, `perf`
- Scopes: feature area, screen, or cross-cutting concern in parentheses
- Descriptions: short, action-oriented, 50-70 chars

---

*Convention analysis: 2026-07-29*
