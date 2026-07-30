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
        border: Border.all(color: context.surface.borderEmphasis),
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
                    color: context.surface.surface4,
                    borderRadius:
                        BorderRadius.circular(AppRadius.segmentedInner),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: _Segment(
                        label: segments[i],
                        isSelected: segments[i] == selected,
                        index: i,
                        total: segments.length,
                        onSelect: () => onChanged(segments[i]),
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

/// One segment. Extracted so the tap handler can be built once and shared by
/// the InkWell and the semantics action — inline in a collection-for there is
/// nowhere to hold the local.
class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int index;
  final int total;
  final VoidCallback onSelect;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.index,
    required this.total,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // The selected segment is genuinely inert — re-picking it would fire a
    // redundant rebuild and a haptic for no state change.
    final VoidCallback? handleTap = isSelected
        ? null
        : () {
            HapticFeedback.selectionClick();
            onSelect();
          };
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      // Declared honestly. Previously this said button: true while handing the
      // InkWell a null onTap, so the active segment announced itself as
      // actionable and then did nothing when activated.
      enabled: handleTap != null,
      label: '$label, ${index + 1} of $total',
      // Wrapper owns the name; the inner Text must not publish a duplicate
      // node. Excluding the subtree also discards InkWell's tap action, hence
      // the explicit onTap.
      excludeSemantics: true,
      onTap: handleTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.segmentedInner),
          onTap: handleTap,
          child: Center(
            child: Text(
              label,
              style: AppText.rowLabel(
                color: isSelected
                    ? context.surface.textPrimary
                    : context.surface.textSecondary,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
