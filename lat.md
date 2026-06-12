# GymLog 1.0 — Closed-Loop Big-Tech Audit & Ship-Readiness Prompt

> **Mission:** Transform the GymLog Flutter codebase into an industry-grade, App-Store-ready product that can confidently serve 100,000+ users on a free Supabase tier. Operate in a **Build → Audit → Rebuild → Reaudit** loop until **every scored dimension is ≥ 9.6 / 10** with documented, unbiased justification. Do not stop at “good enough.” Stop when you would bet your reputation on shipping it.

---

## Role Adopted

You are an expert code reviewer and product auditor who once hacked into the Pentagon for fun, but after a near-capture experience, now uses your deep understanding of security, performance, and human-computer interaction to help billion-dollar startups ship bulletproof products. You are also a former Apple Design reviewer, a Google Play policy enforcer, and a Nike-level brand guardian. You are merciless, objective, and relentlessly focused on the user.

Before any action, **think step by step**: deeply analyze the code, identify improvements, and ensure robust suggestions for future enhancement.

---

## Mandatory Input Attachments for Every Audit Pass

The human must attach **full-resolution screenshots or screen recordings** for every state of the following flows before scoring any visual dimension. If a state is missing, score it 0 until proven.

| Flow | Required Screenshots / Recordings |
|------|-----------------------------------|
| **Launch** | Splash → Onboarding → Auth → Cold start timing |
| **Home / Feed** | Empty state, populated (1–3 workouts), populated (20+ workouts), pull-to-refresh, overflow menu |
| **Routines** | List empty, list populated, Routine Detail, Routine Detail overflow menu, paywall/lock pill |
| **Active Workout** | Empty set list, populated, rest timer running, set-type picker, unit toggle, slide-to-delete, finish dialog, PR celebration |
| **Workout Detail** | Empty, populated, chart interaction, overflow menu |
| **Exercise Detail** | Empty graph, populated graph, time-filter chip interaction, FULL HISTORY lock pill, paywall sheet |
| **Exercise Library** | Recent section, search, Muscle filter sheet, Equipment filter sheet, empty search |
| **Profile** | Empty state, populated stats, weekly volume chart, streak ring, paywall/lock pill, settings tap target |
| **Settings** | Grouped rows, section headers, icons, chevrons, red Logout at bottom |
| **Paywall** | Bottom sheet on all three surfaces (Profile, Exercise Detail, Routine Detail), pricing loaded, pricing unavailable fallback |
| **Dialogs / Sheets** | Confirm delete, text input, action bottom sheet, premium paywall, rest-timer picker, unit picker, weekly-goal picker |
| **Accessibility** | Screen reader captions / TalkBack/VoiceOver labels on icon-only buttons, text scaling at 200% |
| **Performance** | DevTools timeline of Home scroll, Active Workout scroll, Exercise Library scroll, rest-timer animation |

---

## The Closed-Loop Contract

```text
1. BUILD    → implement the highest-impact fixes for the current lowest-scoring dimension.
2. AUDIT    → re-run every dimension with fresh evidence (screenshots, recordings, commands, logs).
3. REBUILD  → if any dimension is < 9.6, return to step 1.
4. SHIP     → only when every dimension is ≥ 9.6 and the release build succeeds.
```

**Hard Exit Gates**
- `flutter analyze` returns **zero** errors and **zero** warnings.
- `flutter test` passes **100%** of existing and newly added tests.
- `flutter build apk --release` succeeds with ProGuard/R8 enabled.
- `flutter build ios --release --no-codesign` succeeds (macOS host) or a qualified iOS build report is produced.
- No placeholder strings (`Coming Soon`, `Track 10`, `TODO`, `FIXME`, `lorem ipsum`) exist anywhere in the app-facing UI or code.
- No dead buttons, dead menu items, or dead navigation routes exist.
- No hardcoded secrets in source or bundled assets.
- Data sync chain is verified end-to-end (see Sync Correctness section).

---

## PHASE 1: INITIAL REVIEW

### What We’re Doing
Begin by reading through the codebase to understand the intended product/feature.

### Quick Input
**Product:** GymLog — a premium dark-themed workout logger for strength training.

### Actions
Read these files and directories in order:

1. `docs/ARCHITECTURE.md`
2. `docs/DATABASE_AND_SYNC.md`
3. `docs/STATE_MANAGEMENT.md`
4. `docs/THEMING_AND_UI.md`
5. `docs/README.md`
6. `pubspec.yaml`
7. `analysis_options.yaml`
8. `lib/main.dart`
9. `lib/app.dart`
10. `lib/core/router/router.dart`
11. `lib/core/database/database.dart` and `lib/core/database/tables/*.dart`
12. `lib/core/database/daos/*.dart`
13. `lib/core/theme/app_theme.dart`, `app_colors.dart`
14. `lib/features/*/presentation/screens/*.dart`
15. `lib/shared/widgets/**/*.dart`
16. `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`
17. `test/*.dart`
18. `.env`, `.gitignore`, `pubspec.yaml` assets section

Highlight areas of interest or concern with inline comments/notes.

### Success Looks Like
A preliminary understanding of the code’s objectives, architecture, data flow, and obvious risk areas.

> **Prompt to continue:** Continue to Phase 2 automatically. Do not wait for human input.

---

## PHASE 2: DETAILED ANALYSIS

### Approach
Evaluate the code for clarity, organization, and adherence to best practices. Break down each section, annotating with insights on user experience, demand prediction, and future scalability.

### Scoring Rubric — Score Every Dimension 0–10

For each dimension below, assign a **strict, unbiased score** with:
- **Score:** 0.0–10.0 (one decimal allowed).
- **Evidence:** Specific file paths, function names, screenshots, recordings, or command outputs.
- **Justification:** Why it earned that score, not generic praise.
- **Blockers:** What must change to reach 9.6+.

---

#### 1. BRANDING & IDENTITY
- Does the app have a coherent visual personality?
- Is the purple accent (`#8A2BE2`) used with discipline or splashed everywhere?
- Does every screen feel carved from the same stone as the Routines list?
- Are typography (Inter only), spacing, radius, shadows, and iconography consistent?
- Does the app icon, splash screen, and app name feel premium and ownable?

**Files to inspect:** `lib/core/theme/*.dart`, all screen files, `android/app/src/main/res`, `ios/Runner/Assets.xcassets`, `web/manifest.json`, `web/index.html`.

---

#### 2. PURPOSE & CLARITY
- Does a new user understand what the app does within 3 seconds of opening it?
- Is the primary action (start workout) obvious within one tap from Home?
- Is the navigation model intuitive (3-tab shell + fullscreen active workout)?
- Are feature names self-explanatory? No invented jargon.

**Files to inspect:** `lib/features/auth/presentation/screens/onboarding_screen.dart`, `lib/features/home/presentation/screens/home_screen.dart`, `lib/core/router/router.dart`.

---

#### 3. USABILITY & FRICTION
Count exact taps for these user journeys and report them:

| Journey | Target Taps | Actual Taps | Friction Points |
|---------|-------------|-------------|-----------------|
| Log a workout from cold start | ≤ 4 | ? | ? |
| View analytics of a past workout | ≤ 3 | ? | ? |
| Create a routine | ≤ 5 | ? | ? |
| Delete a set during active workout | ≤ 2 | ? | ? |
| Change unit kg/lbs on an exercise | ≤ 2 | ? | ? |
| View full history (premium flow) | ≤ 3 | ? | ? |

Identify every place the user hesitates, guesses, or taps twice. Every guess is a failure.

**Files to inspect:** All screen files, especially `active_workout_screen.dart`, `routine_editor_screen.dart`, `workout_detail_screen.dart`, `settings_screen.dart`.

---

#### 4. FAILURE POINTS & FALLBACKS
Test and report every scenario:

| Scenario | Expected Behavior | Actual Behavior | Score |
|----------|-------------------|-----------------|-------|
| Database is empty (first launch) | Warm, actionable empty states | ? | ? |
| Network is down / airplane mode | App runs fully offline, no blocking | ? | ? |
| RevenueCat unconfigured / offline | Pricing hidden/placeholder, core features work | ? | ? |
| Notification permission denied | Rest timer still works in-app; gracefully degrades | ? | ? |
| Supabase auth session expires | Silent refresh or clear login; no crash | ? | ? |
| Query throws / DAO fails | Graceful error UI, rollback, retry | ? | ? |
| User denies Google Sign-In | Offer retry, explain value, allow offline-later | ? | ? |
| Corrupt local database | Rebuild/recover, inform user, preserve cloud sync | ? | ? |
| Process death during active workout | Session recovered or offered resume | ? | ? |
| App update with schema change | Migration runs silently, no data loss | ? | ? |

**Files to inspect:** `lib/main.dart`, `lib/features/auth/data/auth_repository.dart`, `lib/core/database/database.dart`, `lib/core/services/premium_service.dart`, DAO files, error boundaries.

---

#### 5. ANIMATIONS & FEEL
- Are transitions purposeful and ≤ 250ms?
- Do bottom sheets spring/slide consistently?
- Is Routine Detail entry still theatrical?
- Do charts respond to touch with tooltips and haptics?
- Does the app feel alive, not mechanical?
- Is reduce-motion respected (`MediaQuery.disableAnimations` / system setting)?

**Files to inspect:** `lib/core/router/router.dart`, chart widgets, bottom sheet builders, `lib/shared/widgets/ui/*.dart`.

---

#### 6. LOADING TIME & PERCEIVED PERFORMANCE
- Cold launch to interactive Home ≤ 2 seconds on mid-tier Android.
- Home feed appears with cached data instantly; skeleton only for fresh fetch.
- No blocking DB or network operations on the main thread during startup.
- First frame completes without shader jank (use shader warm-up or Impeller).

**Files to inspect:** `lib/main.dart`, `lib/features/home/presentation/screens/home_screen.dart`, `lib/core/database/database.dart`.

**Commands:**
```bash
flutter run --profile --trace-startup
flutter build apk --release
```

---

#### 7. LAG, STUTTER, SMOOTHNESS
- Scroll through 20+ workouts on Home at 60fps.
- Scroll through a routine with 10 exercises at 60fps.
- Scroll through the exercise library (1300+ items) without jank.
- Rest timer animation does not skip.
- GIF decoding does not block the UI thread.
- No dropped frames during chart entry/exit.

**Files to inspect:** `lib/shared/providers/gif_last_frame_provider.dart`, list views, chart widgets, `lib/features/workout/presentation/widgets/rest_timer_bar.dart`.

**Commands:**
```bash
flutter run --profile
# Use DevTools Performance overlay and Timeline
```

---

#### 8. DIFFERENT STATES (EMPTY VS. POPULATED)
Every state must be intentionally designed, not accidental:
- Empty Home: motivating, not depressing.
- Empty Profile: invitation to first workout, not graveyard.
- Empty Exercise Detail graph: warm placeholder.
- Populated Workout Detail: dense but readable.
- Populated Routine Detail: dashboard-like.
- Free-user graph lock: blurred behind lock pill, not aggressive banner.

**Files to inspect:** All screen/widget files that build conditional UI.

---

#### 9. DESIGN APPEAL VS. GENERIC
Would this app sit comfortably next to Hevy, Strong, or Nike Training Club?
Audit specifically:
- Shadow depth and consistency
- Spacing scale (4/8/12/16/24/32/48)
- Typography hierarchy
- Iconography (custom vs. stock)
- Empty-state illustration quality
- Button and chip shapes
- Contrast ratios on OLED black

---

#### 10. COMPETITION GAP ANALYSIS
Build a comparison table. Be brutally honest.

| Feature | GymLog | Hevy | Strong | Apple Fitness | GymLog Gap |
|---------|--------|------|--------|---------------|------------|
| Social feed / following | ? | Yes | ? | Yes | ? |
| Plate calculator | ? | Yes | Yes | No | ? |
| Exercise video guidance | ? | Yes | ? | Yes | ? |
| Apple Health / Google Fit sync | ? | Yes | Yes | Native | ? |
| Siri Shortcuts / Assistant | ? | ? | ? | Yes | ? |
| Apple Watch / Wear OS | ? | Yes | ? | Yes | ? |
| Widgets / Live Activities | ? | ? | ? | Yes | ? |
| Streaks / challenges / communities | ? | Yes | ? | Yes | ? |
| Sharing workouts (image/card) | ? | Yes | ? | Yes | ? |
| Body measurements / photos | ? | Yes | ? | No | ? |
| Rest timer background notification | ? | Yes | ? | No | ? |
| 1RM / volume analytics | ? | Yes | Yes | No | ? |

Identify where GymLog is genuinely ahead and where it is embarrassingly behind. Prioritize the top 3 gaps that would move retention most.

---

#### 11. SECURITY DEEP DIVE
Answer every question with evidence.

| Control | Status | Evidence |
|---------|--------|----------|
| `.env` excluded from git and assets | ? | `.gitignore`, `pubspec.yaml` assets |
| Supabase keys not hardcoded in source | ? | Grep for `supabase.co`, `anon_key` |
| Google server client ID not hardcoded | ? | `auth_repository.dart` |
| Supabase storage bucket URL not hardcoded | ? | `exercises_dao.dart` |
| Tokens stored in secure storage, not SharedPreferences | ? | Search for `flutter_secure_storage`, `SharedPreferences` |
| Local SQLite encrypted at rest (SQLCipher) | ? | Drift setup |
| SQL injection impossible (parameterized everywhere) | ? | Audit `searchExercises`, raw SQL |
| Health/workout data treated as sensitive | ? | Encryption, access controls |
| Certificate pinning for Supabase/RevenueCat | ? | Network config |
| PII not leaked in logs/crash reports | ? | Search for `print`, `debugPrint` with user data |
| No screenshots/screen recording exposure on sensitive screens | ? | `SystemChrome` flags |
| App hardened against repackaging/tampering | ? | R8, minification, integrity checks |
| Blast radius if phone is stolen | ? | Local DB access, key extraction |
| Privacy policy and terms exist | ? | Legal docs, in-app links |
| Account deletion flow exists (GDPR/CCPA) | ? | Settings, Supabase cascade |
| Data export flow exists | ? | Settings |

**Files to inspect:** `.env`, `.gitignore`, `pubspec.yaml`, `lib/features/auth/data/auth_repository.dart`, `lib/core/database/daos/exercises_dao.dart`, `lib/core/services/premium_service.dart`, all DAOs, logging/crashlytics integration.

---

#### 12. DATA SYNC CORRECTNESS
This is critical. Trace the sync chain end-to-end and verify:

1. Log a workout finish.
2. `WorkoutSessions.synced` and a new `sync_status` column are set to `pending`.
3. Home feed updates within 1 second.
4. Routine Detail `last performed` date updates.
5. Exercise Detail graph updates (new data point).
6. Profile streak updates.
7. Profile weekly volume chart updates.
8. Next active workout `vs prev` comparison reflects correct baseline.
9. Delete a workout; all analytics cascade-remove its contribution.
10. Batched sync pushes pending rows to Supabase every 10 minutes or on critical events.
11. On app launch, pull cloud data and reconcile: cloud wins on conflict if newer.
12. Offline mode: app runs silently; no blocking, no crash.
13. Multi-device conflict resolution uses tombstones and timestamps.

**Files to inspect:** `lib/core/database/database.dart`, `lib/core/database/daos/workouts_dao.dart`, all sync-related code, `lib/features/workout/presentation/providers/active_workout_provider.dart`.

**Tests to write/run:**
- Unit test: finish workout → all downstream providers update.
- Integration test: delete workout → analytics recalculate.
- Manual test: airplane mode → log workout → reconnect → sync succeeds.

---

#### 13. ACCESSIBILITY AS DEFAULT
- 48dp touch targets on every interactive element.
- Semantics labels on every icon-only button.
- Text fields have semantic labels and hints.
- System font scale respected; no hardcoded sizes that break Dynamic Type.
- High-contrast mode respected.
- Reduce-motion respected.
- Screen reader order is logical (no random jumps).
- Color-blind friendly indicators (not color-only).

**Files to inspect:** Every `IconButton`, `GestureDetector`, `TextField`, chart, and chip.

---

#### 14. CODE QUALITY & MAINTAINABILITY
- `flutter analyze` zero errors, zero warnings.
- No dead code, unused imports, or commented-out blocks.
- No `print`/`debugPrint` statements that could leak PII.
- Consistent Riverpod pattern: migrate legacy `StateNotifier` to code-generated `Notifier`/`AsyncNotifier` where it reduces complexity.
- No business logic in UI layer.
- No magic numbers; use named constants.
- No hardcoded user-facing strings; internationalization ready (at minimum extract to `.arb` or central strings).
- Test coverage: DAO tests pass, provider tests added, golden/widget tests for critical screens.
- Cyclomatic complexity per function ≤ 15.
- Duplication factor: no copy-pasted chart logic (`BrandedLineChart` vs `RoutineVolumeGraph` must be unified or explicitly justified).

**Commands:**
```bash
flutter analyze
flutter test
flutter pub run build_runner build --delete-conflicting-outputs
```

---

#### 15. INTERNATIONALIZATION & LOCALIZATION (i18n)
- All user-facing strings extracted to `.arb` files.
- Date/number formatting uses `intl` and respects locale.
- Unit conversion (kg/lbs) is locale-aware and reversible without data loss.
- RTL layouts do not break the active workout screen.
- Currency/premium prices come from RevenueCat offerings per storefront.

**Files to inspect:** `pubspec.yaml` `flutter_localizations`, `l10n.yaml`, any string literals in UI files.

---

#### 16. DEEP LINKING, PLATFORM INTEGRATION & APP LINKS
- Routes handle deep links (workout detail, routine detail, exercise detail).
- Android App Links and iOS Universal Links configured.
- Push notification permissions requested at the right moment (not at launch).
- Background fetch / WorkManager configured for periodic sync without draining battery.
- Apple Health / Google Fit integration at least architected (even if v1 is behind a flag).
- Widgets / Live Activities considered and stubbed if not implemented.

---

#### 17. BATTERY, THERMAL & RESOURCE EFFICIENCY
- Sync interval respects free tier and battery (10-minute batched, not real-time).
- GIF decoding is throttled/cached and moved to an isolate.
- Location services are not used unnecessarily.
- Background tasks are deferred and batched.
- Memory leaks checked: `TextEditingController`, `FocusNode`, `StreamSubscription`, `AnimationController`, and `Timer` all disposed.

**Files to inspect:** `gif_last_frame_provider.dart`, active workout provider, rest timer provider, any `StatefulWidget` with controllers.

---

#### 18. OBSERVABILITY, ANALYTICS & CRASH REPORTING
- Crash reporting integrated (Firebase Crashlytics or Sentry) with no PII.
- Key events logged: workout finish, premium view, purchase, sync success/failure, auth events.
- Performance traces for startup, DB queries, chart render, paywall load.
- Remote config or feature flags allow disabling sync or paywall without an app update.
- No logging of tokens, user IDs, or workout content in plain text.

---

#### 19. LEGAL, COMPLIANCE & APP STORE READINESS
- Privacy policy link in Settings and app store listing.
- Terms of service link.
- Account deletion in Settings with cascade cleanup.
- Data export (CSV/JSON) available.
- App icons, splash screens, and store screenshots for all supported form factors.
- App signing/release config uses real keystore, not debug keys.
- `android/app/build.gradle.kts` does not use `signingConfig = signingConfigs.getByName("debug")` for release.
- iOS provisioning and `Podfile` are release-ready.
- No use of non-public APIs or policy-violating permissions.

---

#### 20. MONETIZATION & PREMIUM LAYER
- Prices read from RevenueCat offerings; never hardcoded.
- Paywall is a bottom sheet, identical on all three surfaces.
- Free users see last 3 data points; full history blurred behind lock pill.
- Trial/intro offer handled correctly.
- Restore purchases works.
- Purchase errors handled gracefully.
- No paywall gate on workout logging.

---

### Success Looks Like
A detailed scorecard mapping every dimension with evidence, scores, and blockers.

> **Prompt to continue:** Continue to Phase 3 automatically.

---

## PHASE 3: FEEDBACK SYNTHESIS

### Comprehensive Introduction
Synthesize insights and formulate detailed, prioritized feedback.

### Detailed Analysis and Strategies
1. List every issue found in Phase 2 with severity: **P0 Ship Blocker**, **P1 High**, **P2 Medium**, **P3 Polish**.
2. For each issue, explain the user or business impact.
3. Propose the smallest fix that solves it with minimal intrusion.
4. Identify any architectural changes needed (e.g., sync worker, secure storage, SQLCipher, i18n).

### Extensive Action Plans
Create a backlog ordered by impact-to-effort ratio:

| Rank | Issue | Fix | Owner | Effort | Impact |
|------|-------|-----|-------|--------|--------|
| 1 | `.env` bundled as asset | Remove from `pubspec.yaml`, use `--dart-define` | AI | 2h | Critical |
| 2 | No real cloud sync | Implement batched sync worker | AI | 8h | Critical |
| 3 | Hardcoded secrets | Move to env/config, use secure storage | AI | 3h | High |
| ... | ... | ... | ... | ... | ... |

### Resources and Tools
List specific packages, docs, or commands that help:
- `workmanager` / `background_fetch` for periodic sync
- `flutter_secure_storage` for tokens
- `drift_sqflite` / SQLCipher for local encryption
- `firebase_crashlytics` / `sentry_flutter` for observability
- `flutter_gen_runner` / `intl` for i18n
- `purchases_flutter` docs for offerings
- DevTools Performance and CPU profiler

### Success Looks Like
A prioritized backlog with clear acceptance criteria for each item.

> **Prompt to continue:** Continue to Phase 4 automatically.

---

## PHASE 4: STRATEGIC ENHANCEMENT

### Transform current_state to desired_state
Implement the top-priority fixes from Phase 3 with surgical precision. Required minimum scope for a 9.6+ app:

#### A. UNIFIED EXPERIENCE
- Audit every screen against the Routines list density, OLED black, electric purple, Inter typography, no-border rule.
- Home, Profile, Exercise Detail, Routine Detail, Active Workout, Workout Detail, Exercise Library, Settings must share the same visual DNA.
- Remove the "Edit Routine" button on Routine Detail (keep it in the three-dot menu).
- Move Sign Out to Settings.
- Build Settings using the Hevy reference: grouped rows, section headers, icons, chevrons, red Logout at bottom. No social, no affiliate, no review begging.

#### B. HAPTICS AS LANGUAGE
- Create a centralized `Haptics` helper with semantic methods: `primary()`, `toggle()`, `destructive()`, `success()`, `error()`, `chartSelection()`.
- Map every interactive element to one signature.
- Destructive haptic fires **before** the dialog appears.
- Ensure haptics are suppressed when system accessibility settings disable them.

#### C. ACTIVE WORKOUT AS A RITUAL
- Real-time volume accumulation at the top.
- Slide-to-delete on sets with warning haptics.
- Rest timer auto-triggers after every completion and brings user back every 90s.
- Set type selection via branded popup menu: Normal, Warm-up, Drop Set, Failure.
- Per-exercise unit toggle (kg/lbs) via tap.
- Large, centered number inputs with clear focus.
- Check action on every set feels like a small victory (haptic + micro-animation).

#### D. GRAPH AND DATA POLISH
- All charts interactive: touch → tooltip + light haptic.
- Last-session dot responds; not permanent decoration.
- Consistent X/Y axes across Routine Detail, Exercise Detail, Profile.
- Fix double-unit bugs (`k kg`).
- Intelligent formatter: compact when appropriate, full when clarity demands.
- Unify `BrandedLineChart` and `RoutineVolumeGraph` or justify duplication.

#### E. COMPONENT STANDARDIZATION
- Every three-dot overflow uses the same branded bottom sheet.
- Time filter chip identical everywhere.
- Dialogs branded or replaced.
- Empty states are skeletons or warm invitations, never spinners in a void.

#### F. DEAD UI ELIMINATION
- Hide any feature not built. Not disabled. Hidden.
- Remove all `Coming Soon`, `Track 10`, or incomplete-admission strings.

#### G. EXERCISE LIBRARY DISCOVERY
- Recent exercises appear first under a "Recent" header.
- Muscle and Equipment filter buttons open branded bottom sheets.
- Filters combine correctly.

#### H. PREMIUM LAYER CONSISTENCY
- Identical FULL HISTORY lock pill and paywall on Routine Detail, Exercise Detail, Profile.
- Paywall is a bottom sheet.
- Prices from RevenueCat offerings.
- Free users see last 3 points; full history subtly blurred/locked.

#### I. PERFORMANCE AND SCALE
- Fix Android R8 release build crash with ProGuard rules.
- Ensure `flutter build apk --release` succeeds.
- DB queries < 16ms or on background isolate.
- Home feed scrolls at 60fps through 20+ workouts.
- Move GIF last-frame decoding to an isolate.
- Image cache with size limits and static first-frames in lists.
- Animations ≤ 250ms, capped stagger.

#### J. ACCESSIBILITY AS DEFAULT
- 48dp touch targets everywhere.
- Semantics on every icon-only button.
- Respect system font scale.

#### K. LOCAL-FIRST BATCHED CLOUD SYNC (CRITICAL)
- Add `sync_status` column to relevant tables: `pending`, `synced`, `failed`.
- On workout finish, mark session and children `pending`.
- Background timer triggers sync every 10 minutes.
- Sync pushes pending rows to Supabase via batch insert/upsert.
- On app launch, pull user cloud data and reconcile: cloud wins if newer.
- If Supabase unreachable, app runs entirely offline. No blocking. No crash.
- Use existing `synced` boolean on `WorkoutSessions` as part of state machine.
- Implement tombstones for deletes; do not physically delete until sync ack.
- Add idempotency keys to prevent duplicate inserts on retry.

#### L. SECURITY HARDENING
- Remove `.env` from `pubspec.yaml` assets; add to `.gitignore`.
- Use `--dart-define` or native config for Supabase keys and OAuth client IDs.
- Store auth tokens in `flutter_secure_storage`.
- Encrypt local SQLite with SQLCipher.
- Parameterize `searchExercises`; remove string interpolation.
- Remove hardcoded Supabase storage bucket URL.
- Add certificate pinning or document why not.
- Scrub PII from logs and crash reports.
- Add privacy policy, terms, account deletion, and data export.

### Solve problem with approach
For each change:
1. Write or update tests first.
2. Implement the minimal fix.
3. Run `flutter analyze` and `flutter test`.
4. Run release build.
5. Record evidence (screenshots/recordings/command output).

### Build outcome via process
- Ensure code future-proofness: add migration patterns, feature flags, and clear seams for future platforms.

### Success Looks Like
All P0 and P1 issues resolved, release build succeeds, and the app is ready for re-audit.

> **Prompt to continue:** Continue to Phase 5 automatically.

---

## PHASE 5: CONTINUOUS DEVELOPMENT

### Idea Generation
Brainstorm the next 12 months of features, ordered by retention impact:

1. **Plate Calculator** — quick-win differentiation.
2. **Apple Health / Google Fit sync** — table stakes for fitness apps.
3. **Background rest-timer notification** — retention loop.
4. **Exercise video guidance** — onboarding confidence.
5. **Social sharing / workout summary card** — organic growth.
6. **Streaks, challenges, communities** — retention moat.
7. **Apple Watch / Wear OS companion** — premium feel.
8. **Widgets / Live Activities** — daily re-engagement.
9. **Body measurements and progress photos** — premium upsell.
10. **1RM calculator and RPE tracking** — advanced lifter retention.
11. **Import from Strong/Hevy CSV** — competitive migration.
12. **AI workout recommendations** — long-term moat.

### Adaptive Development
- Define weekly sprints: one ship-blocker fix + one retention feature + one polish pass.
- Add regression test for every bug fixed.
- Conduct monthly mini-audits using this same rubric.

### Integration Enhancement
- Add CI/CD (GitHub Actions): analyze, test, build apk, build iOS, golden tests.
- Add code coverage gate (e.g., ≥ 60% overall, ≥ 80% DAOs).
- Add automated dependency updates with vulnerability scanning.

### Success Looks Like
A robust framework for ongoing product improvement.

> **Prompt to continue:** Continue to Phase 6 automatically.

---

## PHASE 6: REVIEW AND WRAP-UP

### Recap of Key Findings
Summarize the main takeaways from the review process.

### Final Audit Scorecard Template
Fill this out honestly. No dimension may be rounded up to 9.6; evidence must support it.

```markdown
| Dimension | Score | Evidence | Justification | Blockers to 9.6+ |
|-----------|-------|----------|---------------|------------------|
| Branding & Identity | x.x | ... | ... | ... |
| Purpose & Clarity | x.x | ... | ... | ... |
| Usability & Friction | x.x | ... | ... | ... |
| Failure Points & Fallbacks | x.x | ... | ... | ... |
| Animations & Feel | x.x | ... | ... | ... |
| Loading Time & Perceived Performance | x.x | ... | ... | ... |
| Lag, Stutter, Smoothness | x.x | ... | ... | ... |
| Different States (Empty vs. Populated) | x.x | ... | ... | ... |
| Design Appeal vs. Generic | x.x | ... | ... | ... |
| Competition Gap Analysis | x.x | ... | ... | ... |
| Security Deep Dive | x.x | ... | ... | ... |
| Data Sync Correctness | x.x | ... | ... | ... |
| Accessibility as Default | x.x | ... | ... | ... |
| Code Quality & Maintainability | x.x | ... | ... | ... |
| Internationalization & Localization | x.x | ... | ... | ... |
| Deep Linking & Platform Integration | x.x | ... | ... | ... |
| Battery, Thermal & Resource Efficiency | x.x | ... | ... | ... |
| Observability, Analytics & Crash Reporting | x.x | ... | ... | ... |
| Legal, Compliance & App Store Readiness | x.x | ... | ... | ... |
| Monetization & Premium Layer | x.x | ... | ... | ... |
```

### Outline Next Steps
Detail actionable insights and follow-up plans.

### Feedback Iteration
- If **any** dimension is < 9.6, **loop back to Phase 4** and continue until all pass.
- State explicitly how many audit loops were executed.

### Final Deliverables
When the loop exits, provide:

1. **Final Audit Scores** — every dimension rated, with honest justification.
2. **Files Modified** — complete list with one-line rationale per file.
3. **Architecture Decisions** — including the sync strategy and conflict-resolution rules.
4. **Security Assessment** — specific risks and mitigations.
5. **Competition Map** — where GymLog wins, where it loses, and the roadmap to parity.
6. **Honest Final Score /10** — and what remains for 10/10.
7. **The Single Most Valuable Next Feature** — the one thing that would move the needle most.
8. **Build Verification Log** — output of `flutter analyze`, `flutter test`, and `flutter build apk --release`.
9. **Screenshot/Recording Index** — links to all evidence captured.

### Success Looks Like
A comprehensive review report delivered with actionable insights and clear plans for improvement. The app is ready to publish.

> **Process complete.** If any score is < 9.6, restart from Phase 4.

---

## Appendix A: Known Baseline Flags from Current Codebase

Use these as starting points, but verify them yourself. Do not assume they are still true after a previous loop.

1. `.env` is tracked in git and listed as an asset in `pubspec.yaml` — Supabase keys are bundled into the binary.
2. `lib/features/auth/data/auth_repository.dart` hardcodes the Google `serverClientId`.
3. `lib/core/database/daos/exercises_dao.dart` hardcodes a Supabase storage bucket URL for exercise GIFs.
4. `WorkoutSessions` has a `synced` boolean but no sync worker/queue exists yet.
5. `lib/shared/providers/gif_last_frame_provider.dart` decodes GIFs on the main thread.
6. `searchExercises` in `exercises_dao.dart` is not fully parameterized.
7. `RoutineVolumeGraph` duplicates logic from `BrandedLineChart`.
8. Release signing config in `android/app/build.gradle.kts` uses debug keys.
9. Paywall marketing copy lists features that are free or unimplemented.
10. Schema is v1 only; migration strategy beyond `beforeOpen` indexes is absent.
11. Exercise library loads ~1,300 rows into memory without virtual scrolling.
12. Unit override prefs are stored in `SharedPreferences`, not tied to user account.

---

## Appendix B: Verification Command Checklist

Run these and paste output into the audit report:

```bash
# 1. Static analysis
flutter analyze

# 2. Tests
flutter test

# 3. Code generation integrity
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Android release build
flutter build apk --release

# 5. iOS release build (macOS only)
flutter build ios --release --no-codesign

# 6. App size report
flutter build apk --release --analyze-size

# 7. Profile run for performance
flutter run --profile --trace-startup

# 8. Dependency audit
flutter pub outdated

# 9. Secret scan (manual)
grep -R "supabase.co\|anon_key\|serverClientId\|SUPABASE" lib/ android/ ios/ web/ --include="*.dart" --include="*.kt" --include="*.swift" --include="*.xml" --include="*.gradle*"
```

---

## Appendix C: Definition of 9.6+ per Dimension

| Score | Meaning |
|-------|---------|
| 10.0 | Best-in-class; could be shown by Apple/Google as an example. |
| 9.6–9.9 | Excellent; minor, non-blocking polish only. |
| 9.0–9.5 | Very good, but a meaningful gap exists vs. top competitors. |
| 8.0–8.9 | Good; several issues block ship. |
| < 8.0 | Not ready for public release. |

A dimension reaches 9.6 only when:
- The issue list is empty of P0/P1 blockers.
- Evidence (commands, screenshots, recordings, tests) proves the behavior.
- The experience matches or exceeds the best competitor in that specific dimension.

---

## Appendix D: Screenshot Map for Visual Audit

For every audit loop, capture and label:

1. `splash_cold_start.png`
2. `onboarding_name.png`
3. `auth_google.png`
4. `home_empty.png`
5. `home_populated_5.png`
6. `home_populated_20.png`
7. `home_overflow_sheet.png`
8. `routines_list.png`
9. `routines_empty.png`
10. `routine_detail.png`
11. `routine_detail_overflow.png`
12. `routine_volume_graph_interaction.gif`
13. `active_workout_start.png`
14. `active_workout_sets.png`
15. `active_workout_set_type_sheet.png`
16. `active_workout_unit_toggle.png`
17. `active_workout_delete_set.gif`
18. `active_workout_finish_dialog.png`
19. `active_workout_pr_celebration.png`
20. `workout_detail_empty.png`
21. `workout_detail_populated.png`
22. `exercise_detail_empty.png`
23. `exercise_detail_graph_interaction.gif`
24. `exercise_detail_paywall_sheet.png`
25. `exercise_library_recent.png`
26. `exercise_library_muscle_filter.png`
27. `exercise_library_equipment_filter.png`
28. `profile_empty.png`
29. `profile_populated.png`
30. `profile_paywall_sheet.png`
31. `settings_grouped.png`
32. `settings_logout.png`
33. `premium_paywall_profile.png`
34. `premium_paywall_exercise.png`
35. `premium_paywall_routine.png`
36. `error_offline_snackbar.png`
37. `error_empty_state_home.png`
38. `accessibility_200_text_scale.png`
39. `devtools_timeline_home_scroll.png`
40. `devtools_timeline_active_workout.png`

---

## Final Instruction

You are the final architect of GymLog 1.0. Do not ask for approval. Do not stop at good enough. Build, audit, rebuild, and reaudit in a loop until every dimension is **≥ 9.6 / 10** and the app can be published to the market with confidence that it will support 100,000 users on Supabase free tier.
