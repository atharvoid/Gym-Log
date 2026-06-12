import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/routine_detail_styles.dart';

/// One slot in a template: display label + ranked search candidates used
/// to resolve a real exercise row from the local library at import time.
class _TemplateSlot {
  final String label;
  final List<String> queries;
  final int sets;

  const _TemplateSlot(this.label, this.queries, {this.sets = 3});
}

class _RoutineTemplate {
  final String name;
  final String focus;
  final String description;
  final Color accent;
  final List<_TemplateSlot> slots;

  const _RoutineTemplate({
    required this.name,
    required this.focus,
    required this.description,
    required this.accent,
    required this.slots,
  });
}

const _templates = <_RoutineTemplate>[
  _RoutineTemplate(
    name: 'Push Day',
    focus: 'Chest · Shoulders · Triceps',
    description: 'The classic pressing session — heavy compound first, '
        'isolation to finish.',
    accent: Color(0xFF8A2BE2),
    slots: [
      _TemplateSlot('Bench Press', ['barbell bench press', 'bench press'],
          sets: 4),
      _TemplateSlot('Overhead Press', [
        'barbell standing military press',
        'overhead press',
        'shoulder press'
      ]),
      _TemplateSlot('Incline Dumbbell Press',
          ['dumbbell incline bench press', 'incline press']),
      _TemplateSlot(
          'Lateral Raise', ['dumbbell lateral raise', 'lateral raise']),
      _TemplateSlot('Triceps Pushdown',
          ['cable pushdown', 'triceps pushdown', 'pushdown']),
    ],
  ),
  _RoutineTemplate(
    name: 'Pull Day',
    focus: 'Back · Biceps · Rear Delts',
    description: 'Width and thickness — vertical pull, horizontal row, '
        'then arms.',
    accent: Color(0xFF7B68EE),
    slots: [
      _TemplateSlot('Deadlift', ['barbell deadlift', 'deadlift'], sets: 3),
      _TemplateSlot('Pull-Up', ['pull-up', 'pull up'], sets: 4),
      _TemplateSlot('Barbell Row', ['barbell bent over row', 'barbell row']),
      _TemplateSlot('Face Pull', ['cable face pull', 'face pull']),
      _TemplateSlot('Biceps Curl',
          ['dumbbell biceps curl', 'barbell curl', 'biceps curl']),
    ],
  ),
  _RoutineTemplate(
    name: 'Leg Day',
    focus: 'Quads · Hamstrings · Glutes',
    description: 'Squat-centric lower session with hinge balance and '
        'calf work.',
    accent: Color(0xFF9932CC),
    slots: [
      _TemplateSlot('Squat', ['barbell full squat', 'barbell squat', 'squat'],
          sets: 4),
      _TemplateSlot('Romanian Deadlift',
          ['barbell romanian deadlift', 'romanian deadlift']),
      _TemplateSlot('Leg Press', ['sled 45° leg press', 'leg press']),
      _TemplateSlot('Leg Curl', ['lever lying leg curl', 'leg curl']),
      _TemplateSlot('Calf Raise', ['standing calf raise', 'calf raise']),
    ],
  ),
  _RoutineTemplate(
    name: 'Upper Body',
    focus: 'Chest · Back · Shoulders · Arms',
    description: 'Everything above the waist in one efficient session — '
        'built for upper/lower splits.',
    accent: Color(0xFF5D3FD3),
    slots: [
      _TemplateSlot('Bench Press', ['barbell bench press', 'bench press']),
      _TemplateSlot('Barbell Row', ['barbell bent over row', 'barbell row']),
      _TemplateSlot('Overhead Press',
          ['barbell standing military press', 'overhead press']),
      _TemplateSlot(
          'Lat Pulldown', ['cable pulldown', 'lat pulldown', 'pulldown']),
      _TemplateSlot('Biceps Curl', ['dumbbell biceps curl', 'biceps curl']),
      _TemplateSlot('Triceps Pushdown', ['cable pushdown', 'triceps pushdown']),
    ],
  ),
  _RoutineTemplate(
    name: 'Lower Body',
    focus: 'Quads · Hamstrings · Calves',
    description: 'The other half of the upper/lower split — squat and '
        'hinge with unilateral support.',
    accent: Color(0xFFB19CD9),
    slots: [
      _TemplateSlot('Squat', ['barbell full squat', 'barbell squat', 'squat'],
          sets: 4),
      _TemplateSlot(
          'Hip Thrust', ['barbell glute bridge', 'hip thrust', 'glute bridge']),
      _TemplateSlot('Lunge', ['dumbbell lunge', 'barbell lunge', 'lunge']),
      _TemplateSlot('Leg Extension', ['lever leg extension', 'leg extension']),
      _TemplateSlot('Seated Calf Raise',
          ['lever seated calf raise', 'seated calf raise', 'calf raise']),
    ],
  ),
  _RoutineTemplate(
    name: 'Full Body Express',
    focus: 'Everything · 45 minutes',
    description: 'Three compounds and two finishers — for the days when '
        'time is the limiting factor.',
    accent: Color(0xFFCBB2FF),
    slots: [
      _TemplateSlot('Squat', ['barbell full squat', 'barbell squat', 'squat']),
      _TemplateSlot('Bench Press', ['barbell bench press', 'bench press']),
      _TemplateSlot('Barbell Row', ['barbell bent over row', 'barbell row']),
      _TemplateSlot('Plank', ['weighted front plank', 'plank'], sets: 2),
      _TemplateSlot('Biceps Curl', ['dumbbell biceps curl', 'biceps curl'],
          sets: 2),
    ],
  ),
];

/// Explore — a curated catalog of premade routines, importable into the
/// user's library in one tap. Discovery and retention, not navigation.
class ExploreRoutinesScreen extends ConsumerStatefulWidget {
  const ExploreRoutinesScreen({super.key});

  @override
  ConsumerState<ExploreRoutinesScreen> createState() =>
      _ExploreRoutinesScreenState();
}

class _ExploreRoutinesScreenState extends ConsumerState<ExploreRoutinesScreen> {
  final Set<String> _importing = {};
  final Set<String> _imported = {};

  Future<void> _import(_RoutineTemplate template) async {
    final user = ref.read(authProvider);
    if (user == null || _importing.contains(template.name)) return;

    HapticFeedback.mediumImpact();
    setState(() => _importing.add(template.name));

    try {
      final db = ref.read(databaseProvider);

      // Resolve each slot against the local exercise library using its
      // ranked candidate queries. Misses are skipped, never faked.
      final drafts = <RoutineDraftExercise>[];
      var missed = 0;
      for (final slot in template.slots) {
        int? resolvedId;
        for (final query in slot.queries) {
          final hits = await db.exercisesDao.searchExercises(query);
          if (hits.isNotEmpty) {
            resolvedId = hits.first.id;
            break;
          }
        }
        if (resolvedId != null) {
          drafts.add(RoutineDraftExercise(
            exerciseId: resolvedId,
            defaultSets: slot.sets,
          ));
        } else {
          missed++;
        }
      }

      if (drafts.isEmpty) {
        _snack('Could not match these exercises in your library.');
        return;
      }

      await db.routinesDao.createRoutine(
        userId: user.id,
        name: template.name,
        exercises: drafts,
      );

      if (!mounted) return;
      setState(() => _imported.add(template.name));
      HapticFeedback.heavyImpact();
      _snack(missed == 0
          ? '"${template.name}" added to My Routines.'
          : '"${template.name}" added — $missed exercise${missed > 1 ? 's' : ''} not in your library were skipped.');
    } finally {
      if (mounted) setState(() => _importing.remove(template.name));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message, style: GoogleFonts.inter(color: AppColors.textPrimary)),
      backgroundColor: AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Explore',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Proven templates, ready to train. Import one and make it yours.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final template in _templates)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TemplateCard(
                template: template,
                importing: _importing.contains(template.name),
                imported: _imported.contains(template.name),
                onImport: () => _import(template),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _RoutineTemplate template;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;

  const _TemplateCard({
    required this.template,
    required this.importing,
    required this.imported,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final preview = template.slots.take(3).map((s) => s.label).join(', ');
    final extra = template.slots.length - 3;

    return Container(
      decoration: BoxDecoration(
        gradient: RDStyles.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: RDStyles.hairlineBorder,
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: template.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template.name[0],
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: template.accent,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${template.slots.length} exercises  ·  ${template.focus}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            template.description,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Container(height: 1, color: RDStyles.hairline),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$preview${extra > 0 ? '  +$extra' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ImportPill(
                  importing: importing,
                  imported: imported,
                  onTap: onImport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportPill extends StatelessWidget {
  final bool importing;
  final bool imported;
  final VoidCallback onTap;

  const _ImportPill({
    required this.importing,
    required this.imported,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: imported
          ? AppColors.success.withValues(alpha: 0.14)
          : AppColors.accentPrimary,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: imported || importing ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: importing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      imported ? Icons.check_rounded : Icons.download_rounded,
                      size: 15,
                      color: imported ? AppColors.success : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      imported ? 'Added' : 'Add',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: imported ? AppColors.success : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
