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

  const ExerciseGifWidget({
    super.key,
    required this.gifUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (gifUrl == null || gifUrl!.isEmpty) {
      return _buildFallback();
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
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) {
            debugPrint(
              '[ExerciseGifWidget] Failed to load GIF.\n'
              '  URL  : $url\n'
              '  Error: $error',
            );
            return _buildFallback();
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
            error: (_, __) => _buildFallback(),
            data: (img) {
              if (img == null) return _buildFallback();
              return RawImage(
                image: img,
                width: width,
                height: height,
                fit: fit,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
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
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.textSecondary,
          size: 48,
        ),
      ),
    );
  }
}
