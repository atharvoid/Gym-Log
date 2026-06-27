import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';

/// Detail-screen exercise banner with a stable Hero contract:
///  - Poster (static last frame, BoxFit.cover) is the ONLY thing in the Hero
///    flight → matches the source tile exactly (cover → cover, no resize).
///  - The animated GIF cross-fades IN over the poster only after the route
///    transition completes, in the same finite box → no spinner, no reflow.
class ExerciseHeroImage extends ConsumerStatefulWidget {
  final String? gifUrl;
  final int exerciseId;
  final double height;
  final bool enableHero;
  const ExerciseHeroImage({
    super.key,
    required this.gifUrl,
    required this.exerciseId,
    this.height = 220,
    this.enableHero = true,
  });

  @override
  ConsumerState<ExerciseHeroImage> createState() => _ExerciseHeroImageState();
}

class _ExerciseHeroImageState extends ConsumerState<ExerciseHeroImage> {
  bool _showAnimated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      final anim = route?.animation;
      if (anim == null || anim.status == AnimationStatus.completed) {
        setState(() => _showAnimated = true);
        return;
      }
      void listener(AnimationStatus s) {
        if (s == AnimationStatus.completed) {
          anim.removeStatusListener(listener);
          if (mounted) setState(() => _showAnimated = true);
        }
      }

      anim.addStatusListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Reduced motion: no flight staging — show the GIF straight away.
    final showAnimated = _showAnimated || reduceMotion;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth; // finite — never double.infinity in a Hero
        final box = SizedBox(
          width: width,
          height: widget.height,
          child: ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: Container(
              // Letterbox fill: the square GIF is shown CONTAIN, so the empty
              // left/right gutters read as a clean light tile (GIFs are baked
              // on white). Matches the thumbnail tile + the flight shuttle.
              color: AppColors.thumbTile,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Poster(gifUrl: widget.gifUrl),
                  if (showAnimated &&
                      widget.gifUrl != null &&
                      widget.gifUrl!.isNotEmpty)
                    AnimatedOpacity(
                      opacity: 1,
                      duration: Duration(milliseconds: reduceMotion ? 0 : 220),
                      curve: Curves.easeOut,
                      child: CachedNetworkImage(
                        imageUrl: widget.gifUrl!,
                        fit: BoxFit.contain, // was BoxFit.cover
                        memCacheWidth: 720,
                        fadeInDuration: Duration.zero,
                        // Poster shows underneath — never a spinner on this path.
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        if (!widget.enableHero || reduceMotion) return box;
        return Hero(tag: 'exercise-hero-${widget.exerciseId}', child: box);
      },
    );
  }
}

/// Static cover frame. NO spinner: while the frame decodes show a neutral
/// surface fill (the animated layer / poster lands within a frame or two).
class _Poster extends ConsumerWidget {
  final String? gifUrl;
  const _Poster({required this.gifUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = gifUrl;
    if (url == null || url.isEmpty) {
      return const Center(child: _FallbackIcon());
    }
    final frame = ref.watch(gifLastFrameProvider(url)).valueOrNull;
    if (frame == null) return const SizedBox.shrink();
    return Image(image: frame, fit: BoxFit.contain, gaplessPlayback: true);
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();
  @override
  Widget build(BuildContext context) => const Icon(Icons.fitness_center_rounded,
      color: AppColors.thumbIcon, size: 48);
}
