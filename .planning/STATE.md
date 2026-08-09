# Project State — GymLog

**Implementation baseline:** 57e7888f4dbc4089de9fbed4d4f23349677bf1db
**Current documentation HEAD:** 729cfca3c02065c4483bebe74ad84cfcb0c15e32
**Branch:** fix-sha1-auth-issue
**Initialized:** 2026-07-22
**Last updated:** 2026-08-09

## Context

**Legacy ATOMIC remediation** (earlier commits on `fix-sha1-auth-issue`):
addresses the 50-section audit through 15 phases. Labeled "Legacy ATOMIC
remediation" in ROADMAP. Does NOT satisfy UX-95 acceptance criteria.

**Canonical UX-95 program** (14 phases): HEAD `57e7888` implements UX-95-01
(shell/navigation reconstruction) and completes the adaptive/large-text header
reflow for active workout (UX-95-02), plus a cross-app dynamic color-token
migration and partial Help/recovery hardening. This is the active program.

## Phase Progress

| Phase | Description | Status |
|-------|-------------|--------|
| UX-95-01 | Dynamic shell and bottom-navigation reconstruction | **Implementation complete; visual/device acceptance pending** |
| UX-95-02 | Adaptive layout and large-text foundation | **Source implementation complete; physical-device and CI acceptance pending** |
| UX-95-03 | Measurement-aware presentation architecture | **Open** |
| UX-95-04 | Active-workout final density and timer reconstruction | **Open** |
| UX-95-05 | Routine and exercise authoring reconstruction | **Open** |
| UX-95-06 | Help, resume, error, and database-recovery safety | **Open** |
| UX-95-07 | Settings and Profile information architecture | **Open** |
| UX-95-08 | Splash and onboarding time-to-value | **Open** |
| UX-95-09 | Paywall, billing truth, and purchase accessibility | **Open** |
| UX-95-10 | Whole-app accessibility and keyboard qualification | **Open** |
| UX-95-11 | Motion, rendering, and performance budget | **Open** |
| UX-95-12 | Design-system consolidation and visual consistency | **Open** |
| UX-95-13 | Exact-SHA full-screen visual certification | **Open** |
| UX-95-14 | Store, billing, monitoring, and release certification | **Open** |
| 01-fix-muscle-split-bar | Muscle split bar hardcoded purple → settings theme accent | **Source complete; manual device UAT pending** |

## Current Work

- **Active phase:** 01-fix-muscle-split-bar-hardcoded-purple-use-settings-theme-acc — **plan 01-01 COMPLETE** (all 3 tasks, verify gate green)
- **Last action:** Rerouted `MuscleLoadBar` to `context.accent.muscleSplitRamp` (test-first RED→GREEN), added 6-accent golden baselines (windows + ci), hardened verify.ps1 migrated-screen gate, LOOP_LOG H17
- **Next action:** Manual device UAT — Settings → Appearance → switch palette → open "Pull Day" routine → bar follows accent (default Volt)

## Branching Strategy

- Feature branches off `fix-sha1-auth-issue`
- Each phase gets its own branch: `phase/N-name`
- Merge back to `fix-sha1-auth-issue` after verification

## Key Artifacts

- `.planning/PROJECT.md` — Project overview & constraints
- `.planning/REQUIREMENTS.md` — Release criteria, user stories, acceptance criteria
- `.planning/ROADMAP.md` — Legacy ATOMIC remediation + canonical UX-95 program
- `.planning/STATE.md` — This file, state tracking
- `.planning/config.json` — Workflow preferences
- `audit/` — 50-section systematic product audit

## Accumulated Context

### Roadmap Evolution

- Phase 1 added: Fix muscle split bar hardcoded purple; use settings theme accent

## Decisions

- MuscleLoadBar reads `context.accent.muscleSplitRamp` (reactive ThemeExtension) instead of static `AppColors.muscleSplitPalette`; app_colors import kept for `context.surface`
- `AppColors.muscleSplitPalette` retained only as backward-compat fallback in `app_colors.dart` + `MuscleColorService` (no live-surface consumer remains)
- `lib/shared/widgets/body/muscle_load_bar.dart` added to verify.ps1 `$migratedFiles` gate
- Default accent is Volt (higgsfield) — users without a palette choice now see the bar in Volt, not purple (intended behavior, not regression)

## Last Session

- **Timestamp:** 2026-08-09
- **Stopped at:** Completed 01-01-PLAN.md (muscle split bar accent fix)
- **Resume file:** None
