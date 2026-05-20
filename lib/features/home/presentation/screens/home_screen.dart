import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/shared/widgets/ui/tracker_card.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/home/presentation/providers/recent_workouts_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Start Card
            TrackerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Start',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Start Empty Workout',
                    onPressed: () {
                      ref.read(activeWorkoutProvider.notifier).startWorkout();
                      context.push('/workout/active');
                    },
                    icon: Icons.add_circle_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Workout History
            Text(
              'Workout History',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            ref.watch(recentWorkoutsProvider).when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return TrackerCard(
                        child: Text(
                          'No workouts yet. Start your first workout!',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: sessions.map((session) {
                        final dateStr =
                            DateFormat('MMM d, yyyy').format(session.startedAt);
                        final volumeStr =
                            '${session.totalVolumeKg.toStringAsFixed(0)} kg';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () =>
                                context.push('/workout/detail/${session.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: TrackerCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        getWorkoutNameFallback(session.startedAt, session.name),
                                        style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        volumeStr,
                                        style: GoogleFonts.inter(
                                          color: AppColors.accentPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  error: (_, __) => TrackerCard(
                    child: Text(
                      'Failed to load recent workouts',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
