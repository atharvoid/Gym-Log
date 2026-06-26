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
