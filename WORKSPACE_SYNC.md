# WORKSPACE_SYNC.md — GymLog Absolute State Extraction

> Generated: 2026-05-18 | Architecture: High-Density Tracker | Method: Ground-truth disk read

---

## 1. Environment & Dependencies

- **App Name:** GymLog
- **Package:** `gymlog`
- **Version:** `0.1.0`
- **SDK Constraint:** `>=3.0.0 <4.0.0`
- **Flutter:** 3.x (SDK constraint implies Flutter 3.x+)

### Key Packages (from `pubspec.yaml` on disk)

| Package | Version |
|---------|---------|
| `flutter_riverpod` | `^2.5.0` |
| `riverpod_annotation` | `^2.3.0` |
| `drift` | `^2.18.0` |
| `drift_flutter` | `^0.2.0` |
| `sqlite3_flutter_libs` | `^0.5.0` |
| `supabase_flutter` | `^2.5.0` |
| `flutter_secure_storage` | `^9.0.0` |
| `go_router` | `^14.0.0` |
| `fl_chart` | `^0.68.0` |
| `google_fonts` | `^6.2.0` |
| `url_launcher` | `^6.2.0` |
| `cached_network_image` | `^3.3.0` |
| `flutter_svg` | `^2.0.0` |
| `gif_view` | `^0.4.0` |
| `intl` | `^0.19.0` |
| `uuid` | `^4.4.0` |
| `collection` | `^1.18.0` |
| `freezed_annotation` | `^2.4.0` |
| `json_annotation` | `^4.9.0` |
| `shared_preferences` | `^2.2.0` |
| `connectivity_plus` | `^5.0.0` |
| `vibration` | `^1.9.0` |
| `path_provider` | `^2.1.0` |

**Dev:**
| Package | Version |
|---------|---------|
| `build_runner` | `^2.4.0` |
| `drift_dev` | `^2.18.0` |
| `riverpod_generator` | `^2.4.0` |
| `freezed` | `^2.5.0` |
| `json_serializable` | `^6.8.0` |

---

## 2. Design Tokens (Ground Truth)

**Source:** `lib/core/theme/app_colors.dart` (read from disk)

### 2.1 Color Tokens

| Token Name | Hex Code | Flutter Constant | Usage |
|------------|----------|-------------------|-------|
| `bgBase` | `0xFF000000` | Pure Black | Scaffold bg, nav bar bg |
| `bgSurface` | `0xFF1C1C1E` | Dark Grey | Cards, inputs, sheets, secondary buttons |
| `accentPrimary` | `0xFF8A2BE2` | Electric Purple | Primary accent, active nav, primary buttons |
| `textPrimary` | `0xFFFFFFFF` | Pure White | Headlines, data values, primary text |
| `textSecondary` | `0xFF8E8E93` | Muted Grey | Labels, timestamps, inactive nav, hints |
| `borderSubtle` | `0xFF2C2C2E` | Subtle border | Card dividers, inactive toggle pills |
| `error` | `0xFFFF5449` | Red | Error states, destructive actions |
| `success` | `0xFF34C759` | iOS green | Completed sets, PR indicators |
| `warning` | `0xFFFFCC00` | iOS yellow | Warning states |

### 2.2 Backward Compatibility Aliases

| Alias | Maps To | Used In |
|-------|---------|---------|
| `primary` | `accentPrimary` | `active_workout_screen.dart`, `log_screen.dart` |
| `textPrimaryVariant` | `textSecondary` | `active_workout_screen.dart`, `exercise_block.dart`, `set_row.dart`, `log_screen.dart` |
| `textPrimaryMuted` | `textSecondary` | `exercise_block.dart`, `set_row.dart` |
| `textSecondaryContainer` | `bgSurface` | `active_workout_screen.dart` |
| `bgBaseContainer` | `bgSurface` | `log_screen.dart` |
| `bgBaseContainerLow` | `bgSurface` | `log_screen.dart` |

### 2.3 Global Theme Rules

**Source:** `lib/core/theme/app_theme.dart` (read from disk)

- **Font Family:** Inter (via `GoogleFonts.inter().fontFamily`)
- **Brightness:** `Brightness.dark`
- **Material 3:** `useMaterial3: true`
- **Global Border Radius:** 12px — applied to: cards, buttons, inputs, bottom sheets, focused input borders
- **Elevation:** 0 everywhere — no shadows, `shadowColor: Colors.transparent`
- **No gradients, no blur, no glassmorphism** — solid color elevation only
- **Scaffold bg:** `AppColors.bgBase` (#000000)
- **Card bg:** `AppColors.bgSurface` (#1C1C1E)
- **Divider color:** `AppColors.borderSubtle` (#2C2C2E)
- **AppBar:** bg=bgBase, elevation=0, centerTitle=false, titleStyle=Inter w700 28px -0.5 tracking
- **Bottom sheet:** top radius 12px, bg=bgSurface, elevation=0
- **Input fields:** filled=true, fillColor=bgSurface, no border, focused border=accentPrimary width 2, hint=Inter w400 16px textSecondary
- **ElevatedButton default:** bg=accentPrimary, fg=textPrimary, radius=12, padding=v16 h24, text=Inter w700 16px

### 2.4 Typography Scale

| TextTheme Slot | Size | Weight | Letter Spacing | Color |
|---------------|------|--------|----------------|-------|
| `displayLarge` | 32px | w700 | -0.5 | textPrimary |
| `headlineLarge` | 28px | w700 | -0.5 | textPrimary |
| `headlineMedium` | 24px | w700 | 0 | textPrimary |
| `titleLarge` | 20px | w700 | 0 | textPrimary |
| `titleMedium` | 16px | w600 | 0 | textPrimary |
| `titleSmall` | 14px | w600 | 0 | textPrimary |
| `bodyLarge` | 16px | w400 | 0 | textPrimary |
| `bodyMedium` | 14px | w400 | 0 | textPrimary |
| `bodySmall` | 12px | w400 | 0 | textSecondary |
| `labelLarge` | 14px | w400 | 0 | textSecondary |
| `labelMedium` | 12px | w400 | 0 | textSecondary |
| `labelSmall` | 11px | w400 | 0 | textSecondary |

---

## 3. UI Component Registry

**Source:** `lib/shared/widgets/ui/` (all 4 files read from disk)

### 3.1 TrackerCard

**File:** `lib/shared/widgets/ui/tracker_card.dart`

- **Class:** `TrackerCard extends StatelessWidget`
- **Constructor:** `TrackerCard({required Widget child, EdgeInsetsGeometry? padding, VoidCallback? onTap})`
- **Structure:**
  - `Container` with `BoxDecoration(color: AppColors.bgSurface, borderRadius: 12px)`
  - Default padding: `EdgeInsets.all(16)`
  - If `onTap != null`: wrapped in `Material(transparent) → InkWell(borderRadius: 12px)`
  - No border, no shadow, no elevation

### 3.2 PrimaryButton

**File:** `lib/shared/widgets/ui/primary_button.dart`

- **Class:** `PrimaryButton extends StatelessWidget`
- **Constructor:** `PrimaryButton({required String label, VoidCallback? onPressed, bool isFullWidth = true, IconData? icon})`
- **Structure:**
  - `SizedBox(height: 48, width: isFullWidth ? double.infinity : null)`
  - `ElevatedButton` with:
    - `backgroundColor: AppColors.accentPrimary` (#8A2BE2)
    - `foregroundColor: AppColors.textPrimary` (#FFFFFF)
    - `elevation: 0`, `shadowColor: transparent`
    - `shape: RoundedRectangleBorder(borderRadius: 12px)`
    - `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)`
  - If `icon != null`: `Row(min, center)` → `Icon(icon, size: 20)` + `SizedBox(8)` + `Text(label, Inter w700 16px)`
  - If `icon == null`: `Text(label, Inter w700 16px)`

### 3.3 SecondaryButton

**File:** `lib/shared/widgets/ui/secondary_button.dart`

- **Class:** `SecondaryButton extends StatelessWidget`
- **Constructor:** `SecondaryButton({required String label, VoidCallback? onPressed, bool isFullWidth = true, IconData? icon})`
- **Structure:**
  - `SizedBox(height: 48, width: isFullWidth ? double.infinity : null)`
  - `ElevatedButton` with:
    - `backgroundColor: AppColors.bgSurface` (#1C1C1E)
    - `foregroundColor: AppColors.textPrimary` (#FFFFFF)
    - `elevation: 0`, `shadowColor: transparent`
    - `shape: RoundedRectangleBorder(borderRadius: 12px)`
    - `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)`
  - If `icon != null`: `Row(min, center)` → `Icon(icon, size: 20)` + `SizedBox(8)` + `Text(label, Inter w600 16px)`
  - If `icon == null`: `Text(label, Inter w600 16px)`

### 3.4 TogglePill

**File:** `lib/shared/widgets/ui/toggle_pill.dart`

- **Class:** `TogglePill extends StatelessWidget`
- **Constructor:** `TogglePill({required String label, bool isActive = false, VoidCallback? onTap})`
- **Structure:**
  - `GestureDetector` → `AnimatedContainer(duration: 200ms)`
  - `padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)`
  - Active: `color: AppColors.accentPrimary`, text: `AppColors.textPrimary` w600 14px
  - Inactive: `color: AppColors.borderSubtle`, text: `AppColors.textSecondary` w400 14px
  - `borderRadius: 99px` (pill shape)

---

## 4. Screen Architecture Mapping

### 4.1 Global Shell

**File:** `lib/shared/widgets/app_shell.dart` (read from disk)

```
AppShell extends ConsumerWidget
├── Scaffold(bg: AppColors.bgBase)
│   ├── body: SafeArea(bottom: false, child: routeChild)
│   └── bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min)
│       ├── if (isWorkoutActive) ActiveWorkoutBar
│       └── BottomNavBar
```

- `isWorkoutActive` sourced from `ref.watch(activeWorkoutProvider.select((s) => s.isActive))`
- `SafeArea(bottom: false)` prevents bottom overflow while allowing nav bar to sit below safe area

**File:** `lib/shared/widgets/bottom_nav_bar.dart` (read from disk)

```
BottomNavBar extends StatelessWidget
├── Container(decoration: BoxDecoration(color: AppColors.bgBase))
│   └── SafeArea(top: false)
│       └── SizedBox(height: 72)
│           └── Row(MainAxisAlignment.spaceAround)
│               ├── _NavButton(icon: home_filled, label: 'Home', path: '/')
│               ├── _NavButton(icon: fitness_center, label: 'Workout', path: '/workout')
│               └── _NavButton(icon: person, label: 'Profile', path: '/profile')

_NavButton
├── GestureDetector(opaque)
│   └── Padding(horizontal: 20, vertical: 8)
│       └── Column(mainAxisSize: MainAxisSize.min)
│           ├── Icon(size: 26, color: active ? accentPrimary : textSecondary)
│           ├── SizedBox(height: 2)
│           └── Text(fontSize: 11, w500, color: active ? accentPrimary : textSecondary)
```

- **Active color:** `AppColors.accentPrimary` (#8A2BE2)
- **Inactive color:** `AppColors.textSecondary` (#8E8E93)
- **Container height:** 72px (increased from 60px to fix RenderFlex overflow)
- **Icon-label spacing:** 2px (reduced from 4px to fix overflow)

**File:** `lib/shared/widgets/active_workout_bar.dart` (read from disk)

```
ActiveWorkoutBar
├── GestureDetector(onTap: push '/workout/active')
│   └── Container(margin: h16 v8, bg: accentPrimary, radius: 12, padding: h20 v14)
│       └── Row(center)
│           ├── Icon(play_circle_filled, textPrimary, 20)
│           ├── SizedBox(12)
│           └── Expanded → Text('Workout in progress — tap to resume', textPrimary, w600, 14, center)
```

### 4.2 Home Screen (`/`)

**File:** `lib/features/home/presentation/screens/home_screen.dart` (read from disk)

**CONFIRMED ABSENCES:**
- ❌ No notification bell `IconButton` in AppBar
- ❌ No "Welcome back!" `Text` widget
- ❌ No "Ready to crush your workout?" `Text` widget
- AppBar has **no `actions`** — only title

```
HomeScreen extends StatelessWidget
├── Scaffold(bg: bgBase)
│   ├── AppBar(title: 'Home', Inter w700 28px -0.5 tracking, NO actions)
│   └── SingleChildScrollView(padding: 16)
│       └── Column(crossAxisAlignment: start)
│           ├── TrackerCard — Quick Start
│           │   └── Column(crossStart)
│           │       ├── Text('Quick Start', textPrimary, 18px, w700)
│           │       ├── SizedBox(16)
│           │       └── PrimaryButton('Start Empty Workout', icon: add_circle_outline, onPressed: () {})
│           ├── SizedBox(16)
│           ├── Text('Recent Activity', textPrimary, 20px, w700)
│           ├── SizedBox(12)
│           └── TrackerCard — Last Workout
│               └── Column(crossStart)
│                   ├── Row(spaceBetween)
│                   │   ├── Text('Last Workout', textSecondary, 14px, w400)
│                   │   └── Text('2 days ago', textSecondary, 12px, w400)
│                   ├── SizedBox(8)
│                   ├── Text('Push Day', textPrimary, 18px, w700)
│                   ├── SizedBox(8)
│                   └── Row
│                       ├── _StatBadge('Duration', '45 min')
│                       ├── SizedBox(12)
│                       ├── _StatBadge('Exercises', '5')
│                       ├── SizedBox(12)
│                       └── _StatBadge('Sets', '15')
```

### 4.3 Workout Screen (`/workout`)

**File:** `lib/features/workout/presentation/screens/workout_screen.dart` (read from disk)

**CONFIRMED ABSENCES:**
- ❌ No refresh icon in AppBar
- ❌ No folder icon in Routines section header
- AppBar has **no `actions`** — only title

```
WorkoutScreen extends StatefulWidget
├── _WorkoutScreenState
│   ├── State: _routinesExpanded = true
│   ├── Mock: _routines = [Push Day, Pull Day, Leg Day]
│   └── Scaffold(bg: bgBase)
│       ├── AppBar(title: 'Workout', Inter w700 28px -0.5 tracking, NO actions)
│       └── SingleChildScrollView(padding: 16)
│           └── Column(crossAxisAlignment: start)
│               ├── SecondaryButton('+ Start Empty Workout', icon: add, fullWidth)
│               ├── SizedBox(24)
│               ├── Text('Routines', textPrimary, 20px, w700)
│               ├── SizedBox(12)
│               ├── Row — Action Buttons
│               │   ├── Expanded → SecondaryButton('New Routine', isFullWidth: false)
│               │   ├── SizedBox(12)
│               │   └── Expanded → SecondaryButton('Explore', isFullWidth: false)
│               ├── SizedBox(16)
│               ├── GestureDetector — Collapsible Header
│               │   └── Row
│               │       ├── Icon(arrow_down/right, textSecondary, 20)
│               │       ├── SizedBox(4)
│               │       └── Expanded → Text('My Routines (3)', textSecondary, 14px, w500)
│               ├── SizedBox(12)
│               └── if (_routinesExpanded) — Routine Cards (mapped)
│                   ├── TrackerCard — Push Day
│                   │   └── Column(crossStart)
│                   │       ├── Text('Push Day', textPrimary, 18px, w700)
│                   │       ├── SizedBox(8)
│                   │       ├── Text(exercises, textSecondary, 14px, maxLines:2, ellipsis)
│                   │       ├── SizedBox(16)
│                   │       └── PrimaryButton('Start Routine', onPressed: () {})
│                   ├── TrackerCard — Pull Day (same structure)
│                   └── TrackerCard — Leg Day (same structure)
```

### 4.4 Profile Screen (`/profile`)

**File:** `lib/features/profile/presentation/screens/profile_screen.dart` (read from disk)

**CONFIRMED ABSENCES:**
- ❌ No `CircleAvatar` or avatar widget
- ❌ No "Followers" metric
- ❌ No "Following" metric
- ❌ No profile completion banner ("Your profile is X% finished")
- ❌ No workouts feed section
- ❌ No horizontal `Row`/`Wrap`/`GridView` for action buttons

**CONFIRMED LAYOUT FIXES:**
- ✅ Header is strictly `Column(crossAxisAlignment: start)` with Name + Workouts count only
- ✅ 4 Action Buttons are in `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` with `SizedBox(height: 12)` separators
- ✅ All `SecondaryButton` instances use default `isFullWidth: true` (no `isFullWidth: false` override)

```
ProfileScreen extends StatefulWidget
├── _ProfileScreenState
│   ├── State: _selectedMetric = 'Duration'
│   └── Scaffold(bg: bgBase)
│       └── SafeArea
│           └── SingleChildScrollView(padding: 16)
│               └── Column(crossAxisAlignment: start)
│                   ├── Column(crossAxisAlignment: start) — HEADER
│                   │   ├── Text('noobyoume', textPrimary, 20px, w700)
│                   │   ├── SizedBox(4)
│                   │   └── Text('Workouts: 147', textSecondary, 14px, w400)
│                   ├── SizedBox(24)
│                   ├── Row — Chart Header
│                   │   ├── Text('1 hour', textPrimary, 24px, w700)
│                   │   ├── Spacer
│                   │   └── Text('Last 3 months', textSecondary, 12px, w400)
│                   ├── SizedBox(16)
│                   ├── TrackerCard — Chart Placeholder
│                   │   └── Container(height: 200, center, Text('Chart Area', textSecondary, 14px))
│                   ├── SizedBox(16)
│                   ├── SingleChildScrollView(horizontal) — Toggle Pills
│                   │   └── Row
│                   │       ├── TogglePill('Duration', active by default)
│                   │       ├── SizedBox(8)
│                   │       ├── TogglePill('Volume')
│                   │       ├── SizedBox(8)
│                   │       └── TogglePill('Reps')
│                   ├── SizedBox(16)
│                   └── Column(crossAxisAlignment: CrossAxisAlignment.stretch) — ACTION BUTTONS
│                       ├── SecondaryButton('Statistics', icon: bar_chart) [fullWidth]
│                       ├── SizedBox(height: 12)
│                       ├── SecondaryButton('Exercises', icon: fitness_center) [fullWidth]
│                       ├── SizedBox(height: 12)
│                       ├── SecondaryButton('Measures', icon: straighten) [fullWidth]
│                       ├── SizedBox(height: 12)
│                       └── SecondaryButton('Calendar', icon: calendar_month) [fullWidth]
```

---

## 5. Database Schema (Drift)

### 5.1 Current Implementation State

**CRITICAL:** No Drift database files exist on disk. The directory `lib/core/database/` does **not exist**. The provider is a placeholder:

**File:** `lib/core/providers/database_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Placeholder database provider. Replace with Drift AppDatabase provider.
final databaseProvider = Provider((ref) => null);
```

No `.drift` files, no generated `.g.dart` files, no `AppDatabase` class exist anywhere in the project.

### 5.2 Target Schema (from `context.md` — NOT yet implemented on disk)

These are the **planned** table definitions from the project's `context.md` specification. None of these exist as actual Dart files yet.

#### UserProfiles
```dart
class UserProfiles extends Table {
  TextColumn get id          => text()(); // Google UID
  TextColumn get email       => text()();
  TextColumn get displayName => text()();
  TextColumn get photoUrl    => text().nullable()();
  BoolColumn get isPremium   => boolean().withDefault(const Constant(false))();
  DateTimeColumn get premiumExpiry => dateTime().nullable()();
  TextColumn get weightUnit  => text().withDefault(const Constant('kg'))();
  IntColumn  get defaultRestSeconds => integer().withDefault(const Constant(90))();
  DateTimeColumn get createdAt => dateTime()();
}
```

#### Exercises
```dart
class Exercises extends Table {
  IntColumn  get id               => integer().autoIncrement()();
  TextColumn get exerciseDbId     => text().unique()(); // API's own ID
  TextColumn get name             => text()();
  TextColumn get bodyPart         => text()();          // chest, back, legs...
  TextColumn get equipment        => text()();
  TextColumn get target           => text()();          // primary muscle
  TextColumn get gifUrl           => text()();          // API gif URL
  TextColumn get secondaryMuscles => text()();          // JSON array string
  TextColumn get instructions     => text()();          // JSON array string
  BoolColumn get isCustom         => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy        => text().nullable()(); // userId for custom exercises
  DateTimeColumn get seededAt     => dateTime().nullable()();
}
```

#### Routines
```dart
class Routines extends Table {
  TextColumn get id         => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId     => text()();
  TextColumn get name       => text()();
  TextColumn get notes      => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

#### RoutineDays
```dart
class RoutineDays extends Table {
  TextColumn get id        => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get name      => text()();
  IntColumn  get orderIndex => integer()();
}
```

#### RoutineExercises
```dart
class RoutineExercises extends Table {
  TextColumn get id           => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineDayId => text().references(RoutineDays, #id)();
  IntColumn  get exerciseId   => integer().references(Exercises, #id)();
  IntColumn  get orderIndex   => integer()();
  IntColumn  get defaultSets  => integer().withDefault(const Constant(3))();
  IntColumn  get defaultReps  => integer().nullable()();
  RealColumn get defaultWeightKg => real().nullable()();
  IntColumn  get restSeconds  => integer().nullable()();
}
```

#### WorkoutSessions
```dart
class WorkoutSessions extends Table {
  TextColumn  get id        => text().clientDefault(() => const Uuid().v4())();
  TextColumn  get userId    => text()();
  TextColumn  get routineId => text().nullable()();
  TextColumn  get name      => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt   => dateTime().nullable()();
  TextColumn  get notes     => text().withDefault(const Constant(''))();
  RealColumn  get totalVolumeKg => real().withDefault(const Constant(0))();
  BoolColumn  get synced    => boolean().withDefault(const Constant(false))();
}
```

#### WorkoutExercises
```dart
class WorkoutExercises extends Table {
  TextColumn get id        => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();
  IntColumn  get exerciseId => integer().references(Exercises, #id)();
  IntColumn  get orderIndex => integer()();
  TextColumn get notes     => text().nullable()();
}
```

#### WorkoutSets
```dart
class WorkoutSets extends Table {
  TextColumn  get id                 => text().clientDefault(() => const Uuid().v4())();
  TextColumn  get workoutExerciseId  => text().references(WorkoutExercises, #id)();
  IntColumn   get exerciseId         => integer()(); // denormalized for faster analytics queries
  IntColumn   get orderIndex         => integer()();
  TextColumn  get setType            => text().withDefault(const Constant('normal'))();
  RealColumn  get weightKg           => real()();
  IntColumn   get reps               => integer()();
  RealColumn  get rpe                => real().nullable()();
  BoolColumn  get isPr               => boolean().withDefault(const Constant(false))();
  RealColumn  get estimated1rm       => real().nullable()(); // stored for fast queries
  DateTimeColumn get completedAt     => dateTime()();
}
```

---

## 6. Implementation Delta (Current vs. Target)

### 6.1 Stubbed/Non-Functional UI Elements

| Element | File | Current Behavior | Target |
|---------|------|-----------------|--------|
| Quick Start Button | `home_screen.dart:48-52` | `onPressed: () {}` (no-op) | Start workout via `activeWorkoutProvider.startWorkout()` + navigate to `/workout/active` |
| Start Routine Button | `workout_screen.dart:159-161` | `onPressed: () {}` (no-op) | Load routine exercises into active workout + navigate |
| New Routine Button | `workout_screen.dart:81-84` | `onPressed: () {}` (no-op) | Navigate to routine editor screen |
| Explore Button | `workout_screen.dart:89-92` | `onPressed: () {}` (no-op) | Navigate to exercise browser |
| Statistics Button | `profile_screen.dart:129-133` | `onPressed: () {}` (no-op) | Navigate to analytics screen |
| Exercises Button | `profile_screen.dart:135-139` | `onPressed: () {}` (no-op) | Navigate to exercise library |
| Measures Button | `profile_screen.dart:141-145` | `onPressed: () {}` (no-op) | Navigate to body measurements screen |
| Calendar Button | `profile_screen.dart:147-151` | `onPressed: () {}` (no-op) | Navigate to workout history/calendar |
| Add Exercise FAB | `active_workout_screen.dart:226-235` | Shows SnackBar only | Open exercise picker, add to workout |
| Exercise Replace | `exercise_block.dart:51-54` | Shows SnackBar only | Open exercise picker for replacement |
| Exercise Add Note | `exercise_block.dart:58-63` | Shows SnackBar only | Open note editor dialog |
| Exercise Remove | `exercise_block.dart:67-73` | Shows SnackBar only | Remove exercise from active workout |
| Chart Area | `profile_screen.dart:83-95` | `Text('Chart Area')` placeholder | Render actual chart with `fl_chart` |
| Toggle Pills | `profile_screen.dart:103-119` | Toggle state only (no data) | Switch chart data source (Duration/Volume/Reps) |

### 6.2 Completely Missing Modules

- **Drift Database Implementation** — No `AppDatabase` class, no table files, no generated code. `databaseProvider` returns `null`.
- **Supabase Auth** — No `AuthRepository`, no `authProvider`, no login/signup screens. `supabase_flutter` and `flutter_secure_storage` are declared but unused.
- **Auth Guard / Redirect** — `router.dart` has no `redirect` logic. No auth state check on navigation.
- **Exercise Seeding Service** — `assets/db/exercises.db` (913KB) exists but is not wired into Drift. No `ExerciseSeedService` file exists.
- **Exercise Browser Screen** — Not implemented. Referenced in `context.md` as `/exercise/browser`.
- **Routine Editor Screen** — Not implemented. Referenced in `context.md` as `/routine/new` and `/routine/:id/edit`.
- **Analytics Screen** — Not implemented. Referenced in `context.md` as `/analytics`.
- **History Screen** — Not implemented. Referenced in `context.md` as `/history`.
- **Workout Detail Screen** — Not implemented. Referenced in `context.md` as `/workout/:id`.
- **Paywall Screen** — Not implemented. Referenced in `context.md` as `/premium`.
- **PR Tracking** — No UI, no logic. `WorkoutSets.isPr` and `estimated1rm` columns planned but not implemented.
- **Body Measurements** — No table, no UI, no logic.
- **Rest Timer** — `vibration` package declared but no timer logic exists.
- **GIF Caching** — `gif_view`, `cached_network_image`, `connectivity_plus` declared but no exercise detail screen or GIF display logic.
- **Offline Sync** — `WorkoutSessions.synced` column planned but no sync logic. `connectivity_plus` unused.
- **DodoPayments / IAP** — `url_launcher` declared but no payment integration. `in_app_purchase` not in `pubspec.yaml` (only in `context.md` spec).
- **Settings Screen** — Not implemented.

### 6.3 Legacy/Dead Code

| File | Status | Notes |
|------|--------|-------|
| `lib/features/workout/presentation/screens/log_screen.dart` | Compiled but unreachable | Replaced by `WorkoutScreen` in router. Uses backward-compat aliases. |
| `lib/shared/widgets/placeholder_screen.dart` | Compiled but unreachable | Generic scaffold, not referenced by any route. |

---

## Complete File Index (`lib/`)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── providers/
│   │   └── database_provider.dart          (placeholder: returns null)
│   ├── router/
│   │   └── router.dart                     (GoRouter: ShellRoute[/, /workout, /profile] + /workout/active)
│   └── theme/
│       ├── app_colors.dart                 (9 tokens + 6 compat aliases)
│       └── app_theme.dart                  (MaterialData dark, Inter, 12px radius, 0 elevation)
├── features/
│   ├── home/
│   │   └── presentation/screens/
│   │       └── home_screen.dart            (Quick Start + Recent Activity, mock data)
│   ├── profile/
│   │   └── presentation/screens/
│   │       └── profile_screen.dart         (Ultra-minimal header + chart stub + vertical actions)
│   └── workout/
│       └── presentation/
│           ├── providers/
│           │   └── active_workout_provider.dart  (StateNotifier, in-memory only)
│           ├── screens/
│           │   ├── active_workout_screen.dart     (Timer + ExerciseBlocks + FAB)
│           │   ├── log_screen.dart               (Legacy, not in nav tree)
│           │   └── workout_screen.dart            (Routines list + collapsible cards)
│           └── widgets/
│               ├── exercise_block.dart            (Card with sets + add set + context menu)
│               └── set_row.dart                   (Weight/reps inputs + type badge + check)
└── shared/
    └── widgets/
        ├── active_workout_bar.dart           (Solid purple bar, tap to resume)
        ├── app_shell.dart                    (Scaffold + SafeArea + BottomNav + ActiveBar)
        ├── bottom_nav_bar.dart               (3-tab: Home/Workout/Profile, 72px height)
        ├── placeholder_screen.dart           (Unused generic scaffold)
        └── ui/
            ├── primary_button.dart           (Purple bg, 48px h, 12px radius, w700)
            ├── secondary_button.dart         (Dark grey bg, 48px h, 12px radius, w600)
            ├── toggle_pill.dart              (Pill toggle, purple active / grey inactive)
            └── tracker_card.dart             (Dark grey card, 12px radius, zero shadow)
```
