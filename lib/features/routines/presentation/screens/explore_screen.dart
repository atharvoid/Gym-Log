// [explore_screen.dart]
// 10/10 Routine-first & Program Explore experience.
//
// Unifies deep exercise inspection, anatomical SVG MuscleMap, atmospheric OLED
// glow, adaptive tablet layout, categorized filter sheets, and smooth paywall
// gating with the modern routine-first catalog, granular 1-day imports, canonical
// naming, and fast in-memory resolution.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gymlog/core/premium/library_quota.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';
import 'package:gymlog/features/routines/presentation/providers/explore_providers.dart';
import 'package:gymlog/features/routines/presentation/widgets/explore_cards.dart';
import 'package:gymlog/features/routines/presentation/widgets/explore_preview_sheet.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';

const double _kGutter = 16;
const Color _kHeroGlowColor = Color(0x12FFFFFF);

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialTab});

  /// Honours a `?tab=programs` deep link. Null keeps the current tab.
  final ExploreTab? initialTab;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  final GlobalKey _firstImportButtonKey = GlobalKey();

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
    final tourStep = ref.watch(firstRunTourProvider);
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: Stack(
        children: [
          AdaptiveContent(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 104,
                  backgroundColor: surface.bgBase,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  leading: canPop
                      ? IconButton(
                          tooltip: 'Back',
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: surface.textPrimary,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 48, minHeight: 48),
                          onPressed: () => context.pop(),
                        )
                      : null,
                  flexibleSpace: const FlexibleSpaceBar(
                    titlePadding:
                        EdgeInsetsDirectional.only(start: 56, bottom: 10),
                    expandedTitleScale: 1.25,
                    title: _HeroTitle(),
                    background: _HeroGlow(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(_kGutter, 4, _kGutter, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trainer-built routines and programs, ready to train.',
                          style: AppText.body(color: surface.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        _searchField(surface),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _tabSelector(tab)),
                SliverToBoxAdapter(child: _filterBar(filters)),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                if (tab == ExploreTab.routines)
                  _routineSliver(filters)
                else
                  _programSliver(filters),
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            ),
          ),
          if (tourStep == 1)
            SpotlightTourOverlay(
              targetKey: _firstImportButtonKey,
              title: 'Import a routine',
              description:
                  'Tap the card to inspect exercises, or tap "+" to add it directly to your library.',
              step: 1,
            ),
          if (tourStep == 2)
            SpotlightTourOverlay(
              targetKey: _firstImportButtonKey,
              title: 'Routine added',
              description:
                  'Your routine is ready. You can find it in My Routines whenever you are ready to train.',
              step: 2,
            ),
        ],
      ),
    );
  }

  // -- Header pieces --------------------------------------------------------

  Widget _searchField(SurfaceTokens surface) {
    return TextField(
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
        hintText: 'Search routines, programs or exercises...',
        hintStyle: TextStyle(color: surface.textTertiary, fontSize: 14),
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
                },
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  Widget _tabSelector(ExploreTab tab) {
    final surface = context.surface;
    final accent = Theme.of(context).colorScheme.primary;

    Widget segment(ExploreTab value, String label, int count) {
      final selected = tab == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(exploreTabProvider.notifier).state = value;
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? surface.surface3 : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? accent : surface.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          selected ? accent.withAlpha(0x24) : surface.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? accent : surface.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final routineCount = ref.watch(filteredExploreRoutinesProvider).length;
    final programCount = ref.watch(filteredExploreProgramsProvider).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 4, _kGutter, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: surface.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surface.borderSubtle),
        ),
        child: Row(
          children: [
            segment(ExploreTab.routines, 'Routines', routineCount),
            segment(ExploreTab.programs, 'Programs', programCount),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(ExploreFilters filters) {
    final notifier = ref.read(exploreFiltersProvider.notifier);

    // Level label
    final levelLabel = filters.levels.isEmpty
        ? 'Level'
        : filters.levels.length == 1
            ? templateLevelLabel(filters.levels.first)
            : '${filters.levels.length} levels';

    // Equipment label
    final equipmentLabel = filters.equipment == null
        ? 'Equipment'
        : equipmentLabelFor(filters.equipment!);

    // Duration label
    final durationLabel = filters.durations.isEmpty
        ? 'Duration'
        : filters.durations.length == 1
            ? filters.durations.first.chipLabel
            : '${filters.durations.length} durations';

    final surface = context.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kGutter),
      child: Row(
        children: [
          Expanded(
            child: ExploreFilterChip(
              label: levelLabel,
              selected: filters.levels.isNotEmpty,
              onTap: () => _openLevelSheet(filters),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ExploreFilterChip(
              label: equipmentLabel,
              selected: filters.equipment != null,
              onTap: () => _openEquipmentSheet(filters),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ExploreFilterChip(
              label: durationLabel,
              selected: filters.durations.isNotEmpty,
              onTap: () => _openDurationSheet(filters),
            ),
          ),
          if (!filters.isEmpty) ...[
            const SizedBox(width: 8),
            Material(
              color: surface.surface2,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _search.clear();
                  notifier.state = const ExploreFilters();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: surface.borderSubtle),
                  ),
                  child: Tooltip(
                    message: 'Clear all filters',
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: surface.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openLevelSheet(ExploreFilters current) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(exploreFiltersProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final surface = sheetContext.surface;
        return Container(
          decoration: BoxDecoration(
            color: surface.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            _kGutter,
            16,
            _kGutter,
            16 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surface.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Experience Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('All'),
                trailing: current.levels.isEmpty
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  notifier.update((f) => f.copyWith(levels: const {}));
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final level in TemplateLevel.values)
                ListTile(
                  title: Text(templateLevelLabel(level)),
                  trailing: current.levels.contains(level)
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    notifier.update((f) => f.copyWith(levels: {level}));
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _openEquipmentSheet(ExploreFilters current) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(exploreFiltersProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final surface = sheetContext.surface;
        return Container(
          decoration: BoxDecoration(
            color: surface.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            _kGutter,
            16,
            _kGutter,
            16 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surface.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Available Equipment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Any equipment'),
                trailing: current.equipment == null
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  notifier.update((f) => f.copyWith(clearEquipment: true));
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final eq in ProgramEquipment.values)
                ListTile(
                  title: Text(equipmentLabelFor(eq)),
                  trailing: current.equipment == eq
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    notifier.update((f) => f.copyWith(equipment: eq));
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _openDurationSheet(ExploreFilters current) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(exploreFiltersProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final surface = sheetContext.surface;
        return Container(
          decoration: BoxDecoration(
            color: surface.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            _kGutter,
            16,
            _kGutter,
            16 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surface.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Session Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: surface.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Any duration'),
                trailing: current.durations.isEmpty
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  notifier.update((f) => f.copyWith(durations: const {}));
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final d in RoutineDuration.values)
                ListTile(
                  title: Text(d.chipLabel),
                  trailing: current.durations.contains(d)
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    notifier.update((f) => f.copyWith(durations: {d}));
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
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
          final isFirst = index == 0;

          return Consumer(
            builder: (context, ref, _) {
              final profile =
                  ref.watch(routineMuscleProfileProvider(routine.slug));
              final isOwned = _ownsRoutine(routine);

              return KeyedSubtree(
                key: isFirst ? _firstImportButtonKey : null,
                child: ExploreRoutineCard(
                  routine: routine,
                  primaryGroups: profile.primary,
                  secondaryGroups: profile.secondary,
                  isOwned: isOwned,
                  onAdd: () => _importRoutine(routine),
                  onTap: () => showRoutinePreviewSheet(
                    context: context,
                    routine: routine,
                    isOwned: isOwned,
                    onAdd: () => _importRoutine(routine),
                    onView: () => _viewRoutine(routine),
                  ),
                  onOpenProgram: () => _openProgram(routine.programSlug),
                ),
              );
            },
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

          return Consumer(
            builder: (context, ref, _) {
              return ExploreProgramCard(
                template: template,
                routines: routines,
                importedCount: _importedCountFor(slug),
                onOpen: () => _openProgram(slug),
              );
            },
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
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  // -- Ownership & Navigation ------------------------------------------------

  bool _ownsRoutine(ExploreRoutine routine) {
    final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
    if (grouping == null) return false;
    final daySlug = routine.slug.split('/').last;
    for (final group in grouping.programs) {
      if (group.programSlug == routine.programSlug) {
        return group.ownedRoutineSlugs.contains(daySlug);
      }
    }
    for (final loose in grouping.standalone) {
      if (loose.name.toLowerCase() == routine.name.toLowerCase()) {
        return true;
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

  String? _routineIdFor(ExploreRoutine routine) {
    final grouping = ref.read(libraryGroupingProvider).valueOrNull;
    if (grouping == null) return null;
    final daySlug = routine.slug.split('/').last;

    for (final group in grouping.programs) {
      if (group.programSlug == routine.programSlug) {
        for (final r in group.routines) {
          if (r.membership?.routineSlug == daySlug) return r.id;
        }
      }
    }
    for (final loose in grouping.standalone) {
      if (loose.name.toLowerCase() == routine.name.toLowerCase()) {
        return loose.id;
      }
    }
    return null;
  }

  void _viewRoutine(ExploreRoutine routine) {
    final id = _routineIdFor(routine);
    if (id != null) {
      context.push('/routines/$id');
    } else {
      context.push('/routines');
    }
  }

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
// Header visual decorations
// ---------------------------------------------------------------------------

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) => Text(
        'Explore',
        style: AppText.sectionHeading(
          color: context.surface.textPrimary,
          shadows: AppText.depthFor(context),
        ),
      );
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
          colors: [_kHeroGlowColor, Color(0x00FFFFFF)],
          stops: [0.0, 0.72],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Program detail screen
// ---------------------------------------------------------------------------

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

    final programProfile = ref.watch(programMuscleProfileProvider(programSlug));
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final gender = userProfile?.gender ?? 'male';

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        elevation: 0,
        title: Text(template.displayName, overflow: TextOverflow.ellipsis),
      ),
      body: AdaptiveContent(
        child: ListView(
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

            // Program Muscle Focus Section
            Semantics(
              header: true,
              child: Text(
                'Program Muscle Focus',
                style: AppText.cardTitle(color: surface.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: MuscleMap(
                  primaryGroups: programProfile.primary,
                  secondaryGroups: programProfile.secondary,
                  gender: gender,
                  showBack: true,
                  showLegend: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

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
              Consumer(
                builder: (context, ref, _) {
                  final profile =
                      ref.watch(routineMuscleProfileProvider(routine.slug));
                  final isOwned =
                      ownedDays.contains(routine.slug.split('/').last);

                  return ExploreRoutineCard(
                    routine: routine,
                    primaryGroups: profile.primary,
                    secondaryGroups: profile.secondary,
                    isOwned: isOwned,
                    showProgramLine: false,
                    onAdd: () => _importOne(context, ref, routine),
                    onTap: () => showRoutinePreviewSheet(
                      context: context,
                      routine: routine,
                      isOwned: isOwned,
                      onAdd: () => _importOne(context, ref, routine),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
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
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll,
                        ),
                      ),
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
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonPrimaryAll,
                      ),
                    ),
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
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonPrimaryAll,
                  ),
                ),
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
// Shared feedback & Paywall Trigger
// ---------------------------------------------------------------------------

Future<void> showImportOutcome(
  BuildContext context,
  ImportResult result, {
  required String fallbackLabel,
}) async {
  final blocked = result.blockedBy;
  if (blocked != null) {
    if (blocked == ImportVerdict.needsPremiumProgramSlot ||
        blocked == ImportVerdict.needsPremiumRoutineSlots) {
      await showPremiumPaywall(context, source: PaywallSource.routineLimit);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(importBlockedCopy(blocked) ?? 'Import unavailable'),
      duration: const Duration(seconds: 4),
    ));
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

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
