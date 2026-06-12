import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';

/// One set inside the active workout — the most-touched interaction in the
/// entire app.
///
/// Design language (north-star aligned):
///   * Weight and reps live in clean boxed fields — large, centered,
///     tabular digits. No hidden sliders, no cramped underline inputs.
///   * Completion tints the row electric purple (never iOS green) and the
///     check seats with a confident medium impact.
///   * The set-type chip opens an explicit branded picker — no invisible
///     tap-cycling.
///   * The unit label is tappable to override kg/lbs per exercise.
///     Storage stays kg; conversion happens at this boundary only.
class SetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSetState setData;
  final double? previousWeight;
  final int? previousReps;
  final String? equipment;

  /// Display/input unit for this exercise ('kg' | 'lbs').
  final String unit;
  final VoidCallback? onUnitTap;
  final ValueChanged<WorkoutSetState> onChanged;
  final VoidCallback onToggleComplete;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.setData,
    this.previousWeight,
    this.previousReps,
    this.equipment,
    this.unit = 'kg',
    this.onUnitTap,
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
    final display = kgToDisplay(kg, widget.unit);
    final text = display == display.truncateToDouble()
        ? display.toInt().toString()
        : display.toStringAsFixed(1);
    final isBw = widget.equipment?.toLowerCase() == 'body weight';
    return isBw ? '+$text' : text;
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
    final weightChanged = widget.setData.weightKg != oldWidget.setData.weightKg;
    final unitChanged = widget.unit != oldWidget.unit;
    if ((weightChanged || unitChanged) && !_weightFocus.hasFocus) {
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

  Future<void> _pickSetType() async {
    final selected = await showBrandedPickerSheet<String>(
      context: context,
      title: 'Set Type',
      selected: widget.setData.setType,
      options: const [
        PickerOption(
          value: 'normal',
          label: 'Normal',
          subtitle: 'Working set',
          icon: Icons.fitness_center_rounded,
          color: AppColors.textPrimary,
        ),
        PickerOption(
          value: 'warmup',
          label: 'Warm-up',
          subtitle: 'Lighter prep work',
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFE0A422),
        ),
        PickerOption(
          value: 'dropset',
          label: 'Drop Set',
          subtitle: 'Reduced weight, no rest',
          icon: Icons.trending_down_rounded,
          color: Color(0xFFB98CFF),
        ),
        PickerOption(
          value: 'failure',
          label: 'Failure',
          subtitle: 'Taken to the limit',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFFF6B70),
        ),
      ],
    );
    if (selected != null && selected != widget.setData.setType) {
      widget.onChanged(widget.setData.copyWith(setType: selected));
    }
  }

  Widget _setTypeIndicator() {
    Widget pill(IconData icon, String label, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
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

    switch (widget.setData.setType) {
      case 'warmup':
        return pill(Icons.local_fire_department_rounded, 'Warm',
            const Color(0xFFE0A422));
      case 'dropset':
        return pill(
            Icons.trending_down_rounded, 'Drop', const Color(0xFFB98CFF));
      case 'failure':
        return pill(
            Icons.warning_amber_rounded, 'Fail', const Color(0xFFFF6B70));
      default:
        return Text(
          '${widget.setIndex + 1}',
          style: GoogleFonts.inter(
            color: widget.setData.isCompleted
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
    }
  }

  Widget _numberBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required double width,
    required String hint,
    required bool isDecimal,
    required ValueChanged<String> onChanged,
    TextInputAction action = TextInputAction.next,
  }) {
    final completed = widget.setData.isCompleted;
    return Container(
      width: width,
      height: 42,
      decoration: BoxDecoration(
        color: completed
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: completed,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: action,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.+]'))
            else
              FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(isDecimal ? 7 : 3),
          ],
          style: GoogleFonts.inter(
            color: completed ? AppColors.textSecondary : AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
          onSubmitted: (_) => action == TextInputAction.next
              ? FocusScope.of(context).nextFocus()
              : FocusScope.of(context).unfocus(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      color: isCompleted
          ? AppColors.accentPrimary.withValues(alpha: 0.10)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          // ── Set identifier → explicit type picker ──────────────────────
          // Locked once completed (uncheck to edit). FittedBox guarantees
          // the Warm/Drop/Fail chip can never overflow the 56px column.
          SizedBox(
            width: 56,
            child: Semantics(
              button: !isCompleted,
              label: 'Set type',
              child: GestureDetector(
                onTap: isCompleted
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _pickSetType();
                      },
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _setTypeIndicator(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Weight ──────────────────────────────────────────────────────
          _numberBox(
            controller: _weightController,
            focusNode: _weightFocus,
            width: 78,
            hint: widget.previousWeight != null
                ? formatWeight(widget.previousWeight!, widget.unit)
                : '—',
            isDecimal: true,
            onChanged: (val) {
              final clean = val.replaceFirst('+', '');
              final parsed = double.tryParse(clean);
              if (parsed != null) {
                final kg = displayToKg(parsed, widget.unit).clamp(0.0, 999.5);
                widget.onChanged(widget.setData.copyWith(weightKg: kg));
              }
            },
          ),

          // Unit label — tappable, switches kg/lbs for this exercise.
          // Locked while the set is completed.
          Semantics(
            button: !isCompleted,
            label: 'Weight unit ${widget.unit}, tap to change',
            child: GestureDetector(
              onTap: isCompleted ? null : widget.onUnitTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 36,
                height: 48,
                child: Center(
                  child: Text(
                    widget.unit,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Fixed 14px cell (not intrinsic text width) so the column
          // header in ExerciseBlock can mirror these metrics exactly.
          SizedBox(
            width: 14,
            child: Center(
              child: Text(
                '×',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Reps ────────────────────────────────────────────────────────
          _numberBox(
            controller: _repsController,
            focusNode: _repsFocus,
            width: 62,
            hint: widget.previousReps?.toString() ?? '—',
            isDecimal: false,
            action: TextInputAction.done,
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null) {
                widget.onChanged(
                    widget.setData.copyWith(reps: parsed.clamp(0, 999)));
              }
            },
          ),

          const Spacer(),

          // ── Completion check — the small victory ────────────────────────
          Semantics(
            button: true,
            label: isCompleted ? 'Mark set incomplete' : 'Complete set',
            child: GestureDetector(
              onTap: isCompleted || _canComplete
                  ? () {
                      if (!isCompleted) HapticFeedback.mediumImpact();
                      widget.onToggleComplete();
                    }
                  : null,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isCompleted
                          ? AppColors.accentPrimary
                          : AppColors.surfaceRaised,
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: _canComplete
                                  ? AppColors.accentPrimary
                                      .withValues(alpha: 0.45)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: isCompleted
                          ? Colors.white
                          : _canComplete
                              ? AppColors.accentPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.35),
                      size: 18,
                    ),
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
