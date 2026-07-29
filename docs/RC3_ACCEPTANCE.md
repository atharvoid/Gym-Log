# RC3 Acceptance Tracking

This document tracks the verification of corrections for the GymLog release candidate 3.

## Rejected Candidate Evidence (Baseline)
- **Version**: `1.0.0+2`
- **Source SHA**: `269b55cb6aa17bbc480fa31f33cbce8354a5d411`
- **AAB SHA-256**: `81B56B5276925137CCE61663E1131F081C4F348F57467712D515508D0D1B0168`

## Acceptance Matrix

| Finding | Severity | Reproduction | Target Atomic Task | Fix SHA | Automated Evidence | Device Evidence | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Auth screen uses entrance motion (280ms opacity/translate) | P1 | Play-installed build exhibits entrance animations on login screen | `ATOMIC-RC3-07` | `ca43f62` | 16 unit + 14 golden tests pass | | **Passed** |
| No-equipment exercises arrive as `weight_and_reps` | P0 | Play-installed build permits logging weight for bodyweight / no-equipment exercises | `ATOMIC-RC3-03` to `06` | `9ababc4` | 1 e2e test pass (RC3-06) | | **Passed** |
| Home history title uses Hero flying animation to Workout Detail | P1 | Observed flying/resizing animation during transition from Home to Workout Detail | `ATOMIC-RC3-09` | | | | **Reproduced** |
| Cinematic splash adds 1200ms brand pause before routing | P1 | Splash screen uses AnimationController glow/intro/exit animations | `ATOMIC-RC3-08` | `f5abda7` | analyze + 515 tests pass | | **Passed** |
| `finishWorkout()` catches persistence failures and returns empty PR list silently | P0 | Code audit of active workout provider | `ATOMIC-RC3-01` | `bf5e57cadbd1` | 3 unit tests pass | | **Passed** |
| `saveEditedWorkout()` catches failure and returns void | P0 | Code audit of active workout provider | `ATOMIC-RC3-01` | `bf5e57cadbd1` | 3 unit tests pass | | **Passed** |
| Missing/invalid measurement metadata defaults to `weight_and_reps` | P0 | Code audit of domain models | `ATOMIC-RC3-03` | `240f40656a81` | 5 unit tests pass | | **Passed** |
| Hydration key remains `exercises_hydrated_v7` skipping repair | P0 | Code audit of database files | `ATOMIC-RC3-04` | `c2f6d9a3b9` | 3 unit tests pass | | **Passed** |
| Legacy drafts without measurement metadata override catalog | P0 | Code audit of draft store | `ATOMIC-RC3-05` | `d31f676d31` | 2 unit tests pass | | **Passed** |
| `updateSet(weight: null)` retains old weight | P0 | Code audit of active workout provider | `ATOMIC-RC3-02` | `62ac41e66367` | 4 unit tests pass | | **Passed** |
| Rest timer permission status is not queried | P1 | Code audit of rest services | `ATOMIC-RC3-13` | | | | Pending |
| Routine / workout summaries volume-centered | P1 | Code audit of summary projections | `ATOMIC-RC3-14` | | | | Pending |
| Routine editor card overloaded horizontally | P1 | Code audit of routine editor screen | `ATOMIC-RC3-16` | | | | Pending |
| Exercise selection disables normal keyboard resizing | P1 | Code audit of exercise search screen | `ATOMIC-RC3-17` | | | | Pending |
| Resume-draft Discard clears immediately and silently | P1 | Code audit of draft resume sheet | `ATOMIC-RC3-19` | | | | Pending |
| Database recovery catches reset failure silently | P1 | Code audit of database recovery screen | `ATOMIC-RC3-19` | | | | Pending |
| Settings copy claims cloud backup generally | P1 | Code audit of settings screen | `ATOMIC-RC3-20` | | | | Pending |
| Paywall feature/plan rows fragile at large text | P1 | Code audit of paywall widget | `ATOMIC-RC3-22` | | | | Pending |
| Delete menus say "cannot be undone" despite Undo | P1 | Code audit of menus | `ATOMIC-RC3-23` | | | | Pending |
| Exercise removal in Active Workout is immediate | P1 | Code audit of workout screen | `ATOMIC-RC3-12` | | | | Pending |
| Help report silently copies diagnostics | P2 | Code audit of help feedback screen | `ATOMIC-RC3-21` | | | | Pending |
