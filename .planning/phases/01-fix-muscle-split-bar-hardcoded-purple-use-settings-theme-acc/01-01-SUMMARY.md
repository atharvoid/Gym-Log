---
phase: 01-fix-muscle-split-bar-hardcoded-purple-use-settings-theme-acc
plan: 1
subsystem: routines-detail / muscle load bar theming
tags: [theme, accent, muscle-load-bar, golden, verify-gate]
requires: []
provides: [PH-1, PH-2, PH-3]
affects: [lib/shared/widgets/body/muscle_load_bar.dart, scripts/verify.ps1, docs/LOOP_LOG.md]
tech-stack:
  added: []
  patterns: [context.accent.muscleSplitRamp ThemeExtension read, alchemist allThemesGroup golden, verify.ps1 migrated-file gate]
key-files:
  created:
    - test/muscle_load_bar_accent_test.dart
    - test/golden/muscle_load_bar_golden_test.dart
    - test/golden/goldens/windows/muscle_load_bar_all_themes.png
    - test/golden/goldens/ci/muscle_load_bar_all_themes.png
  modified:
    - lib/shared/widgets/body/muscle_load_bar.dart
    - scripts/verify.ps1
    - docs/LOOP_LOG.md
decisions:
  - "muscle_load_bar.dart reads context.accent.muscleSplitRamp instead of the static AppColors.muscleSplitPalette (2-line fix: import + swap)"
  - "AppColors import kept in muscle_load_bar.dart — context.surface (SurfaceContextX) still consumed at lines 46/111/146"
  - "AppColors.muscleSplitPalette retained in app_colors.dart + MuscleColorService fallbacks as backward-compat default (no live-surface consumer remains)"
  - "muscle_load_bar.dart added to verify.ps1 \$migratedFiles so any future AppColors. usage fails the mechanical gate"
metrics:
  duration: "~48 min (15:01Z → 15:49Z)"
  completed: "2026-08-09"
status: complete
---

# Phase 1 Plan 1: Reroute muscle load bar to settings theme accent — Summary

Rerouted the routine-detail muscle load bar from its hardcoded static purple
ramp (`AppColors.muscleSplitPalette`, `0xFF7F00FF`-based) to the user's
selected settings accent via `context.accent.muscleSplitRamp`, test-first with
a new widget test (RED→GREEN), a 6-accent pixel golden baseline, and the
verify.ps1 migrated-screen gate hardened to cover the surface.

## Execution Summary

| Task | Name | Status | Commits |
| ---- | ---- | ------ | ------- |
| 1 | Failing accent test → reroute bar to context.accent (RED→GREEN) | Done | `d2d1015` (RED test), `e8aff6f` (format), `5541ea9` (GREEN fix), `2c2549a` (lint compliance) |
| 2 | 6-palette golden regression baselines | Done | `e29bb31` |
| 3 | verify gate hardening + full suite | Done | `7481288` |

**Commits:** `d2d1015`, `e8aff6f`, `5541ea9`, `2c2549a`, `e29bb31`, `7481288`

## Task 1 — Failing accent test + context.accent reroute

- **RED (observed & recorded):** `flutter test test/muscle_load_bar_accent_test.dart`
  failed 4/5 on color assertions — actual colors were the legacy purple ramp
  (`0xFF7F00FF` family), expected the higgsfield/neonPurple `muscleSplitRamp`.
  Committed as `test(01-01)` before any source edit (AGENTS.md DoD).
- **GREEN:** minimal 2-line fix — added
  `import '../../../core/theme/dynamic_accent_theme.dart';` and replaced
  `const palette = AppColors.muscleSplitPalette;` with
  `final palette = context.accent.muscleSplitRamp;`. `app_colors.dart` import
  kept (`context.surface` still used). No changes to painter rounding, clamp
  logic, or the Semantics wrapper.
- **Tests (5/5 green):** higgsfield ramp equality, neonPurple ramp equality,
  no legacy-purple literal in any legend dot, 8-entry clamp (3 dots +
  `+5` overflow text), empty entries → `SizedBox.shrink`.
- **Static gates:** `muscleSplitPalette` zero hits in `muscle_load_bar.dart`;
  `dart format --set-exit-if-changed` clean.

## Task 2 — Golden baselines (all 6 accent palettes)

- New `test/golden/muscle_load_bar_golden_test.dart` — alchemist `goldenTest`
  with `fileName: 'muscle_load_bar_all_themes'`, `allThemesGroup` renders the
  bar under all 6 palettes (higgsfield, neonPurple, white, neonCyan,
  neonMagenta, blazeOrange) at maxWidth 400, no `setSurfaceSize` (research
  pitfall #3 respected).
- Baselines generated **after** Task 1's fix (`--update-goldens`), capturing
  accent colors: `test/golden/goldens/windows/muscle_load_bar_all_themes.png`
  (17,245 B) + `test/golden/goldens/ci/muscle_load_bar_all_themes.png`
  (5,453 B), matching the repo's windows/ci mirror convention.
- Plain run (no update flag) passes with zero diffs in both Windows and CI
  variants.

## Task 3 — Verify gate hardening + full suite

- `lib/shared/widgets/body/muscle_load_bar.dart` added to `$migratedFiles` in
  `scripts/verify.ps1` (after `exercise_selection_screen.dart`) — the surface
  is now fully on `context.accent`/`context.surface`; any future `AppColors.`
  usage fails the gate.
- `docs/LOOP_LOG.md` H17 entry appended (regression fix record per AGENTS.md
  DoD).
- **Full `.\scripts\verify.ps1` run: ✅ verify passed** — format clean,
  `flutter analyze --fatal-infos --fatal-warnings` 0 issues, `custom_lint`
  clean, `flutter test` 571 tests passed (includes the 5 new accent tests +
  2 golden variants).
- **Static sweep:** `muscleSplitPalette` in `lib/` now limited to
  `app_colors.dart:226` (definition) + `muscle_color_service.dart:19/33/53/71`
  (backward-compat fallbacks only). `Select-String 'AppColors\.' -Quiet` on
  the bar → `False`.

## Deviations from Plan

None — plan executed exactly as written. Two micro-deviations internal to
Task 1's commit sequence, both style-only:
1. `e8aff6f` `style(01-01): format accent test file` — `dart format` required
   a 3-line reformat of the new test (format gate is part of verify.ps1).
2. `2c2549a` `style(01-01): satisfy analyze lints in accent test` — the first
   `flutter analyze --fatal-infos` run flagged 2 info-level lints in the new
   test (`no_leading_underscores_for_local_identifiers` on the `_bar` helper,
   `prefer_const_literals_to_create_immutables`); renamed helper to
   `buildBar` + added `const` to set literals, re-ran full verify green.

## Known Stubs

None.

## Threat Surface Scan

No new security-relevant surface introduced. Presentation-only `List<Color>`
read from a registered compile-time ThemeExtension — no new network endpoints,
auth paths, file access, or schema changes (matches plan threat model
T-01-01/02 accepted low-severity register).

## Manual UAT (pending — device)

- Settings → Appearance → switch palette → open "Pull Day" routine → the
  muscle split bar follows the selected accent (default: Volt). Not gated on
  this phase; recorded here as manual UAT per plan.

## Self-Check: PASSED

- Created files verified: `test/muscle_load_bar_accent_test.dart`,
  `test/golden/muscle_load_bar_golden_test.dart`,
  `test/golden/goldens/windows/muscle_load_bar_all_themes.png`,
  `test/golden/goldens/ci/muscle_load_bar_all_themes.png`.
- Commits verified: `d2d1015` (RED), `e8aff6f`, `5541ea9` (GREEN),
  `2c2549a`, `e29bb31` (golden), `7481288` (gate).
- Full verify.ps1 gate green (571 tests, analyze 0, custom_lint 0).
