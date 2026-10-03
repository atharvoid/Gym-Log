# Independent adversarial review — iteration 2

Candidate: **Home/Routines correction, iteration 2**. Diff baseline: `f12e89664be6aa83d1c86fbfb258c32ea0d7c37a`. Reviewed sections: **Home** and **Routine Library**.

**Verdict: Revision needed.** The supplied evidence establishes a material commitment/feedback ambiguity in the Home training-plan chooser. There is no established blocking task or data-loss defect in this packet. Routine Library itself passes this visual/diff review with a narrow-header polish issue.

## Scope and evidence limits

I read only this packet's RUBRIC.md, EVIDENCE.md, candidate.diff, render-inventory.json, and before/after PNGs. Diff references below are physical line numbers in **candidate.diff**, not repository source line numbers.

The renders are synthetic fixtures using real production Flutter components. I inspected matched ready views at 1.0x, 1.6x and 2.0x, plus representative active, completed, empty, error, recovery, long-name, narrow, closed-keyboard chooser, repeat-mode, searched, paginated and keyboard-inset views. Representative accent views included higgsfield, neonPurple, white, blazeOrange, neonCyan and neonMagenta. This is not a claim that every PNG or every cross-product of state/theme/scale was inspected.

**Haptics: unverified, needs device. Timer feel: unverified, needs device. One-handed use: unverified, needs device.** Native keyboard and screen-reader use also remain unverified. Tests, CI and physical-device acceptance are outside this packet. No test/CI/release certification is implied.

## Scores

Equal weights; arithmetic means are rounded to one decimal.

| Section | Task hierarchy and flow | Information truth and usefulness | Legibility and adaptive presentation | Composition and visual identity | State clarity and feedback | Mean | Section verdict |
|---|---:|---:|---:|---:|---:|---:|---|
| Home | 8 | 8 | 8 | 7 | 6 | **7.4** | **Revision needed** |
| Routine Library | 8 | 8 | 7 | 7 | 8 | **7.6** | **Pass within this packet** |

Home: (8 + 8 + 8 + 7 + 6) / 5 = 7.4. Routine Library: (8 + 8 + 7 + 7 + 8) / 5 = 7.6. The averages do not waive the chooser defect.

### Home: before/after assessment and evidence for scores above 7

- **Task hierarchy and flow — 8.** In `before/home-ready-higgsfield-1.0x.png`, the launch surface repeats Push A even though the history is Pull A; the chooser has to expose the optional Legs A suggestion. In `after/home-chosen-higgsfield-1.0x-synthetic.png`, the primary action is explicitly **Start Legs A**, with **After Pull A in your saved order** immediately above it. The supporting **Train something else** action is contained beneath the primary action. In `after/home-active-higgsfield-2.0x.png`, **Resume Pull A** precedes the clearly separate **For later / Legs A** content. This exceeds the coherent baseline by making the next ordered action and the live-session action distinct without requiring a visit to the chooser. Launch success and speed are unverified.
- **Information truth and usefulness — 8.** `after/home-chosen-neonPurple-1.0x-synthetic.png` names the saved-order reason rather than inventing a fitness recommendation. The new Last workout card visibly states **30 Sep 2026 · 12:48 · completed**, **48 min elapsed**, and **3,850 kg volume**. `after/home-last-older-higgsfield-2.0x.png` preserves **2025**, avoiding the ambiguous month/day-only history label shown lower on that same image. The diff at lines 173–235 renders an ended-at timestamp, distinguishes negative/short/minute elapsed time, and labels displayed volume units; lines 494–523 resolve program order from completion chronology and surface tied completions as a problem. This exceeds baseline usefulness by providing explained chronology and explicitly labelled measures. Mixed-measurement session output and real account data were not visually evidenced.
- **Legibility and adaptive presentation — 8.** The bottom of **Start Push A** is concealed by navigation in `before/home-ready-higgsfield-2.0x.png`. `after/home-ready-higgsfield-2.0x.png` shows the complete **Start Legs A** button above navigation. `after/home-narrow-ready-higgsfield-2.0x.png` keeps the routine name, ordering reason, planned counts and complete primary action legible at 320 logical pixels; the secondary action wraps instead of shrinking. In `after/home-long-name-higgsfield-2.0x.png`, the full long identity wraps and **Start workout** appears before the secondary metadata; diff lines 793–795, 810–819 and 1113–1139 provide the long-name treatment and preserve the full semantic start label. In `after/home-override-keyboard-higgsfield-2.0x.png`, the Full Body target and its complete session-only subtitle sit above the simulated keyboard, whereas `before/chooser-keyboard-higgsfield-2.0x.png` cuts through the target subtitle. Diff lines 1483–1490 and 1556–1559 constrain the scrollable result region to the keyboard inset. These are specific adaptive improvements. Native keyboard/focus behavior remains unverified.
- **Composition and visual identity — 7.** Primary and secondary actions, neutral card containment, accent status and quiet metadata are coherent across the inspected accent samples. The large-text Training plan action and duplicated card containment add considerable vertical weight, and some ready higgsfield captures leave blank space where other captures show Train. The cause of the title discrepancy is not established by the diff; no source regression is asserted from it.
- **State clarity and feedback — 6.** Active, completed, missing-plan and load-error states are visibly separated, and retry is explicit. However, the repeat control represents a pending local override as a normal active setting, with no commit/cancel explanation. Its off-state copy also overstates the behavior for standalone routines. Findings M1 and M2 below are the reason this is below 7.

### Routine Library: before/after assessment and evidence for scores above 7

- **Task hierarchy and flow — 8.** `before/library-ready-higgsfield-1.0x.png` spends a large card on the Home routine before the actual saved list. `after/library-chosen-higgsfield-1.0x-synthetic.png` removes that repeated launch card and shows two complete routine cards plus the beginning of the next card. New routine and Explore become visibly bounded actions. **View next** offers an explicit way to locate the below-fold ordered workout; `after/library-view-next-higgsfield-2.0x.png` shows the Legs A target with a complete **Start Legs A** action. Diff lines 1836–1873 scan lazily mounted cards only after the explicit navigation action, and lines 2019–2041 attach that action to the matching program group. This improves the library's browsing task while retaining a route to the next action. Animation feel and use with a large real library remain unverified.
- **Information truth and usefulness — 8.** `after/library-chosen-higgsfield-1.0x-synthetic.png` distinguishes **Source program · 3 saved routines**, **Following on Home**, and the specific **UP NEXT / Legs A** card. In `after/library-completed-higgsfield-1.0x.png`, UP NEXT moves to Push A, matching `after/home-completed-higgsfield-1.0x.png` and its **After Legs A in your saved order** explanation. The diff at lines 1883–1886 and 2097–2103 derives these indicators from the same resolution; lines 2026–2032 distinguish following a program from choosing a repeated routine. The baseline has inconsistent relative ages for Push A between its Home and Library captures (4 days versus 5 days); diff lines 63–75 changes day labels to local calendar-day boundaries, and the candidate card shows 4 days. These are stronger than generic “recommended” or unexplained selected badges. No real-user interpretation of the labels was validated.
- **Legibility and adaptive presentation — 7.** In `after/library-chosen-higgsfield-1.6x-synthetic.png`, the exercise preview wraps fully above a full-width Start control; the baseline truncates that preview beside the control. Diff lines 615–649 implements the stacking, and lines 584–599 removes routine-name and metadata ellipses. However, `after/library-narrow-ready-higgsfield-2.0x.png` breaks the screen title into **Routine** and a lone **s**, consuming enough vertical space that the first card barely begins above navigation. Long-name and 2.0x library states still require substantial scrolling. There is no evidenced collision or unreachable action, so this is a contained presentation concern rather than a blocking failure.
- **Composition and visual identity — 7.** Card structure and accent roles remain coherent, and the next routine has stronger weight than other routine starts. The expanded creation actions, long group headings and 2.0x screen title are heavy relative to the saved-list task. The candidate improves density over the duplicate Home card, but narrow presentation does not merit 8.
- **State clarity and feedback — 8.** `after/library-error-higgsfield-2.0x.png` names the routine-loading failure and gives **Try again**. `after/library-plan-error-higgsfield-2.0x.png` instead says **Training plan needs attention** and **Your saved routines are available. Check the plan on Home**, with **View Home**; the diff at lines 1957–1981 gates that message on a nonempty available library and plan failure, and lines 1992–2010 separately owns routine-read retry. `after/library-view-next-neonPurple-1.0x.png` differentiates the next routine's full accent start from the other routine starts. Active captures retain the floating resume bar, while diff lines 618–632 and 2094–2096 disables competing starts when a workout exists. This exceeds baseline state clarity by distinguishing plan recovery from library recovery while retaining the library's available actions. Disabled-start announcements and native resume feel remain unverified.

## Material findings established by the packet

### M1 — P2: Repeat mode looks committed when it is only pending

Evidence: `after/home-plan-repeat-higgsfield-1.0x.png` and `after/home-plan-repeat-higgsfield-2.0x.png` show an accent **on** switch and the declarative text **Keep this routine on Home after completion.** Every routine radio is empty. There is no “pending,” “choose below to save,” Save action, or closing-cancels explanation.

The behavior is established by the diff: line 1584 only calls `setState(() => _repeatOverride = value)`. Persistent save is deferred to the routine-row `_choose` path at lines 1314–1339, and Close simply pops the sheet at lines 1524–1527. A user can turn the switch on, close, and believe the Home routine will repeat even though the persisted program still advances. The baseline chooser had radio-row selection and no independent mode control implying an immediately saved setting.

**Smallest correction:** Keep the existing save-on-row interaction, but explicitly frame the switch as how the routine below will be saved, and show “Tap a routine to save this plan. Closing cancels changes.” when its value is pending. The selected/current plan should remain distinguishable from the staged mode. An explicit Apply path or saving the current routine on toggle is another valid design, but changes more behavior.

### M2 — P2: The off-state explanation is false for standalone routines

Evidence: `after/chooser-search-higgsfield-1.6x-synthetic.png` displays only Outdoor walk, with **Repeat this routine · 1 exercises**, while the switch still says **Off: follow the saved program order.** `after/chooser-page-2-higgsfield-1.0x-synthetic.png` shows the same contradiction. Diff lines 1564–1566 tests for any program in the entire library, rather than the visible choices; lines 335–343 and 1624–1628 ensure a standalone routine repeats even with the switch off.

The row subtitle partly explains the outcome, but two adjacent statements give incompatible accounts of the mode. This matters when choosing a standalone routine after disabling repeat: the switch's proposition cannot describe the saved result.

**Smallest correction:** Scope the switch and helper to program routines (“Repeat one day of a program”), or hide it when the displayed choices contain no followable program routines. Explain that standalone routines repeat. Correct the single-exercise grammar at diff line 1628 as minor polish.

## Established regressions and smaller concerns

- **Selected-workout context removed from Home:** `before/home-ready-higgsfield-1.0x.png` displays muscle focus, last-trained age and **Logged set · Bench Press / 60 kg × 8**. Those elements are deleted at diff lines 1181–1253. The new Last workout card is useful but describes Pull A, not the upcoming Legs A, so it is not equivalent prelaunch context. This is an established loss of glanceable information, not evidence that workout performance or logging success worsens. It is not independently blocking in the supplied task-focused evidence.
- **Narrow Library title:** `after/library-narrow-ready-higgsfield-2.0x.png` has the orphan “s.” Reflow the short screen title with an appropriate smaller existing heading token under narrow/large-text conditions; preserve the requested text size instead of scaling all page text down. This is lower priority than M1/M2.
- **Ready title capture discrepancy:** The reviewed higgsfield ready captures leave the top heading area blank, while e.g. `after/home-chosen-neonPurple-1.0x-synthetic.png`, active and completed captures show Train. The diff does not establish why. Resolve the capture/source discrepancy before using these images for final visual acceptance; it is not asserted as a proven production bug.
- **Search wording grammar:** The Outdoor walk choice says “1 exercises”; Routine Library correctly says “1 exercise.” This is visible and minor.

## Micro-element scores

| Affected element | Score | Evidence/consequence |
|---|---:|---|
| Training-plan mode commitment | **4** | M1: on switch without a saved/pending distinction; write waits for a row tap. |
| Mode explanation for standalone search results | **5** | M2: “Off: follow …” beside “Repeat this routine.” |
| Narrow Library screen heading | **5** | `after/library-narrow-ready-higgsfield-2.0x.png`: orphan “s” and excess vertical cost. |

No micro score above 7 is assigned.

## Missing state coverage and unverified hypotheses

- A **zero-exercise resolved next workout** is not convincingly established by the reviewed empty-choice files: `after/home-empty-choice-higgsfield-1.6x-synthetic.png` still shows Legs A, **5 exercises · 15 planned sets**, and Start Legs A. The Add exercises branch exists at diff lines 806–819, but needs a truthful visual capture.
- No inspected PNG establishes the chooser's **saving**, **save failure**, successful persisted repeat mode after closing/reopening, or changed-mode cancellation state. Do not infer these from ready renders or test additions in the diff.
- The saving indicator and error message are appended after all visible choices and pagination (diff lines 1682–1688). In the 1.6x closed chooser, even the third row continues beyond the viewport. **Hypothesis:** feedback after tapping an early row could appear below the scroll position. This needs a saving/failure capture; it is not asserted as an established invisible-error defect.
- The keyboard fixtures deliberately scroll targets above real layout insets. They establish that those targets can fit in the available region, not automatic focus-to-result behavior, native keyboard transitions, or thumb reach.
- The Last workout timestamp, positive-volume fixture and older year were evidenced. Zero-volume/bodyweight, negative elapsed, very short elapsed, mixed measurements, lb output, and an exceptionally long last-workout name were not visually verified.
- Program incompleteness, completion ties and corrupt persisted-plan recovery have diff paths, but no relevant rendered outcome was inspected. Their correctness is not certified.
- Long active-workout names, arbitrary system fonts/nonlinear text scaling, screen-reader traversal and large real libraries remain unknown.
- **Haptics, timer feel and one-handed use: unverified, needs device.** Tests, CI and physical devices remain outside scope.

## Required correction and final verdict

Revise the chooser to communicate pending mode versus the saved plan and accurately scope its follow-order explanation to program routines. Add truthful renders for changed-mode cancellation, committed repeat mode, saving/error feedback, and a zero-exercise next routine. The narrow Library title and singular exercise label are small corrective polish.

**Overall: Revision needed. Home 7.4/10; Routine Library 7.6/10.** Routine Library passes this bounded visual/diff review; the overall candidate does not pass until the established chooser commitment and information-truth defects are resolved. This verdict does not certify tests, CI, devices or release readiness.

