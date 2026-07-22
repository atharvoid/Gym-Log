import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/chrome_tokens.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/dynamic_accent_theme.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../features/workout/presentation/providers/workout_timer_provider.dart';

/// Minimized "workout in progress" bar shown above the bottom nav while a
/// session is live. Decluttered & compact: a pulsing active indicator,
/// the workout name, and the elapsed timer. Tapping anywhere expands /workout/active.
class ActiveWorkoutBar extends ConsumerWidget {
  const ActiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.accent;
    final timer = ref.watch(workoutTimerProvider); // "HH:MM:SS", ticks 1/s

    final workoutName = ref.watch(activeWorkoutProvider.select((s) {
      if (s == null) return 'Workout';
      final raw = s.name?.trim();
      return (raw == null || raw.isEmpty) ? 'Workout' : raw;
    }));

    return Semantics(
      button: true,
      label: 'Resume workout, elapsed $timer',
      child: GestureDetector(
        onTap: () => context.push('/workout/active'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.chrome.activeBarBg,
            borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
            border: Border.all(color: context.surface.borderDefault, width: 1),
          ),
          child: Row(
            children: [
              // Subtle pulsing active indicator
              _ActiveIndicator(color: accent.base),
              const SizedBox(width: 12),
              // Workout Title
              Expanded(
                child: Text(
                  workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle(),
                ),
              ),
              const SizedBox(width: 12),
              // Elapsed duration/timer
              Text(
                timer,
                style: AppText.value(color: accent.light),
              ),
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
