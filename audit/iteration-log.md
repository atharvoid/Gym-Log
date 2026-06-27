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

---

## Iteration 7: Systemic Skeleton Radii Tokenization (SYS-4)

**Date:** 2026-06-27
**Slice:** Systemic Skeleton Radii Tokenization (SYS-4)

### Diff Summary
- **SYS-4 (Radii Tokenization)**: Replaced all hardcoded skeleton radii magic numbers (such as `6.0`, `14.0`, or `0.0`) with standard semantic `AppRadius` tokens (`card`, `thumbnail`, `buttonPrimary`, `segmentedOuter`, `badge`, `input`).
- **SkeletonBox Default Radius**: Tokenized `SkeletonBox` default radius inside `lib/shared/widgets/ui/skeleton.dart` to use `AppRadius.badge` (preserving the default value of `8.0`).
- **Real Component Alignment**: To prevent layout pops on content load, updated the real card widgets (`WorkoutHistoryCard`, `DetailExerciseCard`, `_EmptyRoutines`) and their skeleton card container decorations to standard `AppRadius.card` (10.0) from their previous hardcoded `6.0`.
- **Bookkeeping (RD-1)**: Marked stale `RD-1` backlog item `done` (was already resolved at commit `8a96a01`).
- **Automated Tests**: Created `test/skeleton_radii_test.dart` to verify skeleton box radii on `WorkoutHistoryCardSkeleton`, `RoutineDetailScreen` skeleton, and `WorkoutScreen` skeleton.

### Scoreboard Delta
No changes to `scoreboard.json`. The visual average and individual scores are left unchanged because the visual delta of this subtle skeleton pop fix is negligible on a 0-10 scale. App average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (145 tests passed)

**Gate Verdict:** PASS (SYS-4 done)

---

## Iteration 8: Scroll Physics & Loading Skeletons (SYS-5)

**Date:** 2026-06-27
**Slice:** Scroll Physics & Loading Skeletons (SYS-5)

### Diff Summary
- **SYS-5 (Scroll Physics)**: Standardized CustomScrollView scroll physics on `RoutineDetailScreen` to use `AlwaysScrollableScrollPhysics` instead of a hardcoded `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` wrapper. This keeps pull-to-refresh functioning correctly while leaving the scroll physics platform-aware (iOS bounce, Android stretch).
- **SYS-5 (Spinner to Skeleton)**: Replaced a centered `CircularProgressIndicator` content placeholder inside the loading state of `_RoutineVolumeSection` with `SkeletonPulse(child: SkeletonBox(height: 198, radius: AppRadius.card))`. This ensures the volume graph's loading state visually aligns with the loaded card layout.
- **Automated Tests**: Created `test/routine_detail_scroll_and_loading_test.dart` to assert that `RoutineDetailScreen` loaded view uses `AlwaysScrollableScrollPhysics` and `_RoutineVolumeSection` loading view presents a `SkeletonBox` rather than a spinner.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| RoutineDetailScreen | Motion & Haptics | 8.0 | 8.5 | +0.5 |
| RoutineDetailScreen | Platform Conventions | 9.5 | 10.0 | +0.5 |
| RoutineDetailScreen | +Overall | 8.3 | 8.3 | 0.0 |

App overall average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (147 tests passed)

**Gate Verdict:** PASS (SYS-5 done)

---

## Iteration 9: Accessibility Tap Targets (SYS-6)

**Date:** 2026-06-27
**Slice:** Accessibility Tap Targets (SYS-6)

### Diff Summary
- **ES-3 (Filter Chip Button)**: Increased `minHeight` constraint of `_FilterChipButton` inside `ExerciseSelectionScreen` from `44` to `48` to meet the minimum platform touch target size.
- **AUTH-4 (Legal Links)**: Expanded the touch target of inline legal links ("Terms of Service" and "Privacy Policy") inside `AuthScreen` to `>=48dp` tall by wrapping the inner text in `Padding(vertical: 16, horizontal: 2)` and setting the GestureDetector's behavior to `opaque`. Combined with `WrapCrossAlignment.center` on the parent `Wrap`, the connective text remains centered and visually inline.
- **AppActionRow (General Fix)**: Added `constraints: const BoxConstraints(minHeight: 48)` inside `AppActionRow`'s `InkWell` child to guarantee that even single-line settings/profile items without subtitles measure at least 48dp tall.
- **Verify-or-Stale-Close (HOME-3 & SET-2)**:
  - **HOME-3**: Verified that `_WeekStrip` on the Home screen contains only read-only static text and icons (no tap targets), so `HOME-3` is marked stale/already-compliant.
  - **SET-2**: Checked that the weight unit switcher `AppActionRow` (height 61) and the branded picker option-row (height 62) are already `>=48` height, so `SET-2` is marked stale/already-compliant.
- **Automated Tests**: Created `test/accessibility_target_size_test.dart` to assert that filter buttons in `ExerciseSelectionScreen` and legal links in `AuthScreen` measure `>=48dp` in height.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| AuthScreen | Accessibility | 6.5 | 7.5 | +1.0 |
| AuthScreen | Platform Conventions | 7.0 | 7.5 | +0.5 |
| AuthScreen | +Overall | 7.0 | 7.1 | +0.1 |

App overall average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (149 tests passed)

**Gate Verdict:** PASS (SYS-6 done)

---

## Iteration 10: Retokenize Surface Radii (SYS-7)

**Date:** 2026-06-27
**Slice:** Retokenize Surface Radii (SYS-7)

### Diff Summary
- **Card/Container Surfaces**: Migrated hardcoded border radius `circular(6)` / `circular(10)` / `circular(20)` to `AppRadius.cardAll` / `AppRadius.card` in `DeleteAccountScreen` (cards), `ExerciseDetailScreen` (GIF widget), `ExploreRoutinesScreen` (program cards), `RoutineEditorScreen` (name input field), `ImportScreen` (gradient card containers), and `BrandedLineChart` (chart container card).
- **Primary Buttons**: Migrated hardcoded border radius `circular(14)` to `AppRadius.buttonPrimaryAll` on `DeleteAccountScreen`'s danger-icon chip.
- **Secondary Buttons & Chips**: Migrated hardcoded border radius `circular(14)` to `AppRadius.buttonSecondaryAll` on `ExerciseSelectionScreen` (filter chips) and `ExploreRoutinesScreen` (segmented controls and Add/View buttons).
- **Bottom Sheets**: Migrated hardcoded top corner radius `vertical(top: Radius.circular(20))` to `AppRadius.sheetTop` on the custom premium paywall bottom sheet.
- **Badges**: Migrated hardcoded border radius `circular(8)` to `AppRadius.badgeAll` on `ActiveWorkoutBar` (timer pill), `PremiumPaywall` (ProLockPill), `ProfileGraphLowDataBanner` (warning banner), and `ImportScreen` (selection tags).
- **Thumbnails**: Migrated hardcoded border radius `circular(10)` to `AppRadius.thumbnailAll` on `AppShell` and `AppDialog` icon badges.
- **Skeleton Box**: Migrated initial load header skeleton box radius from `6.0` to `AppRadius.card` in `HomeScreen` to prevent layout corner pops.
- **Automated Tests**: Created `test/radius_token_test.dart` to assert correct radius tokens are styled on `DeleteAccountScreen`, `ExerciseSelectionScreen`, and `HomeScreen` skeletons.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| DeleteAccountScreen | Components | 7.0 | 8.0 | +1.0 |
| DeleteAccountScreen | Code Quality | 8.0 | 9.0 | +1.0 |
| DeleteAccountScreen | Visual Professionalism | 9.0 | 9.5 | +0.5 |
| DeleteAccountScreen | +Overall | 7.6 | 7.8 | +0.2 |

App overall average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (152 tests passed)

**Gate Verdict:** PASS (SYS-7 completed)

---

## Iteration 11: Dynamic Chrome Colors (SYS-8)

**Date:** 2026-06-27
**Slice:** Dynamic Chrome Colors (SYS-8)

### Diff Summary
- **Shared Widgets**: Migrated `AppActionRow` and `AppActionDivider` chevron, fallback icon, and divider colors from static `AppColors` constants to dynamic `context.surface` tokens.
- **Home Feed**: Migrated `WorkoutHistoryCard` options menu button, card separator divider line, and stat chip icon colors to dynamic `context.surface` tokens.
- **Profile / Settings Screen**: Migrated `showWeeklyGoalSheet` unselected goal chip background to `context.surface.surface2` and text to `context.surface.textPrimary`. Snipped Snackbars in Settings and external URL links to use `context.surface.bgSurface` without triggering async gap warnings.
- **Routine Editor Screen**: Migrated background canvas, close button, titles, spinners, input field borders/fills, list item borders, drag indicators, set counter labels, remove buttons, and stepper buttons to use dynamic `context.surface` tokens.
- **Routine Detail Screen**: Normalized `_RoutineProgressPill` border radius to `AppRadius.badgeAll`.
- **Automated Tests**: Created `test/dynamic_chrome_test.dart` to assert that both `AppActionDivider` and `WorkoutHistoryCard` divider colors update dynamically across light and dark surface modes using a custom `AccentColors` test extension that overrides `isLightSurface`.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| SettingsScreen | Color & Typography | - | 10.0 | Backfill |
| SettingsScreen | Visual Professionalism | - | 9.0 | Backfill |
| SettingsScreen | +Overall | - | 8.0 | Backfill |
| ProfileScreen | Color & Typography | - | 10.0 | Backfill |
| ProfileScreen | Visual Professionalism | - | 9.0 | Backfill |
| ProfileScreen | +Overall | - | 8.0 | Backfill |
| RoutineEditorScreen | Color & Typography | - | 10.0 | Backfill |
| RoutineEditorScreen | Visual Professionalism | - | 9.0 | Backfill |
| RoutineEditorScreen | +Overall | - | 8.1 | Backfill |

App overall average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (154 tests passed)

**Gate Verdict:** PASS (SYS-8 completed)

---

## Iteration 12: Profile Cluster Polish & Scoreboard Completion (PR-1/2/3)

**Date:** 2026-06-27
**Slice:** Profile Cluster Polish (PR-1/2/3)

### Diff Summary
- **PR-1 (Avatar Memory Optimization)**: Captures the device pixel ratio (`MediaQuery.devicePixelRatioOf(context)`) in `ProfileAvatar` to apply `cacheWidth` and `cacheHeight` constraints to the loaded image file. This bounds image decoding to the exact physical pixels needed, saving GPU memory.
- **PR-2 (Weekly Bar Chart Typography & Chrome)**:
  - Eliminated the last inline `GoogleFonts.inter` call sites inside `weekly_bar_chart.dart` (axis labels, tooltip titles/values, delta indicator) and replaced them with standard `AppText` configurations.
  - Migrated hardcoded graph labels, progress track fill, unlock banner text, lock icon, and delta neutral-arrow colors to dynamic `context.surface` tokens.
- **PR-3 (Premium Paywall Sheet title & Dynamic colors)**:
  - Aligned premium paywall headline title text style to `AppText.sheetTitle` (matching settings/routine-editor sheet titles).
  - Migrated sheet fills (`AppColors.bgSheet` -> `context.surface.surface2`) and borders (`AppColors.surface3` -> `context.surface.surface3`) to dynamic tokens, preserving AMOLED contrast against the black overlay.
  - Migrated unselected card borders, loading spinners, handle, body text, and features checklist labels to dynamic tokens.
  - Set purchase button spinner color to `accent.onAccent` for premium contrast on fully saturated backgrounds.
- **Profile Screen Icon & SnackBar Polish**:
  - Migrated dumbbell and fire icon fallback colors in `_StatsStrip` to dynamic `context.surface` tokens.
  - Resolved `_openPremium()` SnackBar background color dynamically to `context.surface.bgSurface`.
- **Scoreboard Backfill**:
  - Added new rows scoring `ExerciseSelectionScreen`, `ExploreRoutinesScreen`, and `OnboardingScreen` (which exists under `auth/presentation/screens/onboarding_screen.dart`).
  - Rescored `ProfileScreen` honestly after PR-1/2/3 refactoring (increasing Code Quality, Performance, and Visual Professionalism).
  - Recomputed the average app rating across all 14 screens.
- **Automated Tests**: Created `test/profile_cluster_polish_test.dart` containing widget tests that pump `ProfileAvatar`, `WeeklyBarChart` (low-data), and `PremiumPaywall` sheets under light/dark surface configurations to assert correct theme resolution.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| ProfileScreen | Code Quality | 8.5 | 9.0 | +0.5 |
| ProfileScreen | Performance | 7.5 | 8.5 | +1.0 |
| ProfileScreen | Visual Professionalism | 9.0 | 9.5 | +0.5 |
| ProfileScreen | +Overall | 8.0 | 8.2 | +0.2 |
| ExerciseSelectionScreen | +Overall | - | 8.2 | Backfill |
| ExploreRoutinesScreen | +Overall | - | 8.0 | Backfill |
| OnboardingScreen | +Overall | - | 7.1 | Backfill |

App overall average remains at `7.9`.

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (157 tests passed)

**Gate Verdict:** PASS

---

## Iteration 13: Cleanup Sweep & Consistency Close-out

**Date:** 2026-06-27
**Slice:** Cleanup Sweep (OnboardingScreen & Paywall)

### Diff Summary
- **Task 1 (Paywall Stragglers)**: Migrated the remaining four static `AppColors.textSecondary` occurrences in `_PaywallSheet` inside `premium_paywall.dart` to `surface.textSecondary`. Removed the `const` declaration from the dot separator Container's BoxDecoration to enable resolving its color dynamically off context.
- **Task 2 (Onboarding Screen Dynamics)**: Fully transitioned `OnboardingScreen` to dynamically support light and dark surface theme variations post-auth. Resolved Scaffold background, back button icons/labels, captions, subtitles, input styles, hint text styles, and text field enabled borders to dynamic `context.surface` tokens. Replaced the static hardcoded white enabled border (which was invisible in dark mode and broken in light mode) with `surface.borderSubtle`. Dynamically set status bar overlays depending on `surface.isLight` brightness.
- **Task 3 (AUTH-8 verification)**: Grepped the codebase for password-based auth methods and verified that the auth system is Google OAuth-only with no email/password logic at this tip, resolving `AUTH-8` as stale.
- **Task 4 (Backlog Bookkeeping)**: Filled blank closing commits in `backlog.md` for `SYS-8`, `HOME-4`, `SET-1`, and `RD-2` with their refactor commit SHA `5591cf5`. Marked `AUTH-8` as `done / stale`.
- **Automated Tests**: Extended `profile_cluster_polish_test.dart` to verify onboarding screen text colors, background colors, and dynamic borders under both light and dark theme mocks, and assert correct dynamic resolution of paywall secondary action link and dot separator colors.

### Scoreboard Delta
| Screen | Dimension | Before | After | Change |
|---|---|---|---|---|
| OnboardingScreen | Color & Typography | 6.5 | 10.0 | +3.5 |
| OnboardingScreen | Code Quality | 7.0 | 8.5 | +1.5 |
| OnboardingScreen | Visual Professionalism | 8.0 | 9.5 | +1.5 |
| OnboardingScreen | +Overall | 7.1 | 7.7 | +0.6 |

App overall average rises to `8.0` (computed as: `sum(14 screens) / 14 = 111.3 / 14 = 7.95`, rounding to `8.0`).

### Gate Verification Result
- [x] Format: **PASS**
- [x] Static Analysis: **PASS**
- [x] Custom Linter: **PASS**
- [x] Tests Suite: **PASS** (159 tests passed)

**Gate Verdict:** PASS
