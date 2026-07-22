import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Collapsing two-stage hero for the Workout Detail screen.
///   Expanded → large title + date + three metric pips.
///   Collapsed → small title pinned in the toolbar.
/// The three-dots lives in [actions] so it stays reachable when pinned. The
/// expanded height scales with the OS font size so large Dynamic Type can't
/// clip the metrics (the global text-scale clamp caps the factor at 1.4).
class WorkoutHeroSliver extends StatelessWidget {
  final String? workoutId;
  final String name;
  final String dateStr;
  final String durationStr;
  final String volumeStr;
  final int totalSets;
  final VoidCallback onMoreTap;

  const WorkoutHeroSliver({
    super.key,
    this.workoutId,
    required this.name,
    required this.dateStr,
    required this.durationStr,
    required this.volumeStr,
    required this.totalSets,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final double scale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4).toDouble();
    final expandedHeight = 168.0 * scale + 16;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SliverAppBar(
      pinned: true,
      forceElevated: true,
      scrolledUnderElevation: 0,
      backgroundColor: surface.bgBase,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      expandedHeight: expandedHeight,
      leading: IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_rounded,
            size: 24, color: surface.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        IconButton(
          tooltip: 'Workout options',
          icon: Icon(Icons.more_horiz_rounded,
              size: 24, color: surface.textPrimary),
          onPressed: onMoreTap,
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.maxHeight;
          final collapsedHeight =
              MediaQuery.paddingOf(context).top + kToolbarHeight;
          final isCollapsed = top <= collapsedHeight + 24;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            centerTitle: true,
            titlePadding: const EdgeInsetsDirectional.only(bottom: 16),
            // Small title fades in only when fully collapsed.
            title: AnimatedOpacity(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Text(
                name,
                style: AppText.exerciseName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: Container(
              color: surface.bgBase,
              foregroundDecoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: surface.borderSubtle)),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: workoutId == null || reduceMotion
                            ? Text(
                                name,
                                // S3: text-depth shadow on hero heading
                                style: AppText.sectionHeading(
                                    shadows: AppText.depthFor(context)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Hero(
                                tag: 'workout-hero-$workoutId',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Text(
                                    name,
                                    // S3: text-depth shadow on hero heading
                                    style: AppText.sectionHeading(
                                        shadows: AppText.depthFor(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 2),
                      Text(dateStr, style: AppText.caption()),
                      const SizedBox(height: 12),
                      MergeSemantics(
                        child: Row(
                          children: [
                            Flexible(
                              child: _HeroPip(
                                value: durationStr,
                                label: 'DURATION',
                                shadows: AppText.depthFor(context),
                              ),
                            ),
                            _HeroPip.dot(context),
                            Flexible(
                              child: Tooltip(
                                triggerMode: TooltipTriggerMode.tap,
                                showDuration: const Duration(seconds: 3),
                                message:
                                    'Volume = weight × reps across all completed '
                                    'sets, warm-ups included.',
                                child: _HeroPip(
                                  value: volumeStr,
                                  label: 'VOLUME',
                                  shadows: AppText.depthFor(context),
                                ),
                              ),
                            ),
                            _HeroPip.dot(context),
                            Flexible(
                              child: _HeroPip(
                                value: '$totalSets',
                                label: 'SETS',
                                shadows: AppText.depthFor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPip extends StatelessWidget {
  final String value;
  final String label;
  final List<Shadow>? shadows;

  const _HeroPip({required this.value, required this.label, this.shadows});

  static Widget dot(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text('·',
          style: TextStyle(color: surface.textTertiary, fontSize: 22)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            // S3: text-depth shadow on hero stat values
            child: Text(
              value,
              style: AppText.heroStat(shadows: shadows),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppText.columnHeader(color: context.surface.textSecondary)),
        ],
      ),
    );
  }
}
