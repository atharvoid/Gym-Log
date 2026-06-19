import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// [bottom_nav_bar.dart]
/// 3-tab navigation (Home, Routines, Profile). Driven by the parent
/// StatefulNavigationShell: [currentIndex] is the active branch and
/// [onTap] switches branches (which preserves each tab's state/scroll).
///
/// Active-tab indicator: a small accent underline drawn INSIDE each tab cell,
/// directly under its label — centered by construction, no cross-bar math.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

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
      decoration: const BoxDecoration(color: AppColors.bgBase),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _tabs[i],
                    isActive: i == currentIndex,
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
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accentText : AppColors.textSecondary;
    return Semantics(
      selected: isActive,
      button: true,
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
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 2,
              width: isActive ? 16 : 0,
              decoration: BoxDecoration(
                color: AppColors.accentText,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
