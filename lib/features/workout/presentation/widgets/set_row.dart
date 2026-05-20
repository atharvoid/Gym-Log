import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

class SetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSetState setData;
  final double? previousWeight;
  final int? previousReps;
  final ValueChanged<WorkoutSetState> onChanged;
  final VoidCallback onToggleComplete;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.setData,
    this.previousWeight,
    this.previousReps,
    required this.onChanged,
    required this.onToggleComplete,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setData.weightKg > 0
          ? widget.setData.weightKg.toStringAsFixed(1)
          : '',
    );
    _repsController = TextEditingController(
      text: widget.setData.reps > 0 ? widget.setData.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.setData.weightKg != oldWidget.setData.weightKg &&
        widget.setData.weightKg > 0 &&
        !_weightFocus.hasFocus) {
      final newText = widget.setData.weightKg.toStringAsFixed(1);
      _weightController.value = _weightController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    if (widget.setData.reps != oldWidget.setData.reps &&
        widget.setData.reps > 0 &&
        !_repsFocus.hasFocus) {
      final newText = widget.setData.reps.toString();
      _repsController.value = _repsController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  bool get _canComplete =>
      widget.setData.weightKg > 0 && widget.setData.reps > 0;

  void _cycleType() {
    final current = widget.setData.setType;
    String next;
    switch (current) {
      case 'normal':
        next = 'warmup';
        break;
      case 'warmup':
        next = 'dropset';
        break;
      case 'dropset':
        next = 'failure';
        break;
      default:
        next = 'normal';
        break;
    }
    widget.onChanged(widget.setData.copyWith(setType: next));
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;
    final setType = widget.setData.setType;

    return Container(
      color: isCompleted ? AppColors.success.withValues(alpha: 0.12) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Set Type Indicator
          GestureDetector(
            onTap: _cycleType,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: 28,
                child: Center(
                  child: setType == 'warmup'
                      ? Text(
                          'W',
                          style: GoogleFonts.inter(
                            color: AppColors.warning,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Text(
                          '${widget.setIndex + 1}',
                          style: GoogleFonts.inter(
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Previous History
          SizedBox(
            width: 60,
            child: Text(
              widget.previousWeight != null && widget.previousReps != null
                  ? '${widget.previousWeight!.toStringAsFixed(0)}x${widget.previousReps}'
                  : '-',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Weight Input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              readOnly: isCompleted,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: widget.previousWeight?.toStringAsFixed(1) ?? 'kg',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.all(4),
              ),
              onChanged: (val) {
                final w = double.tryParse(val);
                if (w != null) {
                  widget.onChanged(widget.setData.copyWith(weightKg: w));
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Reps Input
          SizedBox(
            width: 50,
            child: TextField(
              controller: _repsController,
              focusNode: _repsFocus,
              readOnly: isCompleted,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: widget.previousReps?.toString() ?? 'reps',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.all(4),
              ),
              onChanged: (val) {
                final r = int.tryParse(val);
                if (r != null) {
                  widget.onChanged(widget.setData.copyWith(reps: r));
                }
              },
            ),
          ),

          const Spacer(),

          // Checkmark Button
          GestureDetector(
            onTap: isCompleted || _canComplete ? widget.onToggleComplete : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isCompleted
                    ? AppColors.success
                    : _canComplete
                        ? AppColors.borderSubtle
                        : AppColors.borderSubtle.withValues(alpha: 0.4),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.check_circle_outline,
                color: isCompleted
                    ? AppColors.bgBase
                    : _canComplete
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
