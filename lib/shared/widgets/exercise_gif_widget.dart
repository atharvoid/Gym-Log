import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/services/exercise_media_cache_manager.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';

class ExerciseGifWidget extends StatelessWidget {
  final String? gifUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool animate;

  /// What a screen reader should call this animation. Optional and added last
  /// so no existing call site changes; when null the generic label is used.
  final String? semanticLabel;

  const ExerciseGifWidget({
    super.key,
    required this.gifUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.animate = true,
    this.semanticLabel,
  });

  String get _label => semanticLabel ?? 'Exercise demonstration';

  @override
  Widget build(BuildContext context) {
    if (gifUrl == null || gifUrl!.isEmpty) {
      // No media in the catalog for this exercise. Permanent, not a failure.
      return _buildFallback(failed: false);
    }

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = animate && !reduceMotion;

    if (shouldAnimate) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          cacheManager: ExerciseMediaCacheManager(),
          imageUrl: gifUrl!,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth:
              width != null && width! > 0 ? (width! * 2).toInt() : 512,
          imageBuilder: (context, imageProvider) => Semantics(
            image: true,
            label: _label,
            child: Image(
              image: imageProvider,
              width: width,
              height: height,
              fit: fit,
            ),
          ),
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) {
            debugPrint(
              '[ExerciseGifWidget] Failed to load GIF.\n'
              '  URL  : $url\n'
              '  Error: $error',
            );
            return _buildFallback(failed: true);
          },
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final frameAsync = ref.watch(gifLastFrameProvider((
          url: gifUrl!,
          targetWidth: width != null && width! > 0 ? (width! * 2).toInt() : 512,
        )));

        return ClipRRect(
          borderRadius: borderRadius,
          child: frameAsync.when(
            loading: () => _buildPlaceholder(),
            error: (_, __) => _buildFallback(failed: true),
            data: (img) {
              // A null frame means the fetch or decode gave up — that is a
              // failure, not an exercise without media (B19-F4).
              if (img == null) return _buildFallback(failed: true);
              return Semantics(
                image: true,
                label: _label,
                child: RawImage(
                  // Borrowed from the shared bounded frame cache; never
                  // disposed here (see gif_last_frame_provider).
                  image: img,
                  width: width,
                  height: height,
                  fit: fit,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Semantics(
      label: 'Loading exercise demonstration',
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: borderRadius,
          ),
          // Color intentionally omitted — inherits the active palette base via
          // app_theme's progressIndicatorTheme, so the spinner tracks the user's
          // chosen accent instead of a hardcoded purple.
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [failed] false = this exercise has no animation at all (nothing is wrong).
  /// [failed] true  = an animation exists but could not be fetched or decoded.
  /// These used to render identically, which left the user unable to tell a
  /// gap in the catalog from a dropped network request.
  Widget _buildFallback({required bool failed}) {
    return Semantics(
      label: failed
          ? 'Exercise demonstration could not be loaded'
          : 'No demonstration available for this exercise',
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Icon(
              failed
                  ? Icons.broken_image_rounded
                  : Icons.fitness_center_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
