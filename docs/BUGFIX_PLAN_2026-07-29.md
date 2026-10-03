# Bugfix Implementation Plan — 2026-07-29

> Three production bugs, each fixed independently with its own atomic commit.
> Written for an executing agent: every edit lists exact file paths, current
> code, and replacement code. Follow the per-issue order (tests first, then
> fix) and the global verification steps at the end.
>
> **Do not** batch all three issues into one commit.

| # | Issue | Regression introduced by | Primary files |
|---|-------|--------------------------|---------------|
| 1 | FTUE tour never starts after signup | `639126b` + `b388339` | `onboarding_screen.dart` |
| 2 | Startup crash loop ("Something went wrong") | `bae40d2` | `bootstrap.dart`, `app.dart`, `router.dart`, `splash_screen.dart`, `main.dart` |
| 3 | Dead gap above Active Workout header | `bf16c2e` (exposed) | `active_workout_header.dart`, `active_workout_screen.dart` |

**Pre-existing compile break at HEAD that MUST be fixed with Issue 3:**
`ActiveWorkoutHeader` declares `required this.workoutName`
(`lib/features/workout/presentation/widgets/active_workout_header.dart:24`,
used at line 169) but neither call site passes it
(`active_workout_screen.dart:391-401`,
`test/golden/active_workout_header_golden_test.dart:13-23,33-43`). The tree
does not compile until this is resolved.

---

## Issue 1 — Post-Signup Onboarding Tour Routing Failure

### Root Cause Analysis

The "Take the 60-second tour" button writes the tour flag to **raw
SharedPreferences only** and never updates the live Riverpod state:

`lib/features/auth/presentation/screens/onboarding_screen.dart:90-99`
```dart
Future<void> _handleStartTour() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
      'first_run_tour_step', FirstRunTourNotifier.deferredStep);
  if (mounted) {
    context.go('/');
  }
}
```

The single source of truth the UI reacts to is `FirstRunTourNotifier.state`,
which reads prefs **exactly once, at provider construction**
(`lib/features/auth/presentation/providers/tour_provider.dart:16-23`). That
construction happens at app start, because `TourNavigationOrchestrator`
(mounted in `MaterialApp.router.builder`, `lib/app.dart:144`) subscribes via
`ref.listen`. So when the user finishes onboarding minutes later, the
notifier's in-memory state is still `-1` (inactive):

- The orchestrator's listener (`tour_navigation_orchestrator.dart:30-42`)
  fires only on state **changes** → never fires → no navigation.
- Every screen's `ref.watch(firstRunTourProvider)` sees `-1` → no spotlight
  overlay renders.

The Settings → "Replay app tour" path works precisely because it goes through
the notifier (`settings_screen.dart:558`:
`ref.read(firstRunTourProvider.notifier).reset()`), which mutates in-memory
state.

**Compounding design flaw:** even if the state did propagate, the handler
writes `deferredStep` (`-2`), and the kick-off gate
(`home_screen.dart:111-116`) only starts a deferred tour once the user has a
routine or activity — which a brand-new account never has. The button
promises "Take the 60-second tour"; deferral contradicts that promise.

The router is **exonerated**: its redirect (`router.dart:63-80`) only
special-cases `/splash`, `/onboarding`, `/auth`; `context.go('/')` passes
cleanly.

### Optimal Solution

Make the FTUE handlers go through the notifier (like the working Settings
path) and start the tour **immediately at step 0**, matching the button's
promise and the replay semantics. The `deferredStep` machinery stays in place
purely as a migration path for users who already have `-2` persisted from
older builds (the existing `home_screen.dart:111-116` gate continues to
handle them; do not remove it).

### Implementation Plan

1. **Write the failing test first** (new file
   `test/features/auth/onboarding_tour_routing_test.dart` — see Test section
   below). Run it, confirm it fails: provider state stays `-1`.
2. Edit `_handleStartTour` / `_handleSkipTour` in `onboarding_screen.dart`.
3. Re-run the test → green. Run `.\scripts\verify.ps1`.
4. Commit atomically.

### Code Edits

**File:** `lib/features/auth/presentation/screens/onboarding_screen.dart`

Replace lines 90-107 with:

```dart
  Future<void> _handleStartTour() async {
    // Go through the notifier (same path as Settings → "Replay app tour") so
    // the live state changes: the orchestrator listener fires and the
    // step-0 spotlight renders on Home. A raw SharedPreferences write is
    // invisible — the notifier reads prefs once at app start.
    await ref.read(firstRunTourProvider.notifier).setStep(0);
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _handleSkipTour() async {
    await ref.read(firstRunTourProvider.notifier).setStep(-1);
    if (mounted) {
      context.go('/');
    }
  }
```

Then remove the now-unused import at line 19:

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

(Verify with a search that `SharedPreferences` / `prefs` is not referenced
elsewhere in this file before deleting the import. `FirstRunTourNotifier` is
still referenced via `firstRunTourProvider` which is already imported at line
10.)

### Test (write FIRST, watch it fail)

**New file:** `test/features/auth/onboarding_tour_routing_test.dart`

Widget test that drives the wizard to the completion step and taps
"Take the 60-second tour", then asserts the live provider state is `0`.

Setup requirements (patterns already used elsewhere in `test/`):

- `SharedPreferences.setMockInitialValues({});`
- In-memory Drift DB via the existing host-SQLite ffi test infrastructure
  (see any DAO test for the `AppDatabase` test constructor pattern), override
  `databaseProvider`.
- Override `authProvider` with a fake signed-in `User` (Google metadata
  prefill path tolerates null metadata).
- Wrap in `MaterialApp.router` with a minimal `GoRouter` exposing
  `/onboarding` (builds `OnboardingScreen`) and `/` (builds a `SizedBox`
  placeholder) so `context.go('/')` resolves.
- Keep a `ProviderContainer`/`ProviderScope` reference to read
  `firstRunTourProvider` after the tap.

Flow:

1. Pump `OnboardingScreen` at `/onboarding`.
2. Walk the 7 steps: enter a name in step 1 (the Next CTA is disabled until
   non-empty), tap the primary CTA on each subsequent step
   (`StepAge` → `StepGender` → `StepUnits` → `StepExperience` →
   `StepWeeklyGoal` → completion). Use `tester.enterText` /
   `tester.tap(find.text(...))` with `pumpAndSettle()` between steps. If a
   step's CTA is disabled without a selection, tap the first selectable
   option first.
3. On the completion page, tap `find.text('Take the 60-second tour')`.
4. `await tester.pumpAndSettle();`
5. **Assert:** `container.read(firstRunTourProvider) == 0`
6. **Assert:** prefs round-trip — `SharedPreferences` `first_run_tour_step`
   is `0`.
7. Second test: tap `'Skip tour & start'` instead → provider state `-1`,
   prefs `-1`.

Expected pre-fix failure: state is `-1` (and prefs `-2`).

---

## Issue 2 — Critical Initialization Error / Persistent Crash Loop

### Root Cause Analysis

**The magenta theme is a red herring.** The accent save/load path is fully
guarded (`bootstrap.dart:239-257` wraps the whole load in try/catch with a
fallback; `ThemePalette.fromStorage` is string-keyed with an unknown-key
fallback — no `values[index]`, no `.byName()`, nothing that can throw). All 6
palettes including `neonMagenta` have complete, valid token sets.

**Actual mechanism — a deterministic cold-start build-phase exception:**

Commit `bae40d2` ("perf(media): bound exercise cache and defer optional
startup work") moved `Supabase.initialize()` from *before* `runApp()` into a
**post-frame callback**:

- `bootstrap.dart:111` — `runApp(appBuilder(result))`
- `bootstrap.dart:115-121` — post-frame → `_postLaunchBackgroundWork()`
- `bootstrap.dart:140` → `bootstrap.dart:272` — `await Supabase.initialize(...)`

But two consumers read `Supabase.instance.client` **synchronously during the
first frame**, before that callback can ever run:

1. **`lib/app.dart:58`** (in `_GymLogAppState.initState`):
   ```dart
   _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(...)
   ```
2. **`lib/core/router/router.dart:53-54`** (via `ref.watch(routerProvider)`
   at `app.dart:120`):
   ```dart
   final refreshStream = _GoRouterRefreshStream(
     Supabase.instance.client.auth.onAuthStateChange,
   );
   ```

In supabase_flutter 2.14.1 the `Supabase.instance` guard is an `assert`,
compiled out in release; reading the `late SupabaseClient client` field then
throws **`LateInitializationError`** (debug builds throw the
`AssertionError` instead). The framework catches the mount exception and
inflates the `ErrorWidget.builder` product — the full-screen
`AppErrorScreen` ("Something went wrong" / "Restart GymLog" / "Go Home",
`bootstrap.dart:75-78`, `lib/shared/widgets/app_error_screen.dart`).

**Why it loops:** the crash happens before `routerProvider` is created, so
`rootNavigatorKey.currentContext` is null and both buttons fall through to
`SystemNavigator.pop()` (`app_error_screen.dart:21-35`). The app closes; the
next cold start deterministically re-executes the same failing path.

**Why reinstall "fixed" it:** the user reinstalled the *production* build
(from `main`), which does not contain `bae40d2`. The internal-sharing build
(from `fix-sha1-auth-issue`) does — which also explains the **fresh-install
first-launch crash on the CMF Phone 2**, impossible under any corrupted-state
theory. Changing the accent to magenta was simply the last action before a
process kill + cold start.

**Latent second failure mode:** if Supabase init times out or fails (no
config, no network), `_initCloud` returns `false` and the instance may
**never** become initialized — so the fix must tolerate permanent
unavailability (local-only mode), not just a timing race.

### Optimal Solution

Keep the deferred cloud init (it is a legitimate cold-start optimization) and
introduce a **single cloud-readiness future** owned by `Bootstrap`, plumbed
through `BootstrapResult` into a Riverpod provider. Every consumer of
`Supabase.instance` is serialized behind it:

- `app.dart` subscribes to the auth stream only when readiness resolves true.
- `router.dart` builds its refresh-listenable and evaluates `isSignedIn`
  readiness-aware, and **re-runs redirects when readiness flips** (so a
  restored session on `/auth` self-heals into `/splash`).
- `splash_screen.dart` awaits readiness before touching auth/profile sync
  (bounded by the existing 4s `cloudInitTimeout`, so the splash can never
  hang indefinitely).

This is device/OEM-agnostic by construction: there is no state to corrupt,
no timing assumption, and every failure path degrades to the already-designed
local-only mode.

**Consumer inventory (verified — all serialized after this fix):**
`app.dart:58` (fixed), `router.dart:54,69` (fixed), `sync_engine.dart:424`,
`profile_sync_service.dart:203`, `profile_image_sync_service.dart:144`,
`account_deletion_service.dart:175` — all first read in splash/lifecycle/
user-initiated flows **after** readiness. `bootstrap.dart:295,301,316` are
already guarded or run after `_initCloud()`. `auth_provider.dart:7-13` is
already try/catch-guarded. No other `Supabase.instance` references exist in
`lib/`.

### Implementation Plan

1. **Write the failing tests first** (see Test section): a startup widget
   test pumping `GymLogApp` with an unresolved/false cloud-readiness future
   (pre-fix: throws `LateInitializationError` at `app.dart:58`) and a router
   construction test.
2. Add `cloudReadinessProvider`.
3. Thread a `Completer<bool>` through `Bootstrap` → `BootstrapResult`.
4. Override the provider in `main.dart`.
5. Rewrite the auth-stream wiring in `app.dart` to await readiness.
6. Replace `_GoRouterRefreshStream` with a deferred, readiness-aware
   listenable in `router.dart` and make the redirect use it.
7. Await readiness at the top of `SplashScreen._resolveInitialRoute`.
8. Re-run tests → green. Run `.\scripts\verify.ps1`.
9. Commit atomically.

### Code Edits

#### Edit 2.1 — New provider

**New file:** `lib/core/providers/cloud_readiness_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves when cloud (Supabase) initialisation has been attempted during
/// [Bootstrap]. `true` = `Supabase.instance` is safe to use; `false` =
/// local-only mode (no config, timeout, or init failure). Never errors.
///
/// Overridden in `main.dart` with the real bootstrap future. The default is
/// "unavailable" so tests and the database-recovery shell never touch
/// Supabase.
final cloudReadinessProvider = Provider<Future<bool>>((ref) {
  return Future.value(false);
});
```

#### Edit 2.2 — `Bootstrap` owns the readiness future

**File:** `lib/core/bootstrap/bootstrap.dart`

(a) Add the field to `BootstrapResult` (after `accentPalette` field, ~line
38) and to the constructor:

```dart
  /// Completes when cloud (Supabase) initialisation has been attempted.
  /// `true` = available, `false` = local-only mode. Never errors.
  final Future<bool> cloudReady;
```

```dart
  const BootstrapResult({
    required this.db,
    required this.premiumService,
    required this.notificationService,
    required this.databaseCorrupted,
    required this.cloudAvailable,
    required this.accentPalette,
    required this.cloudReady,
    this.status = BootstrapStatus.localReady,
    this.recoverableError = false,
  });
```

(b) In `run()`, create the completer before `SentryFlutter.init` (so it is in
scope for the `appRunner` closure), pass `.future` into the result, and
complete it from both the happy and skipped paths. Inside the `appRunner`
closure, change the result construction and Stage 5 block to:

```dart
        final result = BootstrapResult(
          db: db,
          premiumService: premiumService,
          notificationService: notificationService,
          databaseCorrupted: migrationFailure,
          cloudAvailable: false, // Set asynchronously post-frame
          accentPalette: accentPalette,
          cloudReady: cloudReady.future,
          status: status,
          recoverableError: migrationFailure,
        );

        // ── Stage 4: Launch UI IMMEDIATELY after local ready ─────────────
        runApp(appBuilder(result));

        // ── Stage 5: Move noncritical work post-first-frame ───────────────
        if (!migrationFailure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_postLaunchBackgroundWork(
              db: db,
              premiumService: premiumService,
              notificationService: notificationService,
              cloudReady: cloudReady,
            ));
          });
        } else {
          // Recovery mode never initialises the cloud — release awaiters.
          cloudReady.complete(false);
        }
```

and just inside `run()`, before `await SentryFlutter.init(`:

```dart
    final cloudReady = Completer<bool>();
```

(c) Update `_postLaunchBackgroundWork` to accept and complete the completer,
including on failure:

```dart
  static Future<void> _postLaunchBackgroundWork({
    required AppDatabase db,
    required PremiumService premiumService,
    required NotificationService notificationService,
    required Completer<bool> cloudReady,
  }) async {
    try {
      // 1. Media cache maintenance
      unawaited(ExerciseMediaCacheManager().performMaintenance());

      // 2. Local notifications initialization
      unawaited(notificationService.init());

      // 3. Cloud pull & Supabase readiness check (bounded timeout)
      final cloudOk = await _initCloud();
      cloudReady.complete(cloudOk);

      // 4. Commerce readiness (RevenueCat refresh)
      _initCommerce(db);

      // 5. Catalog metadata refresh & nonessential warm-up queries
      await _postLaunchMaintenance(db);
    } catch (e) {
      debugPrint('[Bootstrap] postLaunchBackgroundWork failed: $e');
      if (!cloudReady.isCompleted) cloudReady.complete(false);
    }
  }
```

`Completer` is already available via `dart:async` (imported at line 1).

#### Edit 2.3 — Override in `main.dart`

**File:** `lib/main.dart`

Add to the `overrides` list (after the `initialAccentPaletteProvider`
override):

```dart
        // Cloud readiness future — consumers of Supabase.instance must
        // await this instead of touching the singleton blindly.
        cloudReadinessProvider.overrideWithValue(result.cloudReady),
```

and the import:

```dart
import 'core/providers/cloud_readiness_provider.dart';
```

#### Edit 2.4 — `app.dart` subscribes only when ready

**File:** `lib/app.dart`

Replace lines 56-60:

```dart
    // Cover the fresh-install path: GoRouter redirects /auth -> / directly on
    // sign-in, so SplashScreen never runs. initSession() is idempotent.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
    );
```

with:

```dart
    // Cover the fresh-install path: GoRouter redirects /auth -> / directly on
    // sign-in, so SplashScreen never runs. initSession() is idempotent.
    //
    // Supabase.initialize() runs post-first-frame (see Bootstrap), so the
    // singleton does not exist yet — touching Supabase.instance here throws
    // LateInitializationError in release builds and crash-loops the app into
    // AppErrorScreen. Await cloud readiness instead; in local-only mode the
    // listener simply never wires and the app stays fully usable offline.
    unawaited(_wireAuthWhenCloudReady());
```

Add the new method immediately after `initState`:

```dart
  Future<void> _wireAuthWhenCloudReady() async {
    final ready = await ref.read(cloudReadinessProvider);
    if (!ready || !mounted || _authSub != null) return;
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        _onAuthStateChange,
      );
    } catch (_) {
      // Defensive: readiness resolved true but the singleton is still not
      // usable (e.g. abandoned init future after timeout). Stay local-only.
    }
  }
```

Add the import:

```dart
import 'core/providers/cloud_readiness_provider.dart';
```

#### Edit 2.5 — `router.dart` readiness-aware refresh + redirect

**File:** `lib/core/router/router.dart`

(a) Replace the `_GoRouterRefreshStream` class (lines 31-44) with:

```dart
/// Defers touching Supabase until cloud initialisation completes (it runs
/// post-first-frame — see Bootstrap). Notifies GoRouter once at creation and
/// again when readiness resolves, so redirects re-evaluate with the real
/// auth state: a restored session sitting on /auth self-heals into /splash.
class _DeferredAuthRefreshListenable extends ChangeNotifier {
  _DeferredAuthRefreshListenable(Future<bool> cloudReady) {
    notifyListeners();
    unawaited(cloudReady.then((ready) {
      _cloudReady = ready;
      if (ready) {
        try {
          _subscription = Supabase.instance.client.auth.onAuthStateChange
              .listen((_) => notifyListeners());
        } catch (_) {
          _cloudReady = false;
        }
      }
      notifyListeners();
    }));
  }

  bool _cloudReady = false;
  StreamSubscription<AuthState>? _subscription;

  /// Safe session check — false until the cloud singleton is confirmed
  /// ready, and never throws if Supabase disappeared underneath us.
  bool get isSignedIn {
    if (!_cloudReady) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

(b) Replace the provider body lines 51-56:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Wire GoRouter to Supabase auth stream so redirects re-run on login/logout
  final refreshStream = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(refreshStream.dispose);
```

with:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Wire GoRouter to the auth stream once the cloud is ready; redirects
  // re-run on readiness and on every subsequent auth change.
  final refreshListenable = _DeferredAuthRefreshListenable(
    ref.read(cloudReadinessProvider),
  );
  ref.onDispose(refreshListenable.dispose);
```

(c) In the `GoRouter(...)` constructor call, rename
`refreshListenable: refreshStream` → `refreshListenable: refreshListenable`.

(d) In the redirect (line 69), replace:

```dart
      final isSignedIn = Supabase.instance.client.auth.currentSession != null;
```

with:

```dart
      final isSignedIn = refreshListenable.isSignedIn;
```

(e) Add the import:

```dart
import '../providers/cloud_readiness_provider.dart';
```

(Verify the relative path depth: `router.dart` lives in `lib/core/router/`,
so `../providers/cloud_readiness_provider.dart` is correct.)

#### Edit 2.6 — Splash awaits readiness

**File:** `lib/features/auth/presentation/screens/splash_screen.dart`

In `_resolveInitialRoute`, after `_hasResolvedOnce = true;` (line 116) and
before `if (!mounted) return;`, insert:

```dart
    // Cloud init runs post-first-frame; wait for it (bounded by
    // Bootstrap.cloudInitTimeout) so auth state and profile sync below see
    // a ready Supabase instance. In local-only mode this resolves false and
    // the existing null-user path routes to /auth without touching Supabase.
    await ref.read(cloudReadinessProvider);
```

Add the import:

```dart
import '../../../../core/providers/cloud_readiness_provider.dart';
```

### Tests (write FIRST, watch them fail)

**New file:** `test/core/app_startup_test.dart`

1. `testWidgets('GymLogApp builds without throwing when cloud is not ready')`:
   pump `ProviderScope` with overrides mirroring `main.dart`
   (`databaseProvider` → in-memory test DB; `premiumServiceProvider` →
   `PremiumService(db)`; `notificationServiceProvider` →
   `NotificationService()`; `initialAccentPaletteProvider` →
   `ThemePalette.fallback`; `cloudReadinessProvider` → `Future.value(false)`)
   around `const GymLogApp()`. `await tester.pump()`.
   Assert `tester.takeException()` is null and a `MaterialApp` exists.
   **Pre-fix:** throws `LateInitializationError` at `app.dart:58` — this is
   the exact production crash, reproduced in a test.
2. Same pump but `cloudReadinessProvider` → a `Completer<bool>().future`
   that is completed `true` *after* the pump (Supabase still not actually
   initialized — simulates the abandoned-timeout race). Pump, complete,
   `pumpAndSettle`. Assert no exception (the defensive try/catch holds).
3. Router: construct a `ProviderContainer` with `cloudReadinessProvider`
   overridden to `Future.value(false)`, read `routerProvider` — must not
   throw — and assert the redirect sends `/` → `/auth` and leaves `/splash`
   alone. Then a container whose readiness completes `true` (with Supabase
   uninitialized) — `isSignedIn` stays `false`, no throw.

**File note:** reuse the existing in-memory Drift test helpers used by the
DAO tests for the `AppDatabase` override.

---

## Issue 3 — Dead Gap Above Active Workout Top Bar (Safe Area)

### Root Cause Analysis

`ActiveWorkoutScreen` (`/workout/active`, a top-level opaque fullscreen
dialog route — `router.dart:166-194`, **not** hosted by the shell, so no
double-inset from `AppShell`) uses the custom `ActiveWorkoutHeader` as its
top bar. The header
(`lib/features/workout/presentation/widgets/active_workout_header.dart:52-76`)
stacks **two** dead regions above the actual navigation row (close | timer |
Finish, `_buildNormalLayout` lines 114-157):

1. `SafeArea(bottom: false)` (lines 60-61) — inserts the **full status-bar
   inset** as empty space;
2. `_buildGrabHandle` (line 67 → lines 78-100) — a fixed **48dp strip** whose
   only content is a 36×4dp pill.

So the nav row starts `statusBarInset + 48dp` (~75-110dp) below the physical
top of the screen. The header background correctly paints into the inset
region (the `Container(decoration:)` wraps the `SafeArea`), which is why the
gap reads as unpolished empty space rather than a transparency bug.

**Why it appeared now:** commit `bf16c2e` added `enableEdgeToEdge()` to
`MainActivity.kt` (and `targetSdk = 36` forces edge-to-edge on Android 15+
regardless). Before that, Android consumed the status bar itself,
`MediaQuery.padding.top == 0`, and the `SafeArea` was a silent no-op — the
header visually started at the grab handle. After `bf16c2e` the `SafeArea`
went live and pushed everything down, with the 48dp strip still stacked
underneath. Every other screen applies the top inset exactly once (AppBar on
Settings; shell-level `SafeArea` on Home/Profile) — only this header stacks
an extra strip.

**Secondary:** `ActiveWorkoutScreen` has no
`AnnotatedRegion<SystemUiOverlayStyle>`; because the route is opaque, the
shell's region does not composite through, so status-bar icon brightness
relies on a previously applied style being sticky.

### Optimal Solution

Apply the top inset **exactly once**, with no full-height strip between it
and the nav row — the standard drag-handle-under-status-bar pattern:

- Remove the `SafeArea`.
- Let the grab-handle strip **absorb** the inset: height
  `max(48, topInset + 20)`, pill bottom-aligned with 8dp padding. The pill
  always clears the status bar/notch on every OEM skin (Android ~24-32dp,
  iOS ~47-59dp), the touch target never drops below the 48dp a11y minimum,
  and the whole-header swipe-to-minimize gesture now also covers the inset
  zone (natural: drag down from the very top minimizes).
- Wrap the screen in an `AnnotatedRegion<SystemUiOverlayStyle>` (light icons
  on dark surfaces, matching `onboarding_screen.dart:117-120`).
- Fix the HEAD compile break by passing `workoutName` at both call sites.

Geometry after fix: nav row top = `max(48, inset + 20)` → Android ~48dp
(was ~72-80), iOS ~67-79 (was ~107-120).

### Implementation Plan

1. **Write the failing tests first** (geometry widget test + new inset
   golden — see Test section).
2. Fix the compile break (pass `workoutName` at screen + golden call sites).
3. Rework the header inset handling.
4. Add the `AnnotatedRegion` to `ActiveWorkoutScreen`.
5. Regenerate goldens, re-run tests → green. Run `.\scripts\verify.ps1`.
6. Commit atomically.

### Code Edits

#### Edit 3.1 — Header: fold the inset into the grab strip

**File:** `lib/features/workout/presentation/widgets/active_workout_header.dart`

(a) Add at the top:

```dart
import 'dart:math' as math;
```

(b) In `build`, after `final isCompactOrLargeText = ...` (line 42-43), add:

```dart
    // Fold the status-bar inset into the grab-handle strip so the close /
    // timer / Finish row sits flush beneath it. Edge-to-edge (MainActivity
    // enableEdgeToEdge + targetSdk 36) makes viewPadding.top non-zero; a
    // SafeArea here would add the inset as dead space ON TOP of the strip.
    final topInset = MediaQuery.viewPaddingOf(context).top;
```

(c) Replace the `Container(...)` body (lines 52-74): delete the
`child: SafeArea(bottom: false, ...)` wrapper so the `padding:`'s child is
directly the `Container(constraints: ...)`; pass the inset to the handle:

```dart
      child: Container(
        decoration: BoxDecoration(
          color: surface.bgBase,
          border: Border(
            bottom: BorderSide(color: surface.borderSubtle, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGrabHandle(surface, topInset),
              if (isCompactOrLargeText) _buildReflowedLayout(surface, accent),
              if (!isCompactOrLargeText) _buildNormalLayout(surface, accent),
            ],
          ),
        ),
      ),
```

(d) Replace `_buildGrabHandle` (lines 78-100):

```dart
  Widget _buildGrabHandle(SurfaceTokens surface, double topInset) {
    // The strip absorbs the status-bar inset: always >= 48dp (minimum touch
    // target), growing on notched devices so the pill always clears the
    // status bar. The pill is bottom-aligned directly above the nav row.
    return Semantics(
      button: true,
      label: 'Minimize workout',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMinimize,
        child: Container(
          width: 60,
          height: math.max(48.0, topInset + 20.0),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: surface.borderEmphasis,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
```

Geometry check: Android inset 24 → strip 48, pill top = 48 − 8 − 4 = 36 > 24
✓. iOS inset 59 → strip 79, pill top = 67 > 59 ✓.

#### Edit 3.2 — Screen: `AnnotatedRegion` + `workoutName`

**File:** `lib/features/workout/presentation/screens/active_workout_screen.dart`

(a) Near the other watches in `build` (after the `isEditing` watch, ~line
361-362), add:

```dart
    final workoutName = ref.watch(activeWorkoutProvider.select((state) =>
        state == null
            ? ''
            : (state.name != null && state.name!.trim().isNotEmpty
                ? state.name!.trim()
                : getWorkoutNameFallback(state.startTime, null))));
```

(`getWorkoutNameFallback` is already imported and used at line 175.)

(b) Pass it into the header call (~line 391-401):

```dart
              return ActiveWorkoutHeader(
                isEditing: isEditing,
                workoutName: workoutName,
                elapsedTime: timer,
                ...
```

(c) Wrap the returned `Scaffold` (line 380) in an `AnnotatedRegion`
(`/workout/active` is an opaque fullscreen dialog — the shell's overlay
style does not composite through):

```dart
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: ...
      ),
    );
```

(`package:flutter/services.dart` is already imported for `HapticFeedback`.)
Adjust the closing parens accordingly.

#### Edit 3.3 — Golden test call sites

**File:** `test/golden/active_workout_header_golden_test.dart`

Add `workoutName: 'Push Day',` to both header constructions (lines 13-23 and
33-43).

### Tests (write FIRST / regenerate goldens)

1. **New geometry widget test** —
   `test/features/workout/active_workout_header_inset_test.dart`:

   ```dart
   // Pump ActiveWorkoutHeader under MediaQueryData(
   //   viewPadding: EdgeInsets.only(top: 30)) inside the standard themed
   //   test harness (see golden_test_helpers / existing widget tests for the
   //   theme wrapper pattern).
   ```

   - Find the close button via `find.byTooltip('Discard workout')`.
   - Assert its top Y ≤ `30 + 48` (inset absorbed, not added: pre-fix it is
     `30 + 48 = 78`+ — fails).
   - Find the pill (`Container` 36×4 — locate via a `find.byWidgetPredicate`
     on size/decoration, or add a `ValueKey('grab-handle-pill')` to the pill
     in Edit 3.1(d) and find by key — **preferred: add the key**).
   - Assert pill top Y > 30 (clears the simulated status bar).
   - Assert the strip is still ≥ 48dp tall (a11y touch target).

2. **New inset golden** — add to
   `test/golden/active_workout_header_golden_test.dart`:

   ```dart
   Widget _headerWithStatusBarInset() => MediaQuery(
         data: const MediaQueryData(
           viewPadding: EdgeInsets.only(top: 30),
         ),
         child: SizedBox(
           width: 390,
           child: ActiveWorkoutHeader(
             isEditing: false,
             workoutName: 'Push Day',
             elapsedTime: '00:12:34',
             volumeKg: 1250.0,
             completedSets: 8,
             weightUnit: 'kg',
             finishEnabled: true,
             onMinimize: () {},
             onClose: () {},
             onFinish: null,
           ),
         ),
       );
   ```

   ```dart
   goldenTest(
     'ActiveWorkoutHeader renders correctly per theme (status-bar inset)',
     fileName: 'active_workout_header_inset',
     builder: () => allThemesGroup(
       'ActiveWorkoutHeader (inset)',
       _headerWithStatusBarInset(),
     ),
   );
   ```

3. Regenerate all header goldens (layout changed in every accent theme):

   ```powershell
   flutter test --update-goldens test/golden/active_workout_header_golden_test.dart
   ```

   Then run without `--update-goldens` to confirm green, and **visually
   inspect the new PNGs** before committing.

---

## Global Verification (after all three issues)

```powershell
.\scripts\verify.ps1   # format, analyze --fatal-infos --fatal-warnings, custom_lint, flutter test
```

Manual/device acceptance:

- [ ] Fresh install → sign up → complete wizard → "Take the 60-second tour" →
      step-0 spotlight renders on Home immediately.
- [ ] Settings → replay tour still works.
- [ ] Cold start ×5 on a previously signed-in device (including one with
      magenta accent persisted): no error screen; splash → home.
- [ ] Cold start with airplane mode ON: splash waits ≤ 4s, app reaches
      home/auth in local-only mode, no error screen.
- [ ] Active workout: close/timer/Finish row sits flush under the status bar
      on a notched Android device; swipe down from the very top minimizes;
      status-bar icons are light/legible.

## Commit Plan

1. `fix(tour): start FTUE tour via notifier state, not raw prefs write`
2. `fix(startup): serialize Supabase consumers behind cloud readiness`

   Body must reference regression `bae40d2` and the CMF Phone 2 /
   reinstall evidence.
3. `fix(workout): fold status-bar inset into active workout grab handle`

   Body must reference `bf16c2e` and the `workoutName` compile break.

## Regression Log (required by Definition of Done)

Issues 2 and 3 are regressions → append two entries to `docs/LOOP_LOG.md`
following its existing format (regression source commits `bae40d2` and
`bf16c2e` respectively; note the acceptance-gap lesson: both landed under
"device acceptance pending").

## Out of Scope (do NOT touch)

- `home_screen.dart:111-116` deferred-tour gate — keep as migration path for
  persisted `-2`.
- `AppErrorScreen` redesign — with Edit 2.x the root-mount failure class
  disappears; a deeper error-boundary rework belongs to UX-95-06.
- Reordering `Supabase.initialize()` back before `runApp()` — would re-add
  up to 4s cold-start latency; the readiness future is the correct fix.
- `deferredStep` removal from `FirstRunTourNotifier` — harmless; removal is
  cleanup for another day.
