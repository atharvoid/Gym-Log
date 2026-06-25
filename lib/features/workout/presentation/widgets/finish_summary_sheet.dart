import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';

/// The "finish" moment — a premium session recap + name field in one cohesive
/// sheet, replacing the bare name dialog. Shows what the user just earned
/// (duration / volume / sets), lets them name it, then save. PRs get their own
/// celebration over Home immediately after (they're computed at save time).
///
/// Returns the trimmed workout name on Finish, or null if cancelled.
Future<String?> showFinishSummarySheet({
  required BuildContext context,
  required Duration duration,
  required double volumeKg,
  required int sets,
  required String unit,
  required String initialName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FinishSummarySheet(
      duration: duration,
      volumeKg: volumeKg,
      sets: sets,
      unit: unit,
      initialName: initialName,
    ),
  );
}

String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}

class _FinishSummarySheet extends StatefulWidget {
  final Duration duration;
  final double volumeKg;
  final int sets;
  final String unit;
  final String initialName;

  const _FinishSummarySheet({
    required this.duration,
    required this.volumeKg,
    required this.sets,
    required this.unit,
    required this.initialName,
  });

  @override
  State<_FinishSummarySheet> createState() => _FinishSummarySheetState();
}

class _FinishSummarySheetState extends State<_FinishSummarySheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);

  @override
  void initState() {
    super.initState();
    // The session is done — a definitive success cue.
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _name.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Padding(
      // Lift above the keyboard when the name field is focused.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface2, AppColors.bgBase],
          ),
          borderRadius: AppRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderEmphasis,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.base.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: accent.base, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Workout complete',
                              style: AppText.sectionHeading()),
                          Text('Name it and save to your history',
                              style: AppText.caption()),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            value: _fmtDuration(widget.duration),
                            label: 'DURATION')),
                    Expanded(
                        child: _Stat(
                            value:
                                '${groupThousands(kgToDisplay(widget.volumeKg, widget.unit))} ${widget.unit}',
                            label: 'VOLUME')),
                    Expanded(
                        child: _Stat(value: '${widget.sets}', label: 'SETS')),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _name,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  cursorColor: accent.base,
                  style: AppText.value(),
                  decoration: InputDecoration(
                    labelText: 'Workout name',
                    labelStyle: AppText.caption(),
                    counterStyle: AppText.caption(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surface3,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.inputAll,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.inputAll,
                      borderSide:
                          BorderSide(color: accent.base, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Finish',
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.heroStat(), maxLines: 1),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.columnHeader(color: AppColors.textSecondary)),
      ],
    );
  }
}
