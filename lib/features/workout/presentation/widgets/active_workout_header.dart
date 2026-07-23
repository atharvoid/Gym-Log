import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/shared/layout/adaptive.dart';

const double _minSwipeVelocity = 120.0;

class ActiveWorkoutHeader extends StatelessWidget {
  final bool isEditing;
  final String workoutName;
  final String elapsedTime;
  final double volumeKg;
  final int completedSets;
  final String weightUnit;
  final bool finishEnabled;
  final VoidCallback onMinimize;
  final VoidCallback onClose;
  final VoidCallback? onFinish;

  const ActiveWorkoutHeader({
    super.key,
    required this.isEditing,
    required this.workoutName,
    required this.elapsedTime,
    required this.volumeKg,
    required this.completedSets,
    required this.weightUnit,
    required this.finishEnabled,
    required this.onMinimize,
    required this.onClose,
    this.onFinish,
  }) : assert(
          !finishEnabled || onFinish != null,
          'onFinish must be non-null when finishEnabled is true',
        );

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;
    final isCompactOrLargeText =
        context.adaptive.isCompact || context.adaptive.textScaleFactor >= 1.6;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > _minSwipeVelocity) {
          onMinimize();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface.bgBase,
          border: Border(
            bottom: BorderSide(color: surface.borderSubtle, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: SafeArea(
          bottom: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGrabHandle(surface),
                if (isCompactOrLargeText) _buildReflowedLayout(surface, accent),
                if (!isCompactOrLargeText) _buildNormalLayout(surface, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrabHandle(SurfaceTokens surface) {
    return Semantics(
      button: true,
      label: 'Minimize workout',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMinimize,
        child: Container(
          width: 60,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: surface.borderEmphasis,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(SurfaceTokens surface) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: isEditing ? 'Cancel' : 'Discard workout',
        padding: EdgeInsets.zero,
        icon: Icon(Icons.close_rounded, color: surface.textPrimary, size: 24),
        onPressed: onClose,
      ),
    );
  }

  Widget _buildNormalLayout(SurfaceTokens surface, AccentColors accent) {
    return Row(
      children: [
        _buildCloseButton(surface),
        Expanded(
          child: Center(
            child: MergeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'Edit Workout' : elapsedTime,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: surface.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEditing
                        ? elapsedTime
                        : (completedSets == 0
                            ? 'Log your first set'
                            : '${groupThousands(kgToDisplay(volumeKg, weightUnit))} $weightUnit · $completedSets set${completedSets != 1 ? 's' : ''}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: surface.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildFinishButton(surface, accent),
      ],
    );
  }

  Widget _buildReflowedLayout(SurfaceTokens surface, AccentColors accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildCloseButton(surface),
            Expanded(
              child: Center(
                child: Text(
                  isEditing ? 'Edit Workout' : workoutName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: surface.textPrimary,
                  ),
                ),
              ),
            ),
            _buildFinishButton(surface, accent),
          ],
        ),
        const SizedBox(height: 8),
        MergeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                elapsedTime,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                completedSets == 0
                    ? 'Log your first set'
                    : '${groupThousands(kgToDisplay(volumeKg, weightUnit))} $weightUnit · $completedSets set${completedSets != 1 ? 's' : ''}',
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: surface.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinishButton(SurfaceTokens surface, AccentColors accent) {
    return Semantics(
      button: true,
      enabled: finishEnabled,
      label: finishEnabled
          ? (isEditing ? 'Save workout changes' : 'Finish workout')
          : 'Finish workout, unavailable until a set is completed',
      child: Material(
        color: finishEnabled ? accent.base : surface.surface3,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: finishEnabled ? onFinish : null,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 92,
              minHeight: 48,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              isEditing ? 'Save' : 'Finish',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: finishEnabled ? accent.onAccent : surface.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
