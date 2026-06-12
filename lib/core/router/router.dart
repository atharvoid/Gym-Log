import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/exercises/presentation/screens/exercise_selection_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  // Wire GoRouter to Supabase auth stream so redirects re-run on login/logout
  final refreshStream = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Allow splash and onboarding to run without interference
      if (location == '/splash' || location == '/onboarding') return null;

      final isSignedIn = ref.read(authProvider) != null;
      final isAuthRoute = location == '/auth';

      // Redirect unauthenticated users to auth
      if (!isSignedIn && !isAuthRoute) return '/auth';

      // Redirect authenticated users away from auth screen
      if (isSignedIn && isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/workout', builder: (c, s) => const WorkoutScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
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
        path: '/routines/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RoutineDetailScreen(routineId: id);
        },
      ),
      GoRoute(
        path: '/workout/active',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: ActiveWorkoutScreen(),
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
