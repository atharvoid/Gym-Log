import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/exercises/body_map.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

/// Atmospheric white bloom behind the "Explore" hero title.
/// 7% white on OLED black — just enough perceived depth without brightness.
/// Intentionally a static surface treatment, NOT a brand token: OLED-only
/// product, the canvas is always pure black.
const Color _kHeroGlowColor = Color(0x12FFFFFF);

/// Resolves primary + secondary muscle groups for [template] from real exercise
/// data, replacing the marketing-tagline approximation used by
/// [_focusGroups]. For every importable [TemplateSlot] across all
/// [ProgramDay]s, looks up the matching [Exercise] (exact case-insensitive
/// name first, else first search hit — same strategy as [_import]) and calls
/// [workedGroupsFor] from `body_map.dart`, unioning primary and secondary sets
/// across every slot.
///
/// Async because it hits [ExercisesDao.searchExercises]. Called once per
/// preview sheet open (event-handler scope), not on every card build.
Future<({Set<String> primary, Set<String> secondary})>
    computedMuscleGroupsForTemplate(
  AppDatabase db,
  RoutineTemplate template,
) async {
  final primary = <String>{};
  final secondary = <String>{};
  for (final slot in template.previewSlots) {
    // previewSlots already filters to importableSlots (isConditioningNote == false).
    final hits = await db.exercisesDao.searchExercises(slot.name);
    Exercise? match;
    for (final e in hits) {
      if (e.name.toLowerCase() == slot.name.toLowerCase()) {
        match = e;
        break;
      }
    }
    match ??= hits.isNotEmpty ? hits.first : null;
    if (match == null) continue;

    final secondaryList = (match.secondaryMuscles != null &&
            match.secondaryMuscles!.isNotEmpty)
        ? (List<String>.from(
            (match.secondaryMuscles!.startsWith('['))
                ? (jsonDecode(match.secondaryMuscles!) as List).cast<String>()
                : [match.secondaryMuscles!],
          ))
        : <String>[];
    final groups = workedGroupsFor(
      target: match.target,
      secondary: secondaryList,
    );
    primary.addAll(groups.primary);
    secondary.addAll(groups.secondary);
  }
  secondary.removeAll(primary);
  return (primary: primary, secondary: secondary);
}

enum _LevelFilter {
  all,
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
        _LevelFilter.all => 'All',
        _LevelFilter.beginner => 'Beginner',
        _LevelFilter.intermediate => 'Intermediate',
        _LevelFilter.advanced => 'Advanced',
      };

  bool matches(RoutineTemplate t) => switch (this) {
        _LevelFilter.all => true,
        _LevelFilter.beginner => t.levels.contains(TemplateLevel.beginner),
        _LevelFilter.intermediate =>
          t.levels.contains(TemplateLevel.intermediate),
        _LevelFilter.advanced => t.levels.contains(TemplateLevel.advanced),
      };
}

/// Equipment filter row shown alongside the level filter. Each program is
/// tagged with exactly one equipment tier (see [RoutineTemplate.equipment]):
/// the minimum gear its slots were written for. A dumbbell-only or
/// bodyweight-only program will not appear when "Full gym" is selected,
/// but selecting "Any equipment" always shows every program.
enum _EquipmentFilter {
  all,
  fullGym,
  dumbbellOnly,
  bodyweight;

  String get label => switch (this) {
        _EquipmentFilter.all => 'Any equipment',
        _EquipmentFilter.fullGym => 'Full gym',
        _EquipmentFilter.dumbbellOnly => 'Dumbbell only',
        _EquipmentFilter.bodyweight => 'Bodyweight',
      };

  bool matches(RoutineTemplate t) => switch (this) {
        _EquipmentFilter.all => true,
        _EquipmentFilter.fullGym => t.equipment == ProgramEquipment.fullGym,
        _EquipmentFilter.dumbbellOnly =>
          t.equipment == ProgramEquipment.dumbbellOnly,
        _EquipmentFilter.bodyweight =>
          t.equipment == ProgramEquipment.bodyweight,
      };
}

sealed class _Row {
  const _Row();
}

class _FeaturedRow extends _Row {
  final RoutineTemplate template;
  const _FeaturedRow(this.template);
}

class _HeaderRow extends _Row {
  final String label;
  final int count;
  const _HeaderRow(this.label, this.count);
}

class _CardRow extends _Row {
  final RoutineTemplate template;
  const _CardRow(this.template);
}

class _ResultsHeaderRow extends _Row {
  final int count;
  const _ResultsHeaderRow(this.count);
}

class _EmptyResultsRow extends _Row {
  final String query;
  const _EmptyResultsRow(this.query);
}

class ExploreRoutinesScreen extends ConsumerStatefulWidget {
  const ExploreRoutinesScreen({super.key});

  @override
  ConsumerState<ExploreRoutinesScreen> createState() =>
      _ExploreRoutinesScreenState();
}

class _ExploreRoutinesScreenState extends ConsumerState<ExploreRoutinesScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _importing = {};
  final Set<String> _imported = {};
  // Maps template.name → list of created routine IDs (one per imported day).
  final Map<String, List<String>> _importedIds = {};
  _LevelFilter _filter = _LevelFilter.all;
  _EquipmentFilter _equipmentFilter = _EquipmentFilter.all;
  final GlobalKey _importButtonKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  late final AnimationController _reveal;
  bool _initializedFilter = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFilter) {
      _initializedFilter = true;
      final tourStep = ref.read(firstRunTourProvider);
      if (tourStep == 1 || tourStep == 2) {
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        final level = profile?.experienceLevel;
        if (level != null) {
          final filter = _LevelFilter.values.firstWhere(
            (f) => f.name == level,
            orElse: () => _LevelFilter.all,
          );
          if (filter != _LevelFilter.all) {
            _filter = filter;
            _reveal.forward(from: 0);
          }
        }
      }
    }
  }

  static final RoutineTemplate _featured = exploreTemplates.firstWhere(
    (t) => t.featured,
    orElse: () => exploreTemplates.first,
  );

  @override
  void dispose() {
    _searchController.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _setFilter(_LevelFilter f) {
    if (f == _filter) return;
    HapticFeedback.selectionClick();
    setState(() => _filter = f);
    _reveal.forward(from: 0);
  }

  void _setEquipmentFilter(_EquipmentFilter f) {
    if (f == _equipmentFilter) return;
    HapticFeedback.selectionClick();
    setState(() => _equipmentFilter = f);
    _reveal.forward(from: 0);
  }

  /// Parses the leading integer out of a reps string (e.g. "8-10" -> 8,
  /// "AMRAP" -> null, "30-45 sec" -> 30). The DB's `defaultReps` column is
  /// `int?`; the original string stays visible in the catalog/preview UI, so
  /// nothing about the request's intent is lost by this parse — it just
  /// gives the workout logger a sane starting number to prefill.
  int? _leadingReps(String reps) {
    final match = RegExp(r'\d+').firstMatch(reps);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  Future<void> _import(RoutineTemplate template) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    if (_importing.contains(template.name) ||
        _imported.contains(template.name)) {
      return;
    }
    // Haptics are fired by the invoking control (mediumImpact on the card
    // CTA, PrimaryButton's own mediumImpact in the preview sheet) — NOT here,
    // or an import from the sheet would buzz twice.
    setState(() => _importing.add(template.name));

    try {
      final isPremium = ref.read(isPremiumProvider);
      final db = ref.read(databaseProvider);

      // Check cap against ALL days at once: reject the entire import rather
      // than partially creating some routines (simpler, more predictable UX).
      final count = await db.routinesDao.countRoutinesForUser(user.id);
      if (!mounted) return;
      if (isAtFreeRoutineLimit(
          isPremium: isPremium,
          routineCount: count + template.days.length - 1)) {
        await showPremiumPaywall(context, source: PaywallSource.routineLimit);
        return;
      }

      // Conditioning-note slots (e.g. "Incline Treadmill Intervals") have no
      // library match by design — they're skipped here, not counted as
      // "missed". Only slots that SHOULD have resolved but didn't count
      // toward the missed tally shown in the import snackbar.
      //
      // Short program name: everything before the first ': ' in the renamed
      // template name (e.g. "Push Pull Legs" from
      // "Push Pull Legs: 6-Day High Frequency (Gym)"). See
      // [RoutineTemplate.shortName].
      final shortName = template.shortName;

      final dayDrafts = <RoutineDayDraft>[];
      var missed = 0;
      var totalImportable = 0;
      for (final day in template.days) {
        // Strip leading "Day N - " prefix so the per-day routine name is just
        // the descriptor part (e.g. "Push A" from "Day 1 - Push A").
        final dayPrefixMatch = RegExp(r'^Day \d+\s*-\s*').firstMatch(day.label);
        final stripped = dayPrefixMatch != null
            ? day.label.substring(dayPrefixMatch.end).trim()
            : day.label;
        // Final routine name: e.g. "Push Pull Legs · Push A"
        final routineName = template.days.length == 1
            ? template.name
            : '$shortName · $stripped';

        final drafts = <RoutineDraftExercise>[];
        for (final slot in day.importableSlots) {
          totalImportable++;
          final hits = await db.exercisesDao.searchExercises(slot.name);
          Exercise? match;
          for (final e in hits) {
            if (e.name.toLowerCase() == slot.name.toLowerCase()) {
              match = e;
              break;
            }
          }
          match ??= hits.isNotEmpty ? hits.first : null;
          if (match != null) {
            drafts.add(RoutineDraftExercise(
              exerciseId: match.id,
              defaultSets: slot.sets,
              defaultReps: _leadingReps(slot.reps),
            ));
          } else {
            missed++;
          }
        }
        dayDrafts.add(RoutineDayDraft(name: routineName, exercises: drafts));
      }

      if (!mounted) return;
      if (totalImportable > 0 && missed == totalImportable) {
        _snack('Could not match these exercises in your library.');
        return;
      }

      // Each day becomes its own independent Routine, tagged with
      // sourceProgramName so the Explore screen can re-detect them on restart.
      final ids = await db.routinesDao.createRoutinesForProgram(
        userId: user.id,
        programName: template.name,
        days: dayDrafts,
      );
      if (!mounted) return;

      setState(() {
        _imported.add(template.name);
        _importedIds[template.name] = ids;
      });

      if (ref.read(firstRunTourProvider) == 1) {
        ref.read(firstRunTourProvider.notifier).setStep(2);
      }

      HapticFeedback.heavyImpact();
      _snackImported(template.name, ids, missed);
    } finally {
      if (mounted) setState(() => _importing.remove(template.name));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: message,
      variant: AppSnackBarVariant.error,
    );
  }

  void _snackImported(String name, List<String> ids, int missed) {
    if (!mounted) return;
    final n = ids.length;
    final added = n == 1 ? '"$name" added' : '$n routines added';
    final skipped = missed == 0
        ? ''
        : '. $missed exercise${missed > 1 ? 's' : ''} not in your library were skipped';
    showAppSnackBar(
      context,
      message: '$added to My Routines$skipped.',
      variant: AppSnackBarVariant.success,
      actionLabel: 'View',
      onAction: () => context.push('/routines/${ids.first}'),
    );
  }

  Future<void> _showPreview(RoutineTemplate t,
      {required bool imported, String? routineId}) async {
    final gender =
        ref.read(currentUserProfileProvider).valueOrNull?.gender ?? 'male';
    final db = ref.read(databaseProvider);
    // Precompute real muscle groups from exercise data before opening the
    // sheet so _PreviewSheet stays synchronous. This runs on the event-handler
    // tap (not on every list build) so the DB lookup is acceptable here.
    final muscleGroups = await computedMuscleGroupsForTemplate(db, t);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PreviewSheet(
        template: t,
        imported: imported,
        gender: gender,
        primaryGroups: muscleGroups.primary,
        secondaryGroups: muscleGroups.secondary,
        onAdd: () {
          Navigator.of(sheetCtx).pop();
          _import(t);
        },
        onView: routineId == null
            ? null
            : () {
                Navigator.of(sheetCtx).pop();
                context.push('/routines/$routineId');
              },
      ),
    );
  }

  List<({String category, List<RoutineTemplate> items})> _sections(
      {required RoutineTemplate? excluded}) {
    final byCategory = <String, List<RoutineTemplate>>{};
    for (final t in exploreTemplates) {
      if (!_filter.matches(t)) continue;
      if (!_equipmentFilter.matches(t)) continue;
      if (!_matchesQuery(t)) continue;
      if (identical(t, excluded)) continue;
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }
    return [
      for (final c in exploreCategoryOrder)
        if (byCategory[c] != null) (category: c, items: byCategory[c]!),
    ];
  }

  /// Case-insensitive substring match over every scannable field of a
  /// program. The catalog is only 16 entries — a plain scan is the right
  /// size; a search index or debounce would be over-engineering.
  bool _matchesQuery(RoutineTemplate t) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return true;
    return t.name.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q) ||
        t.focus.toLowerCase().contains(q) ||
        t.equipmentLabel.toLowerCase().contains(q) ||
        t.levelLabel.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final tourStep = ref.watch(firstRunTourProvider);

    final existing = ref.watch(hydratedRoutinesProvider).valueOrNull ??
        const <HydratedRoutine>[];

    // Programs imported under the new model are tagged with sourceProgramName
    // so they are re-detected correctly on restart (their individual routine
    // names are "PPL · Push A", not the template name).
    final existingByProgram = <String, List<String>>{};
    for (final r in existing) {
      final src = r.routine.sourceProgramName;
      if (src != null) {
        existingByProgram.putIfAbsent(src, () => []).add(r.routine.id);
      }
    }
    // Legacy: programs imported before v6 schema (sourceProgramName == null)
    // stored the full template name as the routine name. Match those by name
    // for backward-compat badge display.
    final existingByName = <String, String>{
      for (final r in existing)
        if (r.routine.sourceProgramName == null) r.routine.name: r.routine.id,
    };

    final searching = _query.isNotEmpty;
    final showFeatured = !searching && _filter == _LevelFilter.all;
    final sections = _sections(excluded: showFeatured ? _featured : null);
    final totalMatches = sections.fold(0, (a, s) => a + s.items.length);

    final rows = <_Row>[
      if (searching && totalMatches == 0)
        _EmptyResultsRow(_query)
      else ...[
        if (searching) _ResultsHeaderRow(totalMatches),
        if (showFeatured) _FeaturedRow(_featured),
        for (final s in sections) ...[
          _HeaderRow(s.category, s.items.length),
          for (final t in s.items) _CardRow(t),
        ],
      ],
    ];

    RoutineTemplate? targetTemplate;
    for (final row in rows) {
      if (row is _FeaturedRow) {
        targetTemplate = row.template;
        break;
      } else if (row is _CardRow) {
        targetTemplate = row.template;
        break;
      }
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: Stack(
        children: [
          // C32: this route (/routines/explore) is pushed outside AppShell and
          // never opted into the AdaptiveContent width cap -- the featured
          // card and program list stretched edge-to-edge on tablets/
          // foldables. Only the scroll content is wrapped; the tour overlays
          // below still need to target buttons at their real on-screen
          // position, so they are left outside the constraint.
          AdaptiveContent(
              child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                // 104px (not the old 150) — the flexible space now hugs the
                // toolbar instead of leaving a ~150px dead band between the
                // back arrow and the title.
                expandedHeight: 104,
                backgroundColor: surface.bgBase,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  tooltip: 'Back',
                  icon: Icon(Icons.arrow_back_rounded,
                      size: 24, color: surface.textPrimary),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                ),
                flexibleSpace: const FlexibleSpaceBar(
                  titlePadding:
                      EdgeInsetsDirectional.only(start: 56, bottom: 8),
                  expandedTitleScale: 1.3,
                  title: _HeroTitle(),
                  background: _HeroGlow(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH, 6, AppSpacing.screenH, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trainer-built programs, ready to train. Import one and '
                        'make it yours.',
                        style: AppText.body(color: surface.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _CredChip(
                              icon: Icons.list_alt_rounded,
                              label: '${exploreTemplates.length} programs'),
                          const SizedBox(width: AppSpacing.x2),
                          _CredChip(
                              icon: Icons.grid_view_rounded,
                              label: '${exploreCategoryOrder.length} splits'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      _SearchField(
                        controller: _searchController,
                        query: _query,
                        onChanged: (value) {
                          setState(() => _query = value.trim());
                          _reveal.forward(from: 0);
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          _reveal.forward(from: 0);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterHeaderDelegate(
                    selected: _filter, onSelect: _setFilter),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _EquipmentFilterHeaderDelegate(
                    selected: _equipmentFilter, onSelect: _setEquipmentFilter),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 8,
                    AppSpacing.screenH, 24 + bottomInset),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final row = rows[i];
                      final Widget child;
                      switch (row) {
                        case _FeaturedRow(:final template):
                          final imported = _isImported(
                              template, existingByProgram, existingByName);
                          final routineId = _routineId(
                              template, existingByProgram, existingByName);
                          final isTarget = targetTemplate != null &&
                              template.name == targetTemplate.name;
                          child = Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.x5),
                            child: _FeaturedCard(
                              template: template,
                              importing: _importing.contains(template.name),
                              imported: imported,
                              onImport: () => _import(template),
                              onView: routineId == null
                                  ? null
                                  : () => context.push('/routines/$routineId'),
                              onPreview: () => _showPreview(template,
                                  imported: imported, routineId: routineId),
                              importButtonKey:
                                  isTarget ? _importButtonKey : null,
                            ),
                          );
                        case _HeaderRow(:final label, :final count):
                          child = _SectionHeader(label: label, count: count);
                        case _ResultsHeaderRow(:final count):
                          child = _ResultsHeader(count: count);
                        case _EmptyResultsRow(:final query):
                          child = _EmptyResults(query: query);
                        case _CardRow(:final template):
                          final imported = _isImported(
                              template, existingByProgram, existingByName);
                          final routineId = _routineId(
                              template, existingByProgram, existingByName);
                          final isTarget = targetTemplate != null &&
                              template.name == targetTemplate.name;
                          child = Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sectionGap),
                            child: _TemplateCard(
                              template: template,
                              importing: _importing.contains(template.name),
                              imported: imported,
                              onImport: () => _import(template),
                              onView: routineId == null
                                  ? null
                                  : () => context.push('/routines/$routineId'),
                              onPreview: () => _showPreview(template,
                                  imported: imported, routineId: routineId),
                              importButtonKey:
                                  isTarget ? _importButtonKey : null,
                            ),
                          );
                      }
                      return _Reveal(
                          index: i, controller: _reveal, child: child);
                    },
                    childCount: rows.length,
                  ),
                ),
              ),
            ],
          )),
          if (tourStep == 1)
            SpotlightTourOverlay(
              targetKey: _importButtonKey,
              title: 'Import your program',
              description:
                  'Tap "Add" on this program to import it into your routines library.',
              step: 1,
            ),
          if (tourStep == 2)
            SpotlightTourOverlay(
              targetKey: _importButtonKey,
              title: 'View your program',
              description:
                  'Awesome! The program has been added. Now tap "View" to check the details and start your workout.',
              step: 2,
            ),
        ],
      ),
    );
  }

  bool _isImported(
    RoutineTemplate t,
    Map<String, List<String>> existingByProgram,
    Map<String, String> existingByName,
  ) =>
      _imported.contains(t.name) ||
      existingByProgram.containsKey(t.name) ||
      existingByName.containsKey(t.name);

  String? _routineId(
    RoutineTemplate t,
    Map<String, List<String>> existingByProgram,
    Map<String, String> existingByName,
  ) =>
      _importedIds[t.name]?.firstOrNull ??
      existingByProgram[t.name]?.firstOrNull ??
      existingByName[t.name];
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) => Text('Explore',
      style: AppText.sectionHeading(
          color: context.surface.textPrimary,
          shadows: AppText.depthFor(context)));
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.85),
          radius: 1.15,
          colors: [_kHeroGlowColor, Colors.transparent],
          stops: [0.0, 0.72],
        ),
      ),
    );
  }
}

class _CredChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CredChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface.surface3,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: surface.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppText.statLabel(color: surface.textSecondary)),
        ],
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final _LevelFilter selected;
  final ValueChanged<_LevelFilter> onSelect;
  _FilterHeaderDelegate({required this.selected, required this.onSelect});

  @override
  double get minExtent => 62;
  @override
  double get maxExtent => 62;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.surface.bgBase,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: _ChipStrip(
        key: const Key('level-filter-row'),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          for (final f in _LevelFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x2),
              child: _FilterChip(
                label: f.label,
                selected: f == selected,
                onTap: () => onSelect(f),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate old) => old.selected != selected;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        // Neutral segmented-selector language: surface4 raised fill for
        // selected, surface3 for idle. Accent selection border mirrors the
        // equipment chip affordance so both rows communicate selection
        // consistently. Intentionally NOT accent.base fill: repeated saturated
        // fill down a strip floods the header.
        color: selected ? surface.surface4 : surface.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonSecondaryAll,
          side: selected
              ? BorderSide(color: accent.selectionBorder)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              maxLines: 1,
              style: AppText.statLabel(
                color: selected ? surface.textPrimary : surface.textSecondary,
              ).copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final _EquipmentFilter selected;
  final ValueChanged<_EquipmentFilter> onSelect;
  _EquipmentFilterHeaderDelegate(
      {required this.selected, required this.onSelect});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.surface.bgBase,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: _ChipStrip(
        key: const Key('equipment-filter-row'),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          for (final f in _EquipmentFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x2),
              child: _EquipmentFilterChip(
                icon: switch (f) {
                  _EquipmentFilter.all => Icons.tune_rounded,
                  _EquipmentFilter.fullGym => Icons.fitness_center_rounded,
                  _EquipmentFilter.dumbbellOnly =>
                    Icons.sports_gymnastics_rounded,
                  _EquipmentFilter.bodyweight =>
                    Icons.accessibility_new_rounded,
                },
                label: f.label,
                selected: f == selected,
                onTap: () => onSelect(f),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_EquipmentFilterHeaderDelegate old) =>
      old.selected != selected;
}

class _EquipmentFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _EquipmentFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        // Equipment is a secondary refinement, not a peer of the level
        // selector — same neutral-raised fill as the level chips, but the
        // selected state carries the accent SELECTION BORDER + accent leading
        // glyph so the two rows still read as distinct hierarchy. Never
        // accent.muted as a fill: that token is reserved for content tinting
        // (the muscle tags), and reusing it for selection made two unrelated
        // meanings share one color.
        color: selected ? surface.surface4 : surface.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonSecondaryAll,
          side: selected
              ? BorderSide(color: accent.selectionBorder)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: selected ? accent.base : surface.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  style: AppText.statLabel(
                    color:
                        selected ? surface.textPrimary : surface.textSecondary,
                  ).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable, single-line chip strip with soft edge fades that
/// appear only while content overflows. The fade is the scroll affordance:
/// clipped text with no cue reads as broken, so the gradient appears exactly
/// when there is more content in the scroll direction, and disappears once
/// the strip is scrolled flush. The strip is a real [ListView], so
/// screen-reader users get a standard scroll action on the row too.
class _ChipStrip extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry padding;
  const _ChipStrip({
    super.key,
    required this.children,
    required this.height,
    required this.padding,
  });

  @override
  State<_ChipStrip> createState() => _ChipStripState();
}

class _ChipStripState extends State<_ChipStrip> {
  final ScrollController _controller = ScrollController();
  bool _fadeLeft = false;
  bool _fadeRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final right = position.pixels < position.maxScrollExtent - 0.5;
    final left = position.pixels > 0.5;
    if (right != _fadeRight || left != _fadeLeft) {
      setState(() {
        _fadeRight = right;
        _fadeLeft = left;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.surface.bgBase;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              padding: widget.padding,
              children: widget.children,
            ),
          ),
          if (_fadeLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [bg, bg.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          if (_fadeRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [bg, bg.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;
  const _Reveal(
      {required this.index, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    if (index >= 8 || MediaQuery.disableAnimationsOf(context)) return child;
    final start = (index * 0.07).clamp(0.0, 0.55);
    const span = 0.45;
    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + span).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      style: AppText.body(color: surface.textPrimary),
      cursorColor: accent.base,
      decoration: InputDecoration(
        hintText: 'Search programs',
        hintStyle: AppText.body(color: surface.textTertiary),
        prefixIcon: Icon(Icons.search_rounded, color: surface.textSecondary),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon:
                    Icon(Icons.cancel, size: 18, color: surface.textSecondary),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: surface.surface3,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonSecondaryAll,
          borderSide: BorderSide(color: surface.borderSubtle, width: 1),
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonSecondaryAll,
          borderSide: BorderSide(color: surface.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonSecondaryAll,
          borderSide: BorderSide(color: accent.selectionBorder),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int count;
  const _ResultsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Text(
        count == 1 ? '1 result' : '$count results',
        style: AppText.columnHeader(color: surface.textSecondary),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: surface.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No programs match "$query"',
            textAlign: TextAlign.center,
            style: AppText.body(color: surface.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different name or equipment type.',
            textAlign: TextAlign.center,
            style: AppText.caption(color: surface.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            // Category glyph — quiet chrome (textTertiary), NOT accent, so
            // each programming family has a scannable visual identity without
            // competing with the filled CTAs or difficulty dots.
            Icon(
              RoutineTemplate.categoryIcon(label),
              size: 13,
              color: surface.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(label.toUpperCase(),
                style: AppText.columnHeader(color: surface.textSecondary)),
            const SizedBox(width: 8),
            Text(
              '$count program${count == 1 ? '' : 's'}',
              style: AppText.statLabel(color: surface.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final RoutineTemplate template;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;
  final VoidCallback? onView;
  final VoidCallback onPreview;
  final GlobalKey? importButtonKey;

  const _FeaturedCard({
    required this.template,
    required this.importing,
    required this.imported,
    required this.onImport,
    required this.onView,
    required this.onPreview,
    this.importButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    final a11yLabel = 'Featured. ${template.displayName}. '
        '${template.levelLabel}, ${template.daysPerWeek}-day split, about '
        '${template.estMinutes} minutes, ${template.totalImportableSlots} '
        'exercises. ${template.focus}. ${template.description}';

    return Semantics(
      container: true,
      button: true,
      label: a11yLabel,
      hint: 'Opens program preview',
      onTap: onPreview,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardAll,
          boxShadow: [
            BoxShadow(
              color: accent.glow,
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            // Hero card: raised one step above the list cards (which use flat
            // surface2) so the spotlight program is unmissable against the
            // page background.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [surface.surface2, surface.surface3],
            ),
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: surface.borderDefault),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPreview,
              excludeFromSemantics: true,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 13, color: surface.textSecondary),
                              const SizedBox(width: 6),
                              Text('FEATURED',
                                  style: AppText.columnHeader(
                                      color: surface.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(template.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sectionHeading(
                                  color: surface.textPrimary,
                                  shadows: AppText.depthFor(context))),
                          const SizedBox(height: 3),
                          Text(template.focus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppText.meta(color: surface.textSecondary)),
                        ],
                      ),
                    ),
                    // One fact language per card: every fact is the
                    // same neutral chip shape, and the whole row
                    // collapses into ONE semantic label so screen
                    // readers announce the facts once, not per chip.
                    // Outside the excludeSemantics wrapper above so the
                    // merged label survives as its own semantics node
                    // (container: true) instead of vanishing.
                    const SizedBox(height: 14),
                    _FactRow(template: template),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ImportPill(
                            key: importButtonKey,
                            importing: importing,
                            imported: imported,
                            onTap: importing
                                ? null
                                : (imported ? (onView ?? () {}) : onImport),
                          ),
                        ),
                      ],
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
}

class _TemplateCard extends StatelessWidget {
  final RoutineTemplate template;
  final bool importing;
  final bool imported;
  final VoidCallback onImport;
  final VoidCallback? onView;
  final VoidCallback onPreview;
  final GlobalKey? importButtonKey;

  const _TemplateCard({
    required this.template,
    required this.importing,
    required this.imported,
    required this.onImport,
    required this.onView,
    required this.onPreview,
    this.importButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final preview = template.previewSlots.take(3).map((s) => s.name).join(', ');
    final extra = template.totalImportableSlots - 3;

    final a11yLabel = '${template.displayName}. ${template.levelLabel}, '
        '${template.daysPerWeek}-day split, about ${template.estMinutes} minutes, '
        '${template.totalImportableSlots} exercises. '
        '${template.focus}. ${template.description}';

    return Semantics(
      container: true,
      button: true,
      label: a11yLabel,
      hint: 'Opens program preview',
      onTap: onPreview,
      child: Container(
        decoration: BoxDecoration(
          // surface2 (#141414) on a #000 page: a genuine 8% luminance step
          // so card boundaries read without squinting — no border-only
          // separation. The border is reinforcement, not the separation.
          color: surface.surface2,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: surface.borderDefault),
          // No per-card glow. repeated accent halos down a scrolling list
          // are visually loud and fight each other. Only the single Featured
          // hero card carries a glow (see _FeaturedCard above).
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPreview,
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4, AppSpacing.x4, AppSpacing.x4, AppSpacing.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle(
                                color: surface.textPrimary,
                                shadows: AppText.depthFor(context))),
                        const SizedBox(height: 3),
                        Text(template.focus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.meta(color: surface.textSecondary)),
                      ],
                    ),
                  ),
                  // Merged fact-row semantics (same contract as the featured
                  // card): one label per card, announced once.
                  const SizedBox(height: AppSpacing.x3),
                  _FactRow(template: template),
                  Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Divider(
                        height: 1, thickness: 1, color: surface.borderSubtle),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              '$preview${extra > 0 ? '  +$extra' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppText.caption(color: surface.textTertiary),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        _ImportPill(
                          key: importButtonKey,
                          importing: importing,
                          imported: imported,
                          onTap: importing
                              ? null
                              : (imported ? (onView ?? () {}) : onImport),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single metadata treatment for a program card: difficulty, time,
/// exercise count, day count and equipment all share ONE chip shape and
/// weight, and the whole row is announced as one semantic label. The muscle
/// groups are NOT repeated here — the focus line above carries them, and the
/// preview sheet has the full muscle map.
class _FactRow extends StatelessWidget {
  final RoutineTemplate template;
  const _FactRow({required this.template});

  String get _label => <String>[
        template.levelLabel,
        '~${template.estMinutes} min',
        '${template.totalImportableSlots} exercises',
        if (template.daysPerWeek > 1) '${template.daysPerWeek}-day',
        template.equipmentLabel,
      ].join(', ');

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final t = template;
    return Semantics(
      container: true,
      label: _label,
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpacing.x2,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FactChip(
            leading: Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: t.levelColor, shape: BoxShape.circle),
            ),
            label: t.levelLabel,
          ),
          _FactChip(
            leading: Icon(Icons.schedule_rounded,
                size: 13, color: surface.textSecondary),
            label: '~${t.estMinutes} min',
          ),
          _FactChip(
            leading: Icon(Icons.fitness_center_rounded,
                size: 13, color: surface.textSecondary),
            label: '${t.totalImportableSlots} exercises',
          ),
          if (t.daysPerWeek > 1)
            _FactChip(
              leading: Icon(Icons.calendar_view_week_rounded,
                  size: 13, color: surface.textSecondary),
              label: '${t.daysPerWeek}-day',
            ),
          _FactChip(
            leading:
                Icon(t.equipmentIcon, size: 13, color: surface.textSecondary),
            label: t.equipmentLabel,
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final Widget leading;
  final String label;
  const _FactChip({required this.leading, required this.label});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: surface.surface3,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 5),
          Text(label, style: AppText.badge(color: surface.textSecondary)),
        ],
      ),
    );
  }
}

class _ImportPill extends StatelessWidget {
  final bool importing;
  final bool imported;
  final VoidCallback? onTap;

  const _ImportPill({
    super.key,
    required this.importing,
    required this.imported,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final accent = context.accent;

    // Catalog-card CTA carve-out (DESIGN_NORTH_STAR principle 3 amendment):
    // each card is a self-contained conversion unit, so its primary action
    // carries the FULL accent fill. The label rides onAccent (near-black) per
    // the "solid accent -> black label" rule. Imported state keeps the same
    // filled form — the snackbar already confirmed the add, a persistent
    // check just adds noise.
    final Widget child = importing
        ? SizedBox(
            key: const ValueKey('spin'),
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: accent.onAccent),
          )
        : (imported
            ? Text(
                'View',
                key: const ValueKey('view'),
                style: AppText.statLabel(color: accent.onAccent),
              )
            : Row(
                key: const ValueKey('add'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded,
                      size: 16, color: accent.onAccent),
                  const SizedBox(width: 6),
                  Text('Add', style: AppText.statLabel(color: accent.onAccent)),
                ],
              ));

    return Semantics(
      button: true,
      enabled: !importing,
      label: importing
          ? 'Adding routine'
          : imported
              ? 'Added. view routine'
              : 'Add this routine',
      excludeSemantics: true,
      child: Material(
        // Filled accent; dimmed accent (not gray) while importing.
        color: importing ? accent.base.withValues(alpha: 0.6) : accent.base,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonSecondaryAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap!();
                },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reduceMotion ? 0 : 200),
              transitionBuilder: (c, anim) => FadeTransition(
                  opacity: anim, child: ScaleTransition(scale: anim, child: c)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  final RoutineTemplate template;
  final bool imported;
  final String gender;
  final Set<String> primaryGroups;
  final Set<String> secondaryGroups;
  final VoidCallback onAdd;
  final VoidCallback? onView;

  const _PreviewSheet({
    required this.template,
    required this.imported,
    required this.gender,
    required this.primaryGroups,
    required this.secondaryGroups,
    required this.onAdd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surface.surface2, surface.bgBase],
          ),
          borderRadius: AppRadius.sheetTop,
          border: Border(top: BorderSide(color: surface.borderSubtle)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: surface.borderEmphasis,
                // AppRadius.badgeAll = same pill radius as badges/chips.
                borderRadius: AppRadius.badgeAll,
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5, AppSpacing.x5, AppSpacing.x5, AppSpacing.x4),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.displayName,
                          style: AppText.sectionHeading(
                              color: surface.textPrimary,
                              shadows: AppText.depthFor(context))),
                      const SizedBox(height: 3),
                      Text(template.focus,
                          style: AppText.meta(color: surface.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  _FactRow(template: template),
                  const SizedBox(height: AppSpacing.x4),
                  Text(template.description,
                      style: AppText.body(color: surface.textSecondary)
                          .copyWith(height: 1.45)),
                  const SizedBox(height: AppSpacing.x5),
                  Semantics(
                    header: true,
                    child: Text('Muscles Worked',
                        style: AppText.cardTitle(color: surface.textPrimary)),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: MuscleMap(
                        primaryGroups: primaryGroups,
                        secondaryGroups: secondaryGroups,
                        gender: gender,
                        showBack: true,
                        showLegend: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  for (final day in template.days) _PreviewDaySection(day: day),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5, 0, AppSpacing.x5, AppSpacing.x3),
                child: PrimaryButton(
                  label:
                      imported ? 'View in My Routines' : 'Add to My Routines',
                  icon: imported ? Icons.check_rounded : Icons.download_rounded,
                  onPressed: imported ? onView : onAdd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One training day inside the multi-day preview sheet: a label/focus
/// header, a divider, then every slot for that day (including conditioning
/// notes, badged rather than hidden).
class _PreviewDaySection extends StatelessWidget {
  final ProgramDay day;
  const _PreviewDaySection({required this.day});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(day.label.toUpperCase(),
                    style: AppText.columnHeader(color: surface.textSecondary)),
                if (day.focus.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(day.focus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption(color: surface.textTertiary)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Divider(height: 1, thickness: 1, color: surface.borderSubtle),
          for (var i = 0; i < day.slots.length; i++)
            _PreviewSlotRow(index: i + 1, slot: day.slots[i]),
        ],
      ),
    );
  }
}

class _PreviewSlotRow extends StatelessWidget {
  final int index;
  final TemplateSlot slot;
  const _PreviewSlotRow({required this.index, required this.slot});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$index',
                style: AppText.statLabel(
                    color: slot.isConditioningNote
                        ? surface.textTertiary
                        : surface.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(slot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowLabel(
                    color: slot.isConditioningNote
                        ? surface.textSecondary
                        : surface.textPrimary)),
          ),
          const SizedBox(width: AppSpacing.x2),
          if (slot.isConditioningNote)
            // Not a library exercise -- nothing to attach set/rep tracking
            // to on import. Shown, not hidden: the user still sees exactly
            // what the program prescribes and logs it manually.
            Tooltip(
              message: 'Not in your exercise library -- log this manually',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: surface.surface3,
                  borderRadius: AppRadius.badgeAll,
                ),
                child: Text('LOG MANUALLY',
                    style: AppText.badge(color: surface.textTertiary)),
              ),
            )
          else
            Text('${slot.sets} × ${slot.reps}',
                style: AppText.statLabel(color: surface.textSecondary)),
        ],
      ),
    );
  }
}
