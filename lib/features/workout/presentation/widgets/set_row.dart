import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

class SetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSetState setData;
  final double? previousWeight;
  final int? previousReps;
  final String? equipment;
  final ValueChanged<WorkoutSetState> onChanged;
  final VoidCallback onToggleComplete;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.setData,
    this.previousWeight,
    this.previousReps,
    this.equipment,
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

  String _formatWeightField(double kg) {
    if (kg <= 0) return '';
    final val = kg.toStringAsFixed(1);
    final isBw = widget.equipment?.toLowerCase() == 'body weight';
    return isBw ? '+$val' : val;
  }

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _formatWeightField(widget.setData.weightKg),
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
      final newText = _formatWeightField(widget.setData.weightKg);
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
    HapticFeedback.selectionClick();
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      color: isCompleted ? AppColors.success.withValues(alpha: 0.15) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // SET Column
          SizedBox(
            width: 64,
            child: GestureDetector(
              onTap: _cycleType,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child: () {
                    Widget buildPill(IconData icon, String label, Color color) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    switch (setType) {
                      case 'warmup':
                        return buildPill(Icons.local_fire_department, 'Warm', Colors.amber);
                      case 'dropset':
                        return buildPill(Icons.trending_down, 'Drop', AppColors.accentPrimary);
                      case 'failure':
                        return buildPill(Icons.warning_amber_rounded, 'Fail', AppColors.error);
                      case 'normal':
                      default:
                        return Text(
                          '${widget.setIndex + 1}',
                          style: GoogleFonts.inter(
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                    }
                  }(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // WEIGHT & REPS Column
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  flex: 6,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 60),
                    child: TextField(
                      controller: _weightController,
                    focusNode: _weightFocus,
                    readOnly: isCompleted,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
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
                      final cleanVal = val.replaceFirst('+', '');
                      final w = double.tryParse(cleanVal);
                      if (w != null) {
                        widget.onChanged(widget.setData.copyWith(weightKg: w));
                      }
                    },
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
              ),
                Text(' × ', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16)),
                Flexible(
                  flex: 5,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 50),
                    child: TextField(
                      controller: _repsController,
                    focusNode: _repsFocus,
                    readOnly: isCompleted,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
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
              ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // VS PREV Column
          SizedBox(
            width: 80,
            child: Text(
              widget.previousWeight != null && widget.previousReps != null
                  ? '${widget.previousWeight!.toStringAsFixed(0)}x${widget.previousReps}'
                  : '-',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),

          // Checkmark Button
          GestureDetector(
            onTap: isCompleted || _canComplete
                ? () {
                    if (!widget.setData.isCompleted) {
                      HapticFeedback.mediumImpact();
                    }
                    widget.onToggleComplete();
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
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
            ),
          ),
        ],
      ),
    );
  }
}
