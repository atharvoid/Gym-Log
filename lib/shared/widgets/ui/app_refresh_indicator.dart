import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// A standardized RefreshIndicator that uses the system's active accent color
/// and a unified background color, ensuring consistent design aesthetics.
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final double displacement;
  final double edgeOffset;
  final double strokeWidth;
  final RefreshIndicatorTriggerMode triggerMode;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.strokeWidth = 3.0,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.accent.base,
      backgroundColor: context.surface.surface2,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: strokeWidth,
      triggerMode: triggerMode,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
