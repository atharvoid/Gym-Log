# Independent verdict — Home/Routines correction, iteration 3

Candidate: Home/Routines correction, iteration 3. Diff baseline: `f12e89664be6aa83d1c86fbfb258c32ea0d7c37a`. This review used only this packet's RUBRIC.md, EVIDENCE.md, candidate.diff, render-inventory.json, and supplied before/after PNGs. No implementation files, plans, ledgers, audits, prior verdicts, or builder conversation were consulted.

**Home: 8.0/10 — Pass. Routine Library: 7.8/10 — Pass.** No unresolved material task failure, information failure, or legibility regression is established by the supplied evidence. These are packet-level passes, not certification of tests, CI, physical devices, or release readiness.

## Scores and explicit before/after comparison

The before scores describe the supplied ready and chooser states only. There are no matched before captures for the added error, active, persistence, and completion states; their improvement cannot be quantified as a before/after state comparison.

| Dimension | Home before | Home candidate | Library before | Library candidate |
| --- | ---: | ---: | ---: | ---: |
| Task hierarchy and flow | 6 | 8 | 6 | 8 |
| Information truth and usefulness | 7 | 8 | 6 | 8 |
| Legibility and adaptive presentation | 5 | 8 | 5 | 8 |
| Composition and visual identity | 7 | 8 | 6 | 7 |
| State clarity and feedback | 6 | 8 | 6 | 8 |
| Arithmetic mean | **6.2** | **8.0** | **5.8** | **7.8** |

Home arithmetic: before (6 + 7 + 5 + 7 + 6) / 5 = 6.2; candidate (8 + 8 + 8 + 8 + 8) / 5 = 8.0.
Library arithmetic: before (6 + 6 + 5 + 6 + 6) / 5 = 5.8; candidate (8 + 8 + 8 + 7 + 8) / 5 = 7.8.

**Home before/after:** In `before/home-ready-higgsfield-1.0x.png`, Push A is a chosen Home routine, with muscles and one logged Bench Press set. In the matched `after/home-chosen-higgsfield-1.0x-synthetic.png`, Legs A is the resolved next workout after the same completed Pull A, and that reason is visible. The after state therefore changes behavior intentionally; it is not merely a restyle of the same chosen routine. The single historical set is replaced by an explicitly completed global last-workout card. At 2.0x, the before Start Push A button is partly under the navigation bar, while the after Start Legs A label and target are fully visible. The after page still requires scrolling for history and, in longer states, secondary actions.

**Library before/after:** `before/library-ready-higgsfield-1.0x.png` repeats Home's large chosen-routine launcher before the actual library. `after/library-chosen-higgsfield-1.0x-synthetic.png` removes that duplicate, keeps New routine and Explore visible, and presents the program group plus its real routine cards earlier. The next routine remains identifiable through group status, View next, and the routine's UP NEXT badge. At 2.0x, the before ready capture reaches only the group heading beneath the duplicate launcher; the after ready capture reaches the first card. The creation utilities are visually larger than before, so this is a functional browsing improvement rather than exceptional density.

## Specific evidence for every candidate dimension above 7

### Home

- **Hierarchy and flow — 8:** `after/home-chosen-higgsfield-1.0x-synthetic.png` places Legs A, the explanation, Start Legs A, and Train something else in one bounded task card. The filled Start action is stronger than the outlined alternative. `after/home-empty-higgsfield-2.0x.png` still offers direct Start workout and Browse programs, and `after/home-active-higgsfield-2.0x.png` replaces the immediate start with Resume Pull A while labeling Legs A For later. The `training_launchpad.dart` hunk `@@ -65,373 +69,190 @@` ties these actions to active, empty-library, and resolved-next branches. This exceeds a coherent static launcher because the intended action changes with the evidenced task state. One-handed reach remains unverified, needs device.

- **Information truth and usefulness — 8:** The matched ready render says “After Pull A in your saved order,” while `after/home-completed-higgsfield-1.0x.png` changes to Push A after Legs A and shows Legs A as the last completed workout. `training_plan_provider.dart`, added `resolveTrainingPlan`, filters completed workouts, orders by endedAt, wraps the saved program order, and reports tied completion ambiguity rather than selecting a guessed day. The `workouts_dao.dart` hunk `@@ -867,6 +867,53 @@` adds a completed-only account-scoped lookup independent of the paginated start-date feed. The ready last-workout card labels the date/time, completed status, elapsed minutes, and kg volume explicitly; `after/home-last-older-higgsfield-2.0x.png` visibly includes 2025. This is stronger than the before screen's disconnected single-set context. Real persisted history, imported records, and unit changes have not been exercised by this review.

- **Legibility and adaptive presentation — 8:** `after/home-ready-higgsfield-2.0x.png` keeps the primary Start Legs A action above navigation, correcting the visibly obscured before button. `after/home-narrow-ready-higgsfield-2.0x.png` preserves the name, reason, counts, and start action at 320 logical pixels. `after/home-long-name-higgsfield-2.0x.png` preserves the full identity and brings the shorter Start workout action forward instead of ellipsizing the identity. The launchpad hunk explicitly stacks its tag/control at large text and preserves the full routine name in the start semantics. `after/home-plan-keyboard-higgsfield-2.0x.png` and `after/home-override-keyboard-higgsfield-2.0x.png` show a fully readable searched target and pinned search above the simulated keyboard. This exceeds ordinary scaling because the evidence includes narrow, long-name, and keyboard constraints. Native keyboard and screen-reader use remain unverified, needs device.

- **Composition and visual identity — 8:** In `after/home-chosen-higgsfield-1.0x-synthetic.png`, the next-workout card has one accent-filled primary action, an accent status tag, quieter gray explanatory text, and an outlined secondary action. The last-workout facts occupy a separate quieter card rather than competing with the start. The ready 2.0x renders for higgsfield, neonPurple, neonCyan, neonMagenta, blazeOrange, and white retain the same priority and readable dark background; the white palette still differentiates the filled start by containment. This improves grouping and action salience over the unbounded before launchpad. The very large secondary button at narrow 2.0x is a density cost, so this earns 8 rather than 9; user preference and real-device viewing remain unknown.

- **State clarity and feedback — 8:** `after/home-plan-repeat-higgsfield-2.0x.png` visibly says to tap a routine to save and close without choosing to cancel. `after/home-repeat-committed-higgsfield-2.0x.png` shows Push A and “Repeating your chosen routine”; `after/home-repeat-canceled-higgsfield-2.0x.png` shows the reopened switch off and the original program choice selected. `after/home-plan-saving-higgsfield-2.0x.png` displays Saving training plan and progress with disabled close/search/choices; `after/home-plan-save-error-higgsfield-2.0x.png` displays a failed-save message with choices available again. The `training_launchpad.dart` hunk `@@ -441,20 +262,70 @@` awaits the write before closing, while the new notifier publishes AsyncData only after successful setString. `after/home-empty-next-higgsfield-2.0x.png` shows actual zero counts and Add exercises instead of a misleading start. Read errors show Try again; the last-workout error remains distinct from plan error. This is observable state separation beyond a coherent ready-only screen. Preference writes are controlled fakes in this packet; physical persistence and device feedback remain unverified.

### Routine Library

- **Hierarchy and flow — 8:** The matched `after/library-chosen-higgsfield-1.0x-synthetic.png` removes the duplicate Home launcher, exposes grouped routine cards sooner, and keeps New routine, Explore, and per-card Start. `after/library-view-next-higgsfield-1.0x.png` and `after/library-view-next-higgsfield-2.0x.png` establish that View next brings the actual Legs A card and its primary Start Legs A into view. The `workout_screen.dart` hunks `@@ -122,25 +186,68 @@` and added `_viewNext` preserve creation/exploration and locate lazy mounted cards on an explicit navigation action. This exceeds baseline browsing because it improves access without duplicating the launcher. Very large libraries and real scroll/navigation feel remain unknown.

- **Information truth and usefulness — 8:** `after/library-chosen-higgsfield-1.0x-synthetic.png` says “Source program · 3 saved routines,” “Following on Home,” and labels Legs A UP NEXT; the same routine is Home's resolved next. `after/library-completed-higgsfield-1.0x.png` moves UP NEXT and the emphasized start to Push A after the latest completion changes. `workout_screen.dart` derives group status and per-card isNext from `trainingPlanResolutionProvider`, not an independent guess. The `relative_time.dart` hunk `@@ -1,7 +1,11 @@` uses local calendar days, and `routine_card.dart` `@@ -63,7 +67,7 @@` uses the supplied clock, correcting the before launchpad/card age inconsistency. This gives cross-screen task context rather than merely a saved-routine inventory. Actual live completion propagation remains unverified by this review.

- **Legibility and adaptive presentation — 8:** `after/library-chosen-higgsfield-1.6x-synthetic.png` wraps the exercise preview and gives Start its own row. `after/library-narrow-ready-higgsfield-2.0x.png` preserves the Routines title, group label, source count, Following on Home, View next, and first card identity without horizontal collisions. `after/library-view-next-higgsfield-2.0x.png` shows a full next card with readable exercise summary and start button. The `routine_card.dart` hunks `@@ -106,15 +110,14 @@` and `@@ -158,39 +161,57 @@` remove one-line truncation from identity/meta and stack the footer at large text. `after/library-long-name-higgsfield-2.0x.png` establishes title wrapping, although its full card is below the fold. These are specific adaptive improvements over the before card and competing compact launchpad. The entire long-name card, narrow keyboard combination, and screen-reader operation remain unknown.

- **State clarity and feedback — 8:** `after/library-empty-higgsfield-2.0x.png` emphasizes New routine and explains how to populate the library. `after/library-error-higgsfield-2.0x.png` distinguishes a routine read failure and offers Try again. `after/library-plan-error-higgsfield-2.0x.png` separately says saved routines are available and routes the plan issue to Home. `after/library-active-higgsfield-2.0x.png` keeps the active Pull A/timer visibly separate from program status. The `workout_screen.dart` hunk `@@ -149,8 +256,26 @@` supplies library-specific retry; `routine_card.dart` disables start when a workout is active; the measured-height active-bar and shell-inset hunks preserve space for scaled active chrome. This is stronger than the before duplicated-launcher state ownership. Timer feel and native feedback remain unverified, needs device.

Library composition is **7**, not above 7: grouping and accent are coherent, but large creation utilities and long section headings still dominate the 2.0x viewport, and this evidence does not demonstrate exceptional visual craft.

## Micro elements

| Element | Score | Evidence and limitation |
| --- | ---: | --- |
| Home start / empty-next repair | 8 | `after/home-ready-higgsfield-2.0x.png` has the full primary start; `after/home-empty-next-higgsfield-2.0x.png` changes it to Add exercises with zero counts. The launchpad unavailable branch routes to edit. Route execution is not independently verified here. |
| Chooser mode commitment and cancellation | 8 | Pending repeat, repeat-committed, and repeat-canceled renders visibly distinguish edited mode from committed intent; `_repeatOverride` is local chooser state and the write is awaited. Barrier/back dismissal during a pending write is not established. |
| Save feedback | 8 | The plan-saving and plan-save-error captures use the real chooser with controlled delayed/rejected writes; status text, progress, disabled actions, and restored choices are visible. Real storage failure/retry is unknown. |
| Last-workout facts | 8 | Ready shows full completion date/time, elapsed, and volume; last-older visibly shows 2025 and last-error supplies a separate retry. Unit variants, zero-volume, and abnormal duration are not rendered. |
| Library View next / next-card start | 8 | `after/library-view-next-higgsfield-2.0x.png` brings UP NEXT, Legs A, readable preview, and Start Legs A into the viewport. Very long targets and large data sets are unknown. |
| Active workout bar legibility | 8 | Both active 2.0x captures show Pull A and 00:24:00 inside a grown bar; `activeBarHeight` measures scaled text and shell inset uses that height. Timer feel, haptics, and one-handed use: **unverified, needs device**. |
| New routine / Explore utility row | 7 | Clear and adaptive, but its visual size competes with the actual library at 2.0x. |
| Narrow Home secondary action density | 7 | `after/home-narrow-ready-higgsfield-2.0x.png` wraps Train something else to three lines and continues below the first viewport. The primary start remains visible; scrolling is expected, not proof of clipping. |

## Findings by consequence

### Established material defects

None established. In particular, the packet does not establish a false saved-plan claim, destructive choice on cancellation, an empty next routine that starts silently, an obscured searched target, or a mismatch between Home next and Library next.

### Established minor costs and regressions

1. **Home loses the visible previous-set/muscle context.** The before ready render exposes Bench Press 60 kg × 8 and muscle coverage; `training_launchpad.dart` removes `_previousContext` and the muscle text. The candidate replaces it with a global completion summary rather than preserving it inline. This is a real presentation tradeoff: less lift-specific preparation context on Home, more reliable global session context. It is not established as material because Library previews remain and the main start task is clearer.
2. **The chooser is verbose at large text.** In the 2.0x pending-repeat and canceled-repeat captures, header, description, search, and mode instructions leave only about one routine initially visible. The scrolling results and explicit commitment instruction make it usable, but it is not exceptional efficiency.
3. **Large-text secondary controls remain visually heavy.** Narrow Home's three-line alternate button and Library's two full-width utility buttons consume substantial vertical space. The packet shows working priorities, not optimal density.
4. **Library ready long-name coverage is partial.** The long-name render proves wrapping but does not show the full long-name card or its eventual start action. This is a coverage limit, not evidence that the action is lost.

### Hypotheses requiring additional evidence

- The modal is created without an explicit barrier/back/drag lock in the supplied `showModalBottomSheet` hunk, while only the Close control is disabled during saving. Whether dismissing through another route can leave a write completing after dismissal needs a focused interaction capture or device check. The close-before-choice cancellation renders do not cover this case. Do not equate it with a demonstrated failed cancellation.
- The pinned header may become too tall for a 320-pixel viewport with 2.0x text and an open keyboard; the packet supplies narrow ready and 390-pixel keyboard states separately. That combined constraint is unknown.
- `_PlannedCounts` now sums raw defaultSets rather than the before fallback of at least one. If zero/negative set defaults can coexist with launch behavior that adds one set, displayed counts could disagree. The packet does not establish that data configuration or mismatch.
- Real-time account changes, database streams, storage retries, imported/tied completions, accessibility announcements, and hardware-back behavior cannot be certified from these synthetic stills and the diff.

## Coverage checked and remaining unknowns

| Requested state | Packet assessment |
| --- | --- |
| Matched ready states | Checked before/after Home and Library at 1.0x, 1.6x, and 2.0x; comparison respects selected sample-0 and completed sample-1/Pull A. |
| Six palettes | Ready Home/Library 2.0x renders checked for higgsfield, neonPurple, neonCyan, neonMagenta, blazeOrange, and white. Geometry and hierarchy remain consistent. |
| Narrow / large text | 320 × 844 ready 2.0x and 390 × 844 1.6x/2.0x, plus long-name states checked. Full long Library target and combined narrow keyboard are unknown. |
| Empty / error / active | Home and Library 2.0x checked; Library plan-error remains separate from library read-error. No matched before captures for these states. |
| Mode commitment / cancellation | Pending-repeat, repeat-committed, and canceled/reopened renders checked. Cancellation before choosing is supported; dismissal during an outstanding write is unknown. |
| Actual pending / failed save | Controlled preferences fake reaches real chooser Saving training plan and failed-save states. This is stronger than a renamed static fixture; real storage remains unknown. |
| Empty resolved next routine | Actual Legs A with zero exercises/counts checked; Add exercises visibly replaces start. Library's empty-next card is not captured. |
| Keyboard | Both plan and one-session modes at 1.0x, 1.6x, and 2.0x inspected; searched target and pinned field fit above simulated keyboard. Native keyboard remains unverified. |
| Search / pagination / no results | 1.6x synthetic chooser states checked; second page says 5 to 5 of 5, searched Outdoor walk is readable, no-results message is explicit. |
| Completion / old date / last-error | Completion updates Home next and Library badge; old-year label and independent last-workout read-error checked. Fixtures are not live-user validation. |

## Smallest corrective changes and verdict boundary

No corrective implementation is required for this packet-level pass. Optional polish should stay small: shorten the mode explanation while retaining “tap routine to save” and “close cancels,” and consider a less tall secondary utility presentation at extreme text scale without shrinking the text or targets.

Before broader acceptance, capture the combined narrow/large-text/keyboard case, a full long-name Library card, and dismissal/retry behavior during an outstanding save. These are explicit unknowns, not failed checks inferred from screenshots.

**Final verdict: Home Pass (8.0); Routine Library Pass (7.8).** A score of 9 or 10 is not supported: the evidence shows strong targeted improvements, with meaningful density tradeoffs and several interaction combinations still unknown. Tests, CI, and physical-device acceptance are outside this packet. Haptics, timer feel, one-handed use, native keyboard, and screen-reader use: **unverified, needs device**.

