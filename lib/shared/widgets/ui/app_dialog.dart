import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Branded confirmation dialog — the single replacement for every stock
/// `AlertDialog` confirm in the app, so destructive flows look and feel
/// identical everywhere. Destructive confirms fire a warning haptic BEFORE
/// the dialog appears. Returns true when the user confirms.
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
      final iconBg = isDestructive
          ? AppColors.error.withValues(alpha: 0.1)
          : AppColors.indigoTint;
      final iconWidget = isDestructive
          ? const Icon(Icons.delete_outline_rounded,
              size: 36, color: AppColors.error)
          : const Icon(Icons.info_outline_rounded,
              size: 36, color: AppColors.accentText);
      final confirmBg =
          isDestructive ? AppColors.error : AppColors.accentPrimary;

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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: iconWidget,
                ),
                const SizedBox(height: 16),
                // Title
                Text(title, style: AppText.sheetTitle(), textAlign: TextAlign.center),
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
  final controller = TextEditingController(text: initialValue);

  // Dispose the controller once the dialog closes (confirm OR dismiss) —
  // otherwise every invocation leaks a TextEditingController + focus node.
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) {
      void submit() {
        final value = controller.text.trim();
        if (value.isEmpty) return;
        Navigator.of(dialogCtx).pop(value);
      }

      return Dialog(
        backgroundColor: AppColors.surface2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.sectionHeading()),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: maxLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColors.accentPrimary,
                  style: AppText.value(),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppText.body(color: AppColors.textTertiary),
                    counterStyle:
                        AppText.caption(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surface3,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.inputAll,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.inputAll,
                      borderSide:
                          BorderSide(color: AppColors.borderActive, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(null),
                    child: Text('Cancel',
                        style: AppText.button(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: submit,
                    child: Text(confirmLabel,
                        style: AppText.button(color: AppColors.accentText)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
}
