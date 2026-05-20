import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/exercises/presentation/screens/exercise_selection_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/routines/presentation/screens/routine_editor_screen.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../core/database/database.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Allow splash to run its 2-second delay without interference
      if (location == '/splash') return null;

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
        path: '/exercise/detail',
        builder: (context, state) {
          final exercise = state.extra as Exercise;
          return ExerciseDetailScreen(exercise: exercise);
        },
      ),
      GoRoute(
        path: '/routines/edit',
        builder: (c, s) => const RoutineEditorScreen(),
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
