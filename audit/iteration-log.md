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
