import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

Future<T?> showActionBottomSheet<T>({
  required BuildContext context,
  String? title,
  required List<ActionSheetItem> items,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ActionBottomSheetContent(
      title: title,
      items: items,
    ),
  );
}

class ActionSheetItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Color? subtitleColor;
  final void Function(BuildContext context) onTap;

  const ActionSheetItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });
}

class _ActionBottomSheetContent extends StatelessWidget {
  final String? title;
  final List<ActionSheetItem> items;

  const _ActionBottomSheetContent({
    this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // surface2 + AppRadius.sheetTop — same chrome as the branded confirm/
      // input sheets (app_dialog), so every sheet in the app matches.
      decoration: BoxDecoration(
        color: context.surface.surface2,
        borderRadius: AppRadius.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 36x4 on borderEmphasis, matching app_dialog exactly. This was
            // 40x4 on borderDefault, which made the comment above false:
            // two sheet families sitting on top of each other with visibly
            // different handles. app_dialog is the reference because it is
            // the destructive-confirm surface and was audited in A12.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.surface.borderEmphasis,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(color: context.surface.textSecondary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: context.surface.borderSubtle,
                height: 0.5,
                thickness: 0.5,
              ),
              const SizedBox(height: 16),
            ],
            ...items.map((item) => _ActionSheetItemWidget(item: item)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// SEMANTICS CONTRACT — see `docs/a11y-semantics-checklist.md` §2.2.
///
/// A row whose title and subtitle are separate `Text` widgets publishes two
/// semantics nodes, so a screen reader stops on each half and the button role
/// belongs to neither. [MergeSemantics] collapses the whole row into one
/// focusable node and lets the `InkWell`'s tap action attach to it.
///
/// This is the third place in the app that needed this fix (C30's chart rows,
/// B18's exercise rows, now here). [MergeSemantics] is used instead of the
/// explicit `Semantics(label: '$title, $subtitle')` wrapper that
/// [AppActionRow] uses: both produce one node, but merging composes the label
/// out of the text actually on screen, so it cannot drift out of sync the way
/// a hand-written label can.
class _ActionSheetItemWidget extends StatelessWidget {
  final ActionSheetItem item;

  const _ActionSheetItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MergeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => item.onTap(context),
            borderRadius: AppRadius.buttonPrimaryAll,
            splashColor: accent.base.withValues(alpha: 0.1),
            highlightColor: accent.base.withValues(alpha: 0.04),
            // minHeight, not a fixed height. 56 is the touch-target floor,
            // not a design constant: with kMaxTextScaleFactor now at 2.0
            // (C31) a title plus a wrapped subtitle no longer fits in 56dp,
            // and a SizedBox would have clipped it.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.iconBackground,
                        borderRadius: AppRadius.buttonPrimaryAll,
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            // 16/500 — off the standard scale, so derive the
                            // family from AppText.button and pin the medium
                            // weight here.
                            style: AppText.button(
                                    color: item.titleColor ??
                                        context.surface.textPrimary)
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.meta(
                                  color: item.subtitleColor ??
                                      context.surface.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
