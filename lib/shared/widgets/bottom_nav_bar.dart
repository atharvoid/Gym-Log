import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// [bottom_nav_bar.dart]
/// Purpose: High-Density Tracker - 3-tab navigation (Home, Workout, Profile)
/// Dependencies: flutter/material.dart, go_router, google_fonts, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _tabs = [
    _NavItem(icon: Icons.home_filled, label: 'Home', path: '/'),
    _NavItem(icon: Icons.fitness_center, label: 'Routines', path: '/workout'),
    _NavItem(icon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isActive ? AppColors.accentPrimary : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.inter(
                color: isActive ? AppColors.accentPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

