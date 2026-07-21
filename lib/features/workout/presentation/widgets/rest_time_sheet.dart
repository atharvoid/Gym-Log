import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// Opens the compact rest-time selection sheet for an exercise.
///
/// Returns the normalized [RestPreference] selected by the user on Save,
/// or `null` if the user cancels or dismisses the sheet.
Future<RestPreference?> showRestTimeSheet({
  required BuildContext context,
  required String exerciseName,
  required RestPreference currentPreference,
  required int globalSeconds,
}) {
  return showModalBottomSheet<RestPreference>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (_) => RestTimeSheet(
      exerciseName: exerciseName,
      currentPreference: currentPreference,
      globalSeconds: globalSeconds,
    ),
  );
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Compact rest-time sheet for exercise-level rest duration preference.
class RestTimeSheet extends StatefulWidget {
  final String exerciseName;
  final RestPreference currentPreference;
  final int globalSeconds;

  const RestTimeSheet({
    super.key,
    required this.exerciseName,
    required this.currentPreference,
    required this.globalSeconds,
  });

  @override
  State<RestTimeSheet> createState() => _RestTimeSheetState();
}

class _RestTimeSheetState extends State<RestTimeSheet> {
  late RestPreference draft;

  @override
  void initState() {
    super.initState();
    draft = normalizeRestPreference(
      preference: widget.currentPreference,
      globalSeconds: widget.globalSeconds,
    );
  }

  int get _workingSeconds {
    if (isOff(draft)) {
      return widget.globalSeconds > 0 ? widget.globalSeconds : 90;
    }
    return resolveRestSeconds(
          preference: draft,
          globalSeconds: widget.globalSeconds,
        ) ??
        (widget.globalSeconds > 0 ? widget.globalSeconds : 90);
  }

  void decrease() {
    final startSec = isOff(draft)
        ? (widget.globalSeconds > 0 ? widget.globalSeconds : 90)
        : _workingSeconds;
    setState(() {
      draft = RestPreference.custom(
        (startSec - 15).clamp(15, 600),
      );
    });
  }

  void increase() {
    final startSec = isOff(draft)
        ? (widget.globalSeconds > 0 ? widget.globalSeconds : 90)
        : _workingSeconds;
    setState(() {
      draft = RestPreference.custom(
        (startSec + 15).clamp(15, 600),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = math.max(20.0, mediaQuery.viewPadding.bottom);
    final maxHeight = mediaQuery.size.height * 0.72;

    final displaySeconds = _workingSeconds;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle: 36x4
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

                  // Title: Rest time (20/700)
                  const Text(
                    'Rest time',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Subtitle: exerciseName · This workout only (14/400)
                  Text(
                    '${widget.exerciseName} · This workout only',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),

                  // Top Option buttons: [ Default · 1:30 ] [ Off ] (option height 48)
                  Row(
                    children: [
                      Expanded(
                        child: _OptionButton(
                          height: 48,
                          isSelected: isDefault(draft),
                          label:
                              'Default · ${_formatDuration(widget.globalSeconds)}',
                          accent: accent,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              draft = const RestPreference.useDefault();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      _OptionButton(
                        height: 48,
                        isSelected: isOff(draft),
                        label: 'Off',
                        accent: accent,
                        minWidth: 80,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            draft = const RestPreference.disabled();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Header / Section label: CUSTOM
                  Text(
                    'CUSTOM',
                    style: AppText.columnHeader(color: AppColors.textSecondary),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),

                  // Stepper row: [ -15s ] (48x48) 1:30 [ +15s ] (48x48)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepperButton(
                        label: '−15s',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          decrease();
                        },
                      ),
                      const SizedBox(width: 24),
                      Text(
                        _formatDuration(displaySeconds),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _StepperButton(
                        label: '+15s',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          increase();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Presets Wrap (preset height 46)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final sec in const <int>[30, 60, 90, 120, 180, 300])
                        _PresetButton(
                          label: _formatDuration(sec),
                          isSelected: isCustomPreset(draft, sec),
                          accent: accent,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              draft = normalizeRestPreference(
                                preference: RestPreference.custom(sec),
                                globalSeconds: widget.globalSeconds,
                              );
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action buttons: [ Cancel ] [ Save ] (action height 50)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, null),
                            child: Text(
                              'Cancel',
                              style: AppText.button(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent.base,
                              foregroundColor: accent.onAccent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              final normalized = normalizeRestPreference(
                                preference: draft,
                                globalSeconds: widget.globalSeconds,
                              );
                              Navigator.pop(context, normalized);
                            },
                            child: Text(
                              'Save',
                              style: AppText.button(color: accent.onAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final double height;
  final bool isSelected;
  final String label;
  final AccentColors accent;
  final double? minWidth;
  final VoidCallback onTap;

  const _OptionButton({
    required this.height,
    required this.isSelected,
    required this.label,
    required this.accent,
    this.minWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? accent.base.withValues(alpha: 0.14) : AppColors.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? accent.base.withValues(alpha: 0.60)
              : AppColors.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: minWidth ?? height,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? accent.light : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepperButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AccentColors accent;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? accent.base.withValues(alpha: 0.14) : AppColors.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? accent.base.withValues(alpha: 0.60)
              : AppColors.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 48,
            minWidth: 80,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? accent.light : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
