import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/app_shell.dart';
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

/// Converts a Supabase AuthState stream into a ChangeNotifier so GoRouter
/// knows to re-evaluate its redirect the moment auth state changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Root navigator key. Lets dependency-light surfaces that may sit outside the
/// normal screen tree — notably the global crash screen ([AppErrorScreen],
/// wired via ErrorWidget.builder) — drive navigation to recover.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

final routerProvider = Provider<GoRouter>((ref) {
  // Wire GoRouter to Supabase auth stream so redirects re-run on login/logout
  final refreshStream = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshStream,
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Allow splash and onboarding to run without interference
      if (location == '/splash' || location == '/onboarding') return null;

      final isSignedIn = Supabase.instance.client.auth.currentSession != null;
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
          final id = int.parse(state.pathParameters['id']!);
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
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: curve,
              )),
              child: child,
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
