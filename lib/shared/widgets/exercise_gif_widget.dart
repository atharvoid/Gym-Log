import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/gif_last_frame_provider.dart';

/// [exercise_gif_widget.dart]
/// Purpose: Hybrid offline-first GIF display.
///   - Downloads from Supabase on first view, caches permanently to disk.
///   - On subsequent opens (even offline) loads from device cache instantly.
///   - Shows a minimal progress indicator while loading.
///   - Shows a fallback icon on network error or null URL.
///   - Supports [animate: false] to decode a single static frame via
///     [gifLastFrameProvider], eliminating animation overhead and codec memory.
///
/// Usage:
///   ExerciseGifWidget(gifUrl: exercise.gifUrl, height: 220)
///   ExerciseGifWidget(gifUrl: exercise.gifUrl, width: 48, height: 48, animate: false)

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

    if (animate) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: gifUrl!,
          width: width,
          height: height,
          fit: fit,
          // Background while downloading — dark surface keeps OLED aesthetics
          placeholder: (context, url) => _buildPlaceholder(),
          // Logs the exact failing URL + exception for debugging
          errorWidget: (context, url, error) {
            debugPrint(
              '[ExerciseGifWidget] Failed to load GIF.\n'
              '  URL  : $url\n'
              '  Error: $error',
            );
            return _buildFallback();
          },
          // Shrink the in-memory footprint: max 400px wide in memory
          memCacheWidth: 400,
        ),
      );
    }

    // Static frame branch: decode once via gifLastFrameProvider, render as
    // a plain Image (MemoryImage). No codec animation, minimal memory.
    return Consumer(
      builder: (context, ref, child) {
        final frameAsync = ref.watch(gifLastFrameProvider(gifUrl!));

        return ClipRRect(
          borderRadius: borderRadius,
          child: frameAsync.when(
            loading: () => _buildPlaceholder(),
            error: (_, __) => _buildFallback(),
            data: (memoryImage) {
              if (memoryImage == null) return _buildFallback();
              return Image(
                image: memoryImage,
                width: width,
                height: height,
                fit: fit,
                gaplessPlayback: true,
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
