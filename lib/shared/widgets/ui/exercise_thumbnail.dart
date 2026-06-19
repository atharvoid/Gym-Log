import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';

/// [exercise_thumbnail.dart]
/// Shared exercise thumbnail: a uniform light tile (Hevy-style) holding the
/// STATIC last frame of the exercise GIF, decoded once via
/// [gifLastFrameProvider].
///
/// Why static (not animated): a list of N exercises with animated GIFs runs N
/// looping codecs at once — sustained CPU/battery + scroll jank. The still
/// frame conveys the same posture for a thumbnail. (The exercise *detail*
/// screen can still animate the single large GIF if it wants.)
///
/// Why a light tile: exercise GIFs are baked on white, so a consistent light
/// tile makes GIF and icon-fallback thumbnails read as one set on the dark feed
/// — identical treatment on Home and Workout Detail.
class ExerciseThumbnail extends ConsumerWidget {
  final String? gifUrl;
  final double size;

  /// Decode only the GIF's first frame (cheaper) instead of walking to the
  /// last frame — for long scrollable lists like the Exercise Library, where
  /// ~400 full decodes stutter the scroll. First ≈ last for these GIFs.
  final bool fastFrame;

  const ExerciseThumbnail({
    super.key,
    required this.gifUrl,
    this.size = 52,
    this.fastFrame = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = gifUrl;

    Widget inner;
    if (url == null || url.isEmpty) {
      inner = _fallback();
    } else {
      final frameAsync = ref.watch(
          fastFrame ? gifFirstFrameProvider(url) : gifLastFrameProvider(url));
      inner = frameAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => _fallback(),
        data: (img) => img == null
            ? _fallback()
            : Image(
                image: img,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      );
    }

    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.thumbTile,
          borderRadius: AppRadius.thumbnailAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: inner,
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.thumbIcon,
          size: size * 0.42,
        ),
      );
}
