import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';

/// Hoisted, locale-stable formatter. Constructing a [DateFormat] inside build
/// re-parses the pattern + reloads locale data every frame; do it once.
final _kDayMonth = DateFormat('MMM d');

/// [workout_history_card.dart]
/// Purpose: Data-dense workout history card for the HomeScreen feed.
///
/// Layout:
///   Row: workout name (bold) + date (secondary)              [⋯ menu]
///   Row × 2: [52×52 framed GIF] exercise name (bold)   N sets
///   Text: "+ N more exercises"  (if totalExerciseCount > 2)
///   Divider
///   Stats row: volume   duration            [🏆 N PRs badge]
///
/// Surface/radius/border come from the shared [AppCard]; type from [AppText].
class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutSessionPreview preview;
  final VoidCallback? onMenuPressed;

  const WorkoutHistoryCard({
    super.key,
    required this.preview,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final session = preview.session;
    final name = getWorkoutNameFallback(session.startedAt, session.name);
    final dateStr = _kDayMonth.format(session.startedAt);
    final durationStr =
        formatWorkoutDuration(session.startedAt, session.endedAt);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      radius: 6.0,
      onTap: () {
        // Navigation/selection feedback — parity with every other tap.
        HapticFeedback.selectionClick();
        context.push('/workout/detail/${session.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: name + date, with the options menu ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppText.cardTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(dateStr, style: AppText.caption()),
                  ],
                ),
              ),
              if (onMenuPressed != null)
                IconButton(
                  tooltip: 'Workout options',
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onMenuPressed,
                ),
            ],
          ),

          // ── Exercise preview rows ───────────────────────────────────────
          if (preview.topExercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...preview.topExercises.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExerciseRow(item: item),
              ),
            ),
            if (preview.totalExerciseCount > 2)
              Text(
                '+ ${preview.totalExerciseCount - 2} more '
                'exercise${preview.totalExerciseCount - 2 > 1 ? 's' : ''}',
                style: AppText.caption(),
              ),
          ],

          const SizedBox(height: 11),
          Container(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 11),

          _StatsRow(preview: preview, durationStr: durationStr),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

/// ConsumerWidget so it can watch the global [gifLastFrameProvider], which
/// decodes + caches the GIF's last frame. The cached MemoryImage survives
/// navigation; no widget state involved.
class _ExerciseRow extends ConsumerWidget {
  final ExercisePreviewItem item;

  const _ExerciseRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Decorative — the exercise name beside it carries the meaning.
        ExcludeSemantics(child: _buildThumbnail(ref)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.exerciseName,
            style: AppText.rowLabel(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${item.setCount} set${item.setCount != 1 ? 's' : ''}',
          style: AppText.meta(),
        ),
      ],
    );
  }

  Widget _buildThumbnail(WidgetRef ref) {
    final url = item.gifUrl;

    Widget inner;
    if (url == null || url.isEmpty) {
      inner = _iconFallback();
    } else {
      final frameAsync = ref.watch(gifLastFrameProvider(url));
      inner = frameAsync.when(
        // Surface-3 fill shows through while the codec runs.
        loading: () => const SizedBox.shrink(),
        error: (_, __) => _iconFallback(),
        data: (memoryImage) => memoryImage == null
            ? _iconFallback()
            : Image(
                image: memoryImage,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      );
    }

    // RepaintBoundary isolates async thumbnail repaints from the scroll layer.
    return RepaintBoundary(child: _frame(inner));
  }

  /// Uniform light tile (Hevy-style). Exercise GIFs are baked on white, so a
  /// consistent light tile makes the GIF and icon-fallback thumbnails read as
  /// one set on the dark feed — not "bright white block vs dark block".
  Widget _frame(Widget child) => Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.thumbTile,
          borderRadius: AppRadius.thumbnailAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  Widget _iconFallback() => const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.thumbIcon,
          size: 22,
        ),
      );
}

class _StatsRow extends StatelessWidget {
  final WorkoutSessionPreview preview;
  final String durationStr;

  const _StatsRow({required this.preview, required this.durationStr});

  @override
  Widget build(BuildContext context) {
    final hasPrs = preview.prCount > 0;

    // Volume + duration are ALWAYS left-clustered at the same positions so the
    // eye holds a stable column across cards regardless of PR presence; the PR
    // badge (when present) is pushed to the trailing edge.
    return MergeSemantics(
      child: Row(
        children: [
          _StatChip(
            icon: Icons.inventory_2_outlined,
            label: _formatVolume(preview.totalVolumeKg),
          ),
          const SizedBox(width: 20),
          _StatChip(icon: Icons.timer_outlined, label: durationStr),
          if (hasPrs) ...[
            const Spacer(),
            _PrBadge(count: preview.prCount),
          ],
        ],
      ),
    );
  }

  static final _volumeFormat = NumberFormat('#,##0.##');

  /// Formats kg with thousands comma: 1488 → "1,488 kg", 980 → "980 kg".
  static String _formatVolume(double kg) {
    return '${_volumeFormat.format(kg)} kg';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(label, style: AppText.statLabel()),
      ],
    );
  }
}

/// Reward emphasis: the one place the system calls for a filled badge
/// (amber 15% fill, amber 30% border). Trophy + "PRs" label = not color-alone.
class _PrBadge extends StatelessWidget {
  final int count;
  const _PrBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.prBadgeBg,
        borderRadius: AppRadius.badgeAll,
        border: Border.all(color: AppColors.prBadgeBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              size: 13, color: AppColors.warning),
          const SizedBox(width: 4),
          Text('$count PR${count > 1 ? 's' : ''}', style: AppText.badge()),
        ],
      ),
    );
  }
}
