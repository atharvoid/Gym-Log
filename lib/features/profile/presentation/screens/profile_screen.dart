import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui/tracker_card.dart';
import '../../../../shared/widgets/ui/secondary_button.dart';
import '../../../../shared/widgets/ui/toggle_pill.dart';

/// [profile_screen.dart]
/// Purpose: High-Density Tracker - Profile Tab with Dashboard & Feed
/// Dependencies: flutter/material.dart, google_fonts, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedMetric = 'Duration';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Username & Workout Count Only
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'noobyoume',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Workouts: 147',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
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

              // Mock Chart Area
              TrackerCard(
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    'Chart Area',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TogglePill(
                      label: 'Duration',
                      isActive: _selectedMetric == 'Duration',
                      onTap: () => setState(() => _selectedMetric = 'Duration'),
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

              // Action Buttons: Vertical Stack
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SecondaryButton(
                    label: 'Statistics',
                    onPressed: () {},
                    icon: Icons.bar_chart,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Exercises',
                    onPressed: () {},
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Measures',
                    onPressed: () {},
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Calendar',
                    onPressed: () {},
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
