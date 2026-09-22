import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// Explicit action signifiers that communicate the expected result of tapping
/// an [AppActionChip].
enum ActionSignifier {
  /// No trailing icon.
  none,

  /// Downward chevron: opens a bottom sheet or dropdown.
  sheet,

  /// Forward chevron: navigates to a new screen or subview.
  navigation,

  /// Pencil icon: opens an inline or modal editor dialog.
  edit,

  /// Horizontal three-dots: opens a popup menu or options sheet.
  popup,
}

/// [AppActionChip]
/// Tier 3 of the Three-Tier Visual Grammar (Interactive Controls).
///
/// Use this for tappable chips, filters, and action selectors:
/// - The ONLY chip in the design system that carries a border ("Border = Clickable").
/// - Mandatory built-in haptic feedback.
/// - Minimum touch target (44×44 or 48×48) separated from the visual surface.
/// - Explicit action signifiers (chevrons, edit icons) indicating the tap result.
/// - Integrated disabled state when [onTap] is null.
/// - Single semantic button node (no double-wrapping over [InkWell]).
class AppActionChip extends StatelessWidget {
  /// The text label displayed on the chip.
  final String label;

  /// Optional leading icon.
  final IconData? leadingIcon;

  /// Trailing signifier indicating the interaction type. Defaults to [ActionSignifier.none].
  final ActionSignifier signifier;

  /// Tap callback. If null, the chip renders in a disabled state.
  final VoidCallback? onTap;

  /// Whether the chip is in a selected or highlighted state (uses accent border/fill).
  final bool isSelected;

  /// Custom semantic label for screen readers. Defaults to [label].
  final String? semanticLabel;

  /// Visual height of the chip. Defaults to 34.
  final double visualHeight;

  /// Minimum touch target size. Defaults to 48.
  final double minTouchTarget;

  /// Border radius for the chip. Defaults to [AppRadius.badgeAll] (8px).
  final BorderRadius borderRadius;

  /// Optional custom text color.
  final Color? textColor;

  /// Optional custom background color.
  final Color? backgroundColor;

  /// Optional custom border color.
  final Color? borderColor;

  /// Custom haptic feedback function. Defaults to [HapticFeedback.selectionClick].
  final VoidCallback? customHaptic;

  /// Internal flag indicating whether this is a compact square chip.
  final bool _isSquare;

  /// Standard horizontal action chip.
  const AppActionChip({
    super.key,
    required this.label,
    this.onTap,
    this.leadingIcon,
    this.signifier = ActionSignifier.none,
    this.isSelected = false,
    this.semanticLabel,
    this.visualHeight = 34,
    this.minTouchTarget = 48,
    this.borderRadius = AppRadius.badgeAll,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.customHaptic,
  }) : _isSquare = false;

  /// Fixed-geometry squircle constructor for tight grid/table slots (e.g. SetRow).
  ///
  /// Fits strictly within constrained columns like `kSetColW = 38` while
  /// maintaining a safe 44×44 minimum hit target via transparent touch slop.
  const AppActionChip.compactSquare({
    super.key,
    required this.label,
    this.onTap,
    this.semanticLabel,
    double size = 28,
    this.minTouchTarget = 44,
    BorderRadius? borderRadius,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.customHaptic,
  })  : visualHeight = size,
        leadingIcon = null,
        signifier = ActionSignifier.none,
        isSelected = false,
        borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(6)),
        _isSquare = true;

  IconData? _signifierIcon(ActionSignifier s) {
    switch (s) {
      case ActionSignifier.sheet:
        return Icons.keyboard_arrow_down_rounded;
      case ActionSignifier.navigation:
        return Icons.chevron_right_rounded;
      case ActionSignifier.edit:
        return Icons.edit_outlined;
      case ActionSignifier.popup:
        return Icons.more_horiz_rounded;
      case ActionSignifier.none:
        return null;
    }
  }

  void _handleTap() {
    if (onTap == null) return;
    if (customHaptic != null) {
      customHaptic!();
    } else {
      HapticFeedback.selectionClick();
    }
    onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;
    final isEnabled = onTap != null;

    // Resolve colors based on state (disabled / selected / default)
    final Color effectiveBg;
    final Color effectiveBorder;
    final Color effectiveFg;

    if (!isEnabled) {
      effectiveBg = backgroundColor ?? surface.surface2.withValues(alpha: 0.5);
      effectiveBorder =
          borderColor ?? surface.borderSubtle.withValues(alpha: 0.3);
      effectiveFg = textColor ?? surface.textDisabled;
    } else if (isSelected) {
      effectiveBg = backgroundColor ?? accent.muted;
      effectiveBorder = borderColor ?? accent.selectionBorder;
      effectiveFg = textColor ?? accent.light;
    } else {
      effectiveBg = backgroundColor ?? surface.surface2;
      effectiveBorder = borderColor ?? surface.borderSubtle;
      effectiveFg = textColor ?? surface.textPrimary;
    }

    final signIcon = _signifierIcon(signifier);

    Widget chipContent;
    if (_isSquare) {
      chipContent = SizedBox(
        width: visualHeight,
        height: visualHeight,
        child: Center(
          child: Text(
            label,
            style: AppText.statLabel(color: effectiveFg).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      chipContent = Container(
        height: visualHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 15,
                color: effectiveFg,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppText.statLabel(color: effectiveFg),
              ),
            ),
            if (signIcon != null) ...[
              const SizedBox(width: 4),
              Icon(
                signIcon,
                size: 15,
                color: isEnabled
                    ? (isSelected ? accent.light : surface.textTertiary)
                    : surface.textDisabled,
              ),
            ],
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label: semanticLabel ?? label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? _handleTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTouchTarget,
            minHeight: minTouchTarget,
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isEnabled ? 1.0 : 0.40,
              child: Material(
                color: effectiveBg,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius,
                  side: BorderSide(
                    color: effectiveBorder,
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: isEnabled ? _handleTap : null,
                  // Exclude semantics from InkWell to prevent duplicate button announcements
                  excludeFromSemantics: true,
                  child: chipContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
