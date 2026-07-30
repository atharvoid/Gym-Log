import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/chrome_tokens.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/dynamic_accent_theme.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../features/workout/presentation/providers/workout_timer_provider.dart';
import '../providers/bottom_chrome_provider.dart';

/// Minimized "workout in progress" mini player.
///
/// PLACEMENT CONTRACT: this widget FLOATS. It is positioned in [AppShell]'s
/// body Stack, [kActiveBarGap] above the nav bar, and is exactly
/// [kActiveBarHeight] tall. It must never be placed inside
/// `bottomNavigationBar` again — doing that changes the height of the bottom
/// chrome when a session starts, which re-lays-out every tab and makes the nav
/// bar itself animate downward.
///
/// Because it floats, it occludes content. Scroll views inside the shell pad
/// against [bottomChromeInsetProvider], which already accounts for this bar.
///
/// Interaction: tap OR swipe up to expand — the same two gestures every
/// now-playing bar on the platform supports, so it needs no discovery.
class ActiveWorkoutBar extends ConsumerWidget {
  const ActiveWorkoutBar({super.key});

  void _expand(BuildContext context) {
    HapticFeedback.selectionClick();
    context.push('/workout/active');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.accent;
    final timer = ref.watch(workoutTimerProvider); // "HH:MM:SS", ticks 1/s

    final workoutName = ref.watch(activeWorkoutProvider.select((s) {
      if (s == null) return 'Workout';
      final raw = s.name?.trim();
      return (raw == null || raw.isEmpty) ? 'Workout' : raw;
    }));

    // ACCESSIBILITY: one stop, one name, one action.
    //
    // excludeSemantics collapses the name+timer Column and the chevron into
    // this single node — without it a screen reader reads the composed label
    // and then the same workout name and elapsed time again as loose text.
    // It also discards the GestureDetector's tap action, so onTap is
    // re-declared here; the swipe-up shortcut has no accessible equivalent
    // and does not need one, since tap does the same thing.
    //
    // The elapsed time is a SNAPSHOT in the label, deliberately not a
    // liveRegion: this timer ticks once a second, and a live region here
    // would interrupt the user with the running time every second forever.
    return Semantics(
      container: true,
      button: true,
      label: 'Resume $workoutName, elapsed $timer',
      excludeSemantics: true,
      onTap: () => _expand(context),
      child: GestureDetector(
        onTap: () => _expand(context),
        // Swipe up to expand. Threshold is on velocity rather than distance so
        // a flick works without traversing the full bar height.
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -180) _expand(context);
        },
        child: Container(
          height: kActiveBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.chrome.activeBarBg,
            borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
            border: Border.all(
              color: accent.base.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              // Lifts the pill off the nav bar. Without this the two chrome
              // layers read as one 130dp slab.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accent.base.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              // Leading accent tile with the live pulse inside it.
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.muted,
                  borderRadius: AppRadius.badgeAll,
                ),
                child: Center(child: _ActiveIndicator(color: accent.base)),
              ),
              const SizedBox(width: 10),
              // Name + elapsed, stacked. Both facts stay legible instead of
              // fighting for a single row.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowLabel(),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      timer,
                      maxLines: 1,
                      style: AppText.statLabel(color: accent.light),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Affordance for both gestures.
              Icon(Icons.keyboard_arrow_up_rounded,
                  size: 22, color: context.chrome.textSecondary),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveIndicator extends StatefulWidget {
  final Color color;
  const _ActiveIndicator({required this.color});

  @override
  State<_ActiveIndicator> createState() => _ActiveIndicatorState();
}

class _ActiveIndicatorState extends State<_ActiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce-motion: a steady dot, no breathing.
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 * _animation.value),
                blurRadius: 6,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
