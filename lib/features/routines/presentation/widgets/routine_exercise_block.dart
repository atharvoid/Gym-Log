
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/daos/routines_dao.dart';
import '../../../../core/database/daos/workouts_dao.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/exercise_gif_widget.dart';

/// Spotify-grade surface color for exercise containers.
const _kSurface = Color(0xFF121212);
const _kTextTertiary = Color(0xFF6A6A6A);



/// [routine_exercise_block.dart]
/// Premium exercise card for RoutineDetailScreen.
///   - #121212 surface container with 16px radius
///   - AnimatedScale press state (0.985 on tap-down)
///   - Rigid Column structure with SizedBoxes for SET/KG/REPS alignment
///   - Space Grotesk for numerical data
///   - PR badge on individual sets
///   - Last-session set-count caption
///   - Rest timer row

class RoutineExerciseBlock extends StatefulWidget {
  final HydratedRoutineExercise hydratedExercise;
  final List<LastSessionSetData>? lastSets;
  final VoidCallback? onTap;
  final bool isLoadingHistory;
  final bool isLast;

  const RoutineExerciseBlock({
    super.key,
    required this.hydratedExercise,
    this.lastSets,
    this.onTap,
    this.isLoadingHistory = false,
    this.isLast = false,
  });

  @override
  State<RoutineExerciseBlock> createState() => _RoutineExerciseBlockState();
}

class _RoutineExerciseBlockState extends State<RoutineExerciseBlock> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.985);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  void _onTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!.call();
    } else {
      context.push('/exercise/detail/${widget.hydratedExercise.exercise.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.hydratedExercise.exercise;
    final config = widget.hydratedExercise.config;
    final restSeconds = config.restSeconds;
    final lastSets = widget.lastSets;
    final hasHistory = lastSets != null && lastSets.isNotEmpty;
    final lastSet = lastSets?.lastOrNull;

    final String subtitleText;
    if (widget.isLoadingHistory) {
      subtitleText = '—';
    } else if (lastSet != null && lastSets != null) {
      final weightStr = lastSet.weightKg != null
          ? (lastSet.weightKg == lastSet.weightKg!.toInt()
              ? lastSet.weightKg!.toInt().toString()
              : lastSet.weightKg!.toStringAsFixed(1))
          : '—';
      final repsStr = lastSet.reps?.toString() ?? '—';
      subtitleText = 'Last: $weightStr kg × $repsStr reps • ${lastSets.length} set${lastSets.length != 1 ? 's' : ''}';
    } else {
      subtitleText = 'Not performed yet';
    }

    return Semantics(
      button: widget.onTap != null,
      label:
          '${exercise.name}, ${config.defaultSets} sets, ${_formatRest(restSeconds)} rest',
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 16),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: _onTap,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutQuint,
            child: Material(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Row: GIF + Name ──────────────────────────────
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: ExerciseGifWidget(
                              gifUrl: exercise.gifUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              animate: false,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // ── Last-session caption ────────────────────
                              Text(
                                subtitleText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: (lastSet == null && !widget.isLoadingHistory)
                                      ? FontStyle.italic
                                      : null,
                                  color: (lastSet == null && !widget.isLoadingHistory)
                                      ? _kTextTertiary.withValues(alpha: 0.5)
                                      : AppColors.textSecondary.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Rest Timer Row ──────────────────────────────────────
                    if (restSeconds != null && restSeconds > 0)
                      SizedBox(
                        height: 28,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 56, top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatRest(restSeconds)} rest',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Data Table (rigid grid) ─────────────────────────────
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: _buildTable(hasHistory, config.defaultSets, lastSets),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(
      bool hasHistory, int defaultSets, List<LastSessionSetData>? lastSets) {
    final List<_TableSet> sets;
    if (hasHistory) {
      sets = lastSets!.map((set) {
        return _TableSet(
          setNumber: set.setNumber,
          weightKg: set.weightKg,
          reps: set.reps,
          setType: set.setType,
          isPr: set.isPr,
        );
      }).toList();
    } else {
      sets = List.generate(
        defaultSets,
        (i) => _TableSet(setNumber: i + 1),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Builder(
            builder: (context) {
              final headerStyle = GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              );
              return Row(
                children: [
                  SizedBox(
                      width: 64,
                      child: Text('Set',
                          textAlign: TextAlign.left,
                          style: headerStyle)),
                  const SizedBox(width: 16),
                  SizedBox(
                      width: 68,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text('Kg',
                              textAlign: TextAlign.right,
                              style: headerStyle),
                        ),
                      )),
                  const SizedBox(width: 16),
                  SizedBox(
                      width: 68,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text('Reps',
                              textAlign: TextAlign.right,
                              style: headerStyle),
                        ),
                      )),
                ],
              );
            }
          ),
        ),
        // Data rows
        ...sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          return Container(
            color: index % 2 == 1 ? AppColors.bgSurface : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                // SET cell
                SizedBox(
                  width: 64,
                  child: Center(
                    child: () {
                      final setType = set.setType?.toLowerCase() ?? 'normal';

                      Widget buildPill(IconData icon, String label, Color color) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      switch (setType) {
                        case 'warmup':
                          return buildPill(Icons.local_fire_department, 'Warm', Colors.amber);
                        case 'dropset':
                        case 'drop':
                          return buildPill(Icons.trending_down, 'Drop', AppColors.accentPrimary);
                        case 'failure':
                          return buildPill(Icons.warning_amber_rounded, 'Fail', AppColors.error);
                        case 'normal':
                        default:
                          return Text(
                            '${set.setNumber}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                          );
                      }
                    }(),
                  ),
                ),
                const SizedBox(width: 16),
                // KG cell
                SizedBox(
                  width: 68,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        set.weightKg != null
                            ? (set.weightKg == set.weightKg!.toInt()
                                ? set.weightKg!.toInt().toString()
                                : set.weightKg!.toStringAsFixed(1))
                            : '—',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // REPS cell — plain SizedBox + Text, no Flexible
                SizedBox(
                  width: 68,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        set.reps?.toString() ?? '—',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                // PR badge — sits outside the 80px column
                if (set.isPr)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PR',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatRest(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${seconds}s';
  }
}

class _TableSet {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final String? setType;
  final bool isPr;

  _TableSet({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.setType,
    this.isPr = false,
  });
}
