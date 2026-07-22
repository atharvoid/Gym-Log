# Requirements — GymLog Release Certification

## Release Criteria (P0 — Hard Blockers)

| # | Criterion | Current | Target |
|---|-----------|---------|--------|
| RC1 | Exercise measurement supports bodyweight/reps-only | Fails — every set requires weightKg > 0 | repsOnly as 4th MeasurementType + reps-only serializer |
| RC2 | Rest timer is usable during workout | Partial — sheet in single-button, no audio/notification | Compact sheet with expand, count-up, sound at expiry, background notif |
| RC3 | Active workout shows correct exercise name in header | Partial — truncated on narrow screens | Single-line scrollable title, ellipsis overflow |
| RC4 | Active workout layout fits all exercise cards on screen | Fails — padding, font sizes, broken expansion | Dense card with max-lines bodyweight hint, stable expansion triangle |
| RC5 | Auth screen communicates clearly and builds trust | Fails — empty state, lone button, no feedback | Calm motion, brand touch, typing gesture feedback, discrete error recovery |
| RC6 | Set deletion is reversible (undo) | Fails — sets are irreversibly deleted | Undo snackbar with configurable timeout |
| RC7 | Exercise replacement preserves unsaved set data | Fails — deletes sets if exercise swapped | Preserves and re-associates unsaved sets |
| RC8 | CSV import handles metric-aware data | Fails — weight only | Accepts both weight and reps in import format |
| RC9 | CSV export includes metric data | Fails — weight only | Export with metric column, backwards-compatible header |
| RC10 | Analytics/PRs are metric-aware | Fails — weight only | Per-measurement-type PRs, history charts, weekly displays |
| RC11 | Premium entitlement check is strict | Fails — uses active.isNotEmpty | Checks specific entitlement ID + feature-level verification |
| RC12 | Sync failures don't cause infinite retry | Fails — no quarantine | Quarantine corrupt payloads, skip without blocking |
| RC13 | Sync uses monotonic versions | Fails — clock-skew-dependent LWW | Monotonic revision counter per object |
| RC14 | Account switch isolates local data | Fails — imports from previous user leak | Purge/isolate on sign-out, scoped sync queries |
| RC15 | Exercise media cache is bounded | Fails — uncached, startup blocking | LRU cache with max 50 entries, deferred loading |
| RC16 | Core workout journey is accessible | Fails — untouchable targets, text scale breaks | 48×48 tappable targets, scrollable scale-to-fit, semantic labels |
| RC17 | Charts are screen-reader ready | Fails — no semantics | FlutterChart accessibility delegate or alt-text |
| RC18 | Release documentation is authoritative | Fails — no single source of truth | docs/ as canonical, AGENTS.md, release verification doc |
| RC19 | Store certification requirements met | Fails — no testers, aged builds | Recent build on tester devices, Google/Apple policies verified |
| RC20 | Sentry native symbolication configured | Fails — missing native debug symbols | upload-native-symbols gradle plugin, dsym upload script |

## User Stories

### Rest & Preference
- As a user doing pull-ups, I want to log reps without entering a weight, so bodyweight exercises work correctly.
- As a user who rests between sets, I want a compact count-up timer with audio alert and background notification.
- As a user with specific rest needs, I want control: global default, per-exercise, or disabled.

### Active Workout
- As a user mid-workout, I want to clearly see what exercise I'm on, even with a long name.
- As a user reviewing sets, I want to see enough cards without scrolling endlessly.
- As a user who deleted a set by accident, I want to undo it immediately.
- As a user who swapped an exercise, I want my partially-entered data preserved.

### Import/Export/History
- As a user who exported my data earlier, I want to re-import it losslessly.
- As a user analyzing progress, I want correct PRs and charts for both weighted and bodyweight exercises.

### Auth & Account
- As a new user, I want clear visual feedback when signing in, not a sudden jump to a workout.
- As a user signing out, I want my local data isolated from the next sign-in.

### Commerce
- As a paying subscriber, I want my premium features to be reliably enforced.

### Sync
- As a user with a spotty connection, I want sync to handle failures gracefully, not hang forever.

### Performance
- As a user on a low-end device, I want the app to start quickly without loading every exercise image.

### Accessibility
- As a user relying on TalkBack/VoiceOver, I want to complete a full workout without issues.

## Acceptance Criteria

### AC-P001 — Bodyweight Measurement
1. `MeasurementType` has a `repsOnly` variant (`-1`).
2. Exercise with `repsOnly` shows empty weight field + "bodyweight" label in the set row.
3. Import/export serializes `repsOnly` correctly.
4. Dashboard PRs/history filter by measurement type.

### AC-P002 — Rest Timer UX
1. Workout page shows a compact sheet with the active rest timer replacing the single-button layout.
2. Sheet can expand to full rest timer (showing history) and collapse back.
3. Timer works in count-up mode (no countdown).
4. Sound plays at expiry (haptic on supported devices).
5. Background notification fires if app is backgrounded during active rest.

### AC-P003 — Active Workout Visual Reconstruction
1. Exercise name in app bar shows full name (scrollable if too long).
2. Exercise cards use denser layout: smaller padding, reduced font sizes, 2-line bodyweight hint.
3. Expansion triangle stays stable during set interactions (doesn't re-roll).
4. Header shows time elapsed, not "00:00:00".

### AC-P004 — Auth Screen Redesign
1. Sign-in screen shows app name, brief tagline, and clean Google icon.
2. Tapping sign-in shows immediate feedback (pulse, brief spinner).
3. Error states show readable message + retry button.
4. Successful sign-in transitions smoothly to workout list.

### AC-P005 — Reversible Deletion & Exercise Replacement
1. Deleting a set shows undo snackbar (4s timeout).
2. Undo restores the deleted set to its original position.
3. Replacing an exercise preserves loosely-associated unsaved sets (reassigns to new exercise).
4. Deleting the last exercise in a section shows confirmation dialog.

### AC-P006 — CSV Import/Export Completeness
1. Export includes metric column (not just weight).
2. Export header is backdated for forward compat.
3. Import parses decimal weights (e.g., `2.5`).
4. Import accepts both weight-based and reps-only rows.

### AC-P007 — Metric-Aware History/Analytics
1. PRs computed per measurement type (weight by weight, reps by reps).
2. History chart scales correctly for bodyweight-only exercises.
3. Weekly bar chart respects metric type.

### AC-P008 — Premium Entitlement Integrity
1. Check specific entitlement ID (not active.isNotEmpty).
2. Premium features degrade gracefully when not entitled.
3. Verification includes offline entitlement cache check.

### AC-P009 — Sync Resilience
1. Corrupt sync payloads go to quarantine (not retried).
2. Monotonic revision counter for conflict resolution.
3. Quarantine doesn't block sync of other objects.

### AC-P010 — Account Isolation
1. Sign-out purges subscriptions to previous user's data.
2. All sync queries scoped to current user.
3. Switching accounts shows clean state.

### AC-P011 — Bounded Media Cache
1. LRU cache with max 50 exercise media entries.
2. Media loading deferred past first paint.
3. Cache eviction doesn't break already-visible media.

### AC-P012 — Accessibility Core Journey
1. All tappable targets ≥ 48×48 dp.
2. Text scales without breaking layout (test at 200%).
3. Screen reader can navigate a full workout end-to-end.
4. Enlarged tap targets don't overlap.

### AC-P013 — Charts Accessibility
1. Bar chart provides semantic accessibility delegate or alternative text.
2. Screen reader can read chart values and date ranges.
3. Weekly summary chart has matching accessibility.

### AC-P014 — Documentation & Support
1. docs/ is the canonical source of truth.
2. AGENTS.md accurately captures build steps.
3. Release verification document exists with checklists.

### AC-P015 — Release Certification
1. Signed APK/AAB built from exact SHA.
2. Sentry source maps + native symbols uploaded.
3. Tested on physical Pixel + recent Samsung.
4. RevenueCat configured with correct entitlement IDs for both stores.
5. Google Play App Signing confirmed.
6. iOS TestFlight build distributed to testers.

## Definition of Done

All P0 acceptance criteria (AC-P001 through AC-P015) pass with automated verification where possible and manual confirmation otherwise. The CI gate (`.\scripts\verify.ps1`) passes without warnings or errors. No new P0/P1 regression bugs.

## Technical Requirements

### Backend
- Supabase: scoped sync queries per user, row-level security verified
- RevenueCat: entitlement ID verified for both stores, offline entitlement caching
- Sentry: native symbol upload, source maps, release tracking

### Client
- Drift: DB schema versioning, migration path for measurement_type column
- Riverpod: providers registered for new features, no dispose leaks
- GoRouter: no broken auth redirects
- Build: dart-define-from-file=.env, obfuscate + split-debug-info

### CI
- `.\scripts\verify.ps1` passes: format, analyze --fatal-infos --fatal-warnings, custom_lint, flutter test
- CI Gate green on pushed branch
- Golden tests for all affected surfaces

---
*Generated from 50-section audit, 2026-07-22*
