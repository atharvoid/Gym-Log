import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';

/// Listens to [firstRunTourProvider] and routes the user to each step's screen.
///
/// Mounted above the router via [MaterialApp.router]'s builder so it can
/// navigate to any tour destination (tab shell routes and detail routes alike).
/// Steps 0, 1, 3, and 4 are driven automatically; step 2 is intentionally
/// excluded because its route is dynamic (`/routines/:id`) and is reached by
/// the user tapping "View" after importing a template.
class TourNavigationOrchestrator extends ConsumerWidget {
  final Widget child;

  /// Step index → route path. A null entry means the step is manually navigated.
  static const _stepRoutes = <int, String>{
    0: '/',
    1: '/routines/explore',
    3: '/settings',
    4: '/',
  };

  const TourNavigationOrchestrator({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(firstRunTourProvider, (previous, next) {
      if (previous == next) return;
      if (next < 0) return;

      final target = _stepRoutes[next];
      if (target == null) return;

      final router = GoRouter.of(context);
      final currentPath = router.routeInformationProvider.value.uri.path;
      if (currentPath != target) {
        router.go(target);
      }
    });

    return child;
  }
}
