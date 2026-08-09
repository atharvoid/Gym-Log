import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// [branded_bottom_sheet.dart]
/// Canonical bottom-sheet shell: drag handle, sheet background, safe-area
/// padding, and optional title/subtitle header. Keeps every branded sheet
/// (weekly goal, picker, etc.) visually identical and token-correct.
class BrandedBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const BrandedBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    // Was EdgeInsets.fromLTRB(24, 12, 24, 18) — 18 matched no AppSpacing rung.
    // Now reads entirely from the spacing scale (C28).
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.x6, AppSpacing.x3, AppSpacing.x6, AppSpacing.x5),
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;

    Widget content = SafeArea(
      top: false,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: accent.base,
                  // 2px — matches every other sheet's drag handle (app_dialog,
                  // action_bottom_sheet, finish_summary_sheet, the in-screen
                  // reorder sheet). This one alone had drifted to 6 (C28).
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 20),
              Text(title!,
                  style: AppText.sheetTitle(color: accent.base),
                  textAlign: TextAlign.start),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: AppText.body(color: surface.textSecondary),
                  textAlign: TextAlign.start),
            ],
            if (title != null || subtitle != null) const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface.surface2,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: content,
    );
  }
}

/// Convenience helper to present a [BrandedBottomSheet].
///
/// KEYBOARD CONTRACT (final-seven #3): a scrollable sheet hosts forms, and a
/// form the keyboard covers is a form no one can finish. Scrollable sheets
/// therefore always present `isScrollControlled`, and every branded sheet
/// pads its body by the live `MediaQuery.viewInsetsOf` bottom, so the
/// keyboard lifts the sheet instead of swallowing the fields. When the
/// keyboard is closed the inset is zero and nothing about the sheet changes.
Future<T?> showBrandedBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  bool useRootNavigator = true,
  bool isScrollControlled = false,
  bool scrollable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    isScrollControlled: isScrollControlled || scrollable,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: BrandedBottomSheet(
        title: title,
        subtitle: subtitle,
        scrollable: scrollable,
        child: child,
      ),
    ),
  );
}
