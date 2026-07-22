import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Subtle banner overlaid when only 1–2 weeks of data exist.
class ProfileGraphLowDataBanner extends StatelessWidget {
  const ProfileGraphLowDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface.surface4,
        borderRadius: AppRadius.badgeAll,
        border: Border.all(color: surface.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: surface.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Log 2 more workouts to unlock your full trend.',
            style: AppText.caption(),
          ),
        ],
      ),
    );
  }
}
