# Home and Routines — one visual direction for approval

4 October 2026. **Review prototype; application implementation awaits the
owner's visual approval.** The plan is approved to proceed. No production route,
preference, DAO, shared token or workout data has been changed by this preview.
The rejected Session 3 options remain withdrawn.

## Review the direction

- [Home, current / proposed](home-comparison-1.0x.png)
- [Routines, current / proposed](library-comparison-1.0x.png)
- [Home at 1.6×](home-comparison-1.6x.png) and [2×](home-comparison-2.0x.png)
- [Routines at 1.6×](library-comparison-1.6x.png) and [2×](library-comparison-2.0x.png)
- [One-session override, keyboard closed/open](override-keyboard-1.0x.png)
- [Override at 1.6×](override-keyboard-1.6x.png) and [2×](override-keyboard-2.0x.png)
- [Training-plan chooser](candidate/plan-chooser-closed-higgsfield-1.0x.png)
  and [with keyboard](candidate/plan-chooser-keyboard-higgsfield-1.0x.png)
- [Next routine after View next](candidate/library-next-higgsfield-1.0x.png)
- [Resume at 2×](candidate/home-active-higgsfield-2.0x.png)
- [After completed Legs A](candidate/home-completed-higgsfield-1.0x.png)
- [Non-weight latest workout](candidate/home-lowData-higgsfield-1.0x.png)
- [No selected plan](candidate/home-noPlan-higgsfield-1.0x.png),
  [first session](candidate/home-noHistory-higgsfield-1.0x.png),
  [empty library](candidate/library-empty-higgsfield-1.0x.png),
  [read error](candidate/home-error-higgsfield-1.0x.png), and
  [loading](candidate/home-loading-higgsfield-1.0x.png)

This is one coherent direction across two screens and their states, not another
A/B/C choice. Up next follows the saved program; Last workout represents actual
completed history. The fixture's latest program workout is Pull A, so the
proposal shows Legs A, while the committed screen still shows chosen Push A.

## Refinements considered

| Refinement | Decision and reason |
|---|---|
| Contained Up next and compact Last workout; next marker in the existing Library sequence | Present this direction. Preserves the card language, makes last/next distinct, restores Library actions and avoids a duplicate selected-routine hero. |
| Put last and next side by side | Reject. Two narrow cards squeeze names, supporting facts and touch targets on a phone; large text requires a second composition. |
| A separate next-workout banner above the Library | Reject. Repeats the same routine identity/control outside its actual card and takes space from New routine/Explore and the program list. |

The main hero omits an additional exercise preview: the full latest-workout
identity fits at normal text without another nested previous-set card. Detailed
history retains the app's real workout-history cards and thumbnail treatment.
Ordinary Library cards retain compact preview/Start footers at normal text and
stack at large text. Full routine identity and useful per-routine recency remain.

## What is real, and what is simulated

- Application source/theme/assets come from committed
  `f12e89664be6aa83d1c86fbfb258c32ea0d7c37a`, in the existing isolated worktree.
  No stash was applied, popped, modified or recreated.
- Real Flutter, bundled Inter, Material icons, `AppCard`, `PrimaryButton`,
  `StartButton`, `AppStatusTag`, shared press feedback, `WorkoutHistoryCard` and
  `BottomNavBar` are used. No image generation or alternate palette/font system.
- Routine-card and chooser composition is review-only code using the existing
  grammar. Buttons select fixtures, close sheets or show preview notices. The
  preview does not prove launch, save, preference migration, edit or reorder.
- All workout/program/metrics data is synthetic. The shared fixture clock is
  2 October 2026; the reviewed completion example is on that fixture day.
  Zero-weight history uses supported exercise count and elapsed duration.
- The committed RoutineCard uses the host clock rather than the fixture clock.
  Consequently its before-render recency can disagree with the committed
  launchpad. The proposal uses the fixed fixture clock. This known discrepancy
  is retained visibly, not painted over; concurrent clock fixes in the primary
  checkout are preserved for integration.
- The keyboard has a real **simulated 280dp viewInset** and an illustrative
  alphabetic silhouette. It is not a native Android/iOS IME. The search field
  and action are checked against the inset at each text scale.
- Bottom navigation is rendered. OS status/navigation chrome and physical
  safe-area/IME behavior are not reproduced by the test host. Native clearance
  remains a device check; these captures do not certify first-fold device fit.
- Ready/after-completion are separate fixture states, not a verified durable
  completion transition or recording of animation feel.

## Mini-player defect found in the reference

The real committed `ActiveWorkoutBar` fixes its height at 56dp. Including it in
the preview caused bottom overflows at 1.6× and 2×. The retained failed render log
records this; the assertion was not disabled. The review-only mini-player now
measures its existing text roles and grows, preserving the floating placement
and matching content clearance. Its timer is a constant fixture snapshot.

The approved implementation will need a small coordinated change to the actual
bar and shell/inset calculation. This is a documented dependency of the Home /
Routines correction, not a new active-workout-screen redesign or token migration.
The real component and its production motion/haptic behavior are unchanged now.

## Checks and their limits

The render test covers ready views in all six accents at 1×/1.6×/2×, normal
360/430px widths, current views in Volt/Purple, alternate states in Volt,
View next navigation, and both chooser purposes with keyboard-open states.
The focused checks include exceptions/overflow, 52dp button floors, normal-text
Start/Last visibility, and query/action bounds above the simulated keyboard.
Final result: **120 render checks pass; format (0 changed), fatal analysis and
custom lint pass.** These results apply to the review fixtures and baseline
source, not to an implemented correction.

[Render evidence](../../baseline/2026-10-04/home-routines-render-reviewed.log),
[static evidence](../../baseline/2026-10-04/home-routines-reviewed-analyze.log),
[custom lint](../../baseline/2026-10-04/home-routines-reviewed-custom-lint.log), and
[inventory](inventory.json) record exact results and hashes. Comparison boards
paste the raw captures without changing their pixels. Earlier failed attempts
remain in the baseline directory.

No acceptance goldens, production behavior tests, full `verify.ps1`, build, CI
or device acceptance are claimed at this visual gate. Those remain required for
the approved app implementation. The historical 8.5/10 is a plan assessment;
there is no final app score or independent acceptance score from this prototype.

Three remaining weaknesses: at large text the main card requires scrolling;
the next Library routine can need View next because saved order is preserved;
the compact Last workout summary repeats some information in the full feed.
These are visible tradeoffs for owner review, not demonstrated speed benefits.

**Haptics: unverified, needs device.**
**Timer feel: unverified, needs device.**
**One-handed use: unverified, needs device.**
Touch accuracy, native keyboard, screen readers and phone-on-bench/rack use also
remain unverified.

## Reproduce

Run from the attached isolated worktree at the committed baseline using Flutter
3.44.0 / Dart 3.12.0. Source snapshots are retained with the baseline evidence.

[Prototype composition source](../../baseline/2026-10-04/home_routines_correction_preview.dart.txt) ·
[Render harness source](../../baseline/2026-10-04/home_routines_correction_render_test.dart.txt) ·
[Source integrity](../../baseline/2026-10-04/home-routines-source-integrity.json) ·
[Check summary](../../baseline/2026-10-04/home-routines-preview-checks.json).

```powershell
flutter test --no-pub test/upgrade/home_routines_correction_render_test.dart --reporter expanded
flutter analyze --no-pub --fatal-infos --fatal-warnings
dart run custom_lint
```
