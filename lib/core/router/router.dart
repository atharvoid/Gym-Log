import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../features/workout/presentation/screens/log_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/log',
    routes: [
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(path: '/log', builder: (c, s) => const LogScreen()),
          GoRoute(path: '/history', builder: (c, s) => const PlaceholderScreen(title: 'History')),
          GoRoute(path: '/routines', builder: (c, s) => const PlaceholderScreen(title: 'Routines')),
          GoRoute(path: '/analytics', builder: (c, s) => const PlaceholderScreen(title: 'Analytics')),
          GoRoute(path: '/profile', builder: (c, s) => const PlaceholderScreen(title: 'Profile')),
        ],
      ),

      GoRoute(
        path: '/workout/active',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: ActiveWorkoutScreen(),
        ),
      ),

      GoRoute(
        path: '/exercise/:id',
        builder: (c, s) => PlaceholderScreen(title: 'Exercise ${s.pathParameters['id']}'),
      ),

      GoRoute(
        path: '/routine/:id/edit',
        builder: (c, s) => PlaceholderScreen(title: 'Edit Routine ${s.pathParameters['id']}'),
      ),
    ],
  );
});
