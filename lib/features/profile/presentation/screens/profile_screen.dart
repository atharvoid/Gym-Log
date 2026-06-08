import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui/tracker_card.dart';
import '../../../../shared/widgets/ui/secondary_button.dart';
import '../../../../shared/widgets/ui/toggle_pill.dart';
import '../providers/profile_provider.dart';

/// [profile_screen.dart]
/// Purpose: High-Density Tracker — Profile tab with live stats from Drift.
/// State: workoutCountProvider, currentUserProfileProvider (StreamProviders).

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedMetric = 'Duration';

  @override
  Widget build(BuildContext context) {
    final workoutCount = ref.watch(workoutCountProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    // Derive display name: local DB profile > Supabase metadata > fallback
    final displayName = profileAsync.valueOrNull?.displayName ?? '...';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Username & live workout count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  workoutCount.when(
                    data: (count) => Text(
                      'Workouts: $count',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    loading: () => Text(
                      'Workouts: —',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart Area Header
              Row(
                children: [
                  Text(
                    '1 hour',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last 3 months',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart placeholder
              TrackerCard(
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    'Chart — Track 10',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Metric Toggle Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TogglePill(
                      label: 'Duration',
                      isActive: _selectedMetric == 'Duration',
                      onTap: () =>
                          setState(() => _selectedMetric = 'Duration'),
                    ),
                    const SizedBox(width: 8),
                    TogglePill(
                      label: 'Volume',
                      isActive: _selectedMetric == 'Volume',
                      onTap: () => setState(() => _selectedMetric = 'Volume'),
                    ),
                    const SizedBox(width: 8),
                    TogglePill(
                      label: 'Reps',
                      isActive: _selectedMetric == 'Reps',
                      onTap: () => setState(() => _selectedMetric = 'Reps'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SecondaryButton(
                    label: 'Statistics',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                    icon: Icons.bar_chart,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Exercises',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Measures',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Calendar',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                    icon: Icons.calendar_month,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
