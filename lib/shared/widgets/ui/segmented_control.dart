import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// [segmented_control.dart]
/// One container with a sliding active segment (NOT three separate pills).
/// Spec: track bg transparent / 1px #3A3A4A border / 10px radius;
/// active segment #2A2A3A / 8px radius; active text white w600,
/// inactive text #8E8E93 w400.
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
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.segmentedOuter),
        border: Border.all(color: const Color(0xFF3A3A4A)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / segments.length;
          return Stack(
            children: [
              // Sliding active highlight (behind the labels).
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: idx * segW,
                width: segW,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
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
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: s == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: s == selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
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
