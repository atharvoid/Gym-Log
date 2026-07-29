# Testing Patterns

**Analysis Date:** 2026-07-29

## Test Framework

**Runner:**
- Framework: `flutter_test` (from Flutter SDK)
- Config: `test/flutter_test_config.dart`
- Version: Bundled with Flutter SDK (environment SDK `>=3.0.0 <4.0.0`)

**Additional Test Packages:**
- `alchemist: ^0.12.0` (`test/flutter_test_config.dart`) — golden/visual regression testing with multi-palette scenario support
- `sqlite3: ^2.4.0` (`pubspec.yaml`) — host-VM SQLite for DAO integration tests
- `mockito` is NOT used — all mocking is done with hand-written fake classes

**Run Commands:**
```bash
flutter test                              # Run all tests
flutter test --coverage                   # Run with coverage
flutter test test/<file>.dart             # Run single file
flutter test --update-goldens             # Update golden reference files
flutter test --machine                    # Machine-readable output (CI mode)
```

## Test Infrastructure

### Global Configuration (`test/flutter_test_config.dart`)

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;  // use local font assets
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: true),
    ),
    run: testMain,
  );
}
```

- **Fonts:** `GoogleFonts.config.allowRuntimeFetching = false` — prevents runtime font download in tests, uses pre-bundled Google Fonts assets in `assets/google_fonts/`
- **Goldens:** Alchemist configured with `platformGoldensConfig.enabled: true` — golden tests compare against platform-specific reference images
- Applied globally to every test suite

### DAO / Database Tests

```dart
// Setup pattern for DAO integration tests (test/dao_integration_test.dart, test/sync_engine_test.dart, etc.)
setUpAll(() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      try {
        return DynamicLibrary.open('libsqlite3.so');
      } catch (_) {
        return DynamicLibrary.open('libsqlite3.so.0');  // fallback soname
      }
    });
  }
});

setUp(() {
  db = AppDatabase.forTesting(NativeDatabase.memory());
  // ... additional setup
});

tearDown(() async {
  await db.close();
});
```

- Uses `AppDatabase.forTesting(NativeDatabase.memory())` — lightweight in-memory SQLite
- `NativeDatabase.memory()` avoids file I/O, makes tests fast and hermetic
- `setUpAll` configures host SQLite for Linux CI runners (looks up `libsqlite3.so` / `libsqlite3.so.0`)
- Each test file manages its own database lifecycle with `setUp`/`tearDown`

### Mock / Fake Pattern

**No mocking framework.** All fakes are hand-written inline classes:

```dart
// test/sync_engine_test.dart — inline FakeRemote
class FakeRemote implements SyncRemote {
  final Map<String, SyncObject> store = {};
  bool failNext = false;
  int pushBatches = 0;

  @override
  Future<List<PushResult>> pushBatch(List<SyncObject> objects) async {
    if (failNext) throw Exception('offline');
    // ...
  }
}
```

```dart
// test/accessibility_core_journey_test.dart — MockNotificationService
class MockNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermissions() async => true;
  // ...
}
```

**Dependency injection setup:**
- `FlutterSecureStorage.setMockInitialValues({})` for secure storage fakes
- `SharedPreferences.setMockInitialValues({})` for shared prefs fakes
- `ProviderScope` overrides for Riverpod provider injection

### ProviderScope Override Pattern

```dart
// test/accessibility_core_journey_test.dart — Provider overrides
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      // ... other provider overrides
    ],
    child: MaterialApp(
      home: ActiveWorkoutScreen(sessionId: sessionId),
    ),
  ),
);
```

## Test File Organization

**Location:** All tests live under `test/` directory, co-located by feature in subdirectories.

**Naming:** `*_test.dart` — descriptive snake_case names that indicate what's tested.

**Structure:**
```
test/
├── active_workout_*_test.dart        # Active workout behavior tests
├── auth/                             # Auth-related tests
│   ├── auth_screen_behavior_test.dart
│   └── account_isolation_test.dart
├── golden/                           # Golden visual regression tests
│   ├── golden_test_helpers.dart      # Shared helper: gymlogApp(), themedScenario(), allThemesGroup()
│   ├── active_workout_header_golden_test.dart
│   ├── nav_bar_golden_test.dart
│   ├── auth_screen_golden_test.dart
│   ├── segmented_control_golden_test.dart
│   ├── muscle_map_golden_test.dart
│   └── ...
├── import/                           # CSV import/export tests
│   ├── import_service_test.dart
│   ├── csv_codec_test.dart
│   ├── exercise_matcher_test.dart
│   ├── import_fixtures.dart          # Shared test fixtures (not a test file)
│   └── ...
├── profile/                          # Profile feature tests
│   ├── profile_sync_service_test.dart
│   └── help_report_form_test.dart
├── premium/                          # Premium/entitlement tests
│   ├── strict_entitlement_verification_test.dart
├── performance/                      # Performance tests
│   ├── bounded_cache_and_startup_test.dart
├── sync/                             # Sync engine tests
│   ├── sync_quarantine_and_monotonic_test.dart
├── shared/                           # Shared widget tests
│   ├── draft_recovery_test.dart
│   ├── chrome_tokens_test.dart
│   └── adaptive_layout_test.dart
├── analytics/                        # Analytics tests
│   ├── metric_aware_pr_test.dart
├── compile_surface_test.dart         # Full-app graph compilation gate
├── dao_integration_test.dart          # DAO integration tests (largest test file, ~472 lines)
├── database_migration_test.dart       # Schema migration tests
├── flutter_test_config.dart           # Global test configuration
├── sync_engine_test.dart              # Sync engine behavior
└── ... (80 test files total)
```

## Test Types

### Unit Tests (Pure Logic)

Testing pure functions with no widgets or database:

```dart
// test/routine_cap_test.dart — pure logic, no DB, no widgets
test('free routine cap is 4 and gates exactly at the limit', () {
  expect(kFreeRoutineLimit, 4);
  expect(isAtFreeRoutineLimit(isPremium: false, routineCount: 3), isFalse);
  expect(isAtFreeRoutineLimit(isPremium: false, routineCount: 4), isTrue);
});
```

```dart
// test/chart_axis_format_test.dart — axis formatter unit tests
test('round thousands compact with NO trailing .0', () {
  expect(BrandedLineChart.defaultAxisFormat(1000), '1k');
  expect(BrandedLineChart.defaultAxisFormat(3000), '3k');  // was "9.0k" bug
});
```

### Widget Tests

Testing widget rendering and interaction:

```dart
// test/active_workout_set_row_test.dart
testWidgets('PREVIOUS column shows "15kg x 12" when prior data exists', (tester) async {
  await tester.pumpWidget(host(SetRow(
    setIndex: 0,
    setData: const WorkoutSetState(id: 's1'),
    previousWeight: 15,
    previousReps: 12,
    unit: 'kg',
    onChanged: (_) {},
    onToggleComplete: () {},
  )));

  expect(find.text('15kg x 12'), findsOneWidget);
});
```

**Widget test host pattern:** Wrapping widget in `MaterialApp`:

```dart
Widget host(SetRow row) => MaterialApp(
  home: Scaffold(body: row),
);
```

### Integration Tests (DAO + Database)

Testing database operations with real SQLite:

```dart
// test/dao_integration_test.dart — 472 lines, covers 8 DAO query paths
setUp(() async {
  db = AppDatabase.forTesting(NativeDatabase.memory());
  // Insert seed data...
});

test('workout detail PR detection', () async {
  // Insert historical and current sessions
  // Assert PR detection logic
});
```

### Golden Tests (Visual Regression)

Using `alchemist` package in `test/golden/`:

```dart
// test/golden/active_workout_header_golden_test.dart
@Tags(['golden'])
library;

void main() {
  goldenTest(
    'ActiveWorkoutHeader renders correctly per theme (normal layout)',
    fileName: 'active_workout_header_normal',
    builder: () => allThemesGroup(
      'ActiveWorkoutHeader (normal)',
      _header(),
    ),
  );
}
```

**Golden test helpers (`test/golden/golden_test_helpers.dart`):**

```dart
/// Wraps [child] in a full GymLog MaterialApp configured for [palette].
Widget gymlogApp(ThemePalette palette, Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(palette.tokens, palette: palette),
    home: Material(
      color: Colors.black,
      child: Center(child: child),
    ),
  );
}

/// Creates one scenario per palette.
GoldenTestScenario themedScenario(ThemePalette palette, Widget child) { ... }

/// Generates a group with one scenario per palette.
GoldenTestGroup allThemesGroup(String label, Widget child) {
  return GoldenTestGroup(
    scenarioConstraints: const BoxConstraints(maxWidth: 400),
    children: [
      for (final palette in ThemePalette.values) themedScenario(palette, child),
    ],
  );
}
```

**Golden test conventions:**
- Tagged with `@Tags(['golden'])` at top of file
- Uses `goldenTest()` from `alchemist`, not `testWidgets()`
- Each golden test renders the widget under all 6 `ThemePalette` values via `allThemesGroup()`
- `fileName:` parameter controls the golden reference file name
- Golden reference images stored in `test/golden/` (platform-specific directories)
- Update with `flutter test --update-goldens`

### Compile-Surface Smoke Test

Full-app graph compilation gate:

```dart
// test/compile_surface_test.dart
test('full app graph compiles', () {
  expect(app.main, isA<Function>());
  expect(showPremiumPaywall, isA<Function>());
  expect(showPrCelebration, isA<Function>());
});
```

- Imports `main.dart` forcing the entire app graph to compile
- Catches type errors anywhere in `lib/` without needing Android SDK on CI
- References symbols to prevent tree-shaking

### Accessibility Tests

Testing screen reader semantics and target sizes:

```dart
// test/accessibility_core_journey_test.dart — 317 lines
// Covers the active workout screen with ProviderScope overrides,
// checks semantics tree, target sizes, and screen reader flow

// test/nav_bar_golden_test.dart — semantics sub-group
group('BottomNavBar — semantics', () {
  testWidgets('tabs expose semantics tree', (tester) async {
    // ...
    final semanticsInside = find.descendant(
      of: navBar, matching: find.byType(Semantics),
    );
    expect(semanticsInside, findsAtLeast(3));
  });
});
```

## Coverage Areas

### What's Tested (80 test files, ~470 individual tests)

| Area | Files | What's Covered |
|------|-------|----------------|
| **DAOs / Database** | `dao_integration_test.dart` | 8 DAO query paths — workout detail, PR detection, previous session CTE, home feed previews |
| **Database Migrations** | `database_migration_test.dart` | v2→v3 migration: column creation, backfill logic, index verification |
| **Sync Engine** | `sync_engine_test.dart`, `sync_engine_test.dart` | Outbox drain, batching, offline requeue/retry, session round-trip, compression codec, quarantine, monotonic ordering |
| **Active Workout** | `active_workout_start_test.dart`, `active_workout_set_row_test.dart`, `active_workout_header_test.dart`, `active_workout_atomic_03/04_test.dart`, `active_workout_minimize_test.dart`, `active_workout_large_text_test.dart` | Start flow, set row rendering (5 behaviors), header rendering, minimize/resume, large-text reflow, atomic behaviors |
| **Set Row** | `set_row_measurement_types_test.dart`, `set_row_focus_test.dart`, `reps_only_exercise_test.dart` | Measurement type variants, focus behavior, reps-only exercises |
| **Rest Timer** | `rest_timer_bar_test.dart`, `rest_timer_override_test.dart`, `rest_time_sheet_atomic_test.dart`, `rest_preference_atomic_test.dart` | Compact layout, override behavior, sheet interaction, preference management |
| **Routines** | `routine_cap_test.dart`, `routine_editor_reorder_test.dart`, `routine_detail_scroll_and_loading_test.dart`, `reorder_exercise_test.dart` | Free cap, reorder logic, scroll behavior, exercise reorder |
| **Goldens** | `test/golden/` (6 files) | Active workout header, nav bar (5 sizes × 6 palettes), auth screen, segmented control, muscle map |
| **Charts** | `chart_axis_format_test.dart`, `profile_weekly_bar_chart_test.dart` | Axis format (k-compact), y-axis unit, empty/low-data/rendered states, weekly bar chart |
| **Profile** | `profile_sync_service_test.dart`, `profile_cluster_polish_test.dart` | Local-first writes, backend hydration, offline queue/retry |
| **Accessibility** | `accessibility_core_journey_test.dart`, `accessibility_target_size_test.dart`, `accessibility_atomic_12_test.dart` | Core journey flow, target sizes, atomic coverage |
| **Import/Export** | `import/` directory (8 files) | CSV codec, roundtrip, muscle taxonomy, exercise matcher, import service, catalog integrity |
| **Auth** | `auth/` directory (2 files) | Screen behavior, account isolation |
| **Premium/Entitlements** | `premium/` directory | Strict entitlement verification |
| **Other** | `undoable_delete_test.dart`, `pressable_scale_test.dart`, `entrance_fade_test.dart`, `tour_sequencing_test.dart`, `tour_orchestration_test.dart`, `body_map_test.dart`, `weekly_goal_sheet_test.dart`, `widget_test.dart`, `workout_export_test.dart`, `typography_guard_test.dart`, `screens_typography_test.dart`, `screens_theme_test.dart`, `delivery_diagnostics_test.dart`, `commerce_and_deletion_test.dart`, `dynamic_chrome_test.dart`, `radius_token_test.dart`, `skeleton_radii_test.dart`, `legal_consistency_test.dart`, `expiry_symptom_test.dart` | Various widgets, design tokens, motion, tours, body map |

### Coverage Gaps (Identified)

| Area | Risk | Priority |
|------|------|----------|
| **Explore/Catalog screen** | No widget tests for explore_routines_screen.dart — only catalog_integrity_test.dart checks the data integrity, not the UI | Medium |
| **Routine detail screen** | `routine_detail_scroll_and_loading_test.dart` exists but may not cover all exercise block rendering states | Low |
| **Settings screens** | Few tests for `settings_screen.dart`, `appearance_screen.dart`, `personal_details_screen.dart` | Medium |
| **Workout export** | Only `workout_export_test.dart` — may not cover all export formats | Low |
| **Premium paywall** | Only entitlement verification tested — paywall UI not tested | Medium |
| **Error states across screens** | Most screens test happy path — error/loading states not exhaustively covered | Medium |
| **Integration tests with live supabase** | All Supabase interactions are faked — no integration test against real Supabase | Low (by design) |

## Test Structure Patterns

**Suite Organization:**

```dart
void main() {
  // Declare shared state
  late AppDatabase db;
  const userId = 'user-1';

  setUpAll(() { /* host SQLite config */ });
  setUp(() async { /* create in-memory DB, seed data */ });
  tearDown(() async { /* close DB */ });

  group('Query group name', () {
    test('specific behavior', () async {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

**Patterns:**
- `setUpAll` for one-time infrastructure (SQLite library loading)
- `setUp` for per-test fresh database and state
- `tearDown` for database cleanup
- `test()` for pure logic, `testWidgets()` for widget/integration
- Groups used for logical organization, not always present

**Assertion Pattern:**
- Standard `expect()` with matchers
- `findsOneWidget`, `findsNothing`, `findsWidgets`, `findsAtLeast(n)` for widget presence
- `tester.getSize()` for geometry assertions
- `tester.widgetList<T>()` for filtering widget trees

## Mocking

**Framework:** None — hand-written fake classes.

**Patterns:**
- Fake classes implement the interface (`implements SyncRemote`, `implements ProfileRemote`)
- Controllable failure: `bool failNext = false` toggle
- Call tracking: `int pushBatches = 0`, `int upsertCalls = 0`
- In-memory state: `Map<String, SyncObject> store = {}`

**What to Mock:**
- Backend/remote services (Supabase, sync)
- Notification services
- Secure storage / shared preferences
- Timer (via Dart's `fakeAsync` where needed, or real timers with short waits)

**What NOT to Mock:**
- Database — use `AppDatabase.forTesting(NativeDatabase.memory())` with real SQLite
- Providers — override via `ProviderScope(overrides: [...])`

## Fixtures and Factories

**Test data approach:** Inline factory functions within test files:

```dart
// test/dao_integration_test.dart — inline helpers
Future<int> insertExercise(String name, String bodyPart, String equipment, String target) async { ... }
Future<String> insertSession(String id, DateTime startedAt, {String? routineId, required List<(int, double, int)> sets}) async { ... }
```

```dart
// test/profile_weekly_bar_chart_test.dart — inline factory
List<WeeklyAggregate> _fourWeeks({double week1 = 2000, ...}) => [
  WeeklyAggregate(weekStart: DateTime(2024, 5, 27), volumeKg: week1, ...),
  // ...
];
```

- No centralized fixture files for test data (except `test/import/import_fixtures.dart` for CSV import data)
- Fixtures are co-located with their test file for clarity

## CI Test Execution

**CI Pipeline (`.github/workflows/ci.yml`):**

1. **Analyze & Test** job on `ubuntu`:
   - `flutter pub get`
   - `dart format --set-exit-if-changed .`
   - `flutter analyze --fatal-infos --fatal-warnings`
   - `dart run custom_lint` (riverpod_lint)
   - `flutter test --machine` — runs ALL tests
   - Uploads `test-results.json`
   - Installs `libsqlite3-dev` for DAO integration tests

2. **CI Gate** — passes only if Analyze & Test + Build Android + Build iOS all pass

**Local verification mirror (scripts/verify.ps1):**

```powershell
.\scripts\verify.ps1   # Runs: format → analyze → custom_lint → flutter test
```

**Test-related CI failure debugging:**

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `sqlite3` load error | Host SQLite missing | CI installs `libsqlite3-dev`; locally install on Linux or macOS |
| Golden test mismatch | Visual change not reflected in reference | `flutter test --update-goldens` and commit updated images |
| A test fails (e.g. `wipeAllData`, routine-cap) | Real regression | Reproduce locally with `flutter test test/<file>.dart`; fix code, not test |

---

*Testing analysis: 2026-07-29*
