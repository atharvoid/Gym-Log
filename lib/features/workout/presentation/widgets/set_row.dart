import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/set_type.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';

// ── Shared column geometry ────────────────────────────────────────
// The header row (ExerciseBlock) and every data row (SetRow) consume these
// SAME constants so a caption can never drift from the column it labels.
// Layout, left → right: SET · PREVIOUS · KG · REPS · ✓
const double kSetColW = 44; // fixed — "1" / "W" / "D" / "F"
const double kCheckColW = 44; // fixed — completion square
const int kPrevFlex = 5; // "999kg x 99" — read-only reference, widest
const int kWeightFlex = 4; // editable number
const int kRepsFlex = 4; // editable number

/// One set inside the active workout — the most-touched interaction in the app.
///
/// Hevy-inspired restraint: weight/reps are plain numbers on the row surface
/// (no boxes), the unit lives in the column header, and the set TYPE letter
/// replaces the set NUMBER in the SET column. Set-type colors come from the
/// shared [SetType] enum so they're identical to every other screen.
class SetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSetState setData;

  /// Previous-session baseline for THIS set index. Null when no prior history.
  final double? previousWeight;
  final int? previousReps;

  /// Display/input unit ('kg' | 'lbs'). Storage stays kg; conversion happens
  /// at this boundary only.
  final String unit;
  final ValueChanged<WorkoutSetState> onChanged;
  final VoidCallback onToggleComplete;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.setData,
    this.previousWeight,
    this.previousReps,
    this.unit = 'kg',
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
    return display == display.truncateToDouble()
        ? display.toInt().toString()
        : display.toStringAsFixed(1);
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
      (widget.setData.weightKg > 0 || widget.previousWeight != null) &&
      (widget.setData.reps > 0 || widget.previousReps != null);

  /// Last session's performance for this set index → "15kg x 12".
  String? get _previousLabel {
    final w = widget.previousWeight;
    final r = widget.previousReps;
    if (w == null || r == null) return null;
    return '${formatWeight(w, widget.unit)}${widget.unit} x $r';
  }

  Future<void> _pickSetType() async {
    final selected = await showBrandedPickerSheet<String>(
      context: context,
      title: 'Set Type',
      selected: widget.setData.setType,
      options: [
        for (final t in SetType.values)
          PickerOption(
            value: t.raw,
            label: t.label,
            subtitle: t.subtitle,
            icon: t.icon,
            color: t.color,
          ),
      ],
    );
    if (selected != null && selected != widget.setData.setType) {
      widget.onChanged(widget.setData.copyWith(setType: selected));
    }
  }

  /// SET column content: the type letter REPLACES the number (Hevy pattern).
  /// Normal → set number; W/D/F → coloured letter (colors from [SetType]).
  Widget _setTypeIndicator() {
    final type = SetType.of(widget.setData.setType);
    final isNormal = type == SetType.normal;
    final label = isNormal ? '${widget.setIndex + 1}' : type.short;
    final color = isNormal
        ? (widget.setData.isCompleted
            ? AppColors.textPrimary
            : AppColors.textSecondary)
        : type.color;
    return Text(label, style: AppText.value(color: color));
  }

  /// A bare value field — no box, border, fill, or radius. The number sits
  /// directly on the row surface; focus is signalled only by the cursor
  /// (tinted with the active accent palette).
  ///
  /// Horizontal padding expands the tap target so a finger lands on the
  /// number field with room, not edge-to-edge.
  Widget _numberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isDecimal,
    required String semanticLabel,
    required ValueChanged<String> onChanged,
    TextInputAction action = TextInputAction.next,
    String? hintText,
  }) {
    final completed = widget.setData.isCompleted;
    return Semantics(
      label: semanticLabel,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: completed,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: action,
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        cursorColor: context.accent.base,
        inputFormatters: [
          if (isDecimal)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          else
            FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(isDecimal ? 6 : 3),
        ],
        style: AppText.value(),
        decoration: InputDecoration(
          hintText: hintText ?? '–',
          hintStyle: AppText.value(color: AppColors.textTertiary),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onChanged: onChanged,
        onSubmitted: (_) => action == TextInputAction.next
            ? FocusScope.of(context).nextFocus()
            : FocusScope.of(context).unfocus(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;
    final prev = _previousLabel;
    // Honor OS reduce-motion: the completion tint + check-pop become instant.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      // Completed row = 3px green left border + 6% green tint (not a full fill).
      // Completion is a fixed success semantic — like reward gold, it never
      // shifts with the accent palette.
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.completionTint : Colors.transparent,
        border: isCompleted
            ? const Border(left: BorderSide(color: AppColors.success, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            // ── SET — type letter replaces number, opens the type picker ──
            SizedBox(
              width: kSetColW,
              child: Semantics(
                button: !isCompleted,
                label: 'Set type, ${SetType.of(widget.setData.setType).label}',
                child: GestureDetector(
                  onTap: isCompleted
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          _pickSetType();
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _setTypeIndicator(),
                  ),
                ),
              ),
            ),

            // ── PREVIOUS — read-only "15kg x 12" from the last session ────
            Expanded(
              flex: kPrevFlex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    prev ?? '—',
                    style: AppText.statLabel(
                      color: prev != null
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // ── KG — bare number, unit lives in the header ────────────
            Expanded(
              flex: kWeightFlex,
              child: _numberField(
                controller: _weightController,
                focusNode: _weightFocus,
                isDecimal: true,
                semanticLabel: 'Weight in ${widget.unit}',
                hintText: widget.previousWeight != null
                    ? _formatWeightField(widget.previousWeight!)
                    : '–',
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    final kg =
                        displayToKg(parsed, widget.unit).clamp(0.0, 999.5);
                    widget.onChanged(widget.setData.copyWith(weightKg: kg));
                  }
                },
              ),
            ),

            // ── REPS — bare number ───────────────────────────────
            Expanded(
              flex: kRepsFlex,
              child: _numberField(
                controller: _repsController,
                focusNode: _repsFocus,
                isDecimal: false,
                action: TextInputAction.done,
                semanticLabel: 'Reps',
                hintText: widget.previousReps != null
                    ? '${widget.previousReps!}'
                    : '–',
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    widget.onChanged(
                        widget.setData.copyWith(reps: parsed.clamp(0, 999)));
                  }
                },
              ),
            ),

            // ── Completion — green square (done) / outline (ready/idle) ────
            SizedBox(
              width: kCheckColW,
              child: Semantics(
                button: true,
                label: isCompleted ? 'Mark set incomplete' : 'Complete set',
                child: GestureDetector(
                  onTap: isCompleted || _canComplete
                      ? () {
                          if (!isCompleted) HapticFeedback.mediumImpact();
                          _onToggleComplete();
                        }
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(isCompleted),
                      tween: Tween<double>(
                        begin: isCompleted ? 1.15 : 1.0,
                        end: 1.0,
                      ),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 100),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.badgeAll,
                          color: isCompleted
                              ? AppColors.success
                              : Colors.transparent,
                          border: isCompleted
                              ? null
                              : Border.all(
                                  color: _canComplete
                                      ? AppColors.success
                                          .withValues(alpha: 0.55)
                                      : AppColors.textPrimary
                                          .withValues(alpha: 0.15),
                                ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: isCompleted
                              ? AppColors.textPrimary
                              : _canComplete
                                  ? AppColors.success.withValues(alpha: 0.7)
                                  : AppColors.textPrimary
                                      .withValues(alpha: 0.10),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Commits any available previous-session values into empty fields, then
  /// toggles completion. If the user already typed a value, it is preserved.
  void _onToggleComplete() {
    if (!widget.setData.isCompleted) {
      // Commit BOTH previous-session values in ONE mutation. The old code
      // emitted two onChanged calls, each derived from the STALE widget.setData,
      // so the second overwrote the first (weight reset to 0, and a multi-digit
      // value could render as a single leftover digit). Build one updated set
      // from a single base and emit it once.
      var next = widget.setData;
      if (next.weightKg <= 0 && widget.previousWeight != null) {
        next = next.copyWith(weightKg: widget.previousWeight!);
        _weightController.text = _formatWeightField(widget.previousWeight!);
      }
      if (next.reps <= 0 && widget.previousReps != null) {
        next = next.copyWith(reps: widget.previousReps!);
        _repsController.text = widget.previousReps!.toString();
      }
      if (next != widget.setData) widget.onChanged(next);
    }
    widget.onToggleComplete();
  }
}
