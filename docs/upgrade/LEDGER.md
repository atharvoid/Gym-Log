# DELT upgrade ledger

Baseline: [AUDIT.md](./AUDIT.md), 2 October 2026, HEAD `ce3d598` plus the existing working tree. Current column scores refer to whole audit sections. Session 1 critics assessed the combined correctness candidate and specific micro elements; those independent scores appear below and do not replace unreviewed whole-section scores. Source-only areas remain provisional.

Targets are proposed acceptance goals of **8/10 per section**, not predicted results. Setup started at iteration zero; Session 1 changes correctness and shared tokens. Four cumulative candidates include the shared-token changes; the iteration count is candidate submissions, not four redesigns of each section. Whole-section redesign/acceptance has not been claimed.

| Section | Current /10 | Target /10 | Status | Iterations | Notes |
|---|---:|---:|---|---:|---|
| 1. Visual identity and system | 6.5 | 8 | Revision needed (scope partial) | 4 | Establish distinct focal/supporting/reference composition; preserve accent tokens and improve meaningful text contrast. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 2. Sign-in / first impression | 6.5 | 8 | Not started (tokens checked) | 4 | Demonstrate a concrete product benefit while retaining a clear sign-in action. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 3. Onboarding / time to value | 5 | 8 | Not started (tokens checked) | 4 | Reduce required setup and end with a useful training action. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 4. Home / daily training intent | 5.5 | 8 | Not started (tokens checked) | 4 | Surface a relevant, explainable routine choice and prominent Start; qualify inactive and empty states. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 5. Workout history | 7 | 8 | Revision needed (scope partial) | 4 | Improve browsing density and specific result recognition without losing useful previews. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 6. Routine library | 6 | 8 | Not started (tokens checked) | 4 | Promote starting a saved routine; improve differentiation and program grouping. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 7. Routine detail | 6.5 | 8 | Not started (tokens checked) | 4 | Put the exercise plan before analysis; clarify volume and muscle-share labels. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 8. Routine authoring | 6.5 | 8 | Not started (tokens checked) | 4 | Show whole-plan feedback; qualify populated plans, reordering, and import entry. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 9. Explore / program discovery | 6.5 | 8 | Not started (tokens checked) | 4 | Reduce header density and explain program fit using stated preferences. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 10. Exercise library / selection | 7 | 8 | Not started (tokens checked) | 4 | Preserve search/recent items; improve fallback imagery and selection context. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 11. Exercise detail / learning | 6.5 | 8 | Revision needed (scope partial) | 4 | Clarify Learn versus History intent, compact unavailable media, and label estimated 1RM. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 12. Active workout / logging | 6 | 8 | Revision needed (scope partial) | 4 | Focus the next set; improve completed/ready distinction, density, and large-text clarity. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 13. Rest and hold timers | 7 | 8 | Not started (tokens checked) | 4 | Reduce duplicated context while retaining controls; hardware feedback remains unqualified. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 14. Ordinary finish / recap | 5.5 | 8 | Revision needed (scope partial) | 4 | Show an honest, measurement-aware recap only after successful durable save, including no-PR sessions. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 15. PR recognition | 7 | 8 | Revision needed (scope partial) | 4 | Preserve existing celebration; correct units and make record type/delta intelligible. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 16. Profile / progress | 6 | 8 | Revision needed (scope partial) | 4 | Clarify purpose, remove chart-label collisions, compare matched periods, and respect planned rest. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 17. Settings and appearance | 7 | 8 | Revision needed (scope partial) | 4 | Keep utility restraint; clarify theme consequences, typography, and sync-state language. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 18. Help, CSV import, AI import | 6.5 | 8 | Revision needed (scope partial) | 4 | Improve support composition and readable reassurance; retain explicit import review. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 19. Paywall / premium value | 6 | 8 | Not started (tokens checked) | 4 | Demonstrate paid benefit and retain truthful pricing/recovery; actual store behavior remains unqualified. Session 1: shared contrast/Purple tokens; full section acceptance pending. |
| 20. Sharing in the user journey | 2.5 | 8 | Revision needed (scope partial) | 4 | Connect real result to preview/privacy/export/share; separate estimated result from actual lifted set. Session 1: shared contrast/Purple tokens; full section acceptance pending. |

## Update rules

- Status sequence: Not started → Building → Awaiting critic → Revision needed or Critic passed → Accepted. Use Blocked only with a concrete dependency noted.
- Increment Iterations once per changed candidate submitted to a fresh critic. Reviewing the same candidate again does not count as a new implementation iteration.
- Keep Current at baseline until a critic evaluates that whole section. Record scoped candidate/micro scores separately when a partial scope spans sections; do not inflate whole-section scores from micro scores. For a whole-section review, record its latest score, including a lower score; retain baseline in AUDIT.md and link the verdict. A high score alone does not mean Accepted.
- Record candidate identity, verdict, remaining defects, and validation evidence in Notes. Changes to shared components can affect several sections; update every affected row.
- Accepted requires target attainment, no unresolved material critic findings, and the applicable repository Definition of Done: behavior-first tests, verify.ps1, affected-palette goldens, accent tokens, pushed CI, and regression loop log when applicable. Record any outstanding native-device qualification explicitly.
- Follow [CRITIC_PROTOCOL.md](./CRITIC_PROTOCOL.md). The critic gets [RUBRIC.md](./RUBRIC.md), before/after renders, and the exact candidate diff only. Do not give the critic this ledger, the audit, target scores, or builder reasoning.

## Baseline verification

Setup session: 2 October 2026. No application source was changed during setup. The owner subsequently authorized Session 1 correctness work; layout redesigns remain out of scope.

Checking the existing working tree at HEAD `ce3d5980e8eba0dd2497310cc1a4d576a2d83dc4` on `feat/explore-routine-first`, including its pre-existing tracked and untracked changes. Toolchain: Flutter 3.44.0 stable, Dart 3.12.0, Windows.

`scripts/verify.ps1` passed (exit 0): token guards, 359 Dart files formatted with zero changes, fatal analysis, custom_lint, and 813 tests. [Verification log](baseline/2026-10-02/verify.log).

Android release build failed (exit 1). Initial Java Unix-domain loopback startup failure was bypassed using process-local `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=<nonexistent temporary directory>` and `GRADLE_OPTS=-Dorg.gradle.daemon=false`; both environment values were restored. Configuration then failed because `flutter_smartlook` 4.1.3 has no Android namespace. No dependency, Pub cache, or build configuration was patched. [Build log](baseline/2026-10-02/android-release-build-tcp-retry.log). A passing Android baseline is **unverified**. iOS and pushed CI are **unverified**.

The setup SHA-256 comparison found only a regenerated tracked Gradle HTML problem report outside docs/upgrade; application, test, dependency and configuration inputs matched the starting snapshot. AUDIT.md was preserved byte-for-byte. [Integrity evidence](baseline/2026-10-02/source-integrity.txt). No commit or push was made.

## Session 1 — correctness before beauty

Owner scope: display units including speech; measurement-aware active/finish summaries; composed tertiary text contrast across six palettes; Purple fill/label contrast; explicit Estimated 1RM and separate logged evidence; neutral aggregate deltas; authoritative design documents. No layout redesigns or new packages. Android dependency remediation is outside this scope and remains an acceptance blocker.

Before production changes, live widgets were captured at 390 × 844 and 1.6× Inter text in `renders/session-1/before/`. Filenames identify synthetic fixtures. After evidence additionally includes every affected palette, empty/low-data/error states, and repeatable real-font goldens.

Three candidates for each scoped concern:

| Concern | A | B | C | Decision / rejected idea |
|---|---|---|---|---|
| Unit truth | Existing conversion helpers at visible/spoken boundaries | Independent formatting per screen | Store converted weights | Choose A; reject C because presentation preference must not alter logged kilograms; reject B because labels can drift. |
| Session summaries | Reuse WorkoutMetricSummary with measurement-aware totals | Display every metric in a new grid | Replace summaries with set count only | Choose A, retaining existing primary-metric precedence and unchanged layout; reject B (layout redesign) and C (hides useful logged measures). Logged hold time must be distinguishable from elapsed session time. |
| Faint text | Raise shared tertiary token after composed-color checks | Introduce one token per role | Promote each meaningful label to secondary | Evaluate A against all actual surface/tint roles; reject B unless measured exceptions require it (unnecessary token system). C remains a fallback for an exceptional backing surface. |
| Purple pair | Small same-hue base adjustment | Change Purple onAccent independently | Replace Purple hue | Choose A if all normal text pairs reach 4.5:1; reject C (loses palette identity). |
| Estimated 1RM | Label estimate and carry actual logged set independently | Infer set from estimate | Hide the estimate | Choose A; reject B (not a logged fact) and C (removes useful existing history). No new celebratory motion. |
| Aggregate deltas | Neutral text/icons, preserving direction and magnitude | Green/red with disclaimer | Remove deltas | Choose A; reject B (still equates more work with success) and C (loses useful comparison). |
| Design authority | DESIGN.md authoritative; other docs link and align | Multiple peer specifications | Delete architectural conventions | Choose A; reject B (continues contradictions) and C (loses unrelated engineering rules). |

Candidate 1 uses existing display converters on detail and PR values, including
the PR spoken current/previous/logged values. PersonalRecord carries logged
weight/reps independently of its estimated value; missing evidence is explicit.
The estimate is labeled on exercise history, celebration and all three share
variants, and never multiplied by its logged reps. Missing exercise estimates
remain absent. Aggregate deltas keep their arrows/magnitude and use neutral ink.

WorkoutMetricSummary now derives completed measures by measurement type, feeding
the active header, finish review, new saves and historical edits. Distance fields
never become kilograms. Logged hold seconds and sub-kilometre metres remain
visible; elapsed time is a separate measure. The existing mixed-session primary
precedence remains volume → reps → distance → logged time. Finish review says
"Finish workout" before persistence. No new layout, motion or package was added;
existing rows received gaps and PR names can wrap to retain context at 1.6×.

DESIGN.md now owns visual/interaction/truth rules. North-star links there;
CONVENTIONS retains architecture and defers UI rules instead of prescribing an
old static-purple theme, unsupported font weights or an inline-font system.

Evidence and validation:

- [Initial red tests](baseline/2026-10-02/session-1-red.log): 16 behavioral
  failures before production changes, including unit, summary, contrast, estimate
  and delta faults. Follow-up red tests caught the historical-edit distance
  multiplication and missing-estimate fallback; a separate red test caught the
  premature completion copy. These logs preserve failed expectations.
- [Focused green checks](baseline/2026-10-02/session-1-green.log): 57 checks,
  including existing header geometry, analytics/PR and document metadata guards.
  PR semantic assertions cover pounds for estimate, previous best and actual set.
- [Before renders](renders/session-1/before/): 72 captured before changes;
  the original source snapshot reproduced every PNG byte-for-byte. Sixteen
  supplemental captures cover share cards and missing estimates from that same
  pre-change source. [Supplement log](baseline/2026-10-02/session-1-before-supplement.log).
- [After renders](renders/session-1/after/): 264 synthetic, real Inter/Material
  font PNGs at 390×844, six palettes and 1.0×/1.6×, including empty/low-data/error.
  Share export retains its fixed 360×640/no text scaling contract; those pairs do
  not demonstrate scalable export typography. Device media is absent.
- New Session 1 goldens compare real glyphs without masking; existing golden
  suites were refreshed for shared-token effects. Legacy Alchemist CI masked
  goldens remain supplemental geometry checks, not typography evidence.
- [Composed contrast report](session-1-CONTRAST.md) and full call-site inventory:
  all live tertiary roles use the raised token; worst tested backing is 5.250:1.
  Purple onAccent/base is 4.517:1 versus 4.393:1 before.
- build_runner succeeded after provider/DAO changes, as repo instructions require.
  Local verification and [independent candidate review](reviews/session-1/iteration-1/)
  completed as recorded below. No commit or push was made.

Candidate 1 verification passed: format (362 files, zero changes), fatal analysis,
custom_lint and **1,101 tests**. [Preserved candidate 1 log](baseline/2026-10-02/session-1-iteration-1-verify.log).
Two preceding verify attempts stopped on new-file lint issues; those were fixed,
not suppressed. Initial whole-suite failures also identified obsolete goldens and
legacy estimate expectations; the added header label caused a geometry regression
and was removed rather than relaxing the existing geometry guard.

[Independent verdict 1](reviews/session-1/iteration-1/VERDICT.md): **Revision
needed**, 5.4 before → **6.4 after** overall. Measurement summaries, PR fact/estimate
separation and reference contrast scored **8 each** with named render/diff evidence.
These are micro-element scores, not replacement whole-audit section scores. The
critic found existing profile large-text tick collisions and detail DURATION
word splitting, plus a new missing-estimate empty-copy regression.

Iteration 2 tries a different state explanation, instead of treating an absent
estimate as an empty history. Three candidates: (A) explicit unavailable-estimate
copy pointing to existing logged metrics; (B) automatically select Heaviest
Weight; (C) synthesize an estimate from aggregate history. Choose A: it preserves
the selected metric and known history. Reject B because it changes user intent;
reject C because aggregate reps/weight are not evidence of the source set.
[Failing copy test](baseline/2026-10-02/session-1-iteration-2-red.log) precedes the
new copy, [24 focused checks pass](baseline/2026-10-02/session-1-iteration-2-green.log),
and 12 all-palette missing-estimate real-font goldens/renders were refreshed.
Candidate 2 received a new fresh-context critic; its cumulative packet contains
no prior verdict or builder discussion. Verification completed after this truth
change. Candidate 1 evidence is preserved separately.

Candidate 2 verify passed all 1,101 tests. [Preserved log](baseline/2026-10-02/session-1-iteration-2-verify.log).
[Independent verdict 2](reviews/session-1/iteration-2/VERDICT.md) remains **Revision
needed**, overall **6.2**. It confirms the unavailable-estimate state fix and
retains 8/10 micro scores for summaries, estimate presentation and reference
visibility. Its diff review catches a new dimensional error: duration records
carry seconds in the legacy reps slot; a generic export suffix could multiply
75 seconds by 75 as if it were a rep count.

Iteration 3 uses explicit record dimensions at the card-model boundary. Three
candidates: (A) gate rep suffixes to weighted categories and preserve recorded
distance/pace units; (B) remove every suffix, losing actual weighted-set evidence;
(C) infer dimensions from a generic legacy reps field. Choose A; reject C because
the field also carries seconds, and B because it discards useful logged detail.
[Red tests](baseline/2026-10-02/session-1-iteration-3-red.log) reproduce the duration
suffix and distance/pace label faults before these fixes. Estimated set evidence
is generated only for estimates, never by converting metres to kilograms.

Two touched export claims also become factual "LOGGED RECORD" / "LOGGED RESULT"
instead of "OFFICIAL RECORD" / "VERIFIED ON-DEVICE", preceded by a
[failing copy check](baseline/2026-10-02/session-1-iteration-3-copy-red.log). The
alternative of a softer verification claim was rejected because no independent
native verification basis exists; removing the footer would lose attribution.
The unrelated example reassurance in the synthetic role specimen is not a
verified guarantee; product reassurance claims still require their own evidence.

[27 focused checks pass](baseline/2026-10-02/session-1-iteration-3-green.log).
Before evidence now totals **112** PNGs (24 additional non-weighted exports from
the original source); after evidence totals **336**, including duration and
distance in all three variants, every palette and both viewport text scales.
All 108 share renders/goldens and affected legacy share goldens were refreshed.
The 1.6× export labels still represent the fixed-scale export contract.
Candidate 3 received a new isolated critic, with no prior reasoning or verdict;
verification completed after the dimensional/copy changes. Existing chart,
detail-label and Technical-footer layout issues are deferred to the owner scope
question above, not counted as passed.

Candidate 3 verify passed **1,176 tests**. [Preserved log](baseline/2026-10-02/session-1-iteration-3-verify.log).
The [third independent verdict](reviews/session-1/iteration-3/VERDICT.md) is
**Revision needed**, overall **6.8**. It confirms the corrected duration export
and record claims, but identifies lost pace precision in the actual DAO `s/m`
path; the previous synthetic `s/km` test missed that representation.

Iteration 4 tries a different measurement representation, rather than adding
decimal places to a raw storage ratio. Three candidates: (A) reuse the existing
nearest-second `MM:SS /km` pace formatter for cards and visible/spoken celebration
values; (B) preserve four raw `s/m` decimal places; (C) keep one raw decimal.
Choose A for quick reading and consistency with logged distance history. Reject
C because 0.1875 s/m becomes 200 instead of 187.5 seconds/km; B preserves storage
precision but makes the result harder to interpret mid-workout. Current/previous
spoken pace must name minutes, seconds and kilometres. The
[red checks](baseline/2026-10-02/session-1-iteration-4-red.log) reproduce the real
DAO unit, collapsed pace exports and unconverted celebration before this fix.
This is the final allowed iteration; inherited layout issues remain deferred.

[29 focused checks pass](baseline/2026-10-02/session-1-iteration-4-green.log),
including visible and semantic current/previous pace. Before evidence now totals
**128** PNGs, with actual DAO-unit pace captures from the preserved original
source; after evidence and unmasked real-font goldens total **384**. The 48 new
pace renders cover celebration and all three export variants across six palettes
at both text scales. Pace uses the existing nearest-second display convention,
not raw one-decimal `s/m` precision. [Render log](baseline/2026-10-02/session-1-iteration-4-renders.log).

The first final verify attempt had clean fatal analysis, then Flutter telemetry
threw a network exception. [Preserved failure log](baseline/2026-10-02/session-1-iteration-4-verify-analytics-failure.log).
The rerun suppresses telemetry with process-local `FLUTTER_SUPPRESS_ANALYTICS=true`
and restores its prior value; no persistent tool configuration or gate was changed.
Candidate 4 verification passed (exit 0): token guards, **362 files** formatted
with no changes, fatal analysis, custom_lint and **1,226 tests**, including all
384 real-font goldens. [Final verification log](baseline/2026-10-02/session-1-iteration-4-verify.log).
[Final source integrity](baseline/2026-10-02/session-1-integrity.txt) confirms no
unexpected changes to original Dart sources, unchanged dependency files, and
unchanged AUDIT/PROTOCOL hashes.

The final [independent verdict](reviews/session-1/iteration-4/VERDICT.md) is
**Revision needed**, **4.6 before → 6.6 after** overall. Information truth is
**8/10**; reference text, estimate/logged separation, measurement units,
missing-estimate state and neutral deltas each score **8/10** with named evidence.
These are scoped scores; full audit section scores remain unevaluated.
Chart labels score **3**, Technical footer **4**, detail label layout **5**,
and error-information truth **3**. No new blocking task/data failure was established.

The critic caught mismatched supplemental pace before fixtures. Those original
packet images are preserved and excluded; corrected Run captures now live in
`renders/session-1/before/` and packet `before-corrected-pace/`. The
[same-critic addendum](reviews/session-1/iteration-4/ADDENDUM.md) confirms matched
evidence, with unchanged score/verdict. Only the capture harness was corrected;
candidate source and after evidence were unchanged. This was evidence repair,
not a fifth implementation iteration.

Four implementation iterations are exhausted. Scoped corrections are locally
verified; whole-section acceptance is **not** claimed. Layout redesigns remain
outside the owner's session scope. Android baseline build, pushed CI and physical
device/native qualification remain unresolved. No commit or push was made.

Self-critique, comparing before and after:

1. The figures now describe the recorded measurement and chosen unit, but mixed
   sessions still expose only one primary measure. Rep totals hide alongside
   weighted volume, and distance-session elapsed/recorded time are not both
   summarized in the active header. A richer summary needs a later scoped design.
2. Tertiary text is readable across evaluated backings, but it shares the secondary
   luminance floor. Tiny chart/share metadata and existing large-text chart/header
   constraints still rely on typography and placement for hierarchy. The existing
   Technical share-card footer/witness overlap is visible and remains a weakness.
3. Synthetic render tests do not qualify physical TalkBack, native media, haptics,
   save-failure navigation or native share/export. Existing SkeletonPulse reduced-
   motion disposal failure means detail/error fixtures use normal motion; no
   reduced-motion/device acceptance is claimed for those surfaces.
   The inherited generic read-error reassurance also claims data is safe without
   an evidenced storage-integrity check; brighter text does not validate it.

Builder proposal: **8/10 for the Session 1 correctness changes**, justified by
unit/measurement assertions, explicit estimate evidence and measured contrast.
This is not a whole-section score increase or an independent acceptance. Remaining
scope outside correctness and native/CI/build gaps prevent Accepted status.

## Session 1 follow-up — error reassurance only

The owner authorized a separate small fix pass after the four Session 1
iterations: unsupported error/save reassurance only, failing tests first,
verification, no self-score and no layout changes. The latest critic's
unsupported data-safety finding is the trigger. This pass does not reopen
the chart/footer/detail redesign scope.

Candidates: (A) describe the observed read/sync failure and retain existing
recovery controls; (B) add conditional safety wording backed by a new integrity
probe; (C) remove the error message entirely. Choose A. Reject B because this
pass authorizes wording, not new persistence logic, and C because the lifter
would lose context for retry. Storage explanations must qualify a successful
save and optional cloud sync, rather than promise instant writes or backups.

Before evidence: 390×844 with real Inter, Volt/Purple, 1.0×/1.6×, using live error
widgets and synthetic failed providers. The inherited Settings sync-title row
overflows by 72px for Pro / 77px for free at 1.6×; the capture harness records that exact known defect
instead of certifying the layout. Dialog copy is opened through its existing
callback; touch behavior is unverified. All-palette after goldens will compare
unmasked text. [Failing assertions](baseline/2026-10-02/reassurance-red.log) cover
default/fallback/workout/routine error wording, offline sync and storage copy.
No score is proposed for this pass.

Iteration 2 addresses the critic's remaining unconditional Pro heading. Three
copy candidates: (A) “Local storage and cloud sync”; (B) “Cloud backup available”;
(C) “Your data storage.” Choose A because it names both available mechanisms
without asserting a completed backup. Reject B because it overemphasizes cloud
protection when offline, and C because it hides the distinction the body explains.
The [heading red test](baseline/2026-10-02/reassurance-heading-red.log) fails on
“cloud-backed” before replacement. No layout changes were made.

The completed copy removes unsupported guarantees from generic/fallback,
workout-detail and routine-history read errors; offline sync no longer asserts
a successful save/future backup; sync errors no longer promise automatic retry.
Storage explanations now qualify successful local saves and enabled/connected
optional cloud sync. The Pro heading names mechanisms without claiming a backup.
[12 focused checks pass](baseline/2026-10-02/reassurance-green.log), including
the existing three fail-closed persistence checks. Before evidence totals 36 PNGs;
after evidence and real-font goldens total 108, covering all six palettes.
Existing detail-error/reference-role goldens were updated for the changed copy.

The [first critic](reviews/session-1-reassurance/iteration-1/VERDICT.md) incorrectly
reported missing content in three intact PNGs. Its preserved
[addendum](reviews/session-1-reassurance/iteration-1/ADDENDUM.md) withdraws that
finding after reopening the unchanged evidence. The
[second fresh critic](reviews/session-1-reassurance/iteration-2/VERDICT.md) gives
**6.4 overall / 8 for information truth**, **Revision needed** for inherited
large-text defects, with no established new material regression. Layout changes
remain explicitly outside this authorized wording pass. No builder score is given.

Remaining weaknesses after the copy correction:

1. The Settings sync heading still overflows at 1.6× and the dialog confirmation
   label clips; these were present before and need a later layout scope.
2. A generic sync error has no evidenced dedicated retry control or last-backup
   state. The shorter copy avoids claiming a retry; recovery behavior remains
   unverified rather than being inferred from a message.
3. Synthetic callbacks/rendered controls do not establish native taps, TalkBack,
   corrupt-database recovery, successful backup or restore across devices.

The wording question is closed by removing the unsupported assurance, not by
asserting an integrity check. Device/recovery and layout qualification remain open.

[Final wording-pass verification](baseline/2026-10-02/reassurance-verify.log)
passed with exit 0: token guards, 365 formatted Dart files, fatal analysis,
custom_lint and **1,342 tests**, including all 108 new unmasked real-font goldens.
AUDIT.md and PROTOCOL.md retain their original SHA256 values. Intermediate
fixture lint failures are preserved; corrections only make the fake sync phase
private and document the deliberately overridden generated provider in the test
root scope. No production provider declaration or validation gate was changed.

The scoped commit candidate was reconstructed over HEAD using only this session's
delta against the original dirty-working-tree snapshot. Related share-card model
and wrapper prerequisites are included; unrelated pre-existing edits remain in
the working tree. Its isolated
[verify run](baseline/2026-10-02/session-1-commit-verify.log) also passed with
**1,327 tests**, fatal analysis and custom_lint. The working tree's 1,342 count
includes additional pre-existing tests not included in this scoped commit.
The owner authorized committing these locally verified corrections. Pushed CI,
device acceptance and deferred layouts are still unverified; no push is requested.

## Open questions for owner

- Which physical Android device and TalkBack configuration should qualify spoken
  units, 1.6× text, reduced motion and haptic behavior? Device evidence is pending.
- Which later scope should address the existing Technical share-card footer overlap
  and SkeletonPulse reduced-motion disposal failure? They are outside this session.
- The independent critic also requests profile-chart label density/width and
  workout-detail label wrapping fixes at 1.6×. Which subsequent layout scope should
  own those baseline defects? Session 1 explicitly forbids layout redesigns, so
  those changes are deferred instead of guessed.
## Shared token changes

- Session 1: dark textTertiary changes from 0x59FFFFFF (~35%) to 0x99FFFFFF (60%).
  chartAxisLabel and profileGraphAxisLabel alias this token instead of keeping
  independent faint values. This affects metadata, ticks, hints, reassurance,
  shared controls and share witnesses throughout audit sections 1–20; those
  sections are not fully accepted on the strength of a shared-token check.
- Session 1: Purple base changes #BF00FF → #C400FF. Muted/glow and muscle-ramp
  first step follow; light/dark companions and near-black onAccent stay the same.
  All six palettes retain the dark OLED canvas. No light-mode rollout occurred.
