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
    return text;
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
    Widget pill(String code, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                code,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );

    switch (widget.setData.setType) {
      case 'warmup':
        return pill('W', const Color(0xFFE0A422));
      case 'dropset':
        return pill('D', const Color(0xFFB98CFF));
      case 'failure':
        return pill('F', const Color(0xFFFF6B70));
      default:
        return Text(
          '${widget.setIndex + 1}',
          style: GoogleFonts.inter(
            color: widget.setData.isCompleted
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.7),
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
    required String hint,
    required bool isDecimal,
    required ValueChanged<String> onChanged,
    TextAlign textAlign = TextAlign.center,
    TextInputAction action = TextInputAction.next,
  }) {
    final completed = widget.setData.isCompleted;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: completed
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: completed ? null : BorderRadius.circular(4),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: completed,
          textAlign: textAlign,
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
            color: completed
                ? AppColors.textPrimary.withValues(alpha: 0.7)
                : AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
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
          ? AppColors.accentPrimary.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // ── Set identifier → explicit type picker ──────────────────────
          // Locked once completed (uncheck to edit). FittedBox guarantees
          // the Warm/Drop/Fail chip can never overflow the 48px column.
          SizedBox(
            width: 48,
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
                      const BoxConstraints(minWidth: 48, minHeight: 32),
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

          // ── Weight column (with inline unit) ─────────────────────────
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _numberBox(
                    controller: _weightController,
                    focusNode: _weightFocus,
                    hint: widget.previousWeight != null
                        ? formatWeight(widget.previousWeight!, widget.unit)
                        : '–',
                    isDecimal: true,
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      final clean = val.replaceFirst('+', '');
                      final parsed = double.tryParse(clean);
                      if (parsed != null) {
                        final kg =
                            displayToKg(parsed, widget.unit).clamp(0.0, 999.5);
                        widget.onChanged(
                            widget.setData.copyWith(weightKg: kg));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 2),
                // Unit label — tappable, switches kg/lbs for this exercise.
                // Locked while the set is completed.
                Semantics(
                  button: !isCompleted,
                  label: 'Weight unit ${widget.unit}, tap to change',
                  child: GestureDetector(
                    onTap: isCompleted ? null : widget.onUnitTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        widget.unit,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── × separator ──────────────────────────────────────────────
          SizedBox(
            width: 20,
            child: Center(
              child: Text(
                '×',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // ── Reps column ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: _numberBox(
              controller: _repsController,
              focusNode: _repsFocus,
              hint: widget.previousReps?.toString() ?? '–',
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
          ),

          // ── Completion check — the small victory ────────────────────
          SizedBox(
            width: 48,
            child: Semantics(
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
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: isCompleted ? 1.15 : 1.0,
                        end: 1.0,
                      ),
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOutBack,
                      key: ValueKey(isCompleted),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isCompleted
                              ? AppColors.accentPrimary
                              : Colors.white.withValues(alpha: 0.08),
                          border: isCompleted
                              ? null
                              : _canComplete
                                  ? Border.all(
                                      color: AppColors.accentPrimary
                                          .withValues(alpha: 0.3),
                                    )
                                  : null,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: isCompleted
                              ? Colors.white
                              : _canComplete
                                  ? AppColors.accentPrimary
                                      .withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.15),
                          size: 18,
                        ),
                      ),
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
