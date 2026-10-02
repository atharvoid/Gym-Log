# DELT experience and visual-design audit

**Date:** 2 October 2026 · **Repository:** GymLog / DELT · **Baseline:** HEAD `ce3d598` plus the existing uncommitted working tree.

**Overall experience: 6/10. Visual consistency: 7/10. Distinctiveness: 4.5/10. Emotional payoff: 4.5/10.** These are editorial assessments of the inspected experience, not user-research measurements or an arithmetic average of the tables.

DELT has a coherent foundation and considerable feature coverage. Its weakest point is the relationship between information, attention, and the user's next action. It presents training records competently, but often makes users interpret what matters and choose what comes next. Repeated containers, cautious emphasis, and generic headings make different moments feel similar. Its strongest expressive work is partly disconnected from the everyday workout journey.

## Evidence and limits

- Read the design north-star, DESIGN.md, conventions, routing, themes, shared components, screen implementations, and relevant providers.
- Rendered current widgets at **390 × 844 logical pixels**, with Inter and Material icons loaded, using an isolated in-memory database and synthetic training history. Also rendered the active workout at **1.6× text scale**. Eighteen renders are stored in [renders](../audit/delt-visual-2026-10-02/renders/).
- [Six-screen comparison](../audit/delt-visual-2026-10-02/contact-sheet.png) shows the current Home, routine library, routine detail, active workout, profile, and share-card prototype side by side. The temporary rendering harness wrote all eighteen images but timed out during teardown; it is not a passing test result and was removed. This audit does not report the app's verification suite as passing.
- The fixture has five exercises, three sample routine names, twelve historical sessions, and a partially completed workout. All three routine names intentionally reuse the same exercise data. Equipment assignments, dates, PR flags, and totals are synthetic; their fitness correctness is not being evaluated. Network exercise media is absent, so the images test fallback presentation rather than production GIF quality.
- The fixture uses a small test router and simulated bottom navigation. It does not exercise production authentication, deep links, real system insets, native purchases, notifications, or the complete app shell. Missing Back buttons on fixture root screens are not counted as app defects. Profile name/version defaults are fixture effects.
- Inspected September device captures as reference, and existing goldens. July store screenshots are explicitly stale in the project documentation. Saved goldens with a router-error panel or masked text are unsuitable for visual acceptance; they are not evidence of a production runtime failure.
- No Android device was connected. Touch speed, real haptic quality, sunlight readability, frame timing, battery use, keyboard behavior, and native sharing remain unqualified. No retention or conversion data was consulted.
- This was an audit, not a redesign or functional certification. Existing application edits were preserved. No production application code was changed.

**Evidence key:** R = current fixture render plus source; S = source inspection; D = saved device reference plus source. Source-only scores are provisional. An unmeasured performance property receives no numeric rating.

**Score meaning:** 3 = major experience gap; 5 = serviceable but ordinary; 7 = coherent and useful; 9 = distinctive, polished, and contextually strong; 10 = exceptional with convincing real-user validation. Scores judge fitness for the screen's purpose, not how decorated it looks. A quiet settings page can deserve a higher score than a flashy workout page.

## Why it feels plain

### 1. Screen hierarchy follows features more than training intent

Home is greeting → weekly progress → Quick Start → history. Even with saved routines, its main start action is **Start Empty Workout**. A returning lifter has to find their routine elsewhere. The greeting uses the 32px screen-title style while the actual training choice is inside a generic card.

The routine library puts a filled accent **New Routine** button above subdued **Start** controls. Creation is visually promoted over the repeat behavior that most returning users came to perform. This is visible in [home](../audit/delt-visual-2026-10-02/renders/home.png) and [routines](../audit/delt-visual-2026-10-02/renders/routines.png), and explicit in `StartButton`, which reserves full accent fills for live states rather than entry controls.

**Change:** make Home answer “What am I training today?” with a user-chosen or transparently suggested routine, a short reason, the relevant last-session result, and Start. Keep freestyle logging and history accessible below. Do not present an inferred rotation as a known schedule.

### 2. The app has a component system but a weak composition system

Cards are consistent; their importance is not differentiated enough. Quick Start, historical records, routine previews, chart containers, and utility sections repeatedly use similar rounded rectangles, near-black surfaces, bold white labels, and grey metadata. Consistency has become visual repetition.

**Change:** establish three page roles: a focal training/result section, supporting information, and compact reference rows. Use scale, alignment, spacing, and containment to distinguish them. Reserve cards for meaningful groups rather than boxing every section. Retain the OLED canvas and accent tokens.

### 3. The active workout spotlights session administration

The large elapsed timer and saturated Finish action dominate the header. The next unfinished set has no equally clear focal treatment in the inspected state. Filled green completed checks and outlined green ready checks distinguish states, but both already carry success imagery. Large tinted **Add Set** controls repeat below every exercise.

At 390px, one exercise block occupies much of a screen. At 1.6×, the header expands and “PREVIOUS” and previous-set values truncate. The layout avoids a catastrophic overflow but loses scan clarity. See [active workout](../audit/delt-visual-2026-10-02/renders/active-workout.png) and [large text](../audit/delt-visual-2026-10-02/renders/active-workout-large-text.png).

**Change:** make the current exercise and next set obvious; keep completed sets available in compact rows; reduce repeated Add Set prominence; show honest planned-set progress when a plan exists. Keep Finish reachable and recognizable. Use a different layout for large text rather than merely enlarging the same five-column table. Any collapse must preserve editing and reordering affordances.

### 4. Progress is counted more often than interpreted

The app already has previous-session comparisons, PR markers, chart deltas, and weekly goal progress. These are useful and should be retained. The opportunity is to connect them into a clear personal narrative: what improved, under what comparable conditions, and what the user can do next.

Routine details show session count, best/average volume, muscle shares, and a large chart before the exercise plan. The sample screen puts the first exercise well down the page. “BEST KG” and “AVG KG” are concise but do not explain that they mean aggregate session volume. Profile mixes identity, streaks, analytics, and an exercise-library entry under “Profile.”

**Change:** put the plan before its historical analysis on the training launchpad. Give analysis a compact summary or separate expandable section. Let a progress surface open with a specific result, such as a comparable rep improvement, then supply the evidence. Separate logged facts, calculated estimates, and suggested actions.

### 5. The emotional arc is concentrated in rare PRs

The PR overlay already has motion, confetti, specific records, and escalated haptics. It is not missing. Ordinary workout completion instead returns to Home after a naming/save sheet. Users who repeat a planned session, maintain effort, or return after a break receive less meaningful recognition.

**Change:** after a confirmed save, show a short result recap: what was completed, one defensible comparison if available, weekly-goal progress, and Done or optional Share. Keep exceptional celebrations rare. For a first workout, recognize the baseline rather than inventing improvement.

### 6. Motivation does not fully match a strength-training schedule

The profile defines a streak as consecutive training days and says “Train today to keep your … day streak alive” or “Train today to start a streak.” This is not a personalized training instruction, but the phrasing can sound like one. It can conflict with planned rest days and make a successful three-day training week feel interrupted.

**Change:** emphasize meeting the user's weekly plan and consistent weeks. Recognize planned rest without claiming physiological readiness. Log-derived muscle shares cannot establish recovery status.

### 7. Expressive components are not necessarily delivered features

Share-card widgets, a preview gallery, a data model, and a sharing service exist. The inspected production routes and workout/PR call sites do not expose a normal entry into them. `ShareCardService.showShareSheet` has no caller outside its own implementation, and the gallery uses mock cases. Their craft therefore contributes little to the current daily experience.

The newly installed Rive, animation, audio, and experience-telemetry packages are documented as dependencies without SDK initialization or added behavior. Package installation has not changed what the user sees.

**Change:** connect one verified result-to-share flow before creating more visual variants. Reuse Flutter's existing motion and haptic primitives for the core interaction improvements. Add custom assets only where a designed moment needs them.

## Macro scorecard

| Area | /10 | Evidence | Main gap or strength |
|---|---:|:---:|---|
| 1. Visual identity and system | 6.5 | R/S | Coherent black/accent foundation; weak signature composition and faint metadata. |
| 2. Sign-in / first impression | 6.5 | R | Clean branded entry; generic history-focused promise and decoration with little product demonstration. |
| 3. Onboarding / time to value | 5 | R/S | Seven steps plus optional tour before experiencing the core benefit. |
| 4. Home / daily training intent | 5.5 | R | Organized feed; weak returning-user launchpad. |
| 5. Workout history | 7 | R | Useful previews and PR markers; repetitious receipts without much narrative. |
| 6. Routine library | 6 | R | Clear cards; creation dominates repeat training and routine identity is thin. |
| 7. Routine detail | 6.5 | R | Strong persistent Start and useful data; analysis pushes the plan down. |
| 8. Routine authoring | 6.5 | R/S | Actionable empty state and import option; limited preview of the plan being assembled. |
| 9. Explore / program discovery | 6.5 | R/S | Catalog, search, and filters are useful; dense shelf and little editorial guidance. |
| 10. Exercise library / selection | 7 | R/S | Recent items and filters support fast retrieval; little contextual selection guidance. |
| 11. Exercise detail / learning | 6.5 | R/S | Media, history, and records exist; form guidance follows analytics and fallback media consumes a large area. |
| 12. Active workout / logging | 6 | R/D/S | Solid table foundation; current task and density need reconstruction. |
| 13. Rest and hold timers | 7 | D/S | Purposeful controls and feedback; context duplication and device qualification remain. |
| 14. Ordinary finish / recap | 5.5 | S | Save sheet is useful; weak payoff after the actual save. |
| 15. PR recognition | 7 | S | Strong existing celebration; units and record interpretation need attention. |
| 16. Profile / progress | 6 | R/S | Goal and comparison signals exist; mixed purpose, chart crowding, ambiguous progress meaning. |
| 17. Settings and appearance | 7 | R/S | Utility restraint is appropriate; theme consequences and information hierarchy can improve. |
| 18. Help, CSV import, AI import | 6.5 | R/S | Practical actions and review promise; uneven composition and reassurance clarity. |
| 19. Paywall / premium value | 6 | S | Context-specific copy and store-backed pricing paths; little visual demonstration of the upgrade. |
| 20. Sharing in the user journey | 2.5 | R/S | Poster craft roughly 7/10, but normal result-to-share integration is absent in inspected callers. |

## Micro scorecard: 100 checks

Each group contains five scored checks. “Upgrade” is a direction to validate, not a claim that its effect on retention is known.

### 1. Visual identity and system — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Palette coherence | 8 | One reactive accent and fixed semantic roles are a strong foundation. Retain them. |
| Screen-to-screen composition | 5 | Similar cards flatten different intentions. Define focal, supporting, and reference roles. |
| Typography hierarchy | 6.5 | Useful named styles; generic titles often outshine personally relevant information. Give outcomes more emphasis. |
| Essential metadata legibility | 4.5 | 35% white is about 3:1 on black. Raise contrast where text carries meaning. |
| Distinctive DELT visual grammar | 4.5 | Logo and Volt are recognizable; most interior layouts remain generic. Use a consistent progression/record motif tied to real data. |

### 2. Sign-in — R

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Brand mark and name | 7.5 | Clear and restrained. Keep the mark rather than inventing another identity. |
| Product promise | 5 | “Track every workout. Keep your history.” describes storage. Test a specific benefit around training progress. |
| Proof of benefit | 3 | No worked example of a saved set or personal progression. Consider one clearly labeled demonstration. |
| Primary-action clarity | 8 | Google sign-in is obvious and readable. Preserve its simplicity. |
| Atmospheric decoration | 5.5 | Large ambient glow adds color but not useful meaning. Reallocate some emphasis to product proof. |

### 3. Onboarding — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Step count and pacing | 4 | Seven screens require repeated continuation. Request essentials first and defer optional profile fields. |
| Progress feedback | 7.5 | Step fraction and progress bar set expectations. Reuse in a shorter flow. |
| Benefit while answering | 4.5 | Questions precede the payoff. Show how a choice changes the user's first training setup. |
| Profile-question sequencing | 4.5 | Name, age, gender, units, experience, and goal precede completion. Audit which are actually needed before logging. |
| First useful training action | 4.5 | Completion/tour adds another decision. End at a chosen routine or an actionable first-set state. |

### 4. Home — R

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Greeting prominence | 5 | Large greeting consumes priority without deciding the workout. Make it supporting text. |
| Next-session relevance | 3.5 | No saved routine launchpad on the main feed. Add a user-selected routine or explain a suggestion. |
| Weekly progress | 7.5 | 2/3 progress is concrete. Explain what counts toward the goal and add a useful completion state. |
| Start-action wording | 5 | “Start Empty Workout” is accurate but emphasizes absence. “Log a workout” can remain the secondary freestyle path. |
| Return after inactivity | 4 | The weekly card can disappear when streak and current-week activity are zero. Keep useful continuity and a low-pressure return action. |

### 5. History — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Session title and date | 7.5 | Clear identification. Preserve readable names and dates. |
| Exercise preview | 7 | Two exercise rows are helpful. Consider compact repeated rows after the latest session. |
| Aggregate stat row | 7 | Volume and time are glanceable; explain volume where it matters and retain unit conversion. |
| Achievement marker | 7 | PR badge differentiates a session. A specific best improvement would communicate more than a count. |
| Browsing rhythm | 5.5 | Repeated tall receipts slow scanning. Combine a richer latest result with denser older entries. |

### 6. Routine library — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Routine identity | 5.5 | Name, tags, and an ellipsized exercise preview do little to differentiate plans. Surface schedule/focus where known. |
| Start versus create emphasis | 4 | Filled New Routine dominates neutral Starts. Promote the primary returning-user action. |
| Metadata usefulness | 6.5 | Exercise count and last trained help. Add planned sets or day position only when available. |
| Program grouping | 4.5 | Source-program metadata exists, but the inspected list is flat. Group imported days under their source program without hiding independent routines. |
| Empty-state action | 7.5 | Creation path is explicit. Offer a clear browse/import alternative when appropriate. |

### 7. Routine detail — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Persistent Start | 8 | Strong, reachable training action. Preserve it while restructuring the body. |
| Plan-first ordering | 4 | Chart and statistics precede exercises. Lead with the workout plan. |
| Historical-stat labeling | 5.5 | BEST KG / AVG KG conceal the metric. Say Best session volume / Average session volume. |
| Muscle-share explanation | 5 | Shares use set-count heuristics, including half-weighted secondary groups. Label them as estimated set distribution. |
| Historical analysis | 7 | Range, chart, data table, and delta are useful. Move behind a compact summary so they support the training decision. |

### 8. Routine editor — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Empty-canvas guidance | 7 | Build your routine + Add Exercise gives a clear next action. |
| Name input | 6 | Obvious field, but largely placeholder-driven in the empty view. Keep a persistent name label once filled. |
| Exercise-order editing | 7 | Reorder and accessible alternatives exist in source. Qualify a realistic populated plan on device. |
| Whole-plan feedback | 4.5 | Limited compact overview of what has been assembled. Show exercise/set totals and day structure when accurate. |
| AI import discoverability | 7 | Both header glyph and text entry expose it. Consolidate if duplication distracts from authoring. |

### 9. Explore — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Search and filter breadth | 8 | Search plus level/equipment/duration covers meaningful constraints. Preserve this. |
| Header and filter density | 5.5 | Much of the top area goes to title, copy, search, tabs, and filters. Tighten the introduction. |
| Routine/program distinction | 6.5 | Separate shelves exist. Explain a program as a sequence of days where newcomers choose. |
| Guidance toward a fit | 4.5 | Catalog browsing requires substantial interpretation. Offer explainable shortlists using stated equipment/experience preferences. |
| Card selection confidence | 6 | Names, duration, level, and equipment help; a one-line “choose this if…” would clarify tradeoffs. |

### 10. Exercise library — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Search access | 8 | Prominent and straightforward. Test real catalog retrieval rather than decoration. |
| Recent exercises | 8 | Reuse fits the frequent workout task. Preserve it. |
| Filter presentation | 7 | Muscle/equipment choices are understandable. Keep selected constraints visible. |
| Rows and fallback thumbnails | 6 | Clear names; white repeated fallback tiles can dominate the dark canvas. Use a quieter informative fallback. |
| Selection context | 5.5 | Browsing/selection modes exist, but which routine/set needs an exercise could be clearer in the selection journey. |

### 11. Exercise detail — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Media usefulness | 6.5 | Full exercise demonstration is valuable when available. Offer deliberate play/static behavior and a compact unavailable state. |
| Title efficiency | 5 | Exercise name repeats in AppBar and body. Use the second location for meaningful context. |
| Muscle/equipment information | 7 | Helpful tags and metadata. Normalize human-readable casing. |
| Form versus history ordering | 5 | Instructions follow analytics. Support Learn and History intents without forcing one long sequence. |
| Estimated strength labeling | 5.5 | “One Rep Max” labels an estimate from recorded sets. Make “Estimated 1RM” visible, with the logged set as evidence. |

### 12. Active workout — R/D/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Current-set focus | 4.5 | Next unfinished row has limited priority. Mark it through a restrained focus treatment and explicit context. |
| Session-header allocation | 5 | Timer and Finish dominate; the routine name is absent in normal layout. Rebalance toward current exercise and progress. |
| Table alignment and previous values | 7 | Shared table layout and historical hints are useful. Preserve them and increase clarity of editable fields. |
| Completed versus ready controls | 5.5 | Both use green checks. Use neutral ready-state controls and reserve strongest success treatment for committed data. |
| Density at large text | 4.5 | 1.6× render truncates previous values and header labels. Switch to stacked current/previous rows when the table cannot remain readable. |

### 13. Timers — D/S; device feel unverified

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Countdown legibility | 8 | Large figures and progress ring are useful glanceable cues. |
| Exercise/set context | 6.5 | Some context is present. Make the exercise and coming set intelligible without expanding everything. |
| Hold-timer controls | 7 | Pause/Done/cancel are explicit. Test operation with sweaty hands and one-handed use. |
| Screen-space cost | 5.5 | Bar plus inline live timer can duplicate priority. Preserve controls while reducing repeated presentation. |
| End-of-rest feedback design | 7 | Distinct haptic sequence exists. Actual intensity and noticeability require physical-device acceptance. |

### 14. Finish and recap — S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Save/name sheet | 7 | More informative than a bare naming dialog; already includes session facts. |
| Save-state truth | 5.5 | Sheet says “Workout complete” before durable save; success haptic correctly waits. Align wording with Ready to save / Saved states. |
| Measurement relevance | 4 | Header and sheet always feature weighted volume, including non-weighted sessions. Choose a suitable metric for the completed exercises. |
| Recognition without a PR | 3.5 | Successful finish routes Home without an equivalent result recap. Add a useful confirmed-save moment. |
| Continued training context | 4.5 | Saved result does not clearly link to plan consistency or the next user-chosen session. Surface this without a medical readiness claim. |

### 15. PR recognition — S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Celebration existence and craft | 8 | Existing overlay has records, motion, confetti, and haptics. Refine rather than replacing it. |
| Improvement specificity | 7 | Current and prior estimates appear. Add an explicit metric label and delta so the accomplishment reads immediately. |
| Unit consistency | 3.5 | PR overlay prints kg and kilogram semantics directly. Respect the user's display unit. |
| Record list hierarchy | 6 | Several equally sized records can dilute the best moment. Feature one main result, then reveal the others. |
| Result-to-share continuation | 2.5 | Keep Going is available, but the share component is not connected to the inspected live flow. |

### 16. Profile and progress — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Page purpose | 5.5 | Identity, settings entry, consistency, analytics, and exercise library share one destination. Make Progress a clear section or destination. |
| Weekly metric and comparison | 7 | Concrete KPI and delta exist. Match periods and explain comparisons. |
| Chart scan legibility | 4.5 | Three centered sample bars produce colliding date labels at 390px. Distribute bars and label adaptively. |
| Training interpretation | 4.5 | Higher volume/duration/reps get green and lower values red. Present neutral changes unless success is actually established. |
| Schedule-compatible consistency | 4 | Day-streak pressure can contradict planned rest. Emphasize weekly plan adherence. |

### 17. Settings and appearance — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Settings grouping | 7.5 | Utility rows and grouped sections suit the task. Keep this area calm. |
| Appearance selection affordance | 8 | Named swatches, visible selection, and instant application are clear. |
| Theme consequence preview | 5 | Source deliberately omits a preview. A compact actual component preview could show how a palette affects readability. |
| Sync status understanding | 7 | Source exposes syncing/offline/error states. Qualify the wording against actual save/backup states. |
| Settings typography consistency | 6 | Mixed header sizes and older documentation make intended hierarchy harder to maintain. Reconcile source-of-truth rules. |

### 18. Help and import utilities — R/S

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Help composition | 5 | Large unused region before support content weakens immediacy. Lead with common problems and actions. |
| Support-channel expectation | 6 | Telegram destination is disclosed. Clearly distinguish public community from a private support route if one is provided. |
| CSV import action | 7.5 | Clear choose-file CTA and template alternative. Preserve the workflow. |
| Import reassurance and explanation | 6.5 | Local-processing reassurance is useful but faint. Keep consequential text legible and show preview outcomes. |
| AI import entry and review promise | 7 | Photo/text paths and verification-before-save are explicit. Improve with a clearly labeled example and intelligible processing stages. |

### 19. Paywall — S; actual store products unverified

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Contextual relevance | 7 | Different source contexts allow relevant copy. Keep the reason for the gate visible. |
| Demonstration of paid benefit | 4.5 | Feature list does most of the explaining. Show the actual additional history or capability with a labeled example. |
| Pricing presentation architecture | 7 | Uses store product strings and annual/monthly paths. Verify with real localized products before acceptance. |
| Purchase/recovery affordances | 7 | Source contains restore and unavailable/error handling. Native behavior still needs qualification. |
| Density and reading burden | 5.5 | Header, feature rows, packages, terms, restore, and legal links create a long sheet. Prioritize value and terms without concealment. |

### 20. Sharing — R/S; prototype versus delivered experience

| Check | /10 | Finding / upgrade |
|---|---:|---|
| Poster visual hierarchy | 7.5 | Monument makes the result the hero. Its typography offers a useful direction for in-app achievement moments. |
| Live journey integration | 2 | Inspected routine/workout/PR routes and call sites do not enter the share service. Wire one complete path. |
| Estimated-result truth | 4.5 | Estimated 1RM hero is displayed beside “× reps,” which can imply that estimate was lifted for those reps. Separate the estimate from the logged set. |
| Privacy defaults | 8 | Name/bodyweight default off in the share model. Preserve this in any live connection. |
| Brand and credibility footer | 6 | Watermark and date exist but can read faintly. Verify readable exports and truthful metric/estimate labeling. |

## Specific issues to fix before decorative polish

| Priority | Issue | Evidence | Corrective direction |
|---|---|---|---|
| High | Unit mismatch on workout detail | `WorkoutDetailScreen._formatVolume` always appends kg; profile/home/routine use display-unit helpers. | Use the existing conversion path and the user's unit throughout summary and set views. |
| High | Unit mismatch on PR celebration | PR text and semantics use kilograms directly. | Resolve the display unit once and use it consistently in visible and spoken values. |
| High | Non-weighted sessions get weighted summaries | Active header and finish sheet accept volumeKg and present it as their aggregate metric. | Project an appropriate summary for weighted, rep-only, timed, and distance sessions; preserve zero as a fact only where it is meaningful. |
| High | Schedule-inappropriate reminder | `_StreakReminder` encourages daily training to preserve consecutive-day streaks. | Base the primary consistency signal on the user's weekly plan, with neutral rest-day language. |
| High | Important faint text | `textTertiary = 0x59FFFFFF`; chart ticks, some placeholders and reassurance text use it. | Evaluate composed colors for each meaningful role, including axes and input hints. Disabled controls are a separate case. |
| Medium | Purple filled labels narrowly miss normal-text contrast benchmark | `#BF00FF` versus `#0A0A0A` is approximately **4.39:1**. | Adjust the token pair while preserving palette identity; normal-size labels should meet 4.5:1. |
| Medium | Profile chart date collisions | Reproduced at 390px with three visible weeks; `BarChartAlignment.center` concentrates the bars. | Spread the groups, reserve adequate label width, and adapt label count to available width. |
| Medium | Misleading progress semantics | Graph KPI and comparison components use green for increasing totals and red for decreases. | A deload, shorter session, or partial week is not automatically failure. Use neutral deltas and compare matched periods. |
| Medium | Estimated 1RM presentation ambiguity | Exercise detail heading “One Rep Max”; Monument combines estimated hero value with rep multiplier. | Label the estimate and show the actual logged set separately. |
| Medium | Muscle percentages appear more scientific than their inputs | Routine distribution weights primary sets at 1 and secondary sets at 0.5; session split counts targets. | Explain the heuristic and align names across screens. Do not label this as recovery, activation, or measured fatigue. |
| Medium | Delight components lack live entry | Sharing model/service/gallery are present; inspected user journey has no caller. | Connect confirmed result → preview/privacy → native sharing, then verify export quality. |
| Medium | Visual acceptance evidence has gaps | Saved Explore baseline contains “No GoRouter found in context”; some goldens intentionally replace text with rectangles. | Fail tests on build exceptions; add full-screen rendered-font acceptance coverage with representative data. Keep masked geometry tests for their narrower purpose. |
| Medium | Design documents disagree | North-star uses older naming/palette references; conventions still describe purple buttons/no spacing constants while DESIGN.md introduces current tokens. | Establish one authoritative rule set and distinguish brand rules from share-card-specific rules. |

The **3:1** tertiary-on-black calculation and **4.39:1** purple/on-accent calculation use declared sRGB colors and the standard relative-luminance formula, not antialiased screenshot pixels. The 4.5:1 normal-text benchmark and 3:1 large-text exception are explained by [W3C's contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html). This is a targeted design assessment, not a whole-app compliance certification.

## Proposed next-level direction

**Quiet instrument, meaningful result.** Keep the black canvas, Inter, selectable accent, and fast logging. Make the user's training intention, current set, and earned result the three recognizable DELT moments.

### Before training: a clear launchpad

```text
TODAY / YOUR CHOSEN ROUTINE
Push A
5 exercises · 15 planned sets
Last bench session: 60 kg × 8

[ Start Push A ]

This week: 2 of 3 training days
Log a different workout · View history
```

This is proposed information hierarchy, not a newly implemented screen. Exercise/set totals come from the plan; previous values come from recorded history. A suggestion needs an explanation and a way to choose something else. Estimated duration is only shown when a defensible estimate exists.

### During training: the next action gets the attention

```text
PUSH A                         Finish
Bench Press · Set 2 of 3

Previous: 60 kg × 8
Today:    [ 60 kg ] [ 8 reps ] [ Log set ]

Set 1  ✓  60 kg × 8
Set 3     planned

Rest timer, when active: remaining time + next set
Other exercises stay accessible below
```

For experienced users, retain the familiar multi-row table. Focused presentation should be optional or smoothly integrated, with no forced extra taps. Large text can use this stacked structure instead of squeezed columns. Freestyle workouts show completed sets, not a made-up percentage denominator.

### After training: show what was earned

```text
WORKOUT SAVED
Push A completed
9 sets logged · 52 min

Bench: +1 rep at the same 60 kg, compared with your last session
Weekly training goal: 3 of 3 days

[ Done ]     [ Share result ]
```

Only show an improvement supported by comparable recorded data. Distinguish rep PRs, weight PRs, estimated 1RM, and volume. For sessions without a comparable result, report completion and consistency rather than inventing a win.

### Progress: one useful claim, then its evidence

Start with a concrete selected metric and comparison. Show the actual recorded values, comparable periods, and enough history to interpret the statement. Avoid equating longer workouts or more total tonnage with greater strength. Let users examine the raw data table; that capability already exists in the shared line chart.

### Motion and haptics: connect states

Use brief feedback when a set commits, progress updates, rest begins/ends, and a saved result appears. Preserve spatial continuity between the action and its result. Respect reduced motion and avoid making inputs wait for animation. The app already has suitable primitives; a general fade on every card adds little. Haptic choreography should distinguish selection, committed completion, timer alert, and exceptional achievement, then be qualified on hardware.

## Prioritized implementation sequence

| Order | Work | Why first | Acceptance evidence |
|---|---|---|---|
| 1 | Correct unit/metric/estimate truth and meaningful text contrast | A stronger-looking presentation must remain truthful and readable. | Failing behavior tests first for relevant projections, then passing tests; all affected palettes; kg/lbs and timed/rep/distance states. |
| 2 | Redesign Home and routine-library emphasis | Most frequent decision: choose and start training. | Returning users identify and start their intended routine without searching the history feed; test empty and inactive states too. |
| 3 | Reconstruct active-workout focus and density | Core utility and product feel depend on this screen. | Set completion speed/error rate, previous-value clarity, keyboard clearance, one-handed operation, and 1.6×/2× text acceptance. |
| 4 | Put routine plans before analysis | Removes a concrete ordering problem without a new feature architecture. | Routine opens with readable exercise plan; historical chart remains easy to access. |
| 5 | Add confirmed-save recap and weekly-plan recognition | Gives ordinary sessions a meaningful end state. | Recap appears only after successful save, stays truthful for no-PR/first/mixed sessions, and offers a clear exit. |
| 6 | Connect sharing to a real result | Converts existing expressive work into a delivered experience. | Actual record → preview → privacy choice → exported image → native share/cancel, with truthful estimated-result formatting. |
| 7 | Improve progress chart purpose and discoverability | Helps users see why their logging matters. | Matched-period comparisons, no crowded labels, neutral deload framing, empty/low-data/full-history states. |
| 8 | Shorten setup and refine discovery | Improves first value after the core experience is compelling. | Time to first useful set/program, completion of setup, understandable program selection. |
| 9 | Refine secondary utilities and premium demonstration | Useful polish after the daily training loop is strong. | Consistent headings, readable support/import copy, native purchase and recovery qualification. |

Follow the repository's relevant behavior-first, verify.ps1, golden, accent-token, and pushed-CI requirements when implementing. This audit does not certify those future changes or override the project's constraints.

## How to validate that the upgrade actually works

Test with first-time loggers, returning routine users, and experienced lifters. Use their actual intended tasks. Five to eight participants can reveal obvious usability failures; that is qualitative discovery, not statistical proof of retention.

Measure or observe:

1. Can a returning user identify their intended workout from Home within roughly five seconds? This is a proposed design target.
2. How many taps and how much time from opening the app to logging the first set?
3. Can a user tell current, previous, editable, ready, and completed values apart without explanation?
4. Do users correctly interpret volume, estimated 1RM, muscle distribution, and displayed units?
5. Does the ordinary saved-workout recap communicate a meaningful result without a PR?
6. Does the interface still work at 360/390/430px, large text, landscape, with keyboard open, reduced motion, and offline media?
7. Are save failures, empty history, cancelled sharing, and purchase recovery understandable?
8. Can users describe what improved and what they plan to do next? Ask this instead of asking only whether the screen is attractive.

If product telemetry is later connected, define workout-start, first-set-commit, finish-attempt, save-success/failure, recap-view, share-open/result, and repeat-use events with an explicit measurement purpose. Track the relevant funnel before and after changes. A native share-sheet completion is not proof that someone published a post. No uplift is predicted by this audit.

## What to retain and what to avoid

Retain the OLED foundation, restrained palette system, consistent font family, previous-session values, real PR recognition, offline-first logging, undo/recovery affordances, recent exercises, and accessible chart data tables.

Avoid adding social feeds, decorative dashboards, recovery scores, calories, achievements with no meaningful conditions, or new libraries to compensate for weak composition. Richer appearance should come from better prioritization, truthful personalization, and a recognizable training-to-result sequence.

The UI/UX skill's initial automatic design-system search returned a generic blue SaaS/marketing direction and was not applied. Its explicit fitness-product result supported OLED and strong block hierarchy, but its optional style/color suggestions were not treated as authority over DELT's existing identity. A framework search also returned generic guidance that did not resolve the observed hierarchy issue; source and actual renders determined the recommendations.

For wider design context, [Material's foundations](https://m3.material.io/foundations/) describe layout, tokens, and interaction states as separate design concerns. That distinction is useful here: consistent tokens alone do not establish useful screen hierarchy.

## Source evidence index

Paths below are relative to the repository root. Use the live source as authority; comments sometimes describe earlier behavior.

| Source | Relevant evidence |
|---|---|
| `lib/features/home/presentation/screens/home_screen.dart` | Conditional weekly stats, Quick Start, Start Empty Workout, history ordering. |
| `lib/shared/widgets/ui/start_button.dart` | Neutral Start treatment and reservation of full accent for live states. |
| `lib/features/workout/presentation/screens/workout_screen.dart` | Filled New Routine, Explore, flat routine list. |
| `lib/features/routines/presentation/widgets/routine_card.dart` | Tags, one-line preview, neutral Start. |
| `lib/features/routines/presentation/screens/routine_detail_screen.dart` | Chart-before-plan ordering, BEST/AVG labels, weighted muscle-share heuristic. |
| `lib/features/workout/presentation/widgets/active_workout_header.dart` | Timer/Finish priority, normal versus large-text layouts, always-weighted aggregate. |
| `lib/features/workout/presentation/widgets/exercise_block.dart` | Exercise/header/table geometry and repeated Add Set control. |
| `lib/features/workout/presentation/widgets/set_row.dart` | Previous hints, ready/complete treatment, measurement-specific fields. |
| `lib/features/workout/presentation/widgets/finish_summary_sheet.dart` | Pre-save summary, name, fixed duration/volume/sets. |
| `lib/features/workout/presentation/screens/active_workout_screen.dart` | Success routes Home; PR overlay only for record-bearing sessions. |
| `lib/features/workout/presentation/widgets/pr_celebration_overlay.dart` | Existing celebration, hardcoded kilograms, record list. |
| `lib/features/workout/presentation/screens/workout_detail_screen.dart` | Hardcoded summary kg, muscle split, action menu lacking result sharing. |
| `lib/features/profile/presentation/providers/profile_stats_provider.dart` | Consecutive-day streak and distinct training days in weekly goal. |
| `lib/features/profile/presentation/screens/profile_screen.dart` | Daily streak reminder, page's mixed purposes. |
| `lib/features/profile/presentation/widgets/graph_kpi_header.dart` | Raw-total delta semantics and partial/current-week comparison. |
| `lib/features/profile/presentation/widgets/weekly_bar_chart.dart` | Centered bars, date labels, low-data comparison and history gate. |
| `lib/shared/widgets/branded_line_chart.dart` | Shared chart, latest selected values, empty/single-sample paths, accessible data table. |
| `lib/features/exercises/presentation/screens/exercise_detail_screen.dart` | Duplicate name, media-first layout, estimate heading, instructions after history. |
| `lib/features/auth/presentation/screens/onboarding_screen.dart` | Seven steps and completion/tour flow. |
| `lib/shared/widgets/premium_paywall.dart` | Context-specific premium sheet, packages, restore, legal/recovery affordances. |
| `lib/core/theme/app_text.dart`, `app_colors.dart`, `theme_palette.dart` | Type hierarchy, faint metadata token, palette contrast pairs. |
| `lib/core/models/pr_card_data.dart` and share-card widgets | Mock/live construction model, privacy defaults, estimated hero plus reps. |
| `lib/core/services/share_card_service.dart` and `lib/core/router/router.dart` | Share service exists; production entry not found in inspected routes/callers. |
| `test/golden/golden_test_helpers.dart` and saved goldens | Theme harness versus acceptance evidence gaps. |
| `docs/APP_EXPERIENCE_TOOLS.md` | Newly installed packages explicitly do not add behavior or SDK initialization. |

