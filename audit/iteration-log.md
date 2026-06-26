# Iteration Log

This file records each loop execution details, diff summaries, scoreboard delta, and gate checks.

---

## Iteration 1: Bootstrap & AW-1 (Active Workout Minimize Tap affordance)

**Date:** 2026-06-26
**Slice:** Active Workout Screen (AW-1)

### Diff Summary
- Modified `lib/features/workout/presentation/screens/active_workout_screen.dart` to support tapping the grab handle to minimize.
- Expanded hit target area to `60x48dp` (from 36x4) to meet target accessibility guidelines.
- Wrapped the grab handle in a `Semantics` widget (button + label: `Minimize workout`).
- Adjusted top/bottom margins of the handle and outer header padding.
- Added `test/active_workout_minimize_test.dart` widget test to verify tap and semantics.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| ActiveWorkoutScreen | TouchTargetSize | 7.0 | 9.0 | +2.0 |
| ActiveWorkoutScreen | A11ySemantics | 7.0 | 8.5 | +1.5 |
| ActiveWorkoutScreen | overall | 7.7 | 8.1 | +0.4 |

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS**
- [x] Regression Test: **PASS** (added `active_workout_minimize_test.dart`)

**Gate Verdict:** PASS

---

## Iteration 2: SYS-1 (Tokenize Typography for Auth/Exercise-Detail/Delete-Account/Import)

**Date:** 2026-06-26
**Slice:** Systemic Typography (SYS-1)

### Diff Summary
- Added `titleLarge` token to `app_text.dart` (24 / 700).
- Replaced 40 inline `GoogleFonts.inter` call sites across `auth_screen.dart`, `exercise_detail_screen.dart`, `delete_account_screen.dart`, and `import_screen.dart` with design-system tokens (`AppText.*`).
- Removed `import 'package:google_fonts/google_fonts.dart';` from the four files.
- Installed check in `verify.ps1` that blocks any new `GoogleFonts.inter(` in `lib/`.
- Created `test/typography_guard_test.dart` asserting zero prohibited inline GoogleFonts usages in `lib/`.
- Added widget test suite in `test/screens_typography_test.dart` to verify successful pumping of the four screens.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| AuthScreen | TypographyTabular | 7.5 | 10.0 | +2.5 |
| AuthScreen | VisualPolish | 6.5 | 8.5 | +2.0 |
| AuthScreen | overall | 6.6 | 7.0 | +0.4 |
| ExerciseDetailScreen | TypographyTabular | 8.0 | 10.0 | +2.0 |
| ExerciseDetailScreen | VisualPolish | 7.5 | 8.5 | +1.0 |
| ExerciseDetailScreen | overall | 7.4 | 7.6 | +0.2 |
| DeleteAccountScreen | TypographyTabular | 8.0 | 10.0 | +2.0 |
| DeleteAccountScreen | VisualPolish | 7.5 | 8.0 | +0.5 |
| DeleteAccountScreen | overall | 7.3 | 7.5 | +0.2 |
| ImportScreen | TypographyTabular | 8.0 | 10.0 | +2.0 |
| ImportScreen | VisualPolish | 7.5 | 8.5 | +1.0 |
| ImportScreen | overall | 7.2 | 7.5 | +0.3 |

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (127 tests passed)
- [x] Typography Guard: **PASS** (zero inline GoogleFonts occurrences)

**Gate Verdict:** PASS (SYS-1 done; awaiting SYS-2/SYS-3 to converge app average)

---

## Iteration 3: SYS-2 (Migrate Chrome Colors to context.surface / context.accent)

**Date:** 2026-06-26
**Slice:** Systemic Colors (SYS-2)

### Diff Summary
- Migrated 8 screens off raw/non-semantic colors to dynamic theme tokens:
  - `HomeScreen`: Scaffold/AppBar background, RefreshIndicator, ActionSheetItem, and week strip.
  - `WorkoutDetailScreen`: Scaffold/AppBar background, BackButton, ActionSheetItem, and SnackBar.
  - `RoutineDetailScreen`: Scaffold/AppBar background, BackButton, RefreshIndicator, CTA button states, and progress pills.
  - `ExerciseDetailScreen`: Scaffold, loading progress, muscle chips, stats toggles, and PR list elements.
  - `DeleteAccountScreen`: Scaffold/AppBar background, BackButton, Alert/SnackBar components, text fields, section cards, and SystemUiOverlayStyle.
  - `ImportScreen`: Scaffold/AppBar background, BackButton, card background gradients, stat rows, unit chooser, and chart label.
  - `ActiveWorkoutScreen`: Unit picker dialog, add-exercise button, and drag handle.
  - `ExploreRoutinesScreen`: Hardcoded dark gradient stops inside featured card, preview sheet gradients, and SnackBar components.
- Added a static build guard in `scripts/verify.ps1` enforcing zero non-semantic `AppColors.*` in migrated files.
- Added widget test suite in `test/screens_theme_test.dart` verifying all 8 screens pump and read the active theme accents successfully under multiple accent palettes (default and non-default).

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| HomeScreen | Color & Typography | 8.5 | 9.5 | +1.0 |
| HomeScreen | Visual Professionalism | 8.0 | 9.0 | +1.0 |
| HomeScreen | +Overall | 7.7 | 7.8 | +0.1 |
| WorkoutDetailScreen | Color & Typography | 8.0 | 9.5 | +1.5 |
| WorkoutDetailScreen | Visual Professionalism | 8.0 | 9.0 | +1.0 |
| WorkoutDetailScreen | +Overall | 7.6 | 7.7 | +0.1 |
| RoutineDetailScreen | Color & Typography | 8.5 | 9.5 | +1.0 |
| RoutineDetailScreen | Visual Professionalism | 8.0 | 9.0 | +1.0 |
| RoutineDetailScreen | +Overall | 7.8 | 8.1 | +0.3 |
| ExerciseDetailScreen | Visual Professionalism | 8.5 | 9.0 | +0.5 |
| ExerciseDetailScreen | +Overall | 7.6 | 7.7 | +0.1 |
| DeleteAccountScreen | Visual Professionalism | 8.0 | 9.0 | +1.0 |
| DeleteAccountScreen | +Overall | 7.5 | 7.6 | +0.1 |
| ImportScreen | Visual Professionalism | 8.5 | 9.5 | +1.0 |
| ImportScreen | +Overall | 7.5 | 7.5 | 0.0 |
| ActiveWorkoutScreen | Color & Typography | 8.5 | 9.5 | +1.0 |
| ActiveWorkoutScreen | Visual Professionalism | 8.0 | 9.0 | +1.0 |
| ActiveWorkoutScreen | +Overall | 8.1 | 8.2 | +0.1 |

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (135 tests passed)
- [x] Non-semantic AppColors Guard: **PASS** (zero non-semantic AppColors in migrated files)

**Gate Verdict:** PASS (SYS-2 done; awaiting SYS-3 to resolve reversible delete undo support and complete the systemic track)

---

## Iteration 4: SYS-3 (Undoable Reversible Deletes for Workouts and Routines)

**Date:** 2026-06-26
**Slice:** Undoable Reversible Deletes (SYS-3)

### Diff Summary
- Added transactional restore methods in DAOs:
  - `restoreSession(String json)` in `WorkoutsDao` to reconstruct deleted workout sessions, including exercises, sets, and associated mappings with original IDs and sequence ordering preserved.
  - `restoreRoutine(String json)` in `RoutinesDao` to reconstruct deleted routines, daily templates, exercises, and targets with original IDs and sequence ordering preserved.
- Implemented a unified `showUndoableDelete` shared helper widget in `lib/shared/widgets/feedback/undoable_delete.dart`. This captures the ScaffoldMessenger State, handles haptic feedback, triggers the Undo action, and commits/fires any cleanup callbacks if allowed to expire.
- Updated `HomeScreen`, `WorkoutDetailScreen`, and `RoutineDetailScreen` to use the shared helper.
- For screens that pop (`WorkoutDetailScreen`, `RoutineDetailScreen`), captured the ScaffoldMessenger and GoRouter before the navigation pop to safely present the Undo SnackBar on the landing screen (RD-4 pop discipline).
- Added medium haptic feedback on delete actions.
- Guarded against double-deletes/taps using a `tapGuard` mechanism.
- Created unit tests for the shared helper (`test/undoable_delete_test.dart`) and integration tests for restoring database models (`test/dao_integration_test.dart`).

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| HomeScreen | Components | 7.0 | 8.0 | +1.0 |
| HomeScreen | Motion & Haptics | 7.0 | 7.5 | +0.5 |
| HomeScreen | Logic & State | 7.5 | 8.0 | +0.5 |
| HomeScreen | +Overall | 7.8 | 8.0 | +0.2 |
| WorkoutDetailScreen | Components | 7.0 | 8.0 | +1.0 |
| WorkoutDetailScreen | Motion & Haptics | 7.0 | 7.5 | +0.5 |
| WorkoutDetailScreen | Logic & State | 7.0 | 8.0 | +1.0 |
| WorkoutDetailScreen | Accessibility | 7.0 | 7.5 | +0.5 |
| WorkoutDetailScreen | +Overall | 7.7 | 8.0 | +0.3 |
| RoutineDetailScreen | Components | 7.5 | 8.5 | +1.0 |
| RoutineDetailScreen | Motion & Haptics | 7.5 | 8.0 | +0.5 |
| RoutineDetailScreen | Logic & State | 7.0 | 8.0 | +1.0 |
| RoutineDetailScreen | +Overall | 8.1 | 8.3 | +0.2 |

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (137 tests passed)
- [x] Restore/Grace/Double-Delete: **PASS** (covered by automated tests)

**Gate Verdict:** PASS

---

## Iteration 5: Exercise Detail Polish (XD-2/3/4/5 & MOTION)

**Date:** 2026-06-27
**Slice:** Exercise Detail Screen Polish (XD-2/3/4/5)

### Diff Summary
- **XD-2 (Primary Muscle Highlight)**: Refactored muscle chip wrap to bind and evaluate the `isPrimary` target flag. Styled primary muscle chip using active palette accent theme (12% alpha background, 35% alpha border, accent text) for AMOLED-dark compliance, keeping secondary chips in surface3 muted.
- **XD-3 (Stat Toggles Touch Targets)**: Expanded stat toggle button touch footprint to `>=48dp` min-height using a nested layout (tight visual pill nested inside center-aligned constraints). Swapped haptics from `lightImpact` to `selectionClick`.
- **XD-4 (Analytics Retry Action)**: Replaced dead-end error message on history analytics failure with an accessible `>=48dp` touch-target `AsyncErrorState` retry button that invalidates the riverpod family provider.
- **XD-5 (Skeletons, RepaintBoundary, PR Memoization)**:
  - Replaced spinner loading indicators with custom dark-mode token-matching `SkeletonPulse` and `SkeletonBox` structures for both partial section loads and full-page loading states.
  - Wrapped `BrandedLineChart` in a `RepaintBoundary` to prevent redundant canvas paints on external widget rebuilds.
  - Optimized build performance by memoizing heaviest weight, best 1RM, max session volume, and max reps PR aggregations, computing them once per history reference update instead of on every frame rebuild.
- **MOTION (Entrance Transition)**: Added a restrained entry fade-and-slide transition to the main content using `AnimationController`. Gated under `MediaQuery.disableAnimationsOf(context)` to immediately set the value to `1.0` and skip the transition under reduced-motion accessibility preferences.
- **Automated Tests**: Created `test/exercise_detail_polish_test.dart` to verify primary chip styling, stat toggle dimensions, error state retry invalidation behavior, and media query reduced motion gating.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| ExerciseDetailScreen | Components | 7.0 | 8.5 | +1.5 |
| ExerciseDetailScreen | Motion & Haptics | 7.0 | 8.0 | +1.0 |
| ExerciseDetailScreen | Logic & State | 7.0 | 8.5 | +1.5 |
| ExerciseDetailScreen | Accessibility | 7.0 | 8.5 | +1.5 |
| ExerciseDetailScreen | Performance | 7.5 | 8.5 | +1.0 |
| ExerciseDetailScreen | Visual Professionalism | 9.0 | 9.5 | +0.5 |
| ExerciseDetailScreen | +Overall | 7.7 | 8.2 | +0.5 |

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (141 tests passed)
- [x] Skeletons & Sizing: **PASS** (covered by automated tests)

**Gate Verdict:** PASS (XD-2/3/4/5 done; app overall average is 7.9)

---

## Iteration 6: Exercise Selection Filter Cache (ES-1)

**Date:** 2026-06-27
**Slice:** Exercise Selection Screen Filter Cache (ES-1)

### Diff Summary
- **ES-1 (Cache-Hit Fix)**: Fixed the dead memoization cache inside `_computeList()` where the cache hit check did nothing and the system unconditionally recompiled filtering `.where(_matchesFilters)` on every frame build.
- **Identical Source Guard**: Added `List<Exercise>? _cachedSource` to replace the unreliable same-length Content check `_cachedDataHash` and `exercises.length`. A cache hit is now correctly established if and only if: `identical(exercises, _cachedSource) && _cachedMuscleFilter == _muscleFilter && _cachedEquipmentFilter == _equipmentFilter`.
- **Eliminated Redundancies**: Removed the three redundant `_cachedFiltered = null` cache invalidations in `setState` callbacks because filtering parameters are now robustly tracked in the cache check.
- **Automated Tests**: Created `test/exercise_selection_polish_test.dart` containing a `SpyingList` wrapper extending `ListMixin<Exercise>` to safely verify filtering correctness and prove cache-hits (preventing redundant runs of `.where()`) on identical list/filter inputs.

### Scoreboard Delta
No changes to `scoreboard.json` as `ExerciseSelectionScreen` is not scored individually. App average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (142 tests passed)

**Gate Verdict:** PASS (ES-1 done)
