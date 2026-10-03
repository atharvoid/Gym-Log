# Independent candidate review

Candidate: **session-2 / critic iteration-1 / self-review render iteration-2**. Sections: **4 Home** and **6 Routine Library**.

Review used only the supplied rubric, diff, and before/after images. Diff references below identify physical lines in [candidate.diff][diff]. Renders are synthetic live-widget captures at 390×844. No native, device, test execution, CI, or real-user qualification is established.

## 4 — Home

**Verdict: Revision needed.**

| Dimension | Before | After |
|---|---:|---:|
| Task hierarchy and flow | 6 | 7 |
| Information truth and usefulness | 5 | 7 |
| Legibility and adaptive presentation | 5 | 7 |
| Composition and visual identity | 6 | 8 |
| State clarity and feedback | 6 | 6 |
| **Arithmetic mean** | **5.6** | **7.0** |

Before, the greeting and weekly card preceded a generic empty-workout entry. Saved routines did not inform the launch action. After, “YOUR CHOICE,” the named routine, plan size, training age, and named Start action form a useful preparation sequence. The previous logged set supplies concrete context without prescribing a weight. Compare [before returning Home][hb] with [after chosen Home][ha].

Large-text presentation improves: “Start Empty Work…” was truncated before; “Start Push A” is complete after. Supporting metadata also wraps cleanly. The cost is substantially reduced history visibility: before, the first workout showed exercise rows at 1.6×; after, weekly progress and history are below the initial viewport. The visible History shortcut helps, but its scroll result is not rendered.

### Justification for the score above 7

**Composition — 8:** In [after chosen Home][ha], the routine name and full-width accent Start button create a clear focal sequence; the previous-set inset separates recorded information from the action; utilities remain visibly secondary. The same hierarchy remains recognizable in the supplied chosen-state renders across all six palettes. [Large-text chosen Home][hal] preserves the named action and readable metadata rather than shrinking them. This exceeds the before screen’s generic stacked cards. Task completion speed, device contrast, and user preference remain unverified.

### Consequential findings

1. **Action labels can disagree with the actual event when a workout is active.** Diff lines 625–638 return `resume` for both routine and freestyle starts whenever an active workout exists; lines 681–682 navigate to that workout. Only the resolved, nonempty chosen-routine branch changes its label to “Resume workout” at lines 847–893. Home’s “Log a different workout” remains unchanged at lines 169–175. Therefore that label can resume the existing session rather than begin a different one. The routing behavior is established by the diff; the active-state visual presentation is missing.

2. **The first-session primary action has an unexplained comparative label.** [New-user Home][hne] presents “Your first session starts here” followed by “Log a different workout,” although there is no selected or previous workout to differ from. The before action, “Start Empty Workout,” was more explicit about the event. Diff lines 777–799 establish that the new wording starts freestyle training. This is a small but consequential clarity regression at first use.

3. **History access becomes more dependent on an unverified shortcut.** Compare [before large-text returning Home][hbl] with [after large-text chosen Home][hal]. The candidate retains history content but removes it from the initial viewport. Diff lines 176–188 implement `ensureVisible` for the History header; no after image demonstrates the destination, retained context, or unobstructed history footer. This is reduced visibility, not evidence of clipping or lost history.

4. **The weekly ratio still lacks its unit.** “This week — 2/3” in [after chosen Home][ha] does not tell a new user whether it counts workouts, training days, or another goal. Diff lines 231–242 describe logged training days in tour copy, but that explanation is not visible on the normal surface. This ambiguity existed before and remains unresolved.

### Micro scores

| Element | Score | Evidence and consequence |
|---|---:|---|
| Named chosen-routine Start | 8 | [Chosen Home][ha] and [large-text variant][hal] identify the exact routine and retain the full action; diff lines 891–893 connect it to the selected ID. Native execution and long names are unverified. |
| Previous-set context | 7 | [Chosen Home][ha] shows a named exercise and `60 kg × 8`; diff lines 579–603 provide typed formatting and spoken units. It does not visibly identify the specific session/set number. |
| First-session action wording | 5 | [New-user Home][hne]: “different” has no referent. |
| Weekly-progress explanation | 6 | [Chosen Home][ha]: readable ratio, unspecified counted unit. |
| Large-text history reachability | 6 | [Large-text chosen Home][hal]: shortcut visible, destination and below-fold result absent. |

### Regressions, corrections, and unknowns

The candidate trades immediate history visibility for routine preparation and removes the empty-history inline start action. That removal is reasonable only if the upper start entry remains consistently clear and reachable.

Smallest corrections:

- Use an explicit first-session label such as **Start workout**.
- Make every action that resumes an active session communicate that event before the tap.
- Explain the weekly ratio with a counted unit.
- Provide an after render following the History shortcut at 1.6×.

Missing coverage: active sessions across chosen/no-choice/error/empty states; unusually long routine and exercise names; loading/error transitions; completed launch/navigation; previous-set loading; and after history pagination/footer states.

## 6 — Routine Library

**Verdict: Revision needed.**

| Dimension | Before | After |
|---|---:|---:|
| Task hierarchy and flow | 7 | 6 |
| Information truth and usefulness | 6 | 7 |
| Legibility and adaptive presentation | 5 | 7 |
| Composition and visual identity | 6 | 7 |
| State clarity and feedback | 6 | 6 |
| **Arithmetic mean** | **6.0** | **6.6** |

Before, creation/exploration led directly into saved routines. After, the selected routine receives a large launch card and other routines receive source-program grouping. Counts are more specific, authoring labels no longer truncate at large text, and selection has a visible Change action. Compare [before returning Library][lb] with [after chosen Library][la].

However, the Library now duplicates the selected routine: a large launch card followed by its ordinary saved-routine card. At 1.0× the before screen exposes three routine cards; the after screen exposes one. At 1.6×, [after chosen Library][lal] shows no usable saved-routine card above the navigation, whereas [before large-text Library][lbl] exposes two complete cards. This is a material browsing/editing cost in the Library.

### Consequential findings

1. **“Compact” does not produce a sufficiently compact Library surface.** Diff line 1306 requests `TrainingLaunchpad(compact: true)`, but lines 855–894 retain the large routine title, source name, plan counts, tags, training age, and full-width Start. Compact mode chiefly removes the previous-set inset. The resulting [large-text chosen Library][lal] displaces the library’s actual list almost entirely below the viewport. Grouping provides useful structure but cannot compensate for the lost initial scan.

2. **Unavailable-choice copy offers an action the Library does not expose.** [Deleted-choice Library][ld] says “Choose another saved routine, or log a different workout,” but provides only **Choose routine**. Diff lines 827–845 confirm that branch contains no freestyle action; the Library has no Home-style fallback utility. A user following the second option must leave this screen and discover another entry point.

3. **Start can silently resume another workout.** The shared launcher returns `resume` for any active session, while ordinary routine cards keep their Start callback at diff lines 1414–1427. The chosen hero can say Resume, but other routine cards do not identify this changed outcome. The protection against overwriting a session is useful; the action’s meaning still needs to be truthful.

4. **Error announcement semantics were removed.** Diff lines 1316–1332 remove the previous error surface’s `Semantics(liveRegion: true)` and delegate the failure to the launchpad. The replacement `message` builder at lines 748–755 has no equivalent live region. The error is visually clear in the supplied render, but an arriving error may be less discoverable for assistive-technology users. Actual TalkBack behavior is unverified.

### Micro scores

| Element | Score | Evidence and consequence |
|---|---:|---|
| Library launch-card footprint | 5 | [Large-text chosen Library][lal] contains no usable routine-list card above navigation; selected content is duplicated below. |
| Source-program grouping | 7 | [Chosen Library][la] labels “Source program” and saved count; diff lines 1348–1400 retain routine lists under groups and standalone headings. |
| Creation utilities | 6 | “New routine” remains complete at 1.6×, but has lower visual emphasis and competes with the larger launch card. |
| Deleted-choice fallback | 5 | [Deleted-choice Library][ld] promises logging without its action. |
| Chooser suggestion provenance | 8 | [Chooser][chooser] separates the selected radio from “Next in your program” and explains “Follows Pull A in saved order.” Diff lines 506–548 require explicit membership, complete unique day positions, and a nonempty next routine; lines 1060 and 1087–1102 keep selection optional and explicit. This exceeds an unexplained recommendation. Production metadata, complete history availability, and user interpretation remain unverified. |

No dimension score exceeds 7; the chooser micro score is justified above.

### Regressions, corrections, and unknowns

Authoring remains available, but browsing density and direct access to other routines regress. The selected routine’s duplication adds vertical cost without adding another capability. Error live-region semantics also regress.

Smallest corrections:

- Give compact mode a shorter title/metadata treatment or a collapsible chosen-routine summary; retain Start and Change.
- Add the promised freestyle action to the unavailable-choice branch, or remove that promise.
- Make routine-card Start behavior explicit when a workout is already active.
- Restore live-region error feedback.

Missing coverage: after below-fold groups, standalone routines, card menus/editing, chooser search/no-results/pagination, saving/save failure, keyboard-visible chooser, and active-session behavior.

## Shared evidence limits

The diff adds tests and golden capture definitions; it does not prove those tests passed or that behavior was tested failing first.

The default routine loader rejects a null auth user at diff lines 606–615. Action tests replace that loader at lines 1735–1740, and render fixtures supply routines while overriding auth to null at lines 1626–1658. Whether real unauthenticated/local routines can be displayed and launched cannot be resolved from this evidence and needs explicit verification.

Native system bars, keyboard, focus order, TalkBack, haptics, physical devices, CI, and release readiness remain unknown.

[diff]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/candidate.diff>
[hb]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/before/home-returning-higgsfield-1.0x-synthetic.png>
[hbl]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/before/home-returning-higgsfield-1.6x-synthetic.png>
[ha]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/home-chosen-higgsfield-1.0x-synthetic.png>
[hal]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/home-chosen-higgsfield-1.6x-synthetic.png>
[hne]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/home-new-user-higgsfield-1.0x-synthetic.png>
[lb]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/before/library-returning-higgsfield-1.0x-synthetic.png>
[lbl]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/before/library-returning-higgsfield-1.6x-synthetic.png>
[la]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/library-chosen-higgsfield-1.0x-synthetic.png>
[lal]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/library-chosen-higgsfield-1.6x-synthetic.png>
[ld]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/library-deleted-choice-higgsfield-1.0x-synthetic.png>
[chooser]: <C:/Users/Atharva Patil/Documents/projects/gymlog/docs/upgrade/reviews/session-2/iteration-1/after/chooser-higgsfield-1.0x-synthetic.png>
