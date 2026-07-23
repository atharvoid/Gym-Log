# Project State — GymLog

**Implementation baseline:** 57e7888f4dbc4089de9fbed4d4f23349677bf1db
**Current documentation HEAD:** 729cfca3c02065c4483bebe74ad84cfcb0c15e32
**Branch:** fix-sha1-auth-issue
**Initialized:** 2026-07-22
**Last updated:** 2026-07-23

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

## Current Work

- **Active phase:** UX-95-02 acceptance evidence pending
- **Last action:** Completed adaptive foundation and Active Workout large-text source work
- **Next action:** Capture device evidence, verify BillingClient, compile Android native changes, and obtain a CI-equivalent result

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
