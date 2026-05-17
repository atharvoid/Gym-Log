import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// [bottom_nav_bar.dart]
/// Purpose: Brutalist bottom navigation bar with active state
/// Dependencies: flutter/material.dart, go_router, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.6

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _tabs = [
    _NavItem(icon: Icons.fitness_center, label: 'Log', path: '/log'),
    _NavItem(icon: Icons.history, label: 'History', path: '/history'),
    _NavItem(icon: Icons.list, label: 'Routines', path: '/routines'),
    _NavItem(icon: Icons.show_chart, label: 'Analytics', path: '/analytics'),
    _NavItem(icon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -3),
            color: AppColors.accent,
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              final isActive = location == tab.path;
              return _NavButton(
                item: tab,
                isActive: isActive,
                onTap: () => context.go(tab.path),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.accent,
                border: const Border.symmetric(
                  vertical: BorderSide(color: AppColors.border, width: 2),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isActive ? AppColors.accentFg : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.label(context).copyWith(
                color: isActive ? AppColors.accentFg : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
