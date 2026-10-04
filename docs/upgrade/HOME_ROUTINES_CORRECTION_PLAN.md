# Home and Routines correction plan

Planned 3 October 2026; implementation authorized 4 October 2026. This reopens
Session 2 following the owner's rejection of its workflow and presentation.
The rejected Session 3 options remain withdrawn. Final implementation and
verification evidence are recorded below.

Refined on 3 October 2026 after the owner's request for stronger visual quality.
**Proposed builder rating: 8.5/10 for this plan.** This rates the specification,
not an implemented screen, owner acceptance or proven device usability. The
visual execution contract below replaces vague instructions to make it polished.

## 1. What went wrong

The idea of giving Home a useful start point was sound. The implementation made
the user manage a permanent shortcut instead of helping them continue a program.
It also removed too much containment and reduced useful actions to faint text.
Passing behavior tests and geometry checks did not establish visual quality or
a good everyday workflow.

| Observed problem | Source evidence | Correction |
|---|---|---|
| Home keeps showing one saved routine until Change is used. | `chosenRoutineProvider` stores a routine ID; `TrainingLaunchpad` renders that chosen routine. | Follow a chosen program; resolve the next member from confirmed completions. |
| The next-program suggestion is hidden in the chooser. | `_TrainingChooser` calls `nextProgramSuggestion`; the main Home card does not use it. | Make Up next directly visible on Home and explain its source. |
| Last trained refers to the chosen routine rather than the latest workout. | The launchpad passes `chosen.lastTrained` to `trainingAgeLabel`. | Add a distinct Last workout summary from the latest completed session overall. |
| The suggestion can depend on the loaded history window. | `WorkoutHistoryNotifier` starts with ten records; the chooser passes `history.items` into the resolver. | Resolve progression independently of pagination and scrolling. |
| New routine and Explore look weak or disabled. | `WorkoutScreen` uses text-only `TextButton`s with `textSecondary` in a left-aligned Wrap. Both have active callbacks. | Give each a real button surface, icon, readable label and predictable placement. |
| Library repeats the selected routine. | A compact `TrainingLaunchpad` card is inserted before the normal grouped routine list. | Represent Up next in its existing routine card instead of adding another hero. |
| Home's header is tall and text-heavy. | A large Train title precedes another large routine title, metadata and a previous-set block. | Restore a contained training card with a compact page header and deliberate information roles. |

These are conclusions from the current source and committed comparison images,
not measured claims about speed, retention or phone usability. The UI reference
is committed `f12e8966`. The current working tree also contains existing branding
and clock-related changes, which this planning pass preserves.

## 2. Confirmed owner decisions

- **Choose a program once and follow its saved order automatically after each
  completed workout. Allow a one-session override.** The owner confirmed this
  explicitly during this planning pass.
- Home must make the latest completed workout and the next planned workout clear.
- Home remains the place to choose the ongoing training plan. Routines reflects
  that choice; it does not gain a competing persistent selector.
- New routine and Explore must be easy to recognize and use.
- Keep the existing cards, tonal depth, accent language, Inter and shared motion.
  Refine the existing app; the audit's aesthetic suggestions are not a brief.
- Present one coherent, high-fidelity direction beside the current screen for
  owner approval before application implementation.
- Stash `907fe39954aee61512db8533684c95dd0e7bb61e` remains untouched.

The following layout, migration and edge-case details are the proposed execution
of those decisions. They are written explicitly for review rather than treated
as already implemented or accepted.

## 3. Training behavior: an ongoing plan, not a daily setting

### The default path

Home stores the identity of the chosen program, not whichever day happens to be
displayed today. A separate derived result identifies the next routine:

1. Read the selected program and validate its explicit membership/order metadata.
2. Find its most recent completed, linked workout for the current account.
3. Resolve the following saved member, wrapping at the end of the program.
4. With no completed program history, use the explicitly chosen starting routine.
5. Display the resolved identity and use that same ID when Start is tapped.

Example only: follow Push A → Pull A → Legs A. Completing Push A makes Pull A
Up next without using Change. Taking two rest days leaves Pull A Up next.
Starting Pull A without finishing it leaves it active; discarding it does not
advance the program. Completing Legs A makes Push A next.

Advancement follows **confirmed persisted completion**, never opening Home,
pressing Start, crossing midnight or a failed save. No stored cursor is advanced
optimistically. Deriving the result from saved history also prevents a separate
cursor from drifting away from edited/deleted/synced records.

### One-session override

- Home offers a clearly enabled **Train something else** action.
- Its sheet says **This workout only** and shows saved routines plus the existing
  freestyle action. Selecting a row identifies the workout; its explicit Start
  action starts it without changing the ongoing program preference.
- Completing a freestyle workout or a different program does not advance the
  selected program. It does become the global Last workout.
- Proposed rule for an override to another member of the same program: after its
  confirmed completion, the next step follows the member actually completed.
  Explain this in the sheet; do not silently pretend the skipped member was done.
- Cancellation, back navigation, loading failure and a failed launch leave the
  selected plan intact. Existing busy/account/active-workout guards remain.

### Plan selection and migration

Rename the persistent chooser's purpose to **Training plan**. Distinguish valid
programs from standalone routines. Choosing a standalone routine remains an
explicit repeat-routine mode; do not invent a sequence from names or muscle tags.

Use the existing preferences mechanism, scoped to the same account, with a
versioned mode/identity value. Reuse existing program metadata and grouping; no
new programs table, scheduling engine or package is needed for this correction.
Keep the original routine ID as a starting/fallback identity where appropriate.

Migration proposal for the approved correction:

- A saved choice belonging to a complete, valid program retains that program and
  anchor. Its new Following label makes the changed behavior visible.
- A standalone choice retains its routine. Do not pick a different program from
  unrelated history or the first library row.
- Invalid/deleted choices remain explicit recovery states. Legacy groups without
  trustworthy saved order cannot auto-progress; offer a manual workout and
  management access instead of guessing their order.
- Migration is idempotent. Preference write failure retains the old value and
  displays the failure; no success marker appears before persistence succeeds.

## 4. Home: visible continuity in the existing card language

Normal returning-user order:

1. **Compact page header.** Avoid stacking two screen-sized headings. Use the
   existing type roles, not a new display font or a flat text-only hero.
2. **Up next card.** The focal contained training card, with actual program name,
   routine name and one short reason such as Follows Push A in your saved order.
   Show exercise/planned-set counts only when known. A small preview can use
   existing exercise thumbnails and real names; no invented artwork or targets.
   Use one prominent **Start Pull A** action and a clearly enabled plan-management
   action. Keep Train something else distinct from changing the ongoing plan.
3. **Last workout card.** Show the actual latest completed session overall: name,
   finished date, elapsed duration, exercise count and an appropriate known
   metric. Its tap opens that saved workout. A History action reaches the
   existing full feed. This card must not reuse the selected routine's age and
   call it the latest workout.
4. **Existing weekly progress.** Preserve its current meaning and goal control;
   this correction does not redesign streaks or introduce adherence claims.
5. **Existing full history.** Keep browsing, pagination, edit/export/delete and
   scroll restoration. The compact last summary is a useful shortcut, not a
   second full copy of the large history card.

Use `AppCard`, existing surface gradients, radii and spacing, `context.accent`
and `AppText`. Keep the rich exercise/history treatment. Metadata is supporting
information, not a tall catalogue of headings and duplicated facts.

At 390×844/normal text, the target is to see the named Start and enough of Last
workout to identify the session without scrolling. This is an acceptance target
to prove in renders, not a claim that it already fits. At 1.6×/2×, allow natural
vertical growth and full names; never shrink text or squeeze actions to force
both cards onto one screen. Collapse only nonessential preview density, not the
identity, reason, date or Start label.

If the latest global workout is a walk but the selected program last completed
Push A, Last workout correctly shows the walk and Up next still shows Pull A.
The reason names the relevant program completion so these two cards do not
contradict each other.

## 5. Routines: a useful library with visible actions

- Restore a proper **New routine / Explore** action row immediately below the
  header. Use existing button shells, raised surfaces, white enabled labels and
  accent icons. Both are full touch targets, not faint text in a corner.
- Give the buttons balanced width at normal text. Stack them when the available
  width/text size needs it; allow complete labels rather than ellipsis. Preserve
  the existing creation sheet, AI-import route, Explore route and limit handling.
- Keep existing program groups and routine cards, including focus tags, previews,
  Start and management menus. No replacement by plain rows.
- Remove the separate duplicate Home-routine hero. Mark the resolved next member
  **Up next** on its existing card; mark the followed program at the group level.
  That row can carry the page's focal named Start. Other routine Starts remain
  clearly enabled secondary controls.
- Keep the logical saved program order. Do not reshuffle all cards every time
  Up next changes. Provide a labeled **View next** navigation action in the
  library header context when a valid next member exists. It scrolls to and
  focuses the actual marked card; it does not start a workout or repeat the
  hero. Preserve list order and scroll restoration, including on return from
  routine detail. This handles large libraries without making users hunt.
- Starting a different saved routine is a one-session action and does not change
  the ongoing Home plan. Retain rename/edit/delete and routine-detail access.
- Empty-library and read-error states keep real New routine/Explore controls.
  Removing the compact launchpad requires replacing its owned error/retry
  presentation; do not accidentally remove recovery along with the duplicate.

One focal accent fill is sufficient; other actions still look like real buttons.
In an empty library with no Start, New routine may take the existing primary
button role. In a populated library, the next workout's Start takes that role.

Source/design discrepancy: `StartButton` comments reserve accent fills for live
states, while authoritative `DESIGN.md` permits one focal filled CTA. Reuse the
existing `PrimaryButton` for that focal action and retain the raised StartButton
elsewhere; do not rewrite shared styles across the app to fix these two screens.

## 6. Visual execution contract

### What should make the screen feel considered

The distinguishing composition is a useful training pair: **the routine you can
start next, followed by the workout you actually finished**. The main card has
enough presence to anchor Home; the recent-workout card is quieter and more
compact. Existing weekly progress and detailed history provide the supporting
rhythm. Quality comes from this hierarchy, the existing tonal depth and precise
alignment, rather than additional widgets or decorations.

The archived Session 2 Home after-render leaves the main routine on the bare
canvas; the Library after-render replaces surfaced actions with grey text. Keep
the before-render's card containment and action affordance while correcting the
workflow. Do not equate reduced containment with cleaner design.

### Home composition, down to individual elements

| Element | Proposed visual treatment | Required restraint |
|---|---|---|
| Page header | One existing screen-title role, aligned to the card gutter. | No second oversized heading or extra greeting/subtitle block. |
| Up next frame | Shared `AppCard` gradient, hairline and radius; ordinary card padding. | No border glow, large tinted panel, drop shadow or replacement card system. |
| Context and management | Small Up next label; readable Training plan action with a full touch target. Stack when necessary. | Up next is planned intent; no completed checkmark or green success treatment. |
| Routine identity | Existing `AppText.titleLarge` for the routine; program name directly associated with it. Full identity remains visible. | No carousel, oversized metric or fabricated motivational claim. |
| Why this routine | One short, truthful line: for example, After Push A in your program. No-history wording identifies the selected starting workout. | No invented recovery/readiness or date-based scheduling. |
| Planned facts and preview | One compact facts group; optionally the first two existing exercise thumbnails/names when there is room. | No tall exercise catalogue, repeated muscle-chip row, previous-set subcard or fake image assets. |
| Start | Full-width shared primary button, at least its existing 52dp minimum, with a complete action label and contextual routine identity. | One focal filled CTA; use `accent.onAccent` for its label. No fixed height at large text. |
| One-session alternative | Clearly surfaced neutral Train something else control, below Start and distinct from Training plan. | Never faint text, an invisible gesture or an action that silently replaces the plan. |
| Last workout | Compact `AppCard`: latest completed name/date, then supported facts. Use one coherent detail tap and a separately labeled History control. | No second Start, duplicate exercise list, generic success flood or comparison delta without context. |

Use existing `AppSpacing` values: align all cards to one page gutter, use the
16dp card-padding token, at least 8dp separation between independent touch
targets, and a consistent 12/16dp card rhythm. Major sections may use the
existing 24dp spacing role. These are token choices to test, not new magic
numbers or rigid height budgets. Align icons, labels and numeric baselines;
use tabular figures and the existing unit helpers.

The optional preview is the first thing to remove if it pushes useful Last
workout context below the initial normal-text viewport. Richness must still
come from the real card treatment, typography, action surface and existing
history imagery. Missing thumbnails use the established neutral placeholder;
do not add decorative imagery merely to make the concept look finished.

### Library composition and action treatment

New routine and Explore occupy a deliberate, equal-width action row immediately
under the title/count. Both have a `surface3` shell, readable primary label,
existing icon family with an accent glyph, consistent radius and at least 52dp
height. Use their full names. At large text or insufficient width, they become
two full-width stacked buttons with the same emphasis and generous separation.
Their labels never fade to the metadata color while they are enabled.

Below that row, retain the existing program/routine card language. Up next gets
a compact accent marker and the focal Start inside its actual card. Other
cards keep raised neutral Start controls, focus tags and management menus.
The followed-program label explains membership; View next is navigation, not
another selection mechanism. It has an explicit label, 48dp minimum target and
visible press feedback. Do not move focus or scroll just because data refreshes;
the jump happens only when requested.

### The same finish in every material state

| Visual state | Presentation requirement |
|---|---|
| Loading | Reuse the eventual card decoration and structural space. Show a clear loading state; no fabricated routine, changing layout skeleton or tappable placeholder Start. |
| Ready | Routine identity and Start carry the hierarchy. Planned labels use accent/neutral treatment, with no success badge. |
| Starting | Preserve the action footprint, expose busy semantics and prevent a second launch. No completion animation before the session exists. |
| Just completed | Update Last workout and Up next only after confirmed persistence. Use existing bounded transition helpers; no confetti or a delayed reveal hiding the next Start. |
| Active workout | Name the actual active session and make Resume the focal action. Up next remains identified as for later; the mini-player uses the same session. No competing filled Start. |
| No history | Keep the contained next-workout card; a concise first-workout invitation replaces invented Last metrics. No large empty illustration or zero-filled trophy. |
| No followed plan | Give Choose training plan the primary role. Keep history and Train something else usable. No silently selected first routine. |
| Failed read or invalid program | Use the same card frame, concise specific explanation and an enabled Retry/manage/override action. Never render failure as an empty success state. |
| Empty next routine | Explain the missing exercises and offer the existing edit/detail path. A disabled-looking Start must not secretly act as an ordinary enabled launch. |
| Chooser with keyboard | Keep its title/purpose, focused query, selected identity and relevant action reachable above the IME; results scroll. Preserve draft text on resize and Back. |

### Detail checks that can reject the render

- At 360/390/430px and 1×/1.6×/2×, full routine identity, action purpose and date
  remain readable. Metadata wraps into stacked groups; it never compresses into
  a tiny table or overlaps a menu. Short facts do not split numbers from units.
- Prefer text-only `PrimaryButton` for the focal launch when its icon variant
  would ellipsize the label. That variant currently uses ellipsis. For very long
  names, use the complete visible label Start workout directly below the fully
  visible routine title, and include the identity in semantics. Repeating
  neutral button shells also need a wrapping policy at these call sites; reuse
  their styling rather than assuming the existing ellipsis policy is qualified.
- Provide whole-card semantics for Last workout without nested duplicate tap
  actions. Menus, plan management and View next retain distinct labels and
  touch regions. At increased text size, move actions onto their own row.
- Check actual alpha-composed contrast across all six accents, including the
  accent-filled CTA. Meaningful normal text requires 4.5:1; large text and
  meaningful control graphics require 3:1. A subtle decorative hairline must
  not be the only cue that an action exists.
- Show keyboard-closed/open pairs for each presented state that includes a
  searchable chooser. Include system bars, bottom navigation and the real
  mini-player state in the evidence; do not gain apparent space by hiding them.
- Before and after use matched dimensions, palette, text scale, fonts, fixtures
  and capture method. Include all content, not just a favorable crop. Concept
  callbacks do not count as behavior evidence; synthetic facts are labeled.

Reject the candidate if it is flatter than the reference, if all cards compete
at the same visual weight, if enabled actions look greyed out, if long names
are concealed, or if Last workout becomes a duplicate of the first history
card. A different layout idea is required when those failures persist; more
accent fill or decoration is not a repair.

## 7. Data and state contracts

Use one shared, tested resolution result for Home and the Routines marker. The
latest global completion and latest selected-program completion are separate
queries. Reuse suitable DAO paths; where missing, add narrow account-filtered,
reactive completed-session queries with `endedAt` ordering. Avoid loading every
historical workout or querying once per routine.

The paginated feed is for browsing. A selected program's last completion may be
older than its first ten rows, so scrolling must never determine progression.
Reuse the existing Drift revision/watch mechanism for save/edit/delete/sync
updates. Dates use an injected clock for repeatable comparisons. The current
workspace already has clock-related edits; inspect and preserve those instead
of declaring them absent or overwriting them.

| State | Required presentation/behavior |
|---|---|
| Program chosen, completed history | Actual Last workout; next valid member; named Start and source reason. |
| New program, no completion | No fabricated Last workout; explicitly selected starting routine; clear first-session action. |
| No chosen plan, saved routines exist | Last workout remains available; Choose training plan and one-session start are distinct. |
| Only a standalone routine | Explicit repeat-routine mode; no claimed rotation. |
| Latest workout belongs elsewhere | It appears in Last workout; selected program progression is unchanged. |
| Active workout | Resume the actual session takes priority; show program next as for later; preserve the existing mini-player and single-session guard. |
| Discarded/failed save | No advancement or completed-success treatment. |
| Deleted/empty next routine | Explain the missing/empty member; offer management and a deliberate override; do not silently skip a program day. |
| Partial/duplicate/legacy membership | Show available saved routines; no confidently inferred order. |
| History read fails | Preserve usable library controls; explain that next cannot be determined; Retry or explicit one-session choice. Failure is not an empty history. |
| Preference read/write fails | Specific recovery; existing valid selection retained where known; no fake saved state. |
| Account switch | Cancel obsolete work and replace scoped data/preference; no cross-account history or choice. |

Additional tests cover rename, deleted latest completion, imported older history,
out-of-order completion timestamps, ambiguous ties, midnight/time-zone labels
and a program completion outside the visible history page. Ambiguous metadata
or chronology requires an explicit choice rather than a fabricated certainty.
Saved weights remain kilograms; use existing measurement/unit helpers for display.
For a non-weight workout, show supported counts/elapsed data if the preview lacks
typed totals; do not invent a reps/distance result or label zero volume as its
primary achievement.

## 8. Work sequence and review gates

1. **Freeze the reference.** Record the committed UI and current workspace inputs.
   Use an isolated workspace for implementation; preserve concurrent branding,
   clock and workout work. Do not apply, pop, modify or recreate the protected
   stash. Render the current screens at 390×844 and 1.6× text into the correction
   session's `before/` directory. No broad revert of Sessions 1/2 and no unrelated
   screen redesign.
2. **One high-fidelity direction.** Assemble the Home/Routines proposal from real
   components and the actual theme. Consider three refinements internally and
   record why at least one is rejected. Show the current before beside that one
   direction, including a completed-session transition, override, empty state,
   long names and large text. Use real fonts; no wireframes or inert generic
   button shapes standing in for the product. Label synthetic data explicitly.
   Stop for owner approval before app-code implementation, as PROTOCOL requires.
3. **Failing behavior tests first.** Cover progression/wraparound, no advancement
   on Start/discard/failure/rest day, same/outside-program overrides, global
   versus program history, pagination independence, migration/write failure,
   account isolation and reactive edit/delete/sync updates. Preserve busy/Resume
   launch behavior and existing history/management interactions.
4. **Implement the agreed correction.** Add the shared resolution and narrow data
   queries, correct Home, then integrate the same resolution into existing
   Routines cards and restore its action row. Run build_runner after provider/DAO
   changes. Keep changes reviewable; no new packages or global token system.
5. **Verify behavior and visual detail.** Run `scripts/verify.ps1`; use affected
   accent goldens with real glyphs. Check 360/390/430px, 1×/1.6×/2×, all six
   accents for changed surfaces, realistic imported and custom libraries, long
   names and every material state above. Include keyboard-open search/chooser,
   system/mini-player clearance and Back/cancel. Fix causes; do not weaken gates
   or blindly regenerate expectations to hide a failure.
6. **Owner/critic/device review.** Compare visual richness with the existing app
   and list three remaining weaknesses. If needed, iterate at most four times,
   trying a different idea each time rather than polishing the same one. Record
   decisions, rejected ideas, evidence, limitations and justified proposed scores
   in LEDGER.md; an independent critic establishes any score of 9 or above.
   Get a fresh review of this exact change. Test on the owner's phone before
   claiming haptic, motion, timer or one-handed benefits. Commit only after the
   local gate passes; record CI and device evidence separately.

## 9. Acceptance checklist

- [ ] No daily Change step is required to follow an established valid program.
- [ ] Last workout describes actual global completion; Up next describes the
  selected program's next intended workout, with a visible reason.
- [ ] Rest days, starts, cancellations and failed saves do not advance anything.
- [ ] One-session overrides preserve the selected program; their completion
  effects are explained and tested.
- [ ] Home and Routines agree before and after completion, restart and sync.
- [ ] New routine and Explore are visibly enabled, labeled and at least 48dp;
  true disabled/busy states have distinct semantics and appearance.
- [ ] No duplicate selected-routine hero, new daily-management chore, guessed
  schedule, guessed legacy order or cross-account data.
- [ ] Existing cards/depth/accent/motion and management/history access remain.
- [ ] Main and supporting cards have distinct hierarchy; Library actions are
  surfaced buttons; View next reaches the actual card without changing order.
- [ ] Loading, ready, busy, completed, active and recovery states meet the same
  visual contract. No placeholder action or uncommitted success treatment.
- [ ] Long names, 1.6×/2× text and chooser keyboard work without clipped identities
  or concealed actions. No fixed-height squeeze to imitate a passing screenshot.
- [ ] One coherent visual direction is owner-approved; verification and affected
  palette goldens pass, with remaining limitations honestly recorded.

Three remaining weaknesses to revisit in the first review: the compact Last
workout summary could still repeat too much of the history card; the optional
preview and secondary actions may make the main card too tall at large text;
complex imported/legacy programs may lack reliable order. View next addresses
the large-library search problem, but its discoverability is still unmeasured.
Resolve these with owner-facing evidence, not extra decoration or a second
selection store.

**Haptics: unverified, needs device.**
**Timer feel: unverified, needs device.**
**One-handed use: unverified, needs device.**
All fit/speed/readability improvements above are targets, not measured outcomes.
No implementation-completion score, application change, test-pass or device
claim is made by this plan.

## 10. Rating and what would justify a higher one

**Whole revised plan: 8.5/10, proposed builder assessment.** The workflow now
matches the confirmed owner decision, the source/data failure is addressed,
visual roles are specified down to controls and spacing, and alternate states
have rejection criteria. These are substantial improvements in specification
quality; they are not proof that users will be impressed by the resulting UI.

The deductions are concrete: first-fold balance is still unrendered, the recent
summary/preview tradeoff needs visual judgment, and legacy/override behavior
still has proposed details to validate. Actual app visual quality is **not yet
rated** by this plan. No independent critic or owner acceptance is claimed.

A higher assessment needs a real-component before/after candidate showing the
same or better visual richness, owner approval, behavior/visual verification and
resolution of the remaining weaknesses. Per PROTOCOL.md, a score of 9 or above
requires an independent critic. Do not raise the number merely by adding more
requirements to this document.

## Source references

Execution update, 4 October 2026: [one high-fidelity review direction](renders/home-routines-correction/README.md)
is prepared from the committed baseline. The owner subsequently approved this direction with “proceed”. The fixed-height
mini player overflow was reproduced before implementation; the real bar and
shell now share its measured large-text height. This is a listed shared
dependency, while the active-workout-screen redesign remains withdrawn.

- [Home composition](../../lib/features/home/presentation/screens/home_screen.dart)
- [Paginated history](../../lib/features/home/presentation/providers/home_provider.dart)
- [Choice, suggestion and launch guards](../../lib/features/routines/presentation/providers/training_launch_provider.dart)
- [Current launchpad and chooser](../../lib/features/routines/presentation/widgets/training_launchpad.dart)
- [Routines composition](../../lib/features/workout/presentation/screens/workout_screen.dart)
- [Existing routine card](../../lib/features/routines/presentation/widgets/routine_card.dart)
- [Completed/history queries](../../lib/core/database/daos/workouts_dao.dart)
- [Program membership](../../lib/core/routines/program_membership.dart)
- [Grouping](../../lib/core/database/daos/program_grouping.dart)
- [Shared card](../../lib/shared/widgets/ui/app_card.dart)
- [Primary action](../../lib/shared/widgets/ui/primary_button.dart)
- [Neutral Start action](../../lib/shared/widgets/ui/start_button.dart)
- [Typography and geometry tokens](../../lib/core/theme/app_text.dart)
- [Visual rules](../../DESIGN.md) and [owner guardrail](PROTOCOL.md)


## Implementation authorization — 4 October 2026

The owner approved the shown before/after direction with “proceed”. The planning
pass above is historical; implementation is now underway on the isolated
`codex/home-routines-correction` branch. The completed plan retains its 8.5/10
proposed specification rating; execution, CI and device acceptance are separate.


## Candidate 2 implementation — 4 October 2026

- Home follows the chosen program from committed completion chronology and shows
  the global Last workout separately. One-session overrides never rewrite the plan.
- Automatic following remains the default. An explicit Repeat one routine option
  preserves persistent repetition, including a member of a complete program.
- Empty Home starts a first workout directly and offers Browse programs. Its
  plan chooser explains the empty library and has a useful browse exit.
- Long identities stay complete; at large text, the existing smaller title role
  and earlier Start action prevent secondary copy displacing the launch.
- Library uses substantial New routine/Explore utilities, marks the real next
  routine, and scrolls to it only on View next. Missing plan markers have a
  visible Home recovery route while saved routines remain available.
- The plan/override sheet keeps its header and search above the keyboard while
  choices scroll. Completion ties are resolved by an explicit starting choice,
  including when selecting a different program; failed reads/saves retain intent.

Fresh review and final local/CI results will be appended to LEDGER.md before
completion. The original 8.5/10 is a specification rating, not a device score.
Haptics, timer feel and one-handed use: **unverified, needs device**. Native
keyboard and screen-reader qualification: **unverified, needs device**.


## Final state clarification — candidate 3

Mode selection is a draft until a routine is chosen; closing cancels it. The
neutral switch and explicit instruction distinguish this from the committed
Home plan. Standalone behavior is explained accurately, and saving/failure
feedback remains above the scrollable result list. Narrow large-text Library
titles reflow with an existing heading token; text scaling remains enabled.

## Final evidence — 4 October 2026

The authorized Home/Routines correction is implemented on the isolated
`codex/home-routines-correction` branch from `f12e8966`. Independent candidate 3
scores: **Home 8.0/10; Library 7.8/10**, both packet-level passes. The original
8.5/10 remains a specification rating. Library's 8/10 acceptance target remains
unmet; no whole-app or device score is claimed.

Final local verification passes all **2,268 tests**, format, fatal analysis and
custom lint. The focused render run passes **738 checks** with real components,
fonts and all six palettes. The configured Android release APK compiles.
[LEDGER.md](LEDGER.md) records exact logs, APK hash, remaining weaknesses and CI.
[Implemented before/after gallery](renders/home-routines-correction/README.md).

Haptics, timer feel and one-handed use: **unverified, needs device**. Native
keyboard and screen-reader use: **unverified, needs device**. No active-workout
redesign or protected-stash change is part of this correction.
