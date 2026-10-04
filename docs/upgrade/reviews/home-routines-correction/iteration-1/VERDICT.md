# Independent verdict — Home/Routines correction, iteration 1

Candidate identifier: `candidate.diff`, baseline `f12e89664be6aa83d1c86fbfb258c32ea0d7c37a`. This review used only this packet's rubric, evidence note, exact diff, and before/after PNGs. Diff references below are one-based **packet diff lines**, not repository source lines. Test additions describe coverage; no execution results were supplied, so they do not certify passing behavior.

## Home — Revision needed

| Dimension | Before | After |
|---|---:|---:|
| Task hierarchy and flow | 7 | 6 |
| Information truth and usefulness | 6 | 7 |
| Legibility and adaptive presentation | 6 | 7 |
| Composition and visual identity | 6 | 7 |
| State clarity and feedback | 6 | 7 |
| **Mean** | **6.2** | **6.8** |

The matched ready comparison is `before/home-ready-higgsfield-1.0x.png` versus `after/home-chosen-higgsfield-1.0x-synthetic.png`, and the corresponding 1.6x neonPurple pair. The before screen keeps Push A chosen despite the more recent Pull A. The after screen shows Legs A, explains “After Pull A in your saved order,” places its Start action inside the launch card, and presents Pull A separately as a completed last workout. That improves the ordinary returning user's decision. The separate `after/home-completed-higgsfield-1.0x.png` fixture shows the subsequent wrap to Push A after Legs A; it is a changed-completion state, not a matched before/after ready comparison.

At 2.0x, the normal ready Start is entirely visible in `after/home-ready-higgsfield-2.0x.png`; the before counterpart places Start partly beneath the navigation chrome. The new last-workout summary supplies a completion timestamp and labels elapsed time and volume, rather than presenting an arbitrary previous set as the main preparation context. Full routine names and utility labels wrap. These are useful improvements, but the empty entry, missing repeat mode, and long-name action displacement limit the scores.

### Material findings

1. **[P2] Empty Home sends its primary action into an empty chooser.** `after/home-empty-higgsfield-2.0x.png` gives “Choose training plan” the only primary emphasis despite having no routines. Diff lines 1122–1138 make that action unconditional whenever no next routine exists; chooser lines 1515–1519 then render “No matching routines.” The plan chooser has no browse/create/start fallback. The previous empty branch at diff lines 926–947 directly offered Start workout on Home. A new user must back out, discover Browse programs, or find Train something else and then Start without a routine. The capability survives through a longer secondary path, but the strongest invitation produces no progress. **Smallest correction:** distinguish a genuinely empty library from an unchosen populated library and make the empty primary a direct Start workout/Start without a routine action, with Browse programs alongside it. Restore a tap test for the first session; the removed explicit-first-start tests at diff lines 2834–2840 were not replaced with equivalent Home behavior coverage.

2. **[P2] A routine in a complete program cannot be selected as a persistent repeat.** The before chooser (`before/chooser-closed-higgsfield-1.0x.png`) explicitly chooses a routine shown on Home and says suggestions are optional; the matched before Home continues to offer Push A. In the candidate, `planForRoutine` always selects program mode when membership is valid (diff lines 334–342), and `_choose` always uses that result (406–419, 1271–1280). The plan chooser renders every such member as “Follow …” (1529–1532); there is no repeat-mode control. A user who wants to repeat Push A while retaining all three program routines must repeatedly use the session override. This also narrows the chooser's claim that users can “repeat a routine” without explaining the restriction. **Smallest correction:** expose an explicit Follow program / Repeat this routine choice for program members, retaining the current program-following default and completion-derived progression. Persist that mode and test it across reopening/account scope. This finding concerns the lost persistent choice; automatic next-program progression itself is an improvement.

3. **Long identities delay the principal action excessively at large text.** In `after/home-long-name-higgsfield-1.6x.png`, the launch title and repeated predecessor identity consume nearly the whole viewport, leaving Start workout at the navigation edge. At 2.0x the title alone occupies most of the viewport and no Start action is visible. The diff uses an unbounded `AppText.titleLarge` identity followed by a reason containing the full predecessor name (1075–1101, 509–511). The name remains readable and the page is scrollable; this is action displacement, not proved clipping or data loss. **Smallest correction:** use a smaller existing heading role for long identities at large text and reduce the repeated predecessor copy while preserving full identity and accessible meaning. Verify the scrolled Start action and its clearance, rather than only asserting unbounded text (`test` diff lines 3271–3302).

### Affected micro elements

| Element | Score | Evidence and limitation |
|---|---:|---|
| Ready progression explanation | 8 | `after/home-chosen-higgsfield-1.0x-synthetic.png` visibly ties Legs A to completed Pull A, while the separate last-workout card confirms the completion. Diff lines 482–511 derive this from matching program completions, order by completion time, and stop on distinct-day ties; DAO lines 8–53 avoid the paginated start-date feed. This exceeds a bare coherent suggestion by exposing the reason. Real completion/sync behavior is not validated by these renders. |
| Empty primary action | 3 | Empty render and unconditional Choose action described in finding 1. |
| Plan chooser with keyboard at 2.0x | 8 | `after/home-plan-keyboard-higgsfield-2.0x.png` retains the heading, close control, search field, and a complete Pull A choice above the simulated keyboard. In `before/chooser-keyboard-higgsfield-2.0x.png`, the larger explanatory block pushes the matching choice's subtitle under the keyboard. Diff lines 1424–1431 reserve real viewInset height and 1497–1500 make choices scroll independently. The fixture uses program-name search, so its Pull query matching all three program members is consistent with diff lines 1339–1342. Native keyboard and screen-reader use remain unverified. |
| Long-name launch presentation | 6 | Full identity is preserved, but the evidenced 1.6x/2.0x action displacement remains. |
| Active resume presentation | 7 | `after/home-active-higgsfield-2.0x.png` gives Resume Pull A the main action and keeps Legs A for later; however, the “For later” tag sits above the current-workout subsection too. Place that tag immediately above the later routine for clearer scope. |

### Regressions and missing coverage

The former direct freestyle entry is now inside a sheet. The previous-set preview, muscles and last-trained context are removed from Home (diff lines 1140–1212); the last-workout summary serves a different purpose. Their removal makes the ordinary card easier to scan, but no user evidence establishes whether losing preparation context is preferable.

There are no supplied after renders of an empty plan chooser, a closed-keyboard plan chooser, deleted/corrupt preference repair, incomplete program repair, tied-completion repair, preference-save failure, or launch failure. The supplied error render establishes readable retry copy, not successful recovery. The new corrupt/deleted widget test asserts the error but does not complete the repair (diff lines 2983–2997). Tie handling has resolver tests, but a first selection into a different program with tied history is not covered by the current-program-based `_choose` tie detection (1272–1280). The isolated last-workout loading/read-error states and older-year dates are also not rendered.

Some after Home captures (`home-ready-higgsfield-2.0x.png`, `home-completed-higgsfield-1.0x.png`) have blank space where Train appears in chosen/active captures. Explain or repeat this capture before using those images to certify top-of-page composition; the supplied diff alone does not establish an implementation regression.

## Routine library — Pass for the supplied evidence

| Dimension | Before | After |
|---|---:|---:|
| Task hierarchy and flow | 6 | 8 |
| Information truth and usefulness | 6 | 8 |
| Legibility and adaptive presentation | 5 | 8 |
| Composition and visual identity | 6 | 8 |
| State clarity and feedback | 6 | 7 |
| **Mean** | **5.8** | **7.8** |

The matched comparisons are the higgsfield 1.0x ready/chosen pair, the neonPurple 1.6x ready/chosen pair, and the higgsfield 2.0x ready pair. The after library removes the duplicate launch card, promotes New routine and Explore to substantial utilities, shows program ownership at the group, and marks the actual next routine. It preserves the original program order; View next deliberately brings the next card into view rather than reordering the library. That gives the section a more coherent library purpose.

### Specific evidence for scores above 7

- **Task hierarchy and flow, 8:** `before/library-ready-higgsfield-1.0x.png` spends a full card on a duplicate Push A launch above the actual library. `after/library-chosen-higgsfield-1.0x-synthetic.png` starts the grouped cards much earlier and gives Following on Home a View next action. `after/library-view-next-higgsfield-2.0x.png` shows the resulting actual Legs A card with its entire Start button visible. Diff lines 1739–1777 only move on that explicit action, and 1962–1978 attach the next state to the routine's stable ID. This is a specific navigation improvement; large libraries, interrupted navigation, and real touch use remain unverified.
- **Information truth and usefulness, 8:** `after/library-completed-higgsfield-1.0x.png` marks Push A as UP NEXT after the completion changes to Legs A, whereas the ordinary matched after fixture marks Legs A. The group says Following on Home, while standalone plans use Chosen on Home (diff lines 1894–1953), avoiding the former duplicated HOME ROUTINE identity. Calendar-day last-trained labeling is shared with an injected clock (diff lines 59–76, 563–564), eliminating the visible before disagreement between Home's four days and the card's five days for the same fixture. Live edits/imports are covered by added test source, not supplied execution evidence.
- **Legibility and adaptive presentation, 8:** `before/library-ready-higgsfield-2.0x.png` splits Push A into two lines in the duplicated side-by-side header, while the after removes that constrained header and stacks the utility buttons. `after/library-view-next-higgsfield-2.0x.png` presents a full readable exercise preview and Start Legs A together. Diff lines 572–587 remove one-line identity/metadata truncation; 603–637 stack the next card and large-text footer. This preserves meaningful labels instead of shrinking them. The long-name card is readable but very tall; widths below 390 logical pixels are not evidenced.
- **Composition and visual identity, 8:** In `after/library-completed-higgsfield-1.0x.png`, the two utilities share aligned, quieter containment; program information is grouped once; only the actual next routine carries the strong full-width accent action. `after/library-view-next-neonPurple-1.6x.png` and `after/library-view-next-white-1.6x.png` preserve that hierarchy across markedly different accents, with the supporting Full Body action visually quieter. Diff lines 1675–1700 use surface/accent tokens, and 606–615 restrict the primary routine action to the next card. This is more intentional than the before duplicated primary plus weak text utilities. Formal contrast measurement and user preference are unverified.

### Material findings and micro elements

No unresolved material library defect is established by the supplied evidence. New routine and Explore remain available in error/active states; the error is explicitly announced and retryable (diff lines 1867–1885), and routine Start controls stay disabled during an active workout (606–629). The provided active bar grows with text and the shell reserves its measured height (1999–2014, 2053–2064). These observations support coherence, not device certification.

| Element | Score | Evidence and limitation |
|---|---:|---|
| Actual next-routine card | 8 | `after/library-view-next-higgsfield-2.0x.png` keeps UP NEXT, name, exercises, muscles, preview and primary Start legible in one card; `after/library-view-next-neonPurple-1.6x.png` shows the same hierarchy in another accent. Diff lines 576–614 apply the marker and full action to the real card. Device scrolling and touch use remain unverified. |
| Creation/exploration utilities | 8 | Matched 2.0x library renders show the change from weak separated text links to full-width, readable stacked controls; `after/library-empty-higgsfield-2.0x.png` gives New routine a clear primary role. Diff lines 1826–1856 reserve at least 52 logical pixels through TrainingUtilityButton and stack at large text. Successful creation/explore routing is not certified by screenshots. |
| Active resume bar | 7 | `after/library-active-higgsfield-2.0x.png` displays the full timer and name with separate navigation, but name truncation for longer active names, localized fonts and interaction are not covered. |

### Missing coverage and smallest follow-ups

The library intentionally no longer reports a saved-plan read failure: it observes `.valueOrNull` (diff lines 1786–1788), so corrupt preference and completion-read errors simply remove the Following/UP NEXT markers while routine loading succeeds. This does not block the library's management/start task, but an isolated render should establish whether a quiet status is needed to explain the missing marker. Only the general routine-read error is rendered.

View next is evidenced for a three-routine program, not a target far beyond the lazy-sliver cache, a target changing while navigation scans, or an active/long-name target whose button might require additional scrolling. The after closed-keyboard chooser/pagination and all recovery branches listed under Home are absent. All supplied viewports are 390×844 logical pixels; 1x/2x raster resolution is not additional responsive-width coverage.

## Overall decision and limits

**Revision needed** because the Home empty primary does not advance the task and the previously persistent repeat choice is unavailable for complete program members. The Routine library passes this limited critique. Correct those Home behaviors, reduce large-text long-name action displacement, and add the missing behavioral/capture evidence before a fresh review.

Haptics, timer feel, and one-handed use: **unverified, needs device**. Native keyboard and screen-reader use: **unverified, needs device**. Test results, CI, physical devices, real-user validation and release readiness were not supplied and are not certified by this verdict.
