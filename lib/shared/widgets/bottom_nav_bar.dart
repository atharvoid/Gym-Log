import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/chrome_tokens.dart';
import '../../core/theme/dynamic_accent_theme.dart';
import '../../core/theme/app_text.dart';

/// [bottom_nav_bar.dart]
/// 3-tab navigation (Home, Routines, Profile). Driven by the parent
/// StatefulNavigationShell: [currentIndex] is the active branch and
/// [onTap] switches branches (which preserves each tab's state/scroll).
///
/// Active-tab indicator: a small accent underline drawn INSIDE each tab cell,
/// directly under its label — centered by construction, no cross-bar math.
/// The active color follows the user's chosen accent palette.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Height of the navigation bar excluding the system safe-area inset.
  /// This is the ONLY place the nav height is declared. `build` below consumes
  /// it rather than repeating a literal, so the constant can never drift from
  /// the rendered pixels — the shell's inset math depends on that guarantee.
  static const height = 72.0;

  /// Nav height INCLUDING the system gesture/safe-area inset.
  ///
  /// Anything positioning itself above the nav bar (the floating active-workout
  /// bar, a FAB, a docked CTA) should use this instead of adding
  /// `MediaQuery.viewPaddingOf(context).bottom` at the call site.
  static double totalHeight(BuildContext context) =>
      height + MediaQuery.viewPaddingOf(context).bottom;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    _NavItem(icon: Icons.home_filled, label: 'Home'),
    _NavItem(icon: Icons.fitness_center, label: 'Routines'),
    _NavItem(icon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.chrome.navBackground,
        border: Border(
          top: BorderSide(width: 1, color: context.chrome.separator),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _tabs[i],
                    isActive: i == currentIndex,
                    index: i,
                    total: _tabs.length,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final int index;
  final int total;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.index,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final color = isActive ? accent.light : context.chrome.textSecondary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // ACCESSIBILITY CONTRACT for a tab cell. All five parts matter:
    //
    //   container + excludeSemantics — the cell is ONE stop in the traversal.
    //     Without excludeSemantics the inner Text publishes its own node, so a
    //     screen reader lands on a nameless button and then, separately, on the
    //     word "Home". Two stops, neither of them complete.
    //   onTap — MANDATORY whenever excludeSemantics is used. Excluding the
    //     subtree also discards the GestureDetector's tap action, so without
    //     re-declaring it here the tab announces as a button and then ignores
    //     TalkBack's double-tap. Same callback as the gesture, so the haptic
    //     and the branch switch behave identically either way.
    //   label — the annotation node has no name of its own; the icon is
    //     decorative and Text semantics are now excluded, so the name must be
    //     supplied here or the tab is announced as an unlabelled button.
    //   inMutuallyExclusiveGroup — tells the platform these three are a radio
    //     set, which is what makes `selected` read as "selected" rather than
    //     "checked".
    //   position in the label — a bare "Home, selected" gives no sense of where
    //     you are in the bar. Tab N of M is the platform convention.
    return Semantics(
      container: true,
      button: true,
      selected: isActive,
      inMutuallyExclusiveGroup: true,
      label: '${item.label}, tab ${index + 1} of $total',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppText.rowLabel(
                color: color,
              ).copyWith(
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 2,
              width: isActive ? 16 : 0,
              decoration: BoxDecoration(
                color: accent.light,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
