import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.bgSurface,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.fitness_center, color: AppColors.textPrimary),
            Icon(Icons.history, color: AppColors.textPrimary),
            Icon(Icons.list, color: AppColors.textPrimary),
            Icon(Icons.show_chart, color: AppColors.textPrimary),
            Icon(Icons.person, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}
