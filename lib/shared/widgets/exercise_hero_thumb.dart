import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/shared/providers/gif_last_frame_provider.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';

class ExerciseHeroThumb extends StatelessWidget {
  final Exercise exercise;
  final double size;
  final bool fastFrame;

  /// Only ONE source per exerciseId per screen may set this true.
  final bool enableHero;
  const ExerciseHeroThumb({
    super.key,
    required this.exercise,
    this.size = 52,
    this.fastFrame = true,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = ExerciseThumbnail(
        gifUrl: exercise.gifUrl, size: size, fastFrame: fastFrame);
    if (!enableHero || MediaQuery.disableAnimationsOf(context)) return thumb;
    return Hero(
      tag: 'exercise-hero-${exercise.id}',
      flightShuttleBuilder: (flightCtx, anim, dir, fromCtx, toCtx) => Consumer(
        builder: (context, ref, _) {
          final last = ref
              .watch(gifLastFrameProvider(
                  (url: exercise.gifUrl ?? '', targetWidth: null)))
              .valueOrNull;
          final first = ref
              .watch(gifFirstFrameProvider((
                url: exercise.gifUrl ?? '',
                targetWidth: kGifThumbnailDecodeWidth
              )))
              .valueOrNull;
          final img = last ?? first;
          return ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: Container(
              color: AppColors.gifCanvas,
              child: img != null
                  ? RawImage(image: img, fit: BoxFit.contain)
                  : const Center(
                      child: Icon(Icons.fitness_center_rounded,
                          color: AppColors.thumbIcon)),
            ),
          );
        },
      ),
      child: thumb,
    );
  }
}
