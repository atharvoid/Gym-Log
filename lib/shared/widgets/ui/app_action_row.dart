import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// [app_action_row.dart]
/// The canonical tappable list row used across Profile, Settings, and any
/// future grouped-list screen. Combines a leading icon, title/subtitle stack,
/// and optional trailing chevron into one Semantics-aware, InkWell-ripple row.
///
/// Replaces the duplicated `_ActionRow` (Profile) and `_Row` (Settings) widgets.
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

    if (onTap == null) return child;

    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
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
