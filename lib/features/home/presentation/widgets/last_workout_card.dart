import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/routines/presentation/providers/training_plan_provider.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';

class LastWorkoutCard extends ConsumerWidget {
  const LastWorkoutCard({super.key, required this.onHistory});
  final VoidCallback onHistory;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestCompletedWorkoutsProvider);
    final unit = ref.watch(weightUnitProvider);
    final s = context.surface;
    final preview = latest.valueOrNull?.firstOrNull;
    final ended = preview?.session.endedAt?.toLocal();
    return AppCard(
        onTap: preview == null
            ? null
            : () => context.push('/workout/detail/${preview.session.id}'),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text('Last workout',
                    style: AppText.caption(color: s.textSecondary))),
            TextButton(
                onPressed: onHistory,
                style: TextButton.styleFrom(
                    foregroundColor: s.textPrimary,
                    minimumSize: const Size(48, 48)),
                child: const Text('History'))
          ]),
          if (latest.hasError) ...[
            Semantics(
                liveRegion: true,
                child: Text("Couldn't load your last workout",
                    style: AppText.sheetTitle(color: s.textPrimary))),
            TextButton(
                onPressed: () =>
                    ref.invalidate(latestCompletedWorkoutsProvider),
                child: const Text('Try again')),
          ] else if (latest.isLoading) ...[
            Text('Loading your last workout',
                style: AppText.body(color: s.textSecondary)),
          ] else if (preview == null) ...[
            Text('No completed workouts yet',
                style: AppText.body(color: s.textSecondary)),
          ] else ...[
            Text(
                (preview.session.name ?? '').trim().isEmpty
                    ? 'Workout'
                    : preview.session.name!,
                style: AppText.sectionHeading(color: s.textPrimary)),
            const SizedBox(height: 4),
            Text(
                '${DateFormat('d MMM yyyy · HH:mm').format(ended!)} · completed',
                style: AppText.caption(color: s.textSecondary)),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _LastFact(
                icon: Icons.timer_outlined,
                label: preview.duration.isNegative
                    ? 'Elapsed unavailable'
                    : preview.duration.inSeconds < 60
                        ? '${preview.duration.inSeconds} sec elapsed'
                        : '${preview.duration.inMinutes} min elapsed',
              ),
              _LastFact(
                icon: preview.totalVolumeKg > 0
                    ? Icons.fitness_center_rounded
                    : Icons.format_list_numbered_rounded,
                label: preview.totalVolumeKg > 0
                    ? '${NumberFormat('#,##0.#').format(kgToDisplay(preview.totalVolumeKg, unit))} ${unitLabel(unit)} volume'
                    : '${preview.totalExerciseCount} ${preview.totalExerciseCount == 1 ? 'exercise' : 'exercises'}',
              ),
            ]),
          ],
        ]));
  }
}

class _LastFact extends StatelessWidget {
  const _LastFact({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: context.surface.textSecondary),
        const SizedBox(width: 8),
        Flexible(
            child: Text(label,
                style: AppText.caption(color: context.surface.textSecondary)
                    .copyWith(fontFeatures: kTabular))),
      ]);
}
