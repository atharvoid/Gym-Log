import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// Branded confirmation dialog — the single replacement for every stock
/// `AlertDialog` confirm in the app, so destructive flows look and feel
/// identical everywhere. Destructive confirms fire a warning haptic BEFORE
/// the dialog appears. Returns true when the user confirms.
///
/// Non-destructive accents (info icon, confirm fill, icon wash) track the
/// active accent palette via [BuildContext.accent]; destructive flows stay
/// red because danger is a fixed semantic, never a personalization.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  if (isDestructive) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.lightImpact();
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final accent = sheetCtx.accent;
      final iconBg =
          isDestructive ? AppColors.error.withValues(alpha: 0.1) : accent.muted;
      final iconWidget = isDestructive
          ? const Icon(Icons.delete_outline_rounded,
              size: 36, color: AppColors.error)
          : Icon(Icons.info_outline_rounded, size: 36, color: accent.light);
      final confirmBg = isDestructive ? AppColors.error : accent.base;

      return SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface2,
            borderRadius: AppRadius.sheetTop,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderEmphasis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon badge
                Container(
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: AppRadius.thumbnailAll,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: iconWidget,
                ),
                const SizedBox(height: 16),
                // Title
                Text(title,
                    style: AppText.sheetTitle(), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                // Message
                Text(message,
                    style: AppText.body(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmBg,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(sheetCtx).pop(true);
                    },
                    child: Text(confirmLabel, style: AppText.button()),
                  ),
                ),
                const SizedBox(height: 8),
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonSecondaryAll),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(false),
                    child: Text(cancelLabel,
                        style: AppText.button(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Branded single-field text input dialog (rename routine, etc.).
/// Returns the trimmed non-empty value, or null when cancelled.
Future<String?> showAppTextInputDialog({
  required BuildContext context,
  required String title,
  required String hint,
  String? initialValue,
  String confirmLabel = 'Save',
  int maxLength = 50,
}) {
  HapticFeedback.selectionClick();
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) {
      return _AppTextInputDialogContent(
        title: title,
        hint: hint,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        maxLength: maxLength,
      );
    },
  );
}

class _AppTextInputDialogContent extends StatefulWidget {
  final String title;
  final String hint;
  final String? initialValue;
  final String confirmLabel;
  final int maxLength;

  const _AppTextInputDialogContent({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.maxLength,
  });

  @override
  State<_AppTextInputDialogContent> createState() =>
      _AppTextInputDialogContentState();
}

class _AppTextInputDialogContentState
    extends State<_AppTextInputDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;

    return Dialog(
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppText.sectionHeading()),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: widget.maxLength,
                textCapitalization: TextCapitalization.words,
                cursorColor: accent.base,
                style: AppText.value(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppText.body(color: AppColors.textTertiary),
                  counterStyle: AppText.caption(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface3,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.inputAll,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputAll,
                    borderSide: BorderSide(color: accent.light, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('Cancel',
                      style: AppText.button(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _submit,
                  child: Text(widget.confirmLabel,
                      style: AppText.button(color: accent.light)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
