import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// [app_card.dart]
/// Shared card surface for the whole app — the "felt-not-seen" near-black
/// gradient fill + a 1px white-6% hairline + the system card radius.
///
/// This is the single source of truth for card chrome. Features must not
/// re-declare gradients/borders or reach into another feature's style class
/// for one (Home previously imported the routines feature's `RDStyles` for
/// exactly this). Skeletons reuse [AppCard.decoration] so the loading
/// placeholder is geometrically identical to the real card and never "pops"
/// on swap.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.onTap,
    this.radius = AppRadius.card,
  });

  /// Canonical card decoration, exposed for non-interactive stand-ins
  /// (skeletons) so they render identical geometry to the real card.
  static BoxDecoration decoration({double radius = AppRadius.card}) =>
      BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      );

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: decoration(radius: radius),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
    // Clip the ink ripple to the rounded corners via the container.
    return Container(
      decoration: decoration(radius: radius),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
