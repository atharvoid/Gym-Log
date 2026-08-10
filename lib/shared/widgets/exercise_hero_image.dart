import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';

import 'package:gymlog/core/services/exercise_media_cache_manager.dart';

/// Detail-screen exercise banner with a stable Hero contract:
///  - Poster (static first frame, BoxFit.contain) is the ONLY thing in the Hero
///    flight → matches the source tile exactly (contain → contain, no resize).
///  - The animated GIF cross-fades IN over the poster only after the route
///    transition completes, in the same finite box → no spinner, no reflow.
class ExerciseHeroImage extends ConsumerStatefulWidget {
  final String? gifUrl;
  final int exerciseId;
  final double height;
  final bool enableHero;

  /// What a screen reader should call this banner. Optional and added last so
  /// no existing call site changes; pass the exercise name where it is known.
  final String? semanticLabel;

  const ExerciseHeroImage({
    super.key,
    required this.gifUrl,
    required this.exerciseId,
    this.height = 220,
    this.enableHero = true,
    this.semanticLabel,
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
    final showAnimated = _showAnimated && !reduceMotion;
    final hasMedia = widget.gifUrl != null && widget.gifUrl!.isNotEmpty;

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
              color: AppColors.gifCanvas,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Poster(gifUrl: widget.gifUrl),
                  if (showAnimated && hasMedia)
                    AnimatedOpacity(
                      opacity: 1,
                      duration: Duration(milliseconds: reduceMotion ? 0 : 220),
                      curve: Curves.easeOut,
                      child: CachedNetworkImage(
                        cacheManager: ExerciseMediaCacheManager(),
                        imageUrl: widget.gifUrl!,
                        fit: BoxFit.contain,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        final Widget hero = (!widget.enableHero || reduceMotion)
            ? box
            : Hero(tag: 'exercise-hero-${widget.exerciseId}', child: box);

        // The largest element on the detail screen published nothing to a
        // screen reader (B19-F5). It is meaningful content — it is the only
        // thing that shows how the movement is performed — so it gets an image
        // role and a label. Applied outside the Hero so the flight geometry is
        // untouched.
        return Semantics(
          container: true,
          image: true,
          label: hasMedia
              ? (widget.semanticLabel ?? 'Exercise demonstration')
              : 'No demonstration available for this exercise',
          child: hero,
        );
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
      return const Center(child: _FallbackIcon(failed: false));
    }
    // Previously .valueOrNull, which flattened "still decoding", "decode
    // failed" and "no frames" into one blank box (B19-F4). Loading stays blank
    // by design — the no-spinner Hero contract — but a real failure now shows
    // a distinct glyph instead of an empty canvas the user cannot interpret.
    return ref.watch(gifFirstFrameProvider((url: url, targetWidth: null))).when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Center(child: _FallbackIcon(failed: true)),
          data: (frame) => frame == null
              ? const Center(child: _FallbackIcon(failed: true))
              // Borrowed from the shared bounded frame cache; never disposed
              // here (see gif_last_frame_provider).
              : RawImage(image: frame, fit: BoxFit.contain),
        );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) => Icon(
        failed ? Icons.broken_image_rounded : Icons.fitness_center_rounded,
        color: AppColors.thumbIcon,
        size: 48,
      );
}
