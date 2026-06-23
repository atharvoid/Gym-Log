import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// [segmented_control.dart]
/// One container with a sliding active segment (NOT three separate pills).
/// Track: transparent fill, borderEmphasis hairline, AppRadius.segmentedOuter.
/// Active segment: surface4 fill (a neutral RAISED surface — intentionally NOT
/// the accent, so a Phase 7 dynamic-accent theme never recolors filter
/// toggles), AppRadius.segmentedInner. Active label textPrimary / w600,
/// inactive label textSecondary / w400.
class SegmentedControl extends StatelessWidget {
  final List<String> segments;
  final String selected;
  final ValueChanged<String> onChanged;

  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final idx = segments.indexOf(selected).clamp(0, segments.length - 1);
    // Honor OS reduce-motion: the active highlight jumps instead of sliding.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.segmentedOuter),
        border: Border.all(color: AppColors.borderEmphasis),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / segments.length;
          return Stack(
            children: [
              // Sliding active highlight (behind the labels). Neutral raised
              // surface, NOT the accent — keeps filter toggles accent-agnostic.
              AnimatedPositioned(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: idx * segW,
                width: segW,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface4,
                    borderRadius:
                        BorderRadius.circular(AppRadius.segmentedInner),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final s in segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: s == selected
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onChanged(s);
                              },
                        child: Center(
                          child: Text(
                            s,
                            style: AppText.rowLabel(
                              color: s == selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ).copyWith(
                              fontWeight: s == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
