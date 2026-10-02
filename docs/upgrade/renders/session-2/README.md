# Session 2 render evidence

The `options/` captures are **static, synthetic Flutter concepts for the owner's
pick**. Production code was unchanged when those concepts and `before/` were
captured. Buttons and selectors in the concepts deliberately have no behavior.
The owner selected A. Live implementation captures are now in `after/`.

All original PNGs are 390 × 844 app viewports. Screenshots use bundled Inter
Regular, SemiBold and Bold, Material icons, OLED canvas and existing accent and
surface tokens. Text is actually rendered; it is neither masked nor replaced.
Platform status/navigation bars, keyboard and hardware are not simulated.

| Evidence | Images |
|---|---|
| Current live widgets | [Normal](before-1.0x.png), [1.6×](before-1.6x.png) |
| All Home options | [Normal](home-options-1.0x.png), [1.6×](home-options-1.6x.png), [scrolled](home-options-below-fold-1.0x.png) |
| All Library options | [Normal](library-options-1.0x.png), [1.6×](library-options-1.6x.png), [scrolled](library-options-below-fold-1.0x.png) |
| A: chosen routine | [Pair](chosen-pair-1.0x.png), [1.6×](chosen-pair-1.6x.png), [Purple](chosen-pair-purple.png), [Home states](chosen-home-states.png), [Library states](chosen-library-states.png) |
| B: explained rotation | [Pair](sequence-pair-1.0x.png), [1.6×](sequence-pair-1.6x.png), [Purple](sequence-pair-purple.png), [Home states](sequence-home-states.png), [Library states](sequence-library-states.png) |
| C: choose each session | [Pair](chooser-pair-1.0x.png), [1.6×](chooser-pair-1.6x.png), [Purple](chooser-pair-purple.png), [Home states](chooser-home-states.png), [Library states](chooser-library-states.png) |

## Fixture provenance and limits

The example is dated 2 October 2026. It includes three saved program routines
(Push A, Pull A, Legs A), Full Body and Outdoor walk. The sample program has
explicit membership/order metadata. Focus tags and exercise counts are known
fixture data. Weighted sample plans specify three planned sets per exercise;
15 planned sets is a plan total, not a logged total. The one-exercise walking
plan has no focus tags, planned-set total or logged result to display.

Synthetic logged evidence: Push A on 28 September, Bench Press 60 kg × 8;
Pull A on 30 September, Lat Pulldown 50 kg × 10; Legs A on 26 September,
Squat 80 kg × 5. The most recent session is Pull A, 48 minutes, five exercises,
3,850 kg logged volume. The inactive fixture changes those dates to 12, 14 and
9 September respectively, with 18 days since the latest session. These example
sets in the concept are not queries against an actual user's database. Before
renders override the live widgets' routine/history/streak providers with the
same synthetic plan/session facts; the current app still determines its greeting.

A assumes the owner of the sample library already chose Push A for Home. C shows
Push A **after a deliberate selection for this session**; it does not propose
silently selecting the first row. B shows a suggestion justified by known saved
order and the last linked session. Order is not a calendar, recovery estimate,
readiness assessment or recommendation to increase load.

Empty means no routines or history. No-routine means history exists but no saved
routine exists. Low-data means a walking plan exists with no history. Error
means both sample reads fail; it is distinct from an empty result. All three
options intentionally share truthful fallback actions. Separate routine/history
loading and partial failures still need behavior tests after the owner picks.

## Coverage and reproduction

Before: all six states, both screens, Volt/Purple, 1.0×/1.6×, plus returning-user
scroll views. Concepts: all six states and both text scales in Volt; returning
screens in Purple at both scales; returning-user scroll views in both palettes.
[Inventory](inventory.json): 56 before PNGs, 108 concept PNGs, 25 contact sheets.
Contact sheets only add labels around unchanged screenshot pixels.

```powershell
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:SESSION_2_SAVE_RENDERS = '1'
flutter test test/upgrade/session_2_render_test.dart
python docs/upgrade/renders/session-2/compose.py
Remove-Item Env:SESSION_2_SAVE_RENDERS
```

132 capture checks passed, including concept render-exception checks before and
after scrolling. No baseline render exceptions were collected. This is geometry
evidence, not verification of selection, persistence, Start, routing, spoken
values, motion or real device behavior. These PNGs are option evidence, not
accepted production goldens. Failing production behavior tests and every affected
palette's production goldens wait for the owner's selection.

## Implemented A

The immutable `before/` PNGs remain the pre-build baseline. `after/iteration-1/`
preserves the first live candidate; `after/iteration-2/` captures state-specific
recovery: empty Library browses programs first, an emptied chosen routine keeps
its name/date and offers Add exercises, and a Library read failure has one Retry.
`after/iteration-3/` records the compact Library candidate. `after/iteration-4/`
prioritizes the named active session, separates the routine choice for later,
and allows explicit selection to repair a damaged saved choice. No text is masked.
All **528 final screenshots** are 390 × 844, using
Inter and Material icons at 1.0× / 1.6× in all six palettes. They also back 528 PNG
goldens under `test/upgrade/goldens/session-2/`; the render file has 456 widget
tests plus 72 extra chooser, search, paging, History and Library-scroll comparisons.

- [Home and Library](implemented-a-1.0x.png), [1.6×](implemented-a-1.6x.png),
  [Purple](implemented-a-purple.png).
- [Change chooser](implemented-chooser-1.0x.png), [1.6×](implemented-chooser-1.6x.png).
- [Home choice recovery](implemented-home-choices-1.6x.png),
  [Library choice recovery](implemented-library-choices-1.6x.png).
- [Home data states](implemented-home-states-1.6x.png),
  [Library data states](implemented-library-states-1.6x.png).
- [Home comparison](implemented-home-comparison.png),
  [Library comparison](implemented-library-comparison.png), [inventory](after-inventory.json).
- [History tap and Library scroll](implemented-scroll-1.6x.png),
  [chooser interactions](implemented-chooser-states-1.6x.png),
  [active Home](implemented-home-active-1.6x.png),
  [active Library](implemented-library-active-1.6x.png).
- [Active Home choice recovery](implemented-home-active-recovery-1.6x.png),
  [active Library choice recovery](implemented-library-active-recovery-1.6x.png).

Nineteen live states per screen: chosen, no choice, deleted choice, emptied choice,
new user, retained history without routines, inactive return, low data, read
error, previous-set error, choice-storage error and loading. Choice error uses
a wrong-type preference to exercise a real read failure. Seven additional active
session states cover chosen, no choice, no routines, read failure, deleted choice,
emptied choice and damaged choice storage. Inactive return uses
18 days since the last completed workout and 20 days since Push A. Only the
chooser labels a next-program suggestion; the checked choice remains Push A.
The walking fixture has an actual one-set configuration, displayed on Home as
`1 planned set`; this is planned metadata, not a completed set or logged result.
The compact Library choice keeps name, last-trained age, Chosen on Home and Start;
counts/focus/preview remain in the ordinary routine cards and detail view.
Home and Library show the same HOME ROUTINE marker from one saved provider.
Only Home offers the chooser. The sheet explicitly says it controls the routine
shown on Home, and a program-order suggestion is labeled within its own row.
Library recovery has compact guidance, with the first saved Start visible at
1.6× for no choice, deleted choice and damaged choice storage.

```powershell
$env:SESSION_2_SAVE_AFTER = '1'
$env:SESSION_2_ITERATION = 'owner-fix-4'
flutter test test/upgrade/session_2_acceptance_render_test.dart --update-goldens
Remove-Item Env:SESSION_2_SAVE_AFTER
Remove-Item Env:SESSION_2_ITERATION
python docs/upgrade/renders/session-2/compose_after.py owner-fix-4
# Compare without regenerating expectations:
flutter test test/upgrade/session_2_acceptance_render_test.dart
```

Original implementation validation ran in the recorded pre-session baseline plus
Session 2 changes in an isolated workspace, as requested by the owner. The owner
then requested real-workspace integration. Code generation, the final debug APK,
and `verify.ps1` with **2,008 tests** passed there. The final independent critic
marked both screens **Pass**, scoring Home **7.8** and Library **7.6**:
[frozen verdict](../../reviews/session-2/iteration-7/VERDICT.md). Per-check scores,
audit comparisons and final build/test logs are recorded in the [ledger](../../LEDGER.md).
The owner-fix-4 captures and current goldens are generated in the real workspace.
Concurrent PR-model/DAO/configuration edits are excluded from the Session 2 commit.
The fixture providers do not read an actual account's database. Native system
bars, keyboard, TalkBack, haptics and physical-device behavior remain unverified.
Loading captures retain normal motion because the existing shared SkeletonPulse
has a known reduced-motion disposal defect outside this session. The screenshots
do not qualify animation or reduced motion. Contact sheets label original pixels
without scaling, editing or obscuring the app screenshots.

The original isolated `verify.ps1` passed with 1,979 tests. All 456 final real-font
render cases now also inspect raster foreground ink in headings and navigation,
plus the chosen Home Change control. Goldens and after captures are identical
unmasked PNGs. Review packets are frozen separately; packet 4's recovery regression
was fixed in owner-fix-2, and its disputed missing-paint allegations are preserved
with small original-pixel inspection crops. The empty Library plan uses just one
HOME ROUTINE marker and says to choose another on Home. Latest independent scores and final
gate results are in the ledger. No self-score or native/CI acceptance is claimed.
