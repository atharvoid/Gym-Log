# GymLog

## What This Is

GymLog is a cross-platform Flutter workout logging app with local-first persistence (Drift/SQLite), Google Sign-In via Supabase, and premium subscriptions via RevenueCat. OLED-first dark theme with 6 selectable accent palettes. Currently at version 1.0.0+1 — a mature codebase with significant UX, domain-model, and release-readiness gaps identified by a comprehensive 50-section audit.

## Core Value

Users can log weighted and bodyweight exercises during a workout with accurate tracking, rest timers, and persistent history — all working correctly during training without data loss.

## Requirements

### Validated

- ✓ Flutter/Dart app with Riverpod state management — existing
- ✓ Drift (SQLite) local database with 8 tables, 4 DAOs — existing
- ✓ Google Sign-In via Supabase — existing
- ✓ GoRouter navigation — existing
- ✓ OLED-first dark theme with 6 accent palettes — existing
- ✓ Exercise catalog with 400+ bundled exercises — existing
- ✓ Workout creation, completion, and history — existing
- ✓ Basic rest timer with configurable durations — existing
- ✓ Routine creation and management — existing
- ✓ Sync infrastructure with Supabase — existing
- ✓ RevenueCat integration framework — existing
- ✓ CSV import/export — existing
- ✓ Basic analytics and personal records — existing

### Active

- [ ] P0-01: Exercise measurement model — reps-only/bodyweight support without kilograms
- [ ] P0-02: Active workout UI density — rest timer sheet, card layout, header, snackbar
- [ ] P0-03a: Auth screen first-principles reconstruction — calm motion, trust, accessibility
- [ ] P0-04: Reversible set deletion and safe exercise replacement
- [ ] P0-05: Metric-aware CSV import with decimal parsing
- [ ] P0-06: Versioned lossless metric-aware CSV export
- [ ] P0-07: Metric-aware history, analytics and personal records
- [ ] P0-08: RevenueCat strict premium entitlement verification
- [ ] P0-09: Sync failure quarantine and monotonic version conflict resolution
- [ ] P0-10: Local account isolation and safe sign-out
- [ ] P0-11: Bounded exercise media cache and nonblocking startup
- [ ] P0-12: Screen-reader, text-scale, reduced-motion, and chart accessibility
- [ ] P0-13: Authoritative documentation, support metadata, and public truth
- [ ] P0-14: Exact-SHA release certification — Play, iOS, Sentry, RevenueCat

### Out of Scope

- Real-time collaborative workouts — not core to individual logging
- Social features / friend networks — would distract from release
- Video exercise demonstrations — storage/bandwidth, defer
- Apple Watch / Wear OS companion — future platform
- AI-powered workout generation — out of scope for v1 release

## Context

Based on a comprehensive 50-section systematic product audit covering product strategy, UX, domain modeling, database, sync, auth, security, performance, accessibility, commerce, release engineering, compliance, and operations.

Key audit conclusions:
- **Overall rating**: 6.6/10 (source maturity 7.2, visual quality 5.8)
- **Release verdict**: NO-GO
- **Hard blockers**: bodyweight/reps-only measurement, rest timer UX, accessibility core journey, store certification, Sentry symbolication, operational ownership

The app functional core works but the interaction model doesn't match how people actually train — bodyweight movements require kilograms, rest timers lack audio/background notification, set deletion is unrecoverable, and visual polish is inconsistent.

Current HEAD: b32af2c09d8cc8a9a51d1149b51bccc0df6e3982 on fix-sha1-auth-issue.

## Constraints

- **Tech stack**: Flutter/Dart, Riverpod, Drift SQLite, Supabase, GoRouter, RevenueCat
- **Platform**: Cross-platform (Android release primary, iOS secondary)
- **Code generation**: build_runner required after Drift/Riverpod/Freezed changes
- **Secrets model**: Compile-time dart-define-from-file=.env (gitignored)
- **Performance**: OLED-first dark theme, pure black background
- **Accessibility**: WCAG AA required for release (a core audit blocker)
- **Release**: Signed artifacts, Play App Signing, Sentry uploads required for GO verdict

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| repsOnly measurement type for bodyweight | Audit found P0 defect — sets incorrectly require weightKg > 0 | — Pending (P0-01) |
| Rest preference as sealed class (UseGlobalDefault / Disabled / CustomDuration) | Removes ambiguous "None" state and exclusive selection | — Pending (P0-02) |
| Strict entitlement check (not active.isNotEmpty) | Prevents unrelated entitlements from unlocking premium | — Pending (P0-08) |
| Sync quarantine for corrupt payloads | Prevents infinite retry loops; one bad object doesn't block others | — Pending (P0-09) |
| Monotonic revisions for sync conflict resolution | Removes clock-skew-dependent last-write-wins | — Pending (P0-09) |

---
*Last updated: 2026-07-22 after initialization*
