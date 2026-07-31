import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// [app_action_row.dart]
/// The canonical tappable list row used across Profile, Settings, and any
/// future grouped-list screen. Combines a leading icon, title/subtitle stack,
/// and optional trailing chevron into one Semantics-aware, InkWell-ripple row.
///
/// Replaces the duplicated `_ActionRow` (Profile) and `_Row` (Settings) widgets.
///
/// SEMANTICS CONTRACT — see `docs/a11y-semantics-checklist.md` §2.2.
/// This row publishes exactly ONE node: a button whose label is
/// "<title>, <subtitle>". Two things make that true and both are load-bearing:
///
///   * `excludeSemantics: true` suppresses the child Text nodes. Without it the
///     wrapper's label is announced and then the title and subtitle are
///     announced again underneath it — three utterances for one row, on the
///     two most row-dense screens in the app.
///   * `onTap` is declared on the Semantics node ITSELF, not left on the
///     InkWell. Excluding descendants also discards the InkWell's tap action,
///     which would leave a node that announces as a button and cannot be
///     activated. That is precisely the nav-bar regression C30 shipped and
///     then had to repair, so it is spelled out here rather than rediscovered.
///
/// Do not "simplify" this by deleting either line. They only work as a pair.
class AppActionRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  const AppActionRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPad, vertical: AppSpacing.x3),
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final trailing = onTap != null && showChevron
        ? Icon(Icons.chevron_right_rounded,
            size: 20, color: surface.textTertiary)
        : null;

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: padding,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Icon(icon,
                    size: 20, color: iconColor ?? surface.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowLabel(),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption(),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );

    // A row with no onTap is decorative chrome, not a control. It keeps its
    // children's own nodes so the text is still readable, and declares no
    // button role it could not honour.
    if (onTap == null) return child;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: subtitle == null ? title : '$title, $subtitle',
      onTap: onTap,
      child: child,
    );
  }
}

/// Static divider used inside grouped card surfaces. Indented to align with
/// the text baseline of [AppActionRow] (icon width + icon-text gap = 40dp).
class AppActionDivider extends StatelessWidget {
  const AppActionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(height: 1, color: surface.borderSubtle),
    );
  }
}
