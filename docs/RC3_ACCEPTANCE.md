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
| Home history title uses Hero flying animation to Workout Detail | P1 | Observed flying/resizing animation during transition from Home to Workout Detail | `ATOMIC-RC3-09` | `0ae1aac` | 515 tests pass | | **Passed** |
| Cinematic splash adds 1200ms brand pause before routing | P1 | Splash screen uses AnimationController glow/intro/exit animations | `ATOMIC-RC3-08` | `f5abda7` | analyze + 515 tests pass | | **Passed** |
| `finishWorkout()` catches persistence failures and returns empty PR list silently | P0 | Code audit of active workout provider | `ATOMIC-RC3-01` | `bf5e57cadbd1` | 3 unit tests pass | | **Passed** |
| `saveEditedWorkout()` catches failure and returns void | P0 | Code audit of active workout provider | `ATOMIC-RC3-01` | `bf5e57cadbd1` | 3 unit tests pass | | **Passed** |
| Missing/invalid measurement metadata defaults to `weight_and_reps` | P0 | Code audit of domain models | `ATOMIC-RC3-03` | `240f40656a81` | 5 unit tests pass | | **Passed** |
| Hydration key remains `exercises_hydrated_v7` skipping repair | P0 | Code audit of database files | `ATOMIC-RC3-04` | `c2f6d9a3b9` | 3 unit tests pass | | **Passed** |
| Legacy drafts without measurement metadata override catalog | P0 | Code audit of draft store | `ATOMIC-RC3-05` | `d31f676d31` | 2 unit tests pass | | **Passed** |
| `updateSet(weight: null)` retains old weight | P0 | Code audit of active workout provider | `ATOMIC-RC3-02` | `62ac41e66367` | 4 unit tests pass | | **Passed** |
| Rest timer permission status is not queried | P1 | Code audit of rest services | `ATOMIC-RC3-13` | `3d6487b` | 515 tests pass | | **Passed** |
| Routine / workout summaries volume-centered | P1 | Code audit of summary projections | `ATOMIC-RC3-14` | `7576e95` | 519 tests pass | | **Passed** |
| Routine editor card overloaded horizontally | P1 | Code audit of routine editor screen | `ATOMIC-RC3-16` | `201ce25` | 519 tests pass | | **Passed** |
| Exercise selection disables normal keyboard resizing | P1 | Code audit of exercise search screen | `ATOMIC-RC3-17` | `5b0903f` | 519 tests pass | | **Passed** |
| Resume-draft Discard clears immediately and silently | P1 | Code audit of draft resume sheet | `ATOMIC-RC3-19` | `a4c0e46` | 519 tests pass | | **Passed** |
| Database recovery catches reset failure silently | P1 | Code audit of database recovery screen | `ATOMIC-RC3-19` | `a4c0e46` | 519 tests pass | | **Passed** |
| Settings copy claims cloud backup generally | P1 | Code audit of settings screen | `ATOMIC-RC3-20` | `1aca7e6` | 519 tests pass | | **Passed** |
| Motion waste (EntranceFade & AmbientPulse loops) present across screens | P1 | Repeated entrance and ambient animations on Home, Profile, Routine Detail, Exercise Detail, Rest Bar | `ATOMIC-RC3-10` | `2b47dc7` | 519 tests pass | | **Passed** |
| Exercise Detail PR labels duplicated for reps-only exercises | P1 | Code audit of exercise detail screen | `ATOMIC-RC3-15` | `2b47dc7` | 519 tests pass | | **Passed** |
| Paywall missing auto-renewal disclosure & T&C links | P1 | Code audit of paywall widget | `ATOMIC-RC3-22` | `2b47dc7` | 519 tests pass | | **Passed** |
| Delete menus say "cannot be undone" despite Undo | P1 | Code audit of menus | `ATOMIC-RC3-23` | `327cb1b` | 519 tests pass | | **Passed** |
| Exercise removal in Active Workout is immediate | P1 | Code audit of workout screen | `ATOMIC-RC3-12` | `7d7d734` | 515 tests pass | | **Passed** |
| Exercise GIF asset source path updated to GitHub raw assets with 4-digit padding | P1 | Exercise GIFs loading from Supabase bucket | `GIF-STORAGE-MIGRATION` | `40178e6` | 519 tests pass | | **Passed** |
