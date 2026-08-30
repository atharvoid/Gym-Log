# Bugfix Plan — 2026-08-30 (Onboarding / Auth / PR Celebration / Edge-to-edge)

> Companion to AGENTS.md. Five minimal-but-visible defects reported from device
> screenshots. Every fix is root-cause-driven (first-principles), spec-first
> (failing test before code), and gated by `.\scripts\verify.ps1` + goldens.
>
> **STATUS: IMPLEMENTED 2026-08-30** — all fixes landed, `verify.ps1` passes
> (746 tests), goldens generated/regenerated. Regression entries in
> `LOOP_LOG.md`. Two scope extensions from test findings: all 7 onboarding
> steps wrapped in a scrollable `StepScrollView` (Spacer columns overflowed at
> large text scales on short viewports), and the PR card title/meta capped.

---

## Root causes (research summary)

### Bug 1 — Age "100" wraps into "10" + "0" (Screenshot 1)
**File:** `lib/features/auth/presentation/widgets/onboarding/step_age.dart:114-125`

The age is a `Text('$currentAge')` at **72px / w800** inside a hard `SizedBox(width: 100)`.
At 72px, three Inter w800 digits need ≈126px of glyph width ("100" ≈ 42px/digit).
`Text` wraps instead of clipping → "10" on line one, "0" on line two. Larger
system text scales make it strictly worse.

**First-principles fix:** the stepper must be a *single-line metric* whose size
adapts to the viewport. `heroStat` already carries tabular figures, so every
digit has the same advance width and "100" is exactly 3 × that width (~130px at
72px) — i.e. the fixed `100`-wide slot is simply too narrow for 3 digits. Fix:
- Widen the number slot to fit three tabular digits at full size (`width: 132`),
  so "99"→"100" doesn't visibly shrink (uniform digit size across the range).
- Wrap the text in `FittedBox(fit: BoxFit.scaleDown)` so it degrades gracefully
  (single line, no wrap) on the narrowest screens (320pt) and at large text
  scales — the ONLY time it shrinks is when the viewport genuinely can't fit.
- Compensate the wider slot by tightening the two `SizedBox(width: 40)` side
  gaps to `16` (buttons stay 64). Total at 360pt: 64+16+132+16+64 = 292 ≤ 312 ✓;
  at 320pt the FittedBox absorbs the 20pt deficit, never wraps.

---

### Bug 2 — "2 of 1 workouts completed" (Screenshot 2)
**File:** `lib/features/auth/presentation/widgets/onboarding/step_weekly_goal.dart:22-24,70`

The preview hardcodes `completed = 2` and only clamps the **ring**:
`(2 / current).clamp(0.0, 1.0)`. The caption text interpolates the raw values
(`'2 of $current workouts completed'`) so at goal=1 it reads "2 of 1" while the
ring is at 100% — internally inconsistent, and "1 workouts" is wrong grammar.

**First-principles fix:** preview state must be a single source of truth —
`completed = min(2, goal)`; ring progress, caption numerator, and
singular/plural all derive from it. A preview can never show more completed
workouts than the goal it previews.

---

### Bug 3 — Legal links "pop above" the sentence (Screenshot 3)
**File:** `lib/features/auth/presentation/screens/auth_screen.dart:296-331, 574-616`

Each `_LegalLink` wraps its text in `Container(minHeight: 48, padding: vertical 8)`.
Inside the centered `Wrap`, every run becomes 48px tall. Plain-text runs are
vertically centered against the 48px boxes → the link baselines sit ~9px higher
than the sentence baseline ("popped above"), and the wrapped second line
("Privacy Policy .") lands ~35px below line one — a broken, gappy paragraph.

The 48dp boxes exist to satisfy a11y target-size tests
(`test/accessibility_target_size_test.dart:103-137`, `auth_screen_behavior_test.dart`
AUTH-15), but they corrupt the typography. **The constraint (48dp per inline
caption link) is the bug.** Inline links are links, not buttons; platform
guidance (HIG/WCAG 2.5.5 exceptions for inline text) accepts glyph-size targets.

**First-principles fix:** render the legal sentence as ONE inline-flowing
paragraph — `Text.rich` with two `TextSpan`s carrying `TapGestureRecognizer`s,
underline, and the same caption style. Baselines align by construction; the
sentence flows naturally onto 1–2 lines. Semantics: RenderParagraph publishes a
per-span node for spans with recognizers; tests are updated to assert
`isLink` + tap activation on the spans instead of box height.

---

### Bug 4 — PR celebration "Keep Going" clipped (Screenshot after finish)
**File:** `lib/features/workout/presentation/widgets/pr_celebration_overlay.dart:100-283`

`showGeneralDialog`'s `pageBuilder` returns the card inside `Center`. The card
has **no max-height, no scroll, no SafeArea** (only the inner PR list is capped
at 240px). On short viewports (568–640pt), large text scale, or many PRs, the
card paints past the screen bottom → the "Keep Going" CTA is cut off; on
edge-to-edge devices it also collides with the system nav bar.

**First-principles fix:** a celebration dialog must always fit the viewport,
keep the CTA *visible* (not merely reachable), and respect system insets:
1. `ConstrainedBox(maxHeight: viewport − safe insets − margin)`
2. Card `Column`: static header, `Flexible(SingleChildScrollView(PR rows))`,
   pinned CTA at the bottom
3. `SafeArea` around the card content

---

### Bug 5 — 3-button nav: layout doesn't hold on some devices (Screenshot 4)
**Files:** `lib/features/auth/presentation/screens/onboarding_screen.dart:120-235`,
`android/app/build.gradle.kts:42` (targetSdk = 36)

**Root cause chain (first principles):**
- targetSdk 36 → Android 15+ (API 35) **enforces edge-to-edge**: the app window
  extends behind a transparent system nav bar, and the OS draws a light/dark
  scrim strip over the app's bottom on 3-button devices.
- The onboarding body (`PageView` of steps) has **no bottom `SafeArea`** — each
  step ends with `PrimaryButton` + 16px, so on edge-to-edge devices the CTA
  rides against/behind the nav bar strip (white-on-black in screenshot 4).
- Onboarding's `AnnotatedRegion` sets only the status bar — on pre-SDK35
  devices the nav bar keeps the OS default (white) against the pure-black app.
- Gesture-nav devices don't show the scrim, which is why "some devices" break
  and others don't.

**Fix:** every full-screen route must (a) pad content above the bottom inset
via `SafeArea`, and (b) declare a consistent nav-bar style for legacy devices
(mirror `auth_screen.dart:119-127`). Applies to: onboarding body, PR
celebration dialog.

**Scope confirmation (re-checked):** the app shell already handles this —
`app_shell.dart:232` wraps its body in `SafeArea` and `bottom_nav_bar.dart:32`
adds `viewPadding.bottom`; the same is true of home/profile/settings/routine/
workout screens. `auth_screen.dart` already uses `SafeArea` + nav-bar color.
Onboarding is the single full-screen CTA route missing BOTH — the one outlier.
The global `appBarTheme.systemOverlayStyle` (`app_theme.dart:96`) only stamps
the status bar, so nav-bar color is genuinely unset app-wide except on auth —
but that only *visibly* matters on routes with bottom CTAs (onboarding).

---

## Implementation plan

### Phase 1 — Spec-first tests (RED)

New tests (written first, failing):

| Test file | Verifies |
|---|---|
| `test/features/auth/onboarding_age_step_test.dart` | Age renders on ONE line for 14…100 at 320×568 → 430×932 and textScale 1.0/1.3/2.0; "100" never wraps; decrement disabled at 14, increment at 100 |
| `test/features/auth/onboarding_weekly_goal_step_test.dart` | For goal 1→7: caption shows `min(2,goal)` of `goal`, ring progress == completed/goal, grammar "1 workout" vs "N workouts"; tapping segment 1 updates caption |
| `test/features/workout/pr_celebration_overlay_test.dart` | 8 PRs on 320×568 @ textScale 1.3 and 1.0: `Keep Going` fully inside viewport; SafeArea respected; tap dismisses; 390×844 unchanged |

Updated tests (new expectations, still RED until fixes land):

- `test/auth/auth_screen_behavior_test.dart` — AUTH-12: assert `isLink` + tap
  semantics on the legal-link span nodes (helper walking `tester.allSemantics`);
  AUTH-15: keep 48dp assertions for buttons, replace the inline-link height
  check with "inline links expose link semantics + tap action".
- `test/accessibility_target_size_test.dart` — same for the `_LegalLink`
  section (legal paragraph flows as text; buttons remain ≥48dp).

### Phase 2 — Fixes (GREEN)

1. **Weekly goal** (`step_weekly_goal.dart`) — `completed = min(2, current)`;
   caption derives from it with singular/plural.
2. **Age stepper** (`step_age.dart:114-125`) — widen the number slot to `132`,
   wrap the text in `FittedBox(fit: BoxFit.scaleDown, Text(maxLines: 1))`, and
   tighten the side gaps `40 → 16` (buttons unchanged). Single-line at any size.
3. **Legal block** (`auth_screen.dart`) — single `Text.rich` paragraph with two
   recognizer spans; dispose recognizers in a small stateful widget; keep
   `_LegalLink`-style underline + caption color; keep `Semantics(link)`-style
   exposure per span; hover cursor via `MouseRegion`. (The settings-screen
   "Terms of Service" is a plain `ListTile` — unrelated, untouched.)
4. **PR celebration** (`pr_celebration_overlay.dart`) —
   `SafeArea` + `ConstrainedBox(maxHeight)` + `Flexible` scroll region + pinned CTA.
5. **Edge-to-edge** (`onboarding_screen.dart`) — wrap `PageView` body in
   `SafeArea(top: false, left: false, right: false, bottom: true)`; extend
   `SystemUiOverlayStyle` with `systemNavigationBarColor: surface.bgBase` +
   icon brightness (mirrors auth). App shell already safe — no other route
   changes required.

### Phase 3 — Goldens & verification

- Regenerate all 14 `test/golden/goldens/auth_screen_*.png`
  (`flutter test --update-goldens test/golden/auth_screen_golden_test.dart`).
- New goldens per DoD (every affected accent theme):
  - `step_age` + `step_weekly_goal` across the 6 palettes (higgsfield, neonPurple,
    neonCyan, neonMagenta, blazeOrange, white) — new golden test files
    `test/golden/onboarding_steps_golden_test.dart`.
  - `pr_celebration_overlay` across the 6 palettes (CTA uses `accent.base`) —
    `test/golden/pr_celebration_golden_test.dart`, including a small-viewport
    variant proving the CTA is on-screen.
- `.\scripts\verify.ps1` (format → analyze → custom_lint → flutter test).
- `docs/LOOP_LOG.md` entry (regressions fixed, per DoD).
- CI Gate green on the pushed branch.

### Order of execution

Tests → bug 2 → bug 1 → bug 3 (+ goldens) → bug 4 (+ goldens) → bug 5 →
golden regeneration → full verify → LOOP_LOG → commit.

### Risks / notes

- AUTH-12's span-semantics assertions depend on RenderParagraph publishing
  per-span nodes. If the framework node lacks `isLink`, fall back to asserting
  the span's tap action + `semanticsLabel` and keep a single
  `Semantics(container)` label on the paragraph — the visual/reading fix is
  unaffected.
- Adding bottom `SafeArea` to onboarding shifts steps up on inset devices;
  steps use `Spacer`s (deficit-absorbing), so no overflow is expected at
  320×568 / textScale 2.0 — guarded by the age/onboarding tests.
- Golden PNG churn is expected for auth goldens (legal paragraph pixels move).
- `systemNavigationBarColor` is ignored on SDK 35+ by design; the SafeArea pad
  is the real fix there, the color only targets legacy devices.