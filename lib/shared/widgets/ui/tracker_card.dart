import 'package:flutter/material.dart';
import 'app_card.dart';

/// [tracker_card.dart]
/// Thin compatibility wrapper over [AppCard] — kept so existing call sites
/// (empty states, etc.) don't churn. Surface/radius/border now come from the
/// shared card token, so TrackerCard matches the rest of the app exactly.
class TrackerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const TrackerCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
