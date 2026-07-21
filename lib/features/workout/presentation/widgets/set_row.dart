import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/set_type.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';

import 'package:gymlog/core/models/measurement_type.dart';

// ── Shared column geometry ────────────────────────────────────────
// The header row (ExerciseBlock) and every data row (SetRow) consume these
// SAME constants so a caption can never drift from the column it labels.
// Layout, left → right: SET · PREVIOUS · KG · REPS · ✓
const double kSetColW = 48; // fixed — "1" / "W" / "D" / "F"
const double kCheckColW = 48; // fixed — completion square
const int kPrevFlex = 5; // "999kg x 99" — read-only reference, widest
const int kWeightFlex = 4; // editable number
const int kRepsFlex = 4; // editable number

/// One set inside the active workout — the most-touched interaction in the app.
///
/// Hevy-inspired restraint: weight/reps are plain numbers on the row surface
/// (no boxes), the unit lives in the column header, and the set TYPE letter
/// replaces the set NUMBER in the SET column. Set-type colors come from the
/// shared [SetType] enum so they're identical to every other screen.
///
/// ## P0-02 adaptive layout
///
/// | [MeasurementType]   | weight-slot column | reps-slot column |
/// |---------------------|--------------------|------------------|
/// | weightAndReps       | kg / lbs           | REPS             |
/// | repsOnly            | hidden             | REPS             |
/// | duration            | hidden             | SECS             |
/// | distance            | DIST (raw metres)  | hidden           |
class SetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSetState setData;
  final MeasurementType measurementType;

  /// Previous-session baseline for THIS set index. Null when no prior history.
  final double? previousWeight;
  final int? previousReps;

  /// Display/input unit ('kg' | 'lbs'). Storage stays kg; conversion happens
  /// at this boundary only (ignored for [MeasurementType.distance]).
  final String unit;
  final ValueChanged<WorkoutSetState> onChanged;
  final VoidCallback onToggleComplete;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.setData,
    this.measurementType = MeasurementType.weightAndReps,
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

  /// Rapid-tap guard — prevents a fast double-tap from toggling twice.
  bool _completing = false;

  /// When true, empty required fields briefly flash in the accent tint to
  /// signal which value is missing (instead of a silent non-response).
  bool _showValidationHint = false;

  // ── Formatting ────────────────────────────────────────────────────────────

  /// Formats a stored value for display in the weight-slot field.
  /// For [MeasurementType.distance] the value is raw metres — no unit
  /// conversion. For all others the user's preferred kg/lbs is applied.
  String _formatWeightField(double? value) {
    if (value == null || value <= 0) return '';
    if (widget.measurementType == MeasurementType.distance) {
      return value == value.truncateToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }
    final display = kgToDisplay(value, widget.unit);
    return display == display.truncateToDouble()
        ? display.toInt().toString()
        : display.toStringAsFixed(1);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

    // ── Measurement type changed ──────────────────────────────────────────
    // This can happen when the catalog resolves after exercise addition, or
    // when replaceExercise creates a new widget on the same key. Reset
    // controllers that are no longer applicable for the new type.
    if (widget.measurementType != oldWidget.measurementType) {
      if (!widget.measurementType.showsWeightColumn) {
        _weightController.text = '';
      } else if (!_weightFocus.hasFocus) {
        final t = _formatWeightField(widget.setData.weightKg);
        _weightController.value = _weightController.value.copyWith(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
      }
      if (!widget.measurementType.showsRepsColumn) {
        _repsController.text = '';
      }
      return; // skip the per-field refresh below — type change is authoritative
    }

    // ── Weight or unit changed externally ────────────────────────────────
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

  // ── Completion logic ──────────────────────────────────────────────────────

  /// Whether the set has enough data to be marked complete.
  bool get _canComplete => switch (widget.measurementType) {
        MeasurementType.weightAndReps =>
          ((widget.setData.weightKg != null && widget.setData.weightKg! > 0) ||
                  widget.previousWeight != null) &&
              (widget.setData.reps > 0 || widget.previousReps != null),
        MeasurementType.distance =>
          (widget.setData.weightKg != null && widget.setData.weightKg! > 0) ||
              widget.previousWeight != null,
        _ => // repsOnly, duration
          widget.setData.reps > 0 || widget.previousReps != null,
      };

  // ── Validation flash targets ───────────────────────────────────────────

  bool get _weightShouldFlash =>
      _showValidationHint &&
      widget.measurementType.showsWeightColumn &&
      (widget.setData.weightKg == null || widget.setData.weightKg! <= 0) &&
      widget.previousWeight == null;

  bool get _repsShouldFlash =>
      _showValidationHint &&
      widget.measurementType.showsRepsColumn &&
      widget.setData.reps <= 0 &&
      widget.previousReps == null;

  // ── Previous-session label ────────────────────────────────────────────────

  /// Last session's performance for this set index.
  /// Rendered as: "15kg x 12" | "12 reps" | "60s" | "400m" | null.
  String? get _previousLabel {
    final w = widget.previousWeight;
    final r = widget.previousReps;
    if (w == null && r == null) return null;
    return switch (widget.measurementType) {
      MeasurementType.weightAndReps => w != null
          ? '${formatWeight(w, widget.unit)}${widget.unit} x ${r ?? 0}'
          : (r != null ? '$r reps' : null),
      MeasurementType.distance => w != null
          ? '${w == w.truncateToDouble() ? w.toInt() : w.toStringAsFixed(1)}m'
          : null,
      MeasurementType.duration => r != null ? '${r}s' : null,
      _ => r != null ? '$r reps' : null, // repsOnly
    };
  }

  // ── Set-type picker ───────────────────────────────────────────────────────

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

  // ── Widgets ───────────────────────────────────────────────────────────────

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
  /// When [flashHint] is true the hint text briefly renders in a dim accent
  /// tint, signalling which field is missing a required value.
  Widget _numberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isDecimal,
    required String semanticLabel,
    required ValueChanged<String> onChanged,
    TextInputAction action = TextInputAction.next,
    String? hintText,
    bool flashHint = false,
  }) {
    final completed = widget.setData.isCompleted;
    final accent = context.accent;
    final hasFocus = focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        decoration: BoxDecoration(
          color: hasFocus
              ? accent.base.withValues(alpha: 0.12)
              : AppColors.surface3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: flashHint
                ? accent.base
                : (hasFocus
                    ? accent.base.withValues(alpha: 0.80)
                    : AppColors.borderSubtle.withValues(alpha: 0.3)),
            width: hasFocus || flashHint ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Semantics(
            label: semanticLabel,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: completed,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: action,
              keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
              cursorColor: accent.base,
              inputFormatters: [
                if (isDecimal)
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                else
                  FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(isDecimal ? 6 : 5),
              ],
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? '0',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: flashHint
                      ? accent.base.withValues(alpha: 0.85)
                      : AppColors.textTertiary,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onChanged: onChanged,
              onSubmitted: (_) => action == TextInputAction.next
                  ? FocusScope.of(context).nextFocus()
                  : FocusScope.of(context).unfocus(),
            ),
          ),
        ),
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
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

            // ── PREVIOUS — read-only reference from the last session ────
            Expanded(
              flex: kPrevFlex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    prev ?? '',
                    style: AppText.statLabel(
                      color: prev != null
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // ── WEIGHT / DISTANCE — hidden for repsOnly and duration ──────
            Expanded(
              flex: kWeightFlex,
              child: !widget.measurementType.showsWeightColumn
                  ? const SizedBox.shrink()
                  : _numberField(
                      controller: _weightController,
                      focusNode: _weightFocus,
                      isDecimal: true,
                      semanticLabel:
                          widget.measurementType == MeasurementType.distance
                              ? 'Distance in metres'
                              : 'Weight in ${widget.unit}',
                      hintText: widget.previousWeight != null
                          ? _formatWeightField(widget.previousWeight!)
                          : '0',
                      flashHint: _weightShouldFlash,
                      onChanged: (val) {
                        if (val.trim().isEmpty) {
                          widget.onChanged(
                              widget.setData.copyWith(weightKg: null));
                          return;
                        }
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          // Distance: store raw value — no kg/lbs conversion.
                          // Weight: convert from the user's display unit to kg.
                          final stored =
                              widget.measurementType == MeasurementType.distance
                                  ? parsed.clamp(0.0, 99999.0)
                                  : displayToKg(parsed, widget.unit)
                                      .clamp(0.0, 999.5);
                          widget.onChanged(
                              widget.setData.copyWith(weightKg: stored));
                        }
                      },
                    ),
            ),

            // ── REPS / SECS — hidden for distance ───────────────────────
            Expanded(
              flex: kRepsFlex,
              child: !widget.measurementType.showsRepsColumn
                  ? const SizedBox.shrink()
                  : _numberField(
                      controller: _repsController,
                      focusNode: _repsFocus,
                      isDecimal: false,
                      action: TextInputAction.done,
                      semanticLabel:
                          widget.measurementType.repsFieldSemanticLabel,
                      hintText: widget.previousReps != null
                          ? '${widget.previousReps!}'
                          : '0',
                      flashHint: _repsShouldFlash,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          widget.onChanged(widget.setData
                              .copyWith(reps: parsed.clamp(0, 99999)));
                        }
                      },
                    ),
            ),

            // ── Completion — always tappable; validation fires on miss ───
            SizedBox(
              width: kCheckColW,
              child: Semantics(
                button: true,
                label: isCompleted ? 'Mark set incomplete' : 'Complete set',
                child: GestureDetector(
                  onTap: () {
                    if (isCompleted) {
                      _onToggleComplete();
                      return;
                    }
                    if (!_canComplete) {
                      // Show which field(s) are empty for 1.4 s, then fade.
                      HapticFeedback.heavyImpact();
                      setState(() => _showValidationHint = true);
                      Future.delayed(const Duration(milliseconds: 1400), () {
                        if (mounted) {
                          setState(() => _showValidationHint = false);
                        }
                      });
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    _onToggleComplete();
                  },
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

  /// Backfills empty fields from the previous session, then toggles completion.
  /// Guards against rapid double-taps with [_completing].
  void _onToggleComplete() {
    if (_completing) return;
    _completing = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _completing = false;
    });

    if (!widget.setData.isCompleted) {
      var next = widget.setData;
      // Backfill weight-slot from previous session if still empty.
      if (widget.measurementType.showsWeightColumn &&
          (next.weightKg == null || next.weightKg! <= 0) &&
          widget.previousWeight != null) {
        next = next.copyWith(weightKg: widget.previousWeight!);
        _weightController.text = _formatWeightField(widget.previousWeight!);
      }
      // Backfill reps-slot from previous session if still empty.
      if (widget.measurementType.showsRepsColumn &&
          next.reps <= 0 &&
          widget.previousReps != null) {
        next = next.copyWith(reps: widget.previousReps!);
        _repsController.text = widget.previousReps!.toString();
      }
      if (next != widget.setData) widget.onChanged(next);
    }
    widget.onToggleComplete();
  }
}
