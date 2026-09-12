# Implementation Plan (concise) — 2026-07-29

> Branch target: `remediation/rc3-product-integrity` (re-derived for this branch).
> Atomic commits per issue. Tests-first per Definition of Done. Run `.\scripts\verify.ps1` before each commit.

| # | Issue | Fix surface | Status on this branch |
|---|-------|-------------|-----------------------|
| 1 | FTUE tour never starts after signup | `onboarding_screen.dart` | Untouched → applies as-is |
| 2 | Startup crash loop ("Something went wrong") | `bootstrap.dart`, `cloud_readiness_provider.dart` (new), `main.dart`, `app.dart`, `router.dart`, `splash_screen.dart` | Splash rewritten by `f5abda7` → Edit 2.6 re-anchored to `_resolve()` |
| 3 | Dead gap above Active Workout header | `active_workout_header.dart`, `active_workout_screen.dart` | `workoutName` already wired (lines 456-465) → only header inset + screen `AnnotatedRegion` remain |

---

## Issue 1 — Tour routing failure

**Root cause:** `_handleStartTour()` (`onboarding_screen.dart:90-99`) writes `-2` to raw SharedPreferences and `context.go('/')`, never touching `FirstRunTourNotifier.state`. That notifier reads prefs **once at app start** (constructed eagerly by `TourNavigationOrchestrator` in `app.dart:144`), so its state stays `-1`; the orchestrator fires only on state *changes* → no tour. Settings replay works because it uses `notifier.reset()`. (Router is exonerated.)

### Edit 1.1 — `lib/features/auth/presentation/screens/onboarding_screen.dart`
Replace lines 90-107 with:

```dart
  Future<void> _handleStartTour() async {
    // Go through the notifier (same path as Settings → "Replay app tour")
    // so the live state changes: the orchestrator fires and the step-0
    // spotlight renders on Home. A raw prefs write is invisible — the
    // notifier reads prefs once at app start.
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

Then remove the now-unused `import 'package:shared_preferences/shared_preferences.dart';` (line 19) — grep first to confirm no other `SharedPreferences`/`prefs` usage in the file.

### Test (write first, watch fail)
New `test/features/auth/onboarding_tour_routing_test.dart`: in-memory Drift (existing host-ffi helper) + `SharedPreferences.setMockInitialValues({})` + override `authProvider` (fake signed-in `User`) + minimal `GoRouter` (`/onboarding` → `OnboardingScreen`, `/` → placeholder), drive the 7 wizard steps to completion, tap `find.text('Take the 60-second tour')`, `pumpAndSettle`, assert `container.read(firstRunTourProvider) == 0` (pre-fix: `-1`). Second test: tap `'Skip tour & start'` → state `-1`.

---

## Issue 2 — Startup crash loop ⚠️ magenta is a red herring

**Root cause:** `bae40d2` moved `Supabase.initialize()` into a post-frame callback, but `app.dart:58` and `router.dart:53-54` read `Supabase.instance.client` synchronously during the first frame. In release the SDK guard `assert` is compiled out → `LateInitializationError` → framework inflates `AppErrorScreen` → both buttons dead-end into `SystemNavigator.pop()` (router never created) → deterministic loop. Also explains the fresh-install CMF Phone 2 crash; reinstall "fixed" it only because you installed the `main` build (lacks `bae40d2`). Theme load is fully guarded — cannot throw.

**Fix:** single `cloudReady` future owned by `Bootstrap`; all first-frame consumers await it; local-only mode when it resolves `false`.

### Edit 2.1 — New file `lib/core/providers/cloud_readiness_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves when Supabase initialisation has been attempted during Bootstrap.
/// `true` = `Supabase.instance` is safe to use; `false` = local-only mode
/// (no config, timeout, or init failure). Never errors. Overridden in
/// main.dart; default is unavailable so tests/recovery never touch Supabase.
final cloudReadinessProvider = Provider<Future<bool>>((ref) {
  return Future.value(false);
});
```

### Edit 2.2 — `lib/core/bootstrap/bootstrap.dart`
- `BootstrapResult`: add `final Future<bool> cloudReady;` field + `required this.cloudReady,` to the constructor.
- In `run()`, before `await SentryFlutter.init(`: `final cloudReady = Completer<bool>();`
- In the `appRunner` closure result construction: add `cloudReady: cloudReady.future,`.
- Replace the Stage-5 block so the completer is passed in and the recovery path completes it:
```dart
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
          cloudReady.complete(false);
        }
```
- `_postLaunchBackgroundWork`: add `required Completer<bool> cloudReady,` param; after `final cloudOk = await _initCloud();` add `cloudReady.complete(cloudOk);`; in the `catch` add `if (!cloudReady.isCompleted) cloudReady.complete(false);`.

### Edit 2.3 — `lib/main.dart`
Add import `core/providers/cloud_readiness_provider.dart`; add override `cloudReadinessProvider.overrideWithValue(result.cloudReady),`.

### Edit 2.4 — `lib/app.dart`
Add import `core/providers/cloud_readiness_provider.dart`. Replace lines 56-60 (the synchronous `Supabase.instance.client.auth...listen`) with `unawaited(_wireAuthWhenCloudReady());` plus a new method after `initState`:
```dart
  Future<void> _wireAuthWhenCloudReady() async {
    final ready = await ref.read(cloudReadinessProvider);
    if (!ready || !mounted || _authSub != null) return;
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        _onAuthStateChange,
      );
    } catch (_) {
      // Readiness resolved true but singleton still unusable (abandoned
      // timeout future). Stay local-only.
    }
  }
```

### Edit 2.5 — `lib/core/router/router.dart`
- Import: `import '../providers/cloud_readiness_provider.dart';`
- Replace the `_GoRouterRefreshStream` class (lines 31-44) with a deferred, readiness-aware listenable:
```dart
/// Defers touching Supabase until cloud init completes; re-runs redirects on
/// readiness flip so a restored session on /auth self-heals into /splash.
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
- In `routerProvider`: replace the `_GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange)` construction with `_DeferredAuthRefreshListenable(ref.read(cloudReadinessProvider))`; rename the local `refreshStream`/`refreshListenable` accordingly; `ref.onDispose(...dispose)`.
- In the redirect: replace `final isSignedIn = Supabase.instance.client.auth.currentSession != null;` with `final isSignedIn = refreshListenable.isSignedIn;` (matches the local variable name you used).

### Edit 2.6 — `lib/features/auth/presentation/screens/splash_screen.dart` *(re-anchored for rc3)*
The splash was rewritten (`f5abda7`); `_resolveInitialRoute`/`_hasResolvedOnce` no longer exist. Insert the readiness await at the top of `_resolve()`:
- Add import `import '../../../../core/providers/cloud_readiness_provider.dart';`
- In `_resolve()`, after the existing `if (!mounted) return;` (line 38) and before `final user = ref.read(authProvider);` (line 40), insert:
```dart
    // Cloud init runs post-first-frame; wait for it (bounded by
    // Bootstrap.cloudInitTimeout) so profileSync/syncEngine (which construct
    // Supabase remotes eagerly) see a ready singleton. In local-only mode this
    // resolves false and the existing null-user path routes to /auth.
    await ref.read(cloudReadinessProvider);
    if (!mounted) return;
```

### Tests (write first, watch fail)
New `test/core/app_startup_test.dart`:
1. `testWidgets('GymLogApp builds when cloud is not ready')` — `ProviderScope` (`databaseProvider` → in-memory test DB, `premiumServiceProvider`, `notificationServiceProvider`, `initialAccentPaletteProvider` → `ThemePalette.fallback`, `cloudReadinessProvider` → `Future.value(false)`) around `const GymLogApp()`; `pump()`; `expect(tester.takeException(), isNull)` + `find.byType(MaterialApp)` findsOne. **Pre-fix: `LateInitializationError` at app.dart:58.**
2. Same with an unresolved `Completer<bool>()`, then complete it `true` (Supabase still uninitialized) → `pumpAndSettle` → no exception (defensive catch holds).
3. Router unit test: `ProviderContainer` with `cloudReadinessProvider` → `Future.value(false)`; read `routerProvider` — no throw; redirect(`/`) → `/auth`, `/splash` → null. Then readiness completes `true` with Supabase uninitialized → `isSignedIn` false, no throw.

---

## Issue 3 — Dead gap above Active Workout header

**Root cause:** `ActiveWorkoutHeader` stacks `SafeArea(bottom: false)` (full status-bar inset as dead space) **plus** a fixed 48dp near-empty grab-handle strip before the nav row, so close/timer/Finish starts `inset + 48dp` down. Latent until `bf16c2e` added `enableEdgeToEdge()` (`targetSdk 36` forces it) — before that `padding.top == 0` and the SafeArea was a silent no-op. Route is top-level opaque fullscreen (not shell-hosted) → no double-inset.

### Edit 3.1 — `lib/features/workout/presentation/widgets/active_workout_header.dart`
- Add `import 'dart:math' as math;` (top).
- In `build`, after the `isCompactOrLargeText` line (line 43), add:
```dart
    // Fold the status-bar inset into the grab strip (edge-to-edge makes
    // viewPadding.top non-zero); a SafeArea here would add the inset as dead
    // space ON TOP of the strip.
    final topInset = MediaQuery.viewPaddingOf(context).top;
```
- Remove the `SafeArea(bottom: false, child: ...)` wrapper (lines 60-73) so the `padding:`'s child is directly the `Container(constraints: ...)`; pass the inset to `_buildGrabHandle(surface, topInset)`.
- Replace `_buildGrabHandle` with (note the `ValueKey` for the test):
```dart
  Widget _buildGrabHandle(SurfaceTokens surface, double topInset) {
    // Strip absorbs the inset: always >= 48dp (a11y touch target), growing on
    // notched devices so the pill always clears the status bar. Pill is
    // bottom-aligned directly above the nav row.
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
            key: const ValueKey('grab-handle-pill'),
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

### Edit 3.2 — `lib/features/workout/presentation/screens/active_workout_screen.dart` *(workoutName already wired on rc3 — skip 3.2a/3.2b)*
Only the `AnnotatedRegion` wrap remains (`/workout/active` is opaque → shell's overlay style doesn't composite through; `services.dart` already imported). Wrap the `Scaffold` at line 445:
```dart
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: AdaptiveContent( ... ),  // unchanged
      ),
    );
```

### Edit 3.3 — `test/golden/active_workout_header_golden_test.dart` *(workoutName/onFinish already passed on rc3)*
Only add the inset golden:
```dart
Widget _headerWithStatusBarInset() => MediaQuery(
      data: const MediaQueryData(viewPadding: EdgeInsets.only(top: 30)),
      child: SizedBox(
        width: 390,
        child: ActiveWorkoutHeader(
          isEditing: false,
          workoutName: 'Active Workout',
          elapsedTime: '00:12:34',
          volumeKg: 1250.0,
          completedSets: 8,
          weightUnit: 'kg',
          finishEnabled: true,
          onMinimize: () {},
          onClose: () {},
          onFinish: () {},
        ),
      ),
    );
```
and a third `goldenTest` (`fileName: 'active_workout_header_inset'`, `allThemesGroup('ActiveWorkoutHeader (inset)', _headerWithStatusBarInset())`).

### Tests
1. New geometry widget test `test/features/workout/active_workout_header_inset_test.dart`: pump `_headerWithStatusBarInset()` body (no MediaQuery needed — pass `viewPadding: EdgeInsets.only(top: 30)` via a MediaQuery wrapper + themed harness). Find close button by tooltip `'Discard workout'` → assert top Y ≤ `30 + 48`. Find pill by `ValueKey('grab-handle-pill')` → assert top Y > 30. Assert strip height ≥ 48. Pre-fix: close-button top = `30 + 48 = 78` (SafeArea + 48 strip) → fails.
2. Regenerate all header goldens (layout changed in every accent theme):
   ```powershell
   flutter test --update-goldens test/golden/active_workout_header_golden_test.dart
   ```
   Then run without `--update-goldens` to confirm green and visually inspect new PNGs.

---

## Global verification (after all three)

```powershell
.\scripts\verify.ps1   # format, analyze --fatal-infos --fatal-warnings, custom_lint, flutter test
```

Manual acceptance:
- [ ] Fresh install → sign in → wizard → "Take the 60-second tour" → step-0 spotlight on Home immediately.
- [ ] Settings → replay tour still works.
- [ ] Cold start ×5 on signed-in device (one with magenta persisted): no error screen; splash → home.
- [ ] Cold start in airplane mode: splash waits ≤ 4s, reaches home/auth in local-only mode, no error screen.
- [ ] Active workout: close/timer/Finish flush under status bar on a notched device; swipe down from very top minimizes; status icons legible.

## Commits (atomic, in order)

1. `fix(tour): start FTUE tour via notifier state, not raw prefs write`
2. `fix(startup): serialize Supabase consumers behind cloud readiness` — reference regression `bae40d2` + CMF Phone 2 / reinstall evidence in body.
3. `fix(workout): fold status-bar inset into active workout grab handle` — reference `bf16c2e` in body.

## Regression log
Issues 2 & 3 are regressions → append two entries to `docs/LOOP_LOG.md` following its existing format (sources `bae40d2`, `bf16c2e`; both landed under "device acceptance pending").

## Out of scope
- `home_screen.dart` deferred-tour gate (lines 110-113) — keep as migration path for persisted `-2`.
- `AppErrorScreen` redesign (root-mount failure class disappears with Edit 2.x) → belongs to UX-95-06.
- Reordering `Supabase.initialize()` back before `runApp()` — re-adds up to 4s cold-start latency; the readiness future is the correct fix.
- Removing `deferredStep` from `FirstRunTourNotifier` — harmless cleanup for later.

---

> **Note:** This concise plan supersedes `docs/BUGFIX_PLAN_2026-07-29.md`, which was written against the `fix-sha1-auth-issue` HEAD and is stale for Issues 2 (splash) and 3 (workoutName wiring) on `remediation/rc3-product-integrity`.