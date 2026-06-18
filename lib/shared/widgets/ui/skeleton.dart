import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'app_card.dart';

/// Soft-pulsing skeleton bone. One shared animation phase per subtree via
/// [SkeletonPulse] so bones breathe in unison instead of flickering apart.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Higher floor (0.70, was 0.55) so bones stay visible at the pulse trough
    // against pure-black OLED — they read as "content arriving", not blank.
    // Reduce-motion: hold steady at full opacity instead of pulsing.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.70, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // 0.11 (was 0.06) ≈ #1C1C1C on black — clearly a loading placeholder
        // on OLED rather than near-invisible (#0F0F0F).
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Mirrors [WorkoutHistoryCard]'s exact proportions so the Home feed
/// doesn't jump when real data arrives: header (title+date), two exercise
/// rows with 52dp thumbnails, divider, stats row.
class WorkoutHistoryCardSkeleton extends StatelessWidget {
  const WorkoutHistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      // Identical geometry to the real card (shared decoration) so the feed
      // never reflows when content lands.
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: 6),
          const SkeletonBox(width: 64, height: 11),
          const SizedBox(height: 14),
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SkeletonBox(width: 52, height: 52, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SkeletonBox(height: 13, width: i == 0 ? 170 : 130),
                  ),
                  const SizedBox(width: 24),
                  const SkeletonBox(width: 38, height: 12),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          const Row(
            children: [
              SkeletonBox(width: 72, height: 13),
              SizedBox(width: 24),
              SkeletonBox(width: 56, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}
