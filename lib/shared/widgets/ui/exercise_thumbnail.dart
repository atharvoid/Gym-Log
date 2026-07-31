import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';

/// Why a thumbnail has no image. These are not the same situation and must not
/// look the same (B19-F4): one is a permanent property of the exercise, the
/// other is a transient failure the user can act on.
enum _ThumbFallback {
  /// The catalog entry has no media URL. Nothing to retry.
  absent,

  /// A URL exists but the fetch or decode failed. Retryable.
  failed,
}

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
      inner = _fallback(ref, _ThumbFallback.absent);
    } else {
      final frameAsync = ref.watch(fastFrame
          ? gifFirstFrameProvider(
              (url: url, targetWidth: kGifThumbnailDecodeWidth))
          : gifLastFrameProvider(
              (url: url, targetWidth: kGifThumbnailDecodeWidth)));
      inner = frameAsync.when(
        loading: () => _loading(),
        // A thrown error and a null frame are the same thing to the user: the
        // URL was there and the image is not. Both are retryable.
        error: (_, __) => _fallback(ref, _ThumbFallback.failed),
        data: (img) => img == null
            ? _fallback(ref, _ThumbFallback.failed)
            // Decoration next to the exercise name in a merged row — an
            // "exercise image" node on every row adds noise and no meaning.
            : ExcludeSemantics(
                child: RawImage(
                  // Borrowed from the shared bounded frame cache; this widget
                  // must never dispose it (see gif_last_frame_provider).
                  image: img,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
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

  /// Deliberately NOT SkeletonPulse. SkeletonPulse declares a liveRegion, and
  /// a list of thirty rows would declare thirty of them and flood TalkBack
  /// while the user is trying to read the names. The row's own label is
  /// already on screen and unaffected by the image decoding, so the tile is
  /// decorative here and only borrows the skeleton's fill token.
  Widget _loading() => ExcludeSemantics(
        child: SkeletonBox(
          width: size,
          height: size,
          radius: AppRadius.thumbnail,
        ),
      );

  Widget _fallback(WidgetRef ref, _ThumbFallback reason) {
    final icon = Center(
      child: Icon(
        reason == _ThumbFallback.absent
            ? Icons.fitness_center_rounded
            // Distinct glyph so "we couldn't load this" is visibly not the
            // same state as "this exercise has no animation" (B19-F4).
            : Icons.broken_image_rounded,
        color: AppColors.thumbIcon,
        size: size * 0.42,
      ),
    );

    if (reason == _ThumbFallback.absent) {
      // Nothing to retry and nothing to say: the row already names the
      // exercise, and "no image" is not information the user can use.
      return ExcludeSemantics(child: icon);
    }

    void retry() {
      HapticFeedback.lightImpact();
      final url = gifUrl;
      if (url == null || url.isEmpty) return;
      ref.invalidate(fastFrame
          ? gifFirstFrameProvider(
              (url: url, targetWidth: kGifThumbnailDecodeWidth))
          : gifLastFrameProvider(
              (url: url, targetWidth: kGifThumbnailDecodeWidth)));
    }

    // The activate action lives on the Semantics node itself, not on an
    // excluded child — the C30 lesson: an ancestor that later strips child
    // semantics must not be able to take the action with it.
    //
    // Known gap: on the Exercise Library screen the B18 row wrapper sets
    // excludeSemantics: true, so this node is currently swallowed there. The
    // control still works by touch; unblocking it for screen readers requires
    // changing that row wrapper and is tracked separately.
    return Semantics(
      button: true,
      label: 'Exercise image failed to load',
      hint: 'Double tap to retry',
      onTap: retry,
      child: GestureDetector(
        onTap: retry,
        behavior: HitTestBehavior.opaque,
        child: icon,
      ),
    );
  }
}
