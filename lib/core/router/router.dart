import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cloud_readiness_provider.dart';
import '../providers/supabase_client_provider.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/app_error_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/exercises/presentation/screens/exercise_selection_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/help_feedback_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen.dart';
import '../../features/profile/presentation/screens/appearance_screen.dart';
import '../../features/profile/presentation/screens/delete_account_screen.dart';
import '../../features/import/presentation/screens/import_screen.dart';
import '../../features/routines/presentation/screens/explore_routines_screen.dart';
import '../../features/routines/presentation/screens/routine_editor_screen.dart';
import '../../features/routines/presentation/screens/routine_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../core/database/database.dart';

/// Defers touching Supabase until cloud initialisation completes (it runs
/// post-first-frame — see Bootstrap). Notifies GoRouter once at creation and
/// again when readiness resolves, so redirects re-evaluate with the real
/// auth state: a restored session sitting on /auth self-heals into /splash.
///
/// DISPOSAL CONTRACT: the readiness future is started in the constructor and
/// outlives nothing — it can resolve after this notifier is gone (cloud init
/// is bounded at 4s and the watchdog at 12s, both longer than a fast
/// container teardown). Every notifyListeners() below is therefore guarded by
/// [_disposed], and the auth subscription is cancelled immediately if
/// disposal wins the race against its own assignment.
class _DeferredAuthRefreshListenable extends ChangeNotifier {
  _DeferredAuthRefreshListenable(Future<bool> cloudReady) {
    notifyListeners();
    unawaited(cloudReady.then((ready) {
      if (_disposed) return;
      _cloudReady = ready;
      if (ready) {
        final client = supabaseClientOrNull();
        if (client == null) {
          // Readiness resolved true but the singleton is unusable (e.g. an
          // abandoned init future after a timeout). Stay local-only.
          _cloudReady = false;
        } else {
          final subscription = client.auth.onAuthStateChange.listen((_) {
            if (_disposed) return;
            notifyListeners();
          });
          if (_disposed) {
            // dispose() ran while we were awaiting readiness, so it already
            // cancelled a still-null _subscription. Cancel ours directly or
            // it leaks for the life of the process.
            unawaited(subscription.cancel());
            return;
          }
          _subscription = subscription;
        }
      }
      if (_disposed) return;
      notifyListeners();
    }));
  }

  bool _cloudReady = false;
  bool _disposed = false;
  StreamSubscription<AuthState>? _subscription;

  /// Whether cloud initialisation succeeded. False means local-only mode:
  /// no account system exists, so auth gating must not apply.
  bool get cloudReady => _cloudReady;

  bool get isSignedIn {
    if (!_cloudReady) return false;
    return supabaseClientOrNull()?.auth.currentSession != null;
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

/// Root navigator key. Lets dependency-light surfaces that may sit outside the
/// normal screen tree — notably the global crash screen ([AppErrorScreen],
/// wired via ErrorWidget.builder) — drive navigation to recover.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

final routerProvider = Provider<GoRouter>((ref) {
  // Wire GoRouter to the auth stream once the cloud is ready; redirects
  // re-run on readiness and on every subsequent auth change.
  final refreshListenable = _DeferredAuthRefreshListenable(
    ref.read(cloudReadinessProvider),
  );
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    observers: [SentryNavigatorObserver()],
    // Unmatched location: a stale deep link, a hand-typed URL, or a path
    // renamed out from under an old notification payload. Without this,
    // go_router falls back to its own unstyled error page — a white Material
    // scaffold with a raw exception dump — which is both an abrupt visual
    // break on an AMOLED-black app and a near dead end. [AppErrorScreen] is
    // deliberately self-contained (no Material/Theme ancestor required), and
    // its two actions — Restart GymLog (/splash) and Go Home (/) — are
    // exactly the two recoveries an unmatched route needs. It paints from
    // the static palette rather than the live accent, which is the accepted
    // cost of reusing the one branded error surface instead of inventing a
    // second one.
    errorBuilder: (context, state) => const AppErrorScreen(),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Local-only mode: there is no account system, so gating every route
      // on auth can only dead-end the app on a sign-in screen that cannot
      // work. Let navigation proceed; cloud features degrade individually.
      if (!refreshListenable.cloudReady) return null;

      // Splash owns startup navigation and must run without interference.
      // Onboarding is NOT exempt: it persists profile data and therefore
      // requires an authenticated session. Splash only routes there with a
      // live user; anything else (stale history, a hand-typed URL) falls
      // through to the auth gate below instead of reaching a screen that
      // would silently write to no account.
      if (location == '/splash') return null;

      final isSignedIn = refreshListenable.isSignedIn;
      final isAuthRoute = location == '/auth';

      // Redirect unauthenticated users to auth
      if (!isSignedIn && !isAuthRoute) return '/auth';

      // Redirect authenticated users away from auth screen, but always send
      // them through /splash first so the onboarding gate can evaluate them.
      if (isSignedIn && isAuthRoute) return '/splash';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      // Tabbed shell. StatefulShellRoute.indexedStack keeps each branch's
      // navigator alive, so Home / Routines / Profile preserve scroll + state
      // across tab switches. Detail/active routes stay top-level (below) so
      // they push full-screen over the nav bar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/workout', builder: (c, s) => const WorkoutScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile', builder: (c, s) => const ProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/exercises/select',
        builder: (c, s) => const ExerciseSelectionScreen(),
      ),
      GoRoute(
        path: '/exercises/library',
        builder: (c, s) => const ExerciseSelectionScreen(browse: true),
      ),
      GoRoute(
        path: '/exercise/detail/:id',
        builder: (context, state) {
          final exercise = state.extra as Exercise?;
          // Path parameters are untrusted input (hand-typed URLs today,
          // deep links eventually): a non-numeric id must not throw a
          // FormatException mid-navigation. Fall back to the library.
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const ExerciseSelectionScreen(browse: true);
          return ExerciseDetailScreen(exerciseId: id, exercise: exercise);
        },
      ),
      GoRoute(
        path: '/routines/edit',
        builder: (c, s) =>
            RoutineEditorScreen(routineId: s.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/routines/explore',
        builder: (c, s) => const ExploreRoutinesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (c, s) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/help',
        builder: (c, s) => const HelpFeedbackScreen(),
      ),
      GoRoute(
        path: '/settings/personal',
        builder: (c, s) => const PersonalDetailsScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (c, s) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/settings/import',
        builder: (c, s) => const ImportScreen(),
      ),
      GoRoute(
        path: '/settings/delete-account',
        builder: (c, s) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/routines/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RoutineDetailScreen(routineId: id);
        },
      ),
      GoRoute(
        path: '/workout/active',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const ActiveWorkoutScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final disableAnimations = MediaQuery.disableAnimationsOf(context);
            if (disableAnimations) {
              return child;
            }
            final curve = animation.status == AnimationStatus.reverse
                ? Curves.easeInCubic
                : Curves.easeOutCubic;
            final curved = CurvedAnimation(parent: animation, curve: curve);
            // E5: the workout lives at the bottom of the app (the mini
            // player), so it RISES into view and SINKS back into the bar.
            // A short 12% rise + fade reads as the pill expanding into the
            // screen; the old full-height slide read as an unrelated page
            // arriving from offscreen.
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.12),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        ),
      ),
      GoRoute(
        path: '/workout/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WorkoutDetailScreen(sessionId: id);
        },
      ),
    ],
  );
});
