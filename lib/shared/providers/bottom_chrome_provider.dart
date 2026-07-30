import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../widgets/bottom_nav_bar.dart';

/// [bottom_chrome_provider.dart]
/// The single source of truth for "how much space is the app chrome eating at
/// the bottom of the screen right now".
///
/// Why this exists: the active-workout bar used to be stacked INSIDE
/// `bottomNavigationBar`, which pushed the nav bar up and shrank every list by
/// ~62dp whenever a session was live. Making it float over the content is the
/// right fix visually, but a floating bar occludes list content unless every
/// scroll view pads against it. Rather than sprinkle `+ 100` literals across
/// screens (they always rot), screens read [bottomChromeInsetProvider].
///
/// Usage in any scrollable inside the shell:
/// ```dart
/// final inset = ref.watch(bottomChromeInsetProvider);
/// ...
/// SliverPadding(padding: EdgeInsets.only(bottom: inset + AppSpacing.x4))
/// ```
///
/// NOTE: this deliberately excludes the system safe-area inset. Screens inside
/// [AppShell] already sit above the nav bar, which owns its own `SafeArea`.
/// Use [BottomNavBar.totalHeight] when you need the inset-inclusive value for
/// absolute positioning.

/// Height of the floating minimized-workout pill.
///
/// Declared here rather than on the widget so the inset contract is defined
/// independently of the thing that renders it — the provider must not depend on
/// widget internals, and this file is imported by screens that never build the
/// bar itself.
const double kActiveBarHeight = 56.0;

/// Gap between the floating pill and the nav bar above which it docks.
const double kActiveBarGap = 8.0;

/// Vertical space consumed by the floating pill including its gap, or 0 when no
/// session is live.
const double kActiveBarTotal = kActiveBarHeight + kActiveBarGap;

/// Bottom chrome to pad scroll content against, excluding safe-area insets.
///
/// Recomputes only when a workout starts or ends (the provider watches the
/// nullability of the session, not the session body), so this does NOT rebuild
/// on every set edit or on the 1Hz timer tick.
final bottomChromeInsetProvider = Provider<double>((ref) {
  final isWorkoutActive =
      ref.watch(activeWorkoutProvider.select((s) => s != null));
  return BottomNavBar.height + (isWorkoutActive ? kActiveBarTotal : 0.0);
});
