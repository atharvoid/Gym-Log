# GymLog — Loop Log

> Running, append-only record: *bug → root cause → the guard that now prevents it.*
>
> Every regression fix must add (a) a failing-first test that reproduces it and
> (b) a one-line entry here. This is the inner→outer hand-off: each session's
> lesson becomes the next session's guardrail.

---

## Format

```
| Date | Bug | Root Cause | Guard Added |
```

---

## Log

| Date | Bug | Root Cause | Guard Added |
|---|---|---|---|
| 2026-06-25 | CI never ran on `remediation/8-phase` — all v2–v9 regressions shipped without any gate firing | `ci.yml` triggered only on `push`/`PR` to `main`; working branches invisible | H1: widened CI triggers to `remediation/**` |
| 2026-06-25 | Agent declared "done" with no mechanical check — green suite said nothing about actual bugs | No local command mirroring CI; "done" was a feeling, not a measurement | H2: `scripts/verify.ps1` — the termination criterion |
| 2026-06-25 | Local `flutter analyze` weaker than CI — agent missed riverpod lint violations until push | `analysis_options.yaml` didn't register `custom_lint` plugin | H3: wired `custom_lint` into `analysis_options.yaml` |
| 2026-06-25 | Every theme/accent/layout regression (v2–v9) invisible to harness — only caught by human | Zero golden/screenshot tests in the suite | H4: added `alchemist` + seed golden test pipeline |
| 2026-06-25 | `AGENTS.md` said "only a default widget test" and "no CI/CD" — both false; agent misinformed | Guides never updated after test suite and CI were built | H5: rewrote `AGENTS.md`, `CLAUDE.md`; deleted wrong `STITCH_DESIGN_SYSTEM.md`; created `DESIGN_NORTH_STAR.md` |
| 2026-06-25 | `CLAUDE.md` said `npm run build && npm test` — for a Flutter app | Boilerplate from a different tool pasted into the repo | H5: replaced with real Flutter commands |
| 2026-06-25 | `STITCH_DESIGN_SYSTEM.md` described a light-mode smart-home app — agents steered 180° wrong | File was for a different product ("The Luminous Engine") | H5: deleted; replaced with `docs/DESIGN_NORTH_STAR.md` |
| 2026-07-08 | GIFs fail to load in small/thumbnail views | `ui.instantiateImageCodec` with `targetWidth` fails on animated GIFs | Decoded animated GIFs at native size in `gifFirstFrameProvider`/`gifLastFrameProvider` |
| 2026-07-22 | Phase 1–14 already committed on `fix-sha1-auth-issue`, not pending | GSD init assumed phases were future work; branch actually had all 14 atomic fix commits | H15: audit current HEAD against phase plan before assigning work — check `git log --oneline` |
| 2026-07-22 | Shell/nav used hardcoded `AppColors` instead of dynamic `context.surface` tokens | Static color references in `app_shell.dart`, `bottom_nav_bar.dart`, `active_workout_bar.dart` | H16: created `ChromeTokens`/`ChromeContextX` for chrome-specific dynamic color bundle; verify.ps1 enforces no `AppColors` in migrated screens |
| 2026-08-09 | Muscle load bar still hardcoded purple | Missed migration to context.accent in f01ed45 | H17: muscle_load_bar.dart added to $migratedFiles; accent + golden tests added |
| 2026-08-30 | Age "100" rendered as "10"+"0" (wrapped) | 72px w800 value locked in a 100px-wide slot — three tabular digits need ~130px | `onboarding_age_step_test.dart`: single-line assertion for 14–100 at every viewport/scale; FittedBox slot fix |
| 2026-08-30 | Weekly goal preview showed "2 of 1 workouts completed" | Hardcoded completed=2 clamped only the ring, never the caption | `onboarding_weekly_goal_step_test.dart`: caption/ring derive from `min(2, goal)` with singular/plural |
| 2026-08-30 | Legal links "popped above" the sentence with a ~35px gap between wrapped lines | Each `_LegalLink` box was minHeight-48 inside a centered Wrap → every run 48px tall | Inline `Text.rich` paragraph with recognizer spans; AUTH-12/15 + a11y test now assert per-span isLink+tap semantics |
| 2026-08-30 | PR celebration "Keep Going" cut off after finishing a workout | Dialog card had no max-height/scroll/SafeArea; title could blow past the viewport | `pr_celebration_overlay_test.dart` + goldens: SafeArea + max-height + Flexible scroll list + pinned CTA; title/meta capped |
| 2026-08-30 | 3-button nav: CTAs rode against/behind the system bar on Android 15+ | targetSdk 36 → enforced edge-to-edge; onboarding body had no bottom SafeArea and no nav-bar color | Onboarding body wrapped in `SafeArea(bottom)`, nav-bar color in AnnotatedRegion; all 7 steps scroll via `StepScrollView` |
