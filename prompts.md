<aside>
🚫

**Release status: internal-test candidate only.** Baseline source is `269b55cb6aa17bbc480fa31f33cbce8354a5d411`, version `1.0.0+2`. Do not promote this build to production. The Play-installed test exposed two real acceptance failures: Auth motion remains, and no-equipment exercises can still arrive as `weight_and_reps`. Execute this program sequentially and publish a new `1.0.0+3` internal candidate only after all P0/P1 gates pass.

</aside>

## Audit identity

- **Repository:** `atharvoid/Gym-Log`
- **Branch:** `fix-sha1-auth-issue`
- **Exact audited SHA:** `269b55cb6aa17bbc480fa31f33cbce8354a5d411`
- **Evidence used:** exact GitHub source, current 497-test inventory, current internal AAB report, prior 50-section audit, previous screen audit, and observed Play-installed behavior.
- **Primary product invariant:** the UI must be driven by truthful domain state, not fallback guesses or decorative transitions.

## First-principles design rules

1. **No decorative motion in utility flows.** Motion is allowed only when it explains spatial continuity, confirms an action, or prevents disorientation.
2. **Metadata is data, not presentation.** Measurement type must be normalized before reaching widgets.
3. **Never silently report persistence success.** Saving, editing, deleting, restoring, importing, purchasing, and syncing return typed outcomes.
4. **One dominant action per state.** Accent fill is reserved for the most important available action.
5. **No irreversible action without truthful consequences.** If Undo exists, copy must not say “cannot be undone.”
6. **Upgrade paths are product paths.** Fresh install passing does not compensate for an existing user database or draft failing.
7. **Large text is not a scaled screenshot.** At 1.6×–2.0×, rows may reflow vertically instead of shrinking text.
8. **Tests must exercise production wiring.** Explicitly injecting `reps_only` does not test catalog → database → selection → workout → row.

## Verified current defects

| ID   | Severity | Verified source problem                                                                                                                    |
| ---- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| F-01 | P0       | `finishWorkout()` catches persistence failures and returns an empty PR list; the screen can navigate home as if saving succeeded.          |
| F-02 | P0       | `saveEditedWorkout()` catches failure and returns `void`; the screen always leaves the editor.                                             |
| F-03 | P0       | Missing/invalid measurement metadata silently defaults to `weight_and_reps`.                                                               |
| F-04 | P0       | Existing hydration key remains `exercises_hydrated_v7`, so upgraded installations may skip catalog repair.                                 |
| F-05 | P0       | Legacy drafts without measurement metadata restore as weighted and override valid catalog metadata.                                        |
| F-06 | P0       | `updateSet(weight: null)` retains the old weight because null means “do not update”; cleared fields can remain invisibly populated.        |
| F-07 | P1       | Auth still uses a 280ms opacity/translate entrance with staggered wrappers.                                                                |
| F-08 | P1       | Home history title uses a `Hero`; Workout Detail combines the flight with parallax collapse and a second animated title.                   |
| F-09 | P1       | Home, Profile, Workout Detail, Routine Detail, Exercise Detail, Splash, rest tile, and active timer all retain repeated or looping motion. |
| F-10 | P1       | Rest timer permission status is not actually queried; `hasPermission()` effectively returns true.                                          |
| F-11 | P1       | Routine and completed-workout summaries remain universally volume/kg centered.                                                             |
| F-12 | P1       | Routine editor card is overloaded horizontally; save failures are not surfaced.                                                            |
| F-13 | P1       | Exercise selection disables normal keyboard resizing and relies on free-form taxonomy strings.                                             |
| F-14 | P1       | Resume-draft Discard clears encrypted state immediately and silently.                                                                      |
| F-15 | P1       | Database recovery silently catches reset failure and offers destructive reset without export/support diagnostics.                          |
| F-16 | P1       | Settings copy claims cloud backup generally even when sync is unavailable, disabled, or not entitled.                                      |
| F-17 | P1       | Paywall feature rows and plan rows are fragile at large text; renewal/legal disclosure is incomplete.                                      |
| F-18 | P1       | Delete menus say “cannot be undone” while the implementation actually provides Undo.                                                       |
| F-19 | P1       | Exercise removal inside Active Workout is immediate, while set removal is reversible.                                                      |
| F-20 | P2       | Help report silently copies diagnostics to clipboard and raw URLs can appear in stock dialogs.                                             |

## Global execution contract

Copy one atomic prompt at a time into the implementation agent. Do not paste the entire page into a small agent.

For **every** atomic task, the agent must:

1. Print repository, branch, full starting SHA, Flutter/Dart versions, and `git status --short`.
2. Pull with `git pull --ff-only`; stop if the tree is dirty or remote differs.
3. Read every named production file, its model/provider/DAO, and its tests before editing.
4. State the root cause and invariant before making changes.
5. Add failing tests first, then the smallest complete fix.
6. Run focused tests, format, fatal analyzer, custom lint, full tests, and Android compilation.
7. Commit exactly one task with the prescribed commit message.
8. Print final SHA and clean-tree status. Do not begin the next task.
9. Never edit `.env`, `android/key.properties`, or any keystore.
10. Never claim visual PASS without an exact-SHA installed artifact and screenshots/video.

---

# Sequential atomic implementation prompts

- ATOMIC-RC3-00 — Freeze the corrective branch and evidence baseline
  
    **Objective:** Create a controlled `1.0.0+3` remediation line without mutating the accepted internal artifact.
  
    **Instructions:**
  
  - Start from `269b55cb6aa17bbc480fa31f33cbce8354a5d411` on `fix-sha1-auth-issue`.
  
  - Create branch `remediation/rc3-product-integrity`.
  
  - Do not change version yet. Record the current AAB identity as rejected internal candidate evidence: version `1.0.0+2`, source `269b55c`, SHA-256 `81B56B5276925137CCE61663E1131F081C4F348F57467712D515508D0D1B0168`.
  
  - Create `docs/RC3_ACCEPTANCE.md` with a table: finding, severity, reproduction, target atomic task, fix SHA, automated evidence, device evidence, status.
  
  - Mark Auth motion, no-equipment KG, and history-title transition as reproduced failures.
  
  - Do not modify production code.
    
    **Acceptance:** clean branch; baseline document committed; no secrets or generated artifacts staged.
    
    **Commit:** `docs(release): establish RC3 corrective baseline`

- ATOMIC-RC3-01 — Make workout persistence fail closed
  
    **Objective:** Never dismiss an active or edited workout unless the database transaction succeeded.
  
    **Files:**
  
  - `lib/features/workout/presentation/providers/active_workout_provider.dart`
  
  - `lib/features/workout/presentation/screens/active_workout_screen.dart`
  
  - `lib/core/database/daos/workouts_dao.dart`
  
  - focused provider/widget tests
    
    **Required edits:**
  
  - Replace ambiguous `List<PersonalRecord>`/`void` save contracts with a typed result such as sealed `WorkoutSaveResult.success(prs)` and `WorkoutSaveResult.failure(reason, retryable)`.
  
  - In `finishWorkout`, keep `state` and the encrypted draft intact until the transaction commits. On failure, do not set state to null and do not clear the draft.
  
  - In `saveEditedWorkout`, retain edit state on failure.
  
  - In `_finish` and `_saveChanges`, show a shared safe-offset error with **Retry** and remain on the screen.
  
  - Disable Finish/Save while a request is active; prevent duplicate transactions.
  
  - Log a sanitized Sentry diagnostic without workout contents.
    
    **Tests:** transaction failure retains state and draft; retry commits once; successful save navigates once; edited-workout failure stays open; no duplicate session from rapid taps.
    
    **Commit:** `fix(workout): fail closed on persistence errors`

- ATOMIC-RC3-02 — Fix set mutation and completion invariants
  
    **Objective:** The domain state, visible fields, and completion status must never disagree.
  
    **Files:** `active_workout_provider.dart`, `set_row.dart`, `active_workout_state.dart`, tests.
  
    **Required edits:**
  
  - Remove the nullable-parameter ambiguity in `updateSet`. Prefer `replaceSet(exerciseInstanceId, setId, WorkoutSetState next)` or a patch type that distinguishes **unset** from **clear**.
  
  - Clearing a weight field must set `weightKg` to null, not preserve the previous value.
  
  - Clearing reps must set reps to zero.
  
  - Move `canCompleteSet(measurementType, set, previous)` into a pure domain function shared by UI and notifier.
  
  - `toggleSetCompletion` must reject invalid incomplete sets even if invoked outside `SetRow`.
  
  - `hasMeaningfulSetData` must treat `0.0` and zero reps as empty; initial placeholders must not trigger the replacement warning.
  
  - Reps-only/duration sets must normalize weight to null; distance must normalize reps according to the chosen model.
    
    **Tests:** clear-after-enter; no invisible stale weight; direct notifier cannot complete invalid set; untouched weighted placeholder is not meaningful; replacement warning only appears for real data.
    
    **Commit:** `fix(workout): enforce set state invariants`

- ATOMIC-RC3-03 — Build one authoritative measurement resolver
  
    **Objective:** Missing metadata must never silently become weighted.
  
    **Files:** `measurement_type.dart`, exercise table/DAO, active-workout state/provider, routine seeding, import paths.
  
    **Required edits:**
  
  - Add `MeasurementType.tryParse(String?)` returning null for missing/unknown values.
  
  - Add one resolver accepting stored value, equipment, and exercise name. Valid explicit metadata wins; otherwise legacy inference runs.
  
  - Stop using `fromString(null)` as a fallback. Keep `fromString` only if it throws/asserts on unknown input, or replace every call with `resolve`/`tryParse`.
  
  - Remove the default `weight_and_reps` from `WorkoutExerciseState`; require a normalized value at construction, or use a temporary `unknown` state that cannot render an input row.
  
  - Assisted/counterweight exercises remain weighted. Bodyweight/no-equipment exercises become reps-only unless explicitly duration/distance.
  
  - Define explicit exceptions in one reviewed catalog map, not scattered name checks.
    
    **Tests:** null, blank, malformed, bodyweight, no-equipment, plank/hold, assisted pull-up, counterweight dip, machine, cable, custom exercise.
    
    **Commit:** `fix(measurement): centralize authoritative type resolution`

- ATOMIC-RC3-04 — Repair existing catalog data with hydration v8
  
    **Objective:** Existing Play users receive corrected metadata without losing routines or history.
  
    **Files:** `exercises_dao.dart`, `database.dart`, exercise JSON/catalog validation tests.
  
    **Required edits:**
  
  - Bump hydration key from `exercises_hydrated_v7` to `exercises_hydrated_v8`.
  
  - Increment DB schema to v6 only if a durable migration is required; otherwise implement an idempotent transactional catalog repair and document why.
  
  - Fix the v5 contradiction that classified `assisted` as reps-only.
  
  - Upsert every catalog row by stable `exerciseDbId`, preserving integer IDs and foreign keys.
  
  - Store explicit valid `measurementType` for every bundled exercise. Add a catalog test that fails if a value is missing or unknown.
  
  - Keep custom exercises unchanged unless their metadata is invalid; then infer once and persist.
  
  - Set the hydration flag only after the full transaction commits.
  
  - Correct stale “Hydration v5 complete” logging.
    
    **Tests:** simulated v7 upgrade; IDs/history/routines preserved; bodyweight repaired; assisted weighted; failed transaction leaves v8 flag unset; second run is idempotent.
    
    **Commit:** `fix(catalog): migrate measurement metadata to v8`

- ATOMIC-RC3-05 — Upgrade legacy workout drafts and routine starts
  
    **Objective:** Old drafts and routines cannot override valid catalog metadata.
  
    **Files:** `workout_draft_store.dart`, `active_workout_provider.dart`, `active_workout_state.dart`, routines DAO/seeding, tests.
  
    **Required edits:**
  
  - Introduce draft version 3.
  
  - On loading v1/v2, query each exercise ID from the database and reconcile measurement type using the authoritative resolver.
  
  - Distinguish “legacy field absent” from “explicit weighted.” Do not overwrite a valid explicit weighted type.
  
  - Clear incompatible stale weight for reps-only/duration while preserving reps, completion, set type, timestamps, order, timer, and user isolation.
  
  - Routine start, direct add, replace, edit-history, CSV import, and resumed draft must all construct state through one factory.
  
  - In `ExerciseBlock`, do not let a default non-empty state string mask catalog truth. Render a safe loading/repair state if metadata is unresolved.
    
    **Tests:** v1/v2 draft upgrade, routine start, direct selection, replace, edit historical workout, account switch, corrupt draft.
    
    **Commit:** `fix(workout): reconcile legacy measurement state`

- ATOMIC-RC3-06 — Certify no-equipment logging end to end
  
    **Objective:** Prove the real production journey, not an explicitly injected enum.
  
    **Required integration tests:**
  
  1. Hydrate a real in-memory database from representative catalog rows.
  
  2. Select Push-up/Pull-up/Air Squat through an `Exercise` entity.
  
  3. Add to Active Workout through `addExerciseFromEntity`.
  
  4. Render `ExerciseBlock` and `SetRow`.
  
  5. Assert KG/LBS field and unit picker are absent.
  
  6. Enter reps, complete, finish, reload history, export and re-import.
  
  7. Assert null weight is preserved throughout.
  
  8. Plank uses seconds; assisted pull-up still uses weight; distance uses distance semantics.
  
  9. Run the same assertions after simulated v7 upgrade and legacy-draft resume.
     
     **Do not:** solve this with name checks inside `SetRow` or hide KG only visually.
     
     **Commit:** `test(measurement): certify production logging pipeline`

- ATOMIC-RC3-07 — Remove Auth entrance motion completely
  
    **Objective:** Auth renders as a stable, calm sign-in screen on the first frame.
  
    **File:** `auth_screen.dart` plus Auth tests/goldens.
  
    **Required edits:**
  
  - Remove `SingleTickerProviderStateMixin`, `_entranceController`, `initState`, `didChangeDependencies`, `dispose`, and `_entrance()`.
  
  - Replace every `_entrance(child: …)` with the direct child.
  
  - Keep the atmosphere static. No sweep, translate, staged fade, looping glow, or logo-to-wordmark motion.
  
  - Keep press feedback and the progress indicator because they communicate interaction state.
  
  - Add keyboard activation for Terms and Privacy using actual `TextButton`/`InkWell` or `Actions`/`Shortcuts`, not focus-only wrappers.
  
  - Reduce repeated headline layers if 320px/2× text evidence shows crowding.
    
    **Tests:** logo/title/button/legal present immediately; no `AnimationController`, `FadeTransition`, or translated brand block; reduced-motion and normal-motion layouts match; six-theme goldens at 1× and 2×.
    
    **Commit:** `fix(auth): remove decorative entrance motion`

- ATOMIC-RC3-08 — Replace cinematic Splash with route-first startup
  
    **Objective:** Reach useful UI as soon as auth/profile resolution permits.
  
    **File:** `splash_screen.dart`, bootstrap/router tests.
  
    **Required edits:**
  
  - Remove the artificial 1200ms delay, three animation controllers, glow scaling, 1000ms intro, and 300ms exit fade.
  
  - Resolve auth/profile immediately and navigate as soon as the decision is available.
  
  - If a visible splash is needed to prevent a flash, use a static logo with a maximum 250–350ms minimum only when resolution is still pending.
  
  - Add a bounded timeout and actionable Retry/Continue offline state for profile-resolution failure.
  
  - Do not download a profile image on the routing critical path; schedule it after Home is visible.
    
    **Tests:** unauthenticated and returning-user route latency; timeout state; offline route; no ticking controller; no duplicate navigation.
    
    **Commit:** `perf(startup): remove artificial splash ceremony`

- ATOMIC-RC3-09 — Remove the unprofessional workout-name flight
  
    **Objective:** Opening Workout History should use a stable platform route; the title must not fly upward, resize, duplicate, or crossfade against itself.
  
    **Files:**
  
  - `workout_history_card.dart`
  
  - `workout_detail/hero_sliver.dart`
  
  - `workout_detail_screen.dart`
  
  - router transition configuration
  
  - `workout_hero_transition_test.dart`
    
    **Required edits:**
  
  - Remove the workout-name `Hero` from both card and detail.
  
  - Delete `enableHero` and `workoutId` plumbing that exists only for this title flight.
  
  - Replace the collapsing/parallax two-title `WorkoutHeroSliver` with a normal pinned AppBar and a static summary section below it.
  
  - Do not use `AnimatedOpacity` to swap expanded and collapsed copies of the same title.
  
  - Use the default Material route transition, or a single 200–250ms whole-page fade/slide shared by all detail routes. No element-specific title flight.
  
  - Remove `EntranceFade` from each detail exercise card; data should appear without a cascading replay.
    
    **Tests:** no `Hero` in history card/detail; title exists exactly once; back gesture remains smooth; long names at 2× do not jump or clip; route golden before/after navigation.
    
    **Commit:** `fix(history): stabilize workout detail navigation`

- ATOMIC-RC3-10 — Establish a whole-app motion budget
  
    **Objective:** Eliminate the repeated “things rising into place” feeling.
  
    **Inventory and change:**
  
  - Remove full-feed `EntranceFade` from Home.
  
  - Remove repeated `EntranceFade` from Profile identity/stats/chart/links.
  
  - Remove Routine Detail `_entryController` and staggered `_entryFade` intervals.
  
  - Remove Exercise Detail content entrance unless a measured state transition needs it.
  
  - Stop rest tile `_AmbientPulse`; use a static border/ring. Its controller currently repeats even when reduced motion returns static content.
  
  - Active Workout rest-bar `AnimatedSwitcher` must use zero duration under reduced motion.
  
  - Keep only press feedback, progress interpolation, reorder lift, and the full-screen Active Workout spatial transition.
  
  - Centralize allowed durations/curves in `AppMotion`; ban local arbitrary entrance durations through a source test/custom lint.
    
    **Acceptance:** no decorative controller repeats; no list animates item-by-item on navigation/provider refresh; reduced-motion leaves zero decorative tickers.
    
    **Commit:** `refactor(motion): enforce calm interaction budget`

- ATOMIC-RC3-11 — Reconstruct Home around one primary next action
  
    **Objective:** Home answers “What should I do now?” before showing secondary content.
  
    **Files:** `home_screen.dart`, history card, home provider/tests.
  
    **Required edits:**
  
  - Priority order: active workout/resume → next routine or Quick Start → weekly progress → history.
  
  - Do not force artificial weekly stats solely to satisfy a tour anchor. Tour UI must not mutate normal product content.
  
  - Remove the whole-list entrance wrapper.
  
  - Keep history cards static and tap-responsive; add button semantics to the whole card while keeping the menu separately actionable.
  
  - Make the stats row wrap/reflow at 1.6×–2× instead of relying on Spacer and fixed horizontal density.
  
  - If volume is zero, show measurement-neutral completed sets/exercises rather than implying missing performance.
  
  - Replace “cannot be undone” menu subtitle because deletion has Undo.
    
    **Tests:** empty, active, routine, long-history, pagination error, 320px/2×, TalkBack focus order.
    
    **Commit:** `feat(home): clarify next action and history hierarchy`

- ATOMIC-RC3-12 — Rebuild Active Workout action safety and density
  
    **Objective:** Make the workout surface the fastest and safest screen in the product.
  
    **Required edits:**
  
  - Make exercise removal reversible with a stable snapshot and Undo, matching set removal. If removing the final exercise with completed data, require confirmation.
  
  - Announce `Set removed. Undo available.` and exercise removal through `SemanticsService`; keep haptic feedback. Do not play a loud deletion sound—audio is reserved for timer completion.
  
  - Replace raw save-error `SnackBar` with the shared safe-offset helper.
  
  - Recalculate list bottom clearance from the actual rest-bar height and system inset; remove magic padding where possible.
  
  - Let exercise cards reflow at large text; do not squeeze set/previous/KG/reps/check columns below readable widths. At compact width, use a two-row set layout.
  
  - Reorder sheet must expose a Done action and support keyboard/switch reordering.
  
  - Preserve per-exercise rest override when replacing/reordering.
    
    **Tests:** remove/undo after reorder; final-exercise confirmation; snackbar above timer; 1×/1.6×/2×; gesture/three-button nav.
    
    **Commit:** `fix(workout): harden active-session interactions`

- ATOMIC-RC3-13 — Make rest preferences simple and timer delivery truthful
  
    **Objective:** Global default and per-exercise override must be obvious, compact, and reliable.
  
    **Files:** rest preference model, Settings picker, `compact_rest_chip.dart`, `rest_time_sheet.dart`, rest provider/bar, notification service.
  
    **Required edits:**
  
  - Use three exclusive states: **Use default (shows resolved time)**, **Custom**, **Off**.
  
  - In the per-exercise sheet, show the current effective result next to each choice; only show stepper/presets when Custom is selected.
  
  - Replace the dense three-zone sheet with progressive disclosure and a sticky Save action.
  
  - Keep the timer bar static—no ambient pulse. Show exercise name when space permits; expose +15, Skip, and Edit duration.
  
  - Preserve `exerciseName` through `_sync`, `addSeconds`, and draft resume.
  
  - Implement real permission checks. Do not return true without querying platform state.
  
  - Request notification permission contextually when background timer delivery is first needed; explain denial and keep foreground haptic/sound working.
  
  - Verify notification channel sound, background expiry, process death limitations, and exact-alarm behavior. Avoid duplicate foreground and notification sound.
    
    **Tests:** default/custom/off transitions; permission denied; background/resume; add seconds; draft resume; one expiry event/sound only.
    
    **Commit:** `fix(rest): simplify preferences and certify timer delivery`

- ATOMIC-RC3-14 — Make workout and routine summaries measurement-aware
  
    **Objective:** Mixed and non-weight sessions must not be summarized as kilograms.
  
    **Files:** workouts/routines DAO projections, history card, Workout Detail hero/summary, Routine Detail stats/graph, export models.
  
    **Required edits:**
  
  - Introduce a presentation summary model containing completed sets, duration, weighted volume if present, total reps for reps-only, duration totals, distance totals, and dominant/mixed type.
  
  - Home history: show weighted volume only when weighted work exists; otherwise show the relevant metric or a neutral set/exercise count.
  
  - Workout Detail: replace universal `VOLUME` with context-aware metrics. Mixed sessions may show Sets + Duration + a compact breakdown.
  
  - Routine Detail: remove universal `Total Volume (kg)`, `BEST KG`, and `AVG KG`. Use measurement-aware cards and trends.
  
  - Do not combine incompatible metrics into one score.
  
  - Correct delete copy: Undoable operations must not say “cannot be undone.”
    
    **Tests:** weighted-only, reps-only, duration-only, distance-only, mixed routine/session, zero-weight historical rows.
    
    **Commit:** `feat(analytics): present truthful workout metrics`

- ATOMIC-RC3-15 — Correct Exercise Detail analytics semantics
  
    **Objective:** Every toggle, chart, PR, and unit must represent the underlying measurement.
  
    **Files:** `exercise_detail_screen.dart`, analytics provider/DAO, chart and PR models.
  
    **Required edits:**
  
  - Reset/clamp active toggle when exercise type changes.
  
  - Reps-only: distinguish best set reps from session total reps; current PR UI duplicates the same `maxReps` value under two labels.
  
  - Duration: store/query duration explicitly instead of treating generic reps as seconds at the presentation boundary.
  
  - Distance: define a real model for distance, elapsed duration, and pace; do not overload `weight` and `reps` indefinitely.
  
  - Respect the user’s kg/lbs setting in weighted charts and PRs.
  
  - Replace horizontal metric strip with wrapping segmented controls or dropdown at compact/large-text layouts.
  
  - Keep image Hero only if physical evidence shows a clean spatial transition; otherwise remove it consistently.
    
    **Tests:** metric values, units, empty states, premium gating, type switch, large text, chart semantics.
    
    **Commit:** `fix(exercise): correct metric-specific analytics`

- ATOMIC-RC3-16 — Reconstruct Routine Editor for adaptive authoring
  
    **Objective:** Routine creation must remain usable below 360dp and at 2× text.
  
    **Files:** `routine_editor_screen.dart`, routines DAO/draft model, tests/goldens.
  
    **Required edits:**
  
  - Replace the overloaded single horizontal exercise row with: top row drag handle + thumbnail + name + menu; second row sets/reps/load/rest targets appropriate to measurement type.
  
  - Add editing for `defaultReps`, `defaultWeightKg`, and optional rest preference; hide weight for reps-only/duration.
  
  - Make removal undoable; do not immediately destroy the row.
  
  - Catch load/save errors and show retry without losing the draft.
  
  - Do not mark the editor dirty when loading the initial name.
  
  - Ensure duplicate exercises have stable instance IDs and reorder correctly.
  
  - Save through a transaction and return typed success/failure.
    
    **Tests:** compact/2×; keyboard/IME; duplicate exercises; reorder; remove/undo; failed save; measurement-specific defaults.
    
    **Commit:** `feat(routines): rebuild adaptive routine authoring`

- ATOMIC-RC3-17 — Fix Exercise Selection keyboard, taxonomy, and feedback
  
    **Objective:** Search/filter/select remains usable with keyboard, large text, and imperfect catalog strings.
  
    **Required edits:**
  
  - Remove `resizeToAvoidBottomInset: false`, or implement an explicit keyboard-safe sliver layout proven on compact devices.
  
  - Preserve a visible result area and dismiss keyboard on drag/select.
  
  - Replace free-form equipment matching with normalized taxonomy enums/aliases including `none`, `no equipment`, and bodyweight variants.
  
  - Announce result-count changes with a debounced live region.
  
  - Make browse-mode custom creation show the new exercise and a clear success state.
  
  - Ensure filter chips wrap or stack at 2× text.
  
  - Use one navigation transition policy; remove image Hero if it fails visual acceptance.
    
    **Tests:** keyboard open at 320×640; filters + search; result announcement; create custom; taxonomy aliases; 2× text.
    
    **Commit:** `fix(exercises): qualify search and selection layouts`

- ATOMIC-RC3-18 — Consolidate shell, bottom chrome, and system insets
  
    **Objective:** No detached, stacked, or oversized bottom region.
  
    **Files:** `app_shell.dart`, `bottom_nav_bar.dart`, `active_workout_bar.dart`, Android edge-to-edge configuration, adaptive tests.
  
    **Required edits:**
  
  - Maintain one owner for bottom safe-area padding. Avoid nested SafeAreas adding the same inset.
  
  - Compute shell clearance from the rendered navigation and active-workout bar, not duplicated constants in child screens.
  
  - Keep a subtle separator and consistent surface token across content, active bar, nav, and system navigation bar.
  
  - Reflow nav labels at 2× or switch to icon-dominant accessible navigation without clipping.
  
  - Disable active-bar/nav indicator animations under reduced motion.
  
  - Verify keyboard does not leave a blank bottom slab.
    
    **Evidence:** Android 14/15/16, gesture and three-button navigation, portrait/landscape, keyboard, active workout bar present/absent.
    
    **Commit:** `fix(shell): unify bottom chrome and insets`

- ATOMIC-RC3-19 — Make draft discard and recovery safe
  
    **Objective:** Recovery surfaces protect data rather than offering destructive shortcuts.
  
    **Required edits:**
  
  - Resume sheet: add Continue, Start new while preserving draft, and Discard with explicit confirmation. Surface clear failure instead of swallowing it.
  
  - Database Recovery: use dynamic theme tokens; show what may be lost; offer export/diagnostic/support before reset where technically possible.
  
  - Do not promise automatic restore unless the current account is entitled, sync was enabled, and remote data exists.
  
  - Show reset failure with Retry and support reference.
  
  - Replace `SystemNavigator.pop` “Reopen” behavior with an in-app reinitialization route where supported; provide honest platform copy otherwise.
  
  - App Error: replace “Your workout data is safe” with conditional language unless persistence is verified.
    
    **Tests:** local-only, Pro synced, sync paused, reset failure, stale/corrupt draft, iOS-safe behavior.
    
    **Commit:** `fix(recovery): protect drafts and local data`

- ATOMIC-RC3-20 — Separate Profile identity from Settings configuration
  
    **Objective:** Profile presents progress and identity; Settings controls the product.
  
    **Required edits:**
  
  - Profile: identity, progress, training chart, concise routes. Remove duplicated Premium/settings actions.
  
  - Settings: Account, Training Preferences, Data & Sync, Support, Legal, Danger Zone.
  
  - Replace five-tap crash trigger in the Version row with a debug-only diagnostics entry unavailable in release UI.
  
  - Make weekly-goal selection a wrapping grid/picker rather than seven squeezed Expanded buttons.
  
  - Add busy/success/failure state to display name, age, gender, experience, image upload, sync toggle, restore, export, and cache clearing.
  
  - Make display-name edit a real button semantic and keyboard action.
  
  - Rewrite cloud copy based on entitlement + enabled state + last successful sync. Remove universal backup and “Only you can read it” claims unless cryptographically proven.
    
    **Tests:** all entitlement/sync states; mutation failure; 2× text; keyboard; TalkBack order.
    
    **Commit:** `refactor(profile): clarify identity and settings roles`

- ATOMIC-RC3-21 — Finish Help, report, legal, and support flows
  
    **Objective:** A problem report must be transparent, keyboard-safe, and deliverable.
  
    **Required edits:**
  
  - Keep the scrollable branded sheet; verify IME and 2× text.
  
  - Do not silently copy diagnostics. Show an explicit “Copy diagnostic report” action or disclose copying before it occurs.
  
  - Keep the form open until mail/share handoff succeeds or the user chooses Copy.
  
  - Add submission busy/error state and prevent double submit.
  
  - Never show raw legal URLs in a stock dialog; show a branded retry/copy-link action.
  
  - Use the canonical sub-screen title style/back icon.
  
  - Verify support mailbox, privacy, terms, and deletion URLs from the store build.
    
    **Tests:** no mail client, share failure, keyboard, long text, clipboard consent, external-link failure.
    
    **Commit:** `fix(support): complete transparent report flow`

- ATOMIC-RC3-22 — Make paywall accessible and legally complete
  
    **Objective:** Purchase UI must remain readable and truthful at every text scale and store state.
  
    **Required edits:**
  
  - Reflow feature title/subtitle vertically; never place long subtitle at the trailing edge of the same Row.
  
  - Reflow plan price/badge at compact width and 2× text.
  
  - Pricing unavailable retry must be a real semantic button.
  
  - Add live Terms and Privacy links, billing period, auto-renewal statement, cancellation route, and trial-to-paid transition from actual store data.
  
  - Disable dismissal only while the native purchase sheet is active; preserve cancellation semantics.
  
  - Map RevenueCat cancellation, pending, network, entitlement-delay, restore, and account-switch outcomes to distinct user messages.
  
  - Keep live localized prices as the only pricing source.
    
    **Tests/evidence:** monthly/yearly, eligible/ineligible trial, pending, cancel, restore, offline cache, Play license tester, 2× text.
    
    **Commit:** `fix(billing): qualify accessible purchase truth`

- ATOMIC-RC3-23 — Standardize dialogs, snackbars, app bars, and action copy
  
    **Objective:** Remove the “assembled across iterations” feeling.
  
    **Required edits:**
  
  - Use one AppBar style/back icon/title scale on all sub-screens.
  
  - Use shared branded dialog/sheet/snackbar helpers; remove remaining raw `AlertDialog` and raw `SnackBar` where they conflict or collide with persistent bars.
  
  - Centralize safe snackbar offset based on nav/rest/IME.
  
  - Standardize terminology: **Routine** for user-created structures, **Program** for Explore content, no “Template” unless technically a template.
  
  - For undoable deletion, use “Remove/Delete” + “Undo available”; never “cannot be undone.”
  
  - Audit capitalization: “Sign out,” “Short workout,” sentence case.
  
  - Add source tests for forbidden copy and inconsistent title/back patterns.
    
    **Commit:** `refactor(ui): unify product interaction language`

- ATOMIC-RC3-24 — Whole-app accessibility and adaptive qualification
  
    **Objective:** Core journeys work through touch, keyboard/switch access, TalkBack/VoiceOver, and 200% text.
  
    **Required edits:**
  
  - Replace actionable `GestureDetector` controls with Material buttons/InkWell or provide complete focus/keyboard actions.
  
  - Audit every 48×48 target, semantic role, selected/toggled state, hint, focus order, and non-color cue.
  
  - Reflow fixed horizontal rows: set row, weekly goal, paywall, profile stats, history stats, routine editor, timer bar.
  
  - Add live announcements for validation, result counts, timer start/expiry, removal/Undo, save success/failure, and purchase state.
  
  - Ensure charts expose summary/trend/table alternatives.
  
  - Verify contrast across all six accents in light/dark surfaces.
    
    **Matrix:** 320px compact, 360×800, Redmi physical device, tablet width, portrait/landscape, keyboard open, text 1×/1.6×/2×, reduced motion.
    
    **Commit:** `feat(accessibility): qualify complete core journey`

- ATOMIC-RC3-25 — Performance, database, sync, and import regression gate
  
    **Objective:** Product polish must not reintroduce lag or data loss.
  
    **Required verification/corrections:**
  
  - Profile cold start, Home long history, exercise search, 12-exercise active workout, chart switching, GIF scrolling, and large CSV import in profile mode.
  
  - Ensure catalog v8 transaction and legacy-draft reconciliation run off the UI thread where appropriate.
  
  - Preserve foreign keys, account isolation, sync quarantine, monotonic conflict handling, import/export measurement columns, and rollback on failed import.
  
  - Add cancellation for long import and visible file-size guidance.
  
  - Verify no sensitive data is sent to Sentry or included in support reports.
  
  - Record p50/p95 frame times, memory peak, startup-to-useful-screen, and database migration duration.
    
    **Commit:** `perf(release): close RC3 regression budgets`

- ATOMIC-RC3-26 — Build and certify version 1.0.0+3
  
    **Objective:** Produce one exact-SHA internal candidate and invalidate every earlier screenshot/artifact.
  
    **Instructions:**
  
  - Bump to `1.0.0+3` only after tasks 01–25 are merged.
  
  - Run format, fatal analyzer, custom lint, all tests, Android native bundle build, and BillingClient dependency insight.
  
  - Build release-signed AAB with real `.env`, obfuscation, split debug info, and native symbol table.
  
  - Record full source SHA, clean tree, test totals, AAB SHA-256/size, signer fingerprints, BillingClient resolution, and symbol paths.
  
  - Upload to Play Internal testing. Install from Play—not ADB—and verify displayed version.
  
  - Compare upload certificate fingerprints with Play Console.
    
    **Commit:** `chore(release): prepare GymLog 1.0.0+3 internal candidate`

- ATOMIC-RC3-27 — Final Play-installed acceptance matrix
  
    **Objective:** Decide GO/NO-GO using behavior, not commit messages.
  
    **Required journeys on the Play-installed build:**
  
  1. Fresh install and upgrade over `1.0.0+2`.
  
  2. Auth screen is static; no sweep/rise/stagger.
  
  3. Home → Workout Detail has no flying/rising title and exactly one stable title.
  
  4. Push-up, Pull-up, Air Squat: no KG/LBS, reps-only completion succeeds.
  
  5. Plank: seconds; assisted pull-up: weighted; distance: truthful unit.
  
  6. Start routine, add/replace/reorder/remove/undo sets and exercises.
  
  7. Global/default/custom/off rest choices; foreground/background expiry; sound/vibration/notification once.
  
  8. Finish persistence failure simulation retains workout; successful finish appears in history.
  
  9. Edit failure retains editor; retry succeeds once.
  
  10. Draft resume/migrate/discard safety.
  
  11. Purchase, cancel, restore, entitlement delay, account switch.
  
  12. Gesture/three-button navigation, Android 14/15/16, 1×/1.6×/2×, portrait/landscape, keyboard.
  
  13. Live Sentry symbolication, privacy/legal/support links, export/import round trip.
      
      **GO threshold:** zero P0/P1 failures; no data-loss, auth, billing, accessibility, overflow, bottom-inset, or truth defect. Every PASS row must name exact source SHA, AAB hash, device, version, and evidence file.

---

## Required final report schema

- Final branch and full SHA
- Commit list mapped to ATOMIC-RC3 IDs
- Clean-tree proof
- Test totals by suite
- Migration/hydration upgrade evidence
- Fresh-install and upgrade evidence
- Android AAB hash, size, version, signer, BillingClient
- Screen/video matrix with text scale and navigation mode
- OAuth, RevenueCat, Sentry, support, privacy, deletion evidence
- Residual risks with owner and severity
- Final GO/NO-GO

<aside>
✅

**Completion rule:** A task is complete only when source, automated tests, exact-SHA artifact behavior, and the required human/device evidence agree. Passing 497 or more tests cannot override a failed Play-installed workflow.

</aside>
