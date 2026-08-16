// [explore_screen.dart]
// Routine-first Explore.
//
// The screen this replaces presented 16 PROGRAMS as the browsable unit. A
// program is a multi-week commitment, so every card asked the user for a
// decision they could not evaluate, showed one muscle map for six different
// training days (which highlighted the whole body), and offered exactly one
// action: import all of it.
//
// Here the browsable unit is a ROUTINE -- one training day, with its own
// muscles, its own duration and its own Add button. Programs remain, on their
// own tab, presented as what they are: a week-shaped commitment you open
// before you accept.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymlog/core/premium/library_quota.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';
import 'package:gymlog/features/routines/presentation/providers/explore_providers.dart';
import 'package:gymlog/features/routines/presentation/widgets/explore_cards.dart';

const double _kGutter = 16;

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialTab});

  /// Honours a `?tab=programs` deep link. Null keeps the current tab.
  final ExploreTab? initialTab;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab;
    if (tab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(exploreTabProvider.notifier).state = tab;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final tab = ref.watch(exploreTabProvider);
    final filters = ref.watch(exploreFiltersProvider);

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        elevation: 0,
        title: const Text('Explore'),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _searchField(surface)),
            SliverToBoxAdapter(child: _tabSelector(tab)),
            SliverToBoxAdapter(child: _filterRow(filters)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            if (tab == ExploreTab.routines)
              _routineSliver(filters)
            else
              _programSliver(filters),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // -- Header pieces --------------------------------------------------------

  Widget _searchField(SurfaceTokens surface) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 4, _kGutter, 12),
      child: TextField(
        controller: _search,
        onChanged: (value) {
          ref.read(exploreFiltersProvider.notifier).update(
                (f) => f.copyWith(query: value),
              );
        },
        style: TextStyle(color: surface.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: surface.surface2,
          hintText: 'Search routines or an exercise',
          hintStyle: TextStyle(color: surface.textTertiary, fontSize: 15),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: surface.textTertiary),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: surface.textTertiary),
                  onPressed: () {
                    _search.clear();
                    ref
                        .read(exploreFiltersProvider.notifier)
                        .update((f) => f.copyWith(query: ''));
                    setState(() {});
                  },
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: surface.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: surface.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(0x88),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabSelector(ExploreTab tab) {
    final surface = context.surface;
    final accent = Theme.of(context).colorScheme.primary;

    Widget segment(ExploreTab value, String label) {
      final selected = tab == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => ref.read(exploreTabProvider.notifier).state = value,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? surface.surface3 : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? accent : surface.textTertiary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 0, _kGutter, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: surface.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surface.borderSubtle),
        ),
        child: Row(
          children: [
            segment(ExploreTab.routines, 'Routines'),
            segment(ExploreTab.programs, 'Programs'),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(ExploreFilters filters) {
    final notifier = ref.read(exploreFiltersProvider.notifier);

    void toggleLevel(TemplateLevel level) {
      final next = {...filters.levels};
      next.contains(level) ? next.remove(level) : next.add(level);
      notifier.update((f) => f.copyWith(levels: next));
    }

    void toggleDuration(RoutineDuration duration) {
      final next = {...filters.durations};
      next.contains(duration) ? next.remove(duration) : next.add(duration);
      notifier.update((f) => f.copyWith(durations: next));
    }

    void setEquipment(ProgramEquipment equipment) {
      if (filters.equipment == equipment) {
        notifier.update((f) => f.copyWith(clearEquipment: true));
      } else {
        notifier.update((f) => f.copyWith(equipment: equipment));
      }
    }

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kGutter),
        children: [
          for (final level in TemplateLevel.values) ...[
            ExploreFilterChip(
              label: templateLevelLabel(level),
              selected: filters.levels.contains(level),
              onTap: () => toggleLevel(level),
            ),
            const SizedBox(width: 8),
          ],
          for (final duration in RoutineDuration.values) ...[
            ExploreFilterChip(
              label: duration.chipLabel,
              selected: filters.durations.contains(duration),
              onTap: () => toggleDuration(duration),
            ),
            const SizedBox(width: 8),
          ],
          for (final equipment in ProgramEquipment.values) ...[
            ExploreFilterChip(
              label: equipmentLabelFor(equipment),
              selected: filters.equipment == equipment,
              onTap: () => setEquipment(equipment),
            ),
            const SizedBox(width: 8),
          ],
          if (!filters.isEmpty)
            ExploreFilterChip(
              label: 'Clear',
              selected: false,
              onTap: () {
                _search.clear();
                notifier.state = const ExploreFilters();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  // -- Content --------------------------------------------------------------

  Widget _routineSliver(ExploreFilters filters) {
    final routines = ref.watch(filteredExploreRoutinesProvider);
    if (routines.isEmpty) return _emptySliver(filters);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _kGutter),
      sliver: SliverList.separated(
        itemCount: routines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final routine = routines[index];
          final profile = ref.watch(routineMuscleProfileProvider(routine.slug));
          return ExploreRoutineCard(
            routine: routine,
            primaryGroups: profile.primary,
            secondaryGroups: profile.secondary,
            isOwned: _ownsRoutine(routine),
            onAdd: () => _importRoutine(routine),
            onOpenProgram: () => _openProgram(routine.programSlug),
          );
        },
      ),
    );
  }

  Widget _programSliver(ExploreFilters filters) {
    final templates = ref.watch(filteredExploreProgramsProvider);
    if (templates.isEmpty) return _emptySliver(filters);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _kGutter),
      sliver: SliverList.separated(
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final template = templates[index];
          final slug = programSlugFor(template);
          final routines = routinesForProgram(slug);
          return ExploreProgramCard(
            template: template,
            routines: routines,
            importedCount: _importedCountFor(slug),
            onOpen: () => _openProgram(slug),
          );
        },
      ),
    );
  }

  Widget _emptySliver(ExploreFilters filters) {
    final surface = context.surface;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kGutter, 48, _kGutter, 48),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 36, color: surface.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Nothing matches those filters',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: surface.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${filters.activeCount} filter'
              '${filters.activeCount == 1 ? '' : 's'} active',
              style: TextStyle(fontSize: 13, color: surface.textTertiary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _search.clear();
                ref.read(exploreFiltersProvider.notifier).state =
                    const ExploreFilters();
                setState(() {});
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  // -- Ownership ------------------------------------------------------------

  bool _ownsRoutine(ExploreRoutine routine) {
    final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
    if (grouping == null) return false;
    final daySlug = routine.slug.split('/').last;
    for (final group in grouping.programs) {
      if (group.programSlug == routine.programSlug) {
        return group.ownedRoutineSlugs.contains(daySlug);
      }
    }
    return false;
  }

  int _importedCountFor(String programSlug) {
    final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
    if (grouping == null) return 0;
    for (final group in grouping.programs) {
      if (group.programSlug == programSlug) return group.importedCount;
    }
    return 0;
  }

  // -- Actions --------------------------------------------------------------

  void _openProgram(String programSlug) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgramDetailScreen(programSlug: programSlug),
      ),
    );
  }

  Future<void> _importRoutine(ExploreRoutine routine) async {
    final result =
        await ref.read(exploreImportControllerProvider).importRoutine(routine);
    if (!mounted) return;
    showImportOutcome(context, result, fallbackLabel: routine.name);
  }
}

// ---------------------------------------------------------------------------
// Program detail
// ---------------------------------------------------------------------------

/// A program, full screen. The sheet this replaces was 60% of the viewport,
/// so a six-day program was never visible at once, and it offered a single
/// all-or-nothing import.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programSlug});

  final String programSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = context.surface;
    final template = exploreProgramBySlug[programSlug];
    final routines = routinesForProgram(programSlug);

    if (template == null || routines.isEmpty) {
      return Scaffold(
        backgroundColor: surface.bgBase,
        appBar: AppBar(backgroundColor: surface.bgBase, elevation: 0),
        body: const Center(child: Text('This program is no longer available')),
      );
    }

    final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
    Set<String> ownedDays = const {};
    if (grouping != null) {
      for (final group in grouping.programs) {
        if (group.programSlug == programSlug) {
          ownedDays = group.ownedRoutineSlugs;
        }
      }
    }

    final missing = [
      for (final r in routines)
        if (!ownedDays.contains(r.slug.split('/').last)) r,
    ];

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        elevation: 0,
        title: Text(template.displayName, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(_kGutter, 0, _kGutter, 24),
        children: [
          Text(
            template.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: surface.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _ProgramFacts(template: template, routines: routines),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Routines in this program',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: surface.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (ownedDays.isNotEmpty)
                Text(
                  '${ownedDays.length} of ${routines.length} added',
                  style: TextStyle(fontSize: 12, color: surface.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final routine in routines) ...[
            Builder(
              builder: (context) {
                final profile =
                    ref.watch(routineMuscleProfileProvider(routine.slug));
                return ExploreRoutineCard(
                  routine: routine,
                  primaryGroups: profile.primary,
                  secondaryGroups: profile.secondary,
                  isOwned: ownedDays.contains(routine.slug.split('/').last),
                  showProgramLine: false,
                  onAdd: () => _importOne(context, ref, routine),
                  onOpenProgram: () {},
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
      bottomNavigationBar: missing.isEmpty
          ? null
          : _ImportBar(
              programSlug: programSlug,
              missing: missing,
              totalRoutines: routines.length,
            ),
    );
  }

  Future<void> _importOne(
    BuildContext context,
    WidgetRef ref,
    ExploreRoutine routine,
  ) async {
    final result =
        await ref.read(exploreImportControllerProvider).importRoutine(routine);
    if (!context.mounted) return;
    showImportOutcome(context, result, fallbackLabel: routine.name);
  }
}

class _ProgramFacts extends StatelessWidget {
  const _ProgramFacts({required this.template, required this.routines});

  final RoutineTemplate template;
  final List<ExploreRoutine> routines;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    var min = routines.first.estMinutes;
    var max = min;
    for (final r in routines) {
      if (r.estMinutes < min) min = r.estMinutes;
      if (r.estMinutes > max) max = r.estMinutes;
    }

    Widget fact(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: surface.textTertiary),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surface.borderSubtle),
      ),
      child: Row(
        children: [
          fact('per week', '${template.daysPerWeek} days'),
          fact('per session', min == max ? '$min min' : '$min-$max min'),
          fact('level', template.levelLabel),
        ],
      ),
    );
  }
}

/// States the cost of importing before the user commits, and offers the
/// subset path next to the all-in path.
class _ImportBar extends ConsumerWidget {
  const _ImportBar({
    required this.programSlug,
    required this.missing,
    required this.totalRoutines,
  });

  final String programSlug;
  final List<ExploreRoutine> missing;
  final int totalRoutines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = context.surface;
    final accent = Theme.of(context).colorScheme.primary;
    final isPremium = ref.watch(isPremiumProvider);
    final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
    final ownedPrograms = grouping?.programs.length ?? 0;
    final standalone = grouping?.standalone.length ?? 0;
    final isPartial = missing.length < totalRoutines;

    final verdict = evaluateImport(
      isPremium: isPremium,
      kind: isPartial ? ImportKind.routineIntoOwnedProgram : ImportKind.program,
      ownedProgramCount: ownedPrograms,
      standaloneRoutineCount: standalone,
      routineCount: missing.length,
    );

    final blocked = importBlockedCopy(verdict);
    final costLine = blocked ??
        (isPremium
            ? 'Adds ${missing.length} routines to your library'
            : isPartial
                ? 'Free -- completing a program you already have'
                : 'Uses your free program slot');

    return Container(
      padding: EdgeInsets.fromLTRB(
        _kGutter,
        12,
        _kGutter,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: surface.bgSurface,
        border: Border(top: BorderSide(color: surface.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            costLine,
            style: TextStyle(
              fontSize: 12,
              color: blocked == null ? surface.textTertiary : accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (missing.length > 1) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _chooseRoutines(context, ref),
                      child: const Text('Choose routines'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _importAll(context, ref),
                    child: Text(
                      missing.length == 1
                          ? 'Add routine'
                          : 'Add all ${missing.length}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _importAll(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(exploreImportControllerProvider).importProgram(
              programSlug: programSlug,
              routines: missing,
            );
    if (!context.mounted) return;
    showImportOutcome(context, result, fallbackLabel: 'Program');
  }

  Future<void> _chooseRoutines(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<List<ExploreRoutine>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChooseRoutinesSheet(routines: missing),
    );
    if (selected == null || selected.isEmpty) return;
    if (!context.mounted) return;

    final result =
        await ref.read(exploreImportControllerProvider).importProgram(
              programSlug: programSlug,
              routines: selected,
            );
    if (!context.mounted) return;
    showImportOutcome(context, result, fallbackLabel: 'Routines');
  }
}

/// Pick a subset of a program's routines. The capability the old all-or-
/// nothing import never had.
class _ChooseRoutinesSheet extends StatefulWidget {
  const _ChooseRoutinesSheet({required this.routines});

  final List<ExploreRoutine> routines;

  @override
  State<_ChooseRoutinesSheet> createState() => _ChooseRoutinesSheetState();
}

class _ChooseRoutinesSheetState extends State<_ChooseRoutinesSheet> {
  late final Set<String> _selected = {
    for (final r in widget.routines) r.slug,
  };

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: surface.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_kGutter, 4, _kGutter, 12),
            child: Row(
              children: [
                Text(
                  'Choose routines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: surface.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selected.length == widget.routines.length) {
                      _selected.clear();
                    } else {
                      _selected.addAll(widget.routines.map((r) => r.slug));
                    }
                  }),
                  child: Text(
                    _selected.length == widget.routines.length
                        ? 'Clear all'
                        : 'Select all',
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.routines.length,
              itemBuilder: (context, index) {
                final routine = widget.routines[index];
                final checked = _selected.contains(routine.slug);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (_) => setState(() {
                    checked
                        ? _selected.remove(routine.slug)
                        : _selected.add(routine.slug);
                  }),
                  title: Text(routine.name),
                  subtitle: Text(
                    '${routine.estMinutes} min  \u00b7  '
                    '${routine.exerciseCount} exercises',
                    style: TextStyle(fontSize: 12, color: surface.textTertiary),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_kGutter, 8, _kGutter, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop([
                          for (final r in widget.routines)
                            if (_selected.contains(r.slug)) r,
                        ]),
                child: Text(
                  _selected.isEmpty
                      ? 'Select at least one'
                      : 'Add ${_selected.length} routine'
                          '${_selected.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared feedback
// ---------------------------------------------------------------------------

/// One place that reports what an import did. A blocked import explains the
/// rule rather than firing an unexplained paywall, and unresolved catalog
/// slots are admitted instead of silently dropped.
void showImportOutcome(
  BuildContext context,
  ImportResult result, {
  required String fallbackLabel,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final blocked = result.blockedBy;
  if (blocked != null) {
    messenger.showSnackBar(SnackBar(
      content: Text(importBlockedCopy(blocked) ?? 'Import unavailable'),
      duration: const Duration(seconds: 4),
    ));
    return;
  }

  if (!result.didImport) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Nothing was imported'),
    ));
    return;
  }

  final count = result.routineCount;
  final missing = result.unresolvedExercises.length;
  final base = count == 1
      ? '$fallbackLabel added to My Routines'
      : '$count routines added to My Routines';

  messenger.showSnackBar(SnackBar(
    content: Text(
      missing == 0
          ? base
          : '$base  \u00b7  $missing exercise'
              '${missing == 1 ? '' : 's'} not in your library',
    ),
  ));
}
