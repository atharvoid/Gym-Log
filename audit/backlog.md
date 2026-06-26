# Audit Backlog

This file tracks every finding ID with its severity, owning screen, status (`open | in-progress | done`), and the closing commit.

## Tier 0 — Critical

| Finding ID | Screen | Description | Status | Closing Commit |
|---|---|---|---|---|
| **AW-1** | ActiveWorkoutScreen | Active Workout minimize is swipe-only. Make grab handle tap target + Semantics. | `done` | fb09a55 |

## Tier 1 — Systemic Majors

| Finding ID | Screen | Description | Status | Closing Commit |
|---|---|---|---|---|
| **SYS-1** | Systemic | Migrate Auth, Exercise Detail, Delete Account, Import off inline `GoogleFonts.inter` to `AppText` | `done` | a408ac3 |
| **SYS-2** | Systemic | Migrate Home, Workout Detail, Routine Detail chrome, Exercise Detail, Delete Account, Import to `context.surface`/`context.accent` | `done` | 3f41aab |
| **SYS-3** | Systemic | Add snackbar-with-Undo to reversible deletes (Home / Workout Detail / routine delete) | `done` | 7732bd5 |

## Tier 2 — Remaining per-screen Majors

| Finding ID | Screen | Description | Status | Closing Commit |
|---|---|---|---|---|
| **XD-2** | ExerciseDetailScreen | Exercise Detail discards `isPrimary`; tint primary muscle chip with `accent` | `done` | 51e80c5 |
| **ES-1** | ExerciseSelectionScreen | Remove dead memoization cache in `_computeList` | `open` | |
| **HOME-1** | HomeScreen | Folds into SYS-2 (theme token migration) | `done` | 3f41aab |
| **HOME-2** | HomeScreen | Reversible workout deletion with Undo (SYS-3) | `done` | 7732bd5 |
| **WD-2** | WorkoutDetailScreen | Missing theme token compliance | `done` | 3f41aab |
| **WD-3** | WorkoutDetailScreen | Detail page accessibility / semantics gaps | `done` | 7732bd5 |
| **RD-1** | RoutineDetailScreen | Routine Detail list has wrong scroll physics (Android default) | `open` | |
| **AW-2** | ActiveWorkoutScreen | Two color systems on Active Workout screen | `done` | 3f41aab |
| **EX-2** | ExploreRoutinesScreen | Hardcoded dark gradient stop in featured card | `done` | 3f41aab |
| **XD-1** | ExerciseDetailScreen | Color compliance (folds into SYS-2) | `done` | 3f41aab |
| **AUTH-1** | AuthScreen | Google Sign-in release SHA-1 configuration missing | `open` | |
| **AUTH-8** | AuthScreen | Email/Password dead code cleanup | `open` | |
| **IM-1** | ImportScreen | Inline styling cleanup (folds into SYS-1) | `done` | a408ac3 |

## Tier 3 — Minors

| Finding ID | Screen | Description | Status | Closing Commit |
|---|---|---|---|---|
| **SYS-4** | Systemic | Tokenize skeleton border radius to match standard cards | `open` | |
| **SYS-5** | Systemic | Scroll physics standardizations and skeleton-vs-spinner templates | `open` | |
| **SYS-6** | Systemic | Sub-48dp interactive controls scan & cleanup | `open` | |
| **AUTH-4** | AuthScreen | Touch targets for legal links are sub-48dp | `open` | |
| **HOME-3** | HomeScreen | Goal day buttons touch targets are sub-48dp | `open` | |
| **HOME-4** | HomeScreen | History card styling discrepancies | `open` | |
| **HOME-7** | HomeScreen | Performance lag on heavy history feed | `open` | |
| **AW-3** | ActiveWorkoutScreen | Exercise block spacing and font size inconsistencies | `open` | |
| **AW-5** | ActiveWorkoutScreen | Finish summary sheet navigation polish | `open` | |
| **WD-1** | WorkoutDetailScreen | Scroll layout constraints on small screens | `open` | |
| **WD-5** | WorkoutDetailScreen | Volume graph range filters | `open` | |
| **RD-2** | RoutineDetailScreen | Routine Detail subtitle overlaps | `open` | |
| **RD-3** | RoutineDetailScreen | Empty state graphics rendering alignment | `done` | 3f41aab |
| **RE-2** | RoutineEditorScreen | Reorder handle accessibility label | `open` | |
| **RE-3** | RoutineEditorScreen | Routine Editor naming constraints | `open` | |
| **ES-2** | ExerciseSelectionScreen | Search bar cursor color mismatch | `open` | |
| **ES-3** | ExerciseSelectionScreen | Filter chips height is sub-48dp (currently 44dp) | `open` | |
| **XD-3** | ExerciseDetailScreen | Stat toggles touch targets are sub-48dp (expand to >=48dp min height) | `done` | 51e80c5 |
| **XD-4** | ExerciseDetailScreen | Failed to load analytics is a dead end (replace with accessible retry button) | `done` | 51e80c5 |
| **XD-5** | ExerciseDetailScreen | Analytics & full-page spinner loads (replace with skeletons, wrap chart in RepaintBoundary, memoize PR maxes) | `done` | 51e80c5 |
| **PR-1** | ProfileScreen | Avatar picture size constraints | `open` | |
| **PR-2** | ProfileScreen | Weekly stats bar chart styling | `open` | |
| **PR-3** | ProfileScreen | Premium paywall visual alignment | `open` | |
| **SET-1** | SettingsScreen | Settings items list separator lines color | `open` | |
| **SET-2** | SettingsScreen | Weight units switcher click target is sub-48dp | `open` | |
| **DA-1** | DeleteAccountScreen | Confirmation input placeholder text styling (fully resolved with SYS-1 and SYS-2) | `done` | 3f41aab |
| **IM-2** | ImportScreen | CSV template download button styling | `open` | |

## Tier 4 — Polish & Wow

| Finding ID | Screen | Description | Status | Closing Commit |
|---|---|---|---|---|
| **AUTH-2** | AuthScreen | Add signature brand animation moment on login success | `open` | |
| **AUTH-5** | AuthScreen | Privacy policy / Terms alignment | `open` | |
| **AUTH-6** | AuthScreen | Legal footer responsiveness | `open` | |
| **AUTH-7** | AuthScreen | Support link under sign-in card | `open` | |
| **AUTH-9** | AuthScreen | Web OAuth popup styling | `open` | |
| **WL-2** | WorkoutList | Scroll jank when scrolling heavy workout list | `open` | |
| **WL-3** | WorkoutList | Animation transitions when adding new workouts | `open` | |
| **WD-4** | WorkoutDetailScreen | Share-to-image dynamic layout | `open` | |
| **RE-1** | RoutineEditorScreen | Drag and drop animations micro-delight | `open` | |
| **ES-4** | ExerciseSelectionScreen | Hero transition to Exercise Detail screen | `open` | |
| **AP-1** | AppearanceScreen | OLED theme switcher micro-delights | `open` | |
| **AP-2** | AppearanceScreen | Live preview card updates | `open` | |
| **IM-3** | ImportScreen | Import progress bar animations | `open` | |
