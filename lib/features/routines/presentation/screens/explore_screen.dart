// [explore_screen.dart]
// 10/10 Routine-first & Program Explore experience.
//
// Unifies deep exercise inspection, anatomical SVG MuscleMap, atmospheric OLED
// glow, adaptive tablet layout, categorized filter sheets, and smooth paywall
// gating with the modern routine-first catalog, granular 1-day imports, canonical
// naming, and fast in-memory resolution.
//
// LAYOUT INVARIANTS:
// - Filter chips are content-sized and scroll horizontally. They are never put
//   in Expanded: a third of a 360dp screen cannot hold "Intermediate".
// - Filter sheets toggle and stay open. The chip labels promise multi-select
//   ("2 levels"), so the sheets must actually deliver it.
// - Search is debounced. The catalog is filtered in-memory, but not per
//   keystroke.
// - The empty state names what emptied it and offers to undo exactly that.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gymlog/core/premium/library_quota.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
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
const double _kMinTapTarget = 44;
const Color _kHeroGlowColor = Color(0x12FFFFFF);

/// Long enough to swallow a burst of typing, short enough that the result
/// still feels like it is keeping up with you.
const Duration _kSearchDebounce = Duration(milliseconds: 220);

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialTab});

  /// Honours a `?tab=programs` deep link. Null keeps the current tab.
  final ExploreTab? initialTab;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _firstImportButtonKey = GlobalKey();

  Timer? _searchDebounce;

  /// Mirrors whether the field has text. Kept locally because the provider is
  /// now debounced, and the clear button must not lag behind the keyboard.
  bool _hasQuery = false;

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
    _searchDebounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  // -- Search ---------------------------------------------------------------

  void _onQueryChanged(String value) {
    final hasQuery = value.trim().isNotEmpty;
    if (hasQuery != _hasQuery) setState(() => _hasQuery = hasQuery);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(_kSearchDebounce, () => _applyQuery(value));
  }

  void _applyQuery(String value) {
    if (!mounted) return;
    ref
        .read(exploreFiltersProvider.notifier)
        .update((f) => f.copyWith(query: value));
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _search.clear();
    if (_hasQuery) setState(() => _hasQuery = false);
    _applyQuery('');
  }

  void _clearEverything() {
    _searchDebounce?.cancel();
    _search.clear();
    if (_hasQuery) setState(() => _hasQuery = false);
    ref.read(exploreFiltersProvider.notifier).state = const ExploreFilters();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final tab = ref.watch(exploreTabProvider);
    final filters = ref.watch(exploreFiltersProvider);
    final tourStep = ref.watch(firstRunTourProvider);
    final canPop = context.canPop();

    // Switching shelves used to inherit the other shelf's scroll offset, so
    // tapping "Programs" after scrolling routines dropped you into the middle
    // of a list you had never seen.
    ref.listen<ExploreTab>(exploreTabProvider, (previous, next) {
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && _scroll.offset > 0) _scroll.jumpTo(0);
      });
    });

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: Stack(
        children: [
          AdaptiveContent(
            child: CustomScrollView(
              controller: _scroll,
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
                  flexibleSpace: FlexibleSpaceBar(
                    // Reserved 56dp for a back button even when there was no
                    // back button, leaving the title floating mid-air on the
                    // tab-root entry.
                    titlePadding: EdgeInsetsDirectional.only(
                      start: canPop ? 56 : _kGutter,
                      bottom: 10,
                    ),
                    expandedTitleScale: 1.25,
                    title: const _HeroTitle(),
                    background: const _HeroGlow(),
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
          // Step 1 and 2 copy is shelf-aware: program cards have no "+", so
          // promising one was instructing the user to tap something absent.
          if (tourStep == 1)
            SpotlightTourOverlay(
              targetKey: _firstImportButtonKey,
              title: tab == ExploreTab.routines
                  ? 'Import a routine'
                  : 'Open a program',
              description: tab == ExploreTab.routines
                  ? 'Tap the card to inspect exercises, or tap "+" to add it '
                      'directly to your library.'
                  : 'Tap a program to see its training days, then add the days '
                      'you want to your library.',
              step: 1,
            ),
          if (tourStep == 2)
            SpotlightTourOverlay(
              targetKey: _firstImportButtonKey,
              title: tab == ExploreTab.routines
                  ? 'Routine added'
                  : 'Programs are made of routines',
              description: tab == ExploreTab.routines
                  ? 'Your routine is ready. You can find it in My Routines '
                      'whenever you are ready to train.'
                  : 'Add a whole program or just the days that fit your week. '
                      'Everything lands in My Routines.',
              step: 2,
            ),
        ],
      ),
    );
  }

  // -- Header pieces --------------------------------------------------------

  Widget _searchField(SurfaceTokens surface) {
    final accent = context.accent;

    return TextField(
      controller: _search,
      onChanged: _onQueryChanged,
      // The field had no keyboard action and no submit path, so there was no
      // way to say "I am done typing, search now".
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        _searchDebounce?.cancel();
        _applyQuery(value);
      },
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      style: TextStyle(color: surface.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: surface.surface2,
        hintText: 'Search routines, programs or exercises\u2026',
        hintStyle: TextStyle(color: surface.textTertiary, fontSize: 14),
        prefixIcon:
            Icon(Icons.search_rounded, size: 20, color: surface.textTertiary),
        suffixIcon: !_hasQuery
            ? null
            : IconButton(
                tooltip: 'Clear search',
                constraints: const BoxConstraints(
                  minWidth: _kMinTapTarget,
                  minHeight: _kMinTapTarget,
                ),
                icon: Icon(Icons.close_rounded,
                    size: 18, color: surface.textTertiary),
                onPressed: _clearQuery,
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
          borderSide: BorderSide(color: accent.base.withAlpha(0x88)),
        ),
      ),
    );
  }

  Widget _tabSelector(ExploreTab tab) {
    final surface = context.surface;
    final accent = context.accent.base;

    Widget segment(ExploreTab value, String label, int count) {
      final selected = tab == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: '$label, $count available',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(exploreTabProvider.notifier).state = value;
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              // 38dp was below the minimum tap target, and this is the most
              // tapped control on the screen.
              height: _kMinTapTarget,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? surface.surface3 : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? accent : surface.textTertiary,
                      ),
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

  // -- Filters --------------------------------------------------------------

  String _levelLabel(ExploreFilters filters) => filters.levels.isEmpty
      ? 'Level'
      : filters.levels.length == 1
          ? templateLevelLabel(filters.levels.first)
          : '${filters.levels.length} levels';

  String _equipmentLabel(ExploreFilters filters) => filters.equipment == null
      ? 'Equipment'
      : equipmentLabelFor(filters.equipment!);

  String _durationLabel(ExploreFilters filters) => filters.durations.isEmpty
      ? 'Duration'
      : filters.durations.length == 1
          ? filters.durations.first.chipLabel
          : '${filters.durations.length} durations';

  /// Horizontally scrollable and content-sized.
  ///
  /// This used to be a Row of three `Expanded` chips, which handed each chip a
  /// third of the screen minus gutters -- about 100dp on a 360dp phone. Every
  /// label longer than "Level" was ellipsized, and the moment a filter became
  /// active the clear button claimed a fourth slice and made it worse.
  Widget _filterBar(ExploreFilters filters) {
    final surface = context.surface;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kGutter, vertical: 6),
        physics: const ClampingScrollPhysics(),
        children: [
          ExploreFilterChip(
            label: _levelLabel(filters),
            selected: filters.levels.isNotEmpty,
            onTap: _openLevelSheet,
          ),
          const SizedBox(width: 8),
          ExploreFilterChip(
            label: _equipmentLabel(filters),
            selected: filters.equipment != null,
            onTap: _openEquipmentSheet,
          ),
          const SizedBox(width: 8),
          ExploreFilterChip(
            label: _durationLabel(filters),
            selected: filters.durations.isNotEmpty,
            onTap: _openDurationSheet,
          ),
          if (!filters.isEmpty || _hasQuery) ...[
            const SizedBox(width: 8),
            Material(
              color: surface.surface2,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _clearEverything();
                },
                child: Container(
                  width: _kMinTapTarget,
                  height: _kMinTapTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: surface.borderSubtle),
                  ),
                  child: Tooltip(
                    message: 'Clear search and filters',
                    child: Icon(
                      Icons.filter_alt_off_rounded,
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

  /// One sheet implementation for all three filters.
  ///
  /// Previously three ~90-line copies of the same layout, each with its own
  /// grabber, padding and title block, which is how they ended up with
  /// inconsistent reset copy ("All" vs "Any equipment" vs "Any duration").
  ///
  /// It stays open while you toggle, and rebuilds from the provider through a
  /// Consumer, so selections and the counts on the tabs behind it update live.
  Future<void> _showFilterSheet({
    required String title,
    required List<Widget> Function(ExploreFilters filters) options,
  }) async {
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final surface = sheetContext.surface;
        return Consumer(
          builder: (context, sheetRef, _) {
            final filters = sheetRef.watch(exploreFiltersProvider);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
              ),
              decoration: BoxDecoration(
                color: surface.bgSurface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: surface.borderDefault,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_kGutter, 0, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: surface.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: options(filters),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleLevel(TemplateLevel level) {
    ref.read(exploreFiltersProvider.notifier).update((f) {
      final next = {...f.levels};
      if (next.contains(level)) {
        next.remove(level);
      } else {
        next.add(level);
      }
      return f.copyWith(levels: next);
    });
  }

  void _toggleDuration(RoutineDuration duration) {
    ref.read(exploreFiltersProvider.notifier).update((f) {
      final next = {...f.durations};
      if (next.contains(duration)) {
        next.remove(duration);
      } else {
        next.add(duration);
      }
      return f.copyWith(durations: next);
    });
  }

  void _setEquipment(ProgramEquipment? equipment) {
    final notifier = ref.read(exploreFiltersProvider.notifier);
    if (equipment == null) {
      notifier.update((f) => f.copyWith(clearEquipment: true));
    } else {
      notifier.update((f) => f.copyWith(equipment: equipment));
    }
  }

  Future<void> _openLevelSheet() => _showFilterSheet(
        title: 'Experience level',
        options: (filters) => [
          _FilterOptionTile(
            label: 'All levels',
            selected: filters.levels.isEmpty,
            isMulti: false,
            onTap: () => ref
                .read(exploreFiltersProvider.notifier)
                .update((f) => f.copyWith(levels: const {})),
          ),
          for (final level in TemplateLevel.values)
            _FilterOptionTile(
              label: templateLevelLabel(level),
              selected: filters.levels.contains(level),
              isMulti: true,
              onTap: () => _toggleLevel(level),
            ),
        ],
      );

  Future<void> _openEquipmentSheet() => _showFilterSheet(
        // Single-select, honestly: `equipment` is a nullable scalar on the
        // model, not a Set. Making it multi is a provider change, not a UI one.
        title: 'Available equipment',
        options: (filters) => [
          _FilterOptionTile(
            label: 'Any equipment',
            selected: filters.equipment == null,
            isMulti: false,
            onTap: () => _setEquipment(null),
          ),
          for (final eq in ProgramEquipment.values)
            _FilterOptionTile(
              label: equipmentLabelFor(eq),
              selected: filters.equipment == eq,
              isMulti: false,
              onTap: () => _setEquipment(filters.equipment == eq ? null : eq),
            ),
        ],
      );

  Future<void> _openDurationSheet() => _showFilterSheet(
        title: 'Session duration',
        options: (filters) => [
          _FilterOptionTile(
            label: 'Any duration',
            selected: filters.durations.isEmpty,
            isMulti: false,
            onTap: () => ref
                .read(exploreFiltersProvider.notifier)
                .update((f) => f.copyWith(durations: const {})),
          ),
          for (final d in RoutineDuration.values)
            _FilterOptionTile(
              label: d.chipLabel,
              selected: filters.durations.contains(d),
              isMulti: true,
              onTap: () => _toggleDuration(d),
            ),
        ],
      );

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
          final isFirst = index == 0;

          return Consumer(
            builder: (context, ref, _) {
              // The tour's only anchor lived in the routines list, so on this
              // shelf step 1 had nothing to point at.
              return KeyedSubtree(
                key: isFirst ? _firstImportButtonKey : null,
                child: ExploreProgramCard(
                  template: template,
                  routines: routines,
                  importedCount: _importedCountFor(slug),
                  onOpen: () => _openProgram(slug),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Names what emptied the list and lets you undo exactly that.
  ///
  /// The old version said "Nothing matches those filters" and "2 filters
  /// active" even when the culprit was the search text, and its only escape was
  /// a single button that also wiped the query you had just typed.
  Widget _emptySliver(ExploreFilters filters) {
    final surface = context.surface;
    final query = filters.query.trim();
    final chips = _activeFilterChips(filters);

    final headline = query.isNotEmpty && chips.isEmpty
        ? 'No matches for "$query"'
        : query.isNotEmpty
            ? 'No matches for "$query" with these filters'
            : 'Nothing matches these filters';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kGutter, 40, _kGutter, 48),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 36, color: surface.textTertiary),
            const SizedBox(height: 12),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: surface.textSecondary,
              ),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Tap a filter to remove it',
                style: TextStyle(fontSize: 13, color: surface.textTertiary),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
            ],
            const SizedBox(height: 16),
            if (query.isNotEmpty && chips.isNotEmpty)
              TextButton(
                onPressed: _clearQuery,
                child: const Text('Keep filters, clear search'),
              ),
            TextButton(
              onPressed: _clearEverything,
              child: const Text('Reset everything'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _activeFilterChips(ExploreFilters filters) {
    return [
      for (final level in filters.levels)
        _RemovableFilterChip(
          label: templateLevelLabel(level),
          onRemove: () => _toggleLevel(level),
        ),
      if (filters.equipment != null)
        _RemovableFilterChip(
          label: equipmentLabelFor(filters.equipment!),
          onRemove: () => _setEquipment(null),
        ),
      for (final duration in filters.durations)
        _RemovableFilterChip(
          label: duration.chipLabel,
          onRemove: () => _toggleDuration(duration),
        ),
    ];
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
      return;
    }

    // The fallback used to push '/routines', which is not a route in
    // router.dart -- go_router threw, or landed on an error page, instead of
    // explaining that the routine is not in the library yet.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('${routine.name} is not in your library yet'),
    ));
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
// Filter sheet pieces
// ---------------------------------------------------------------------------

/// A single row in a filter sheet.
///
/// `isMulti` drives the affordance: a checkbox reads as "combine these", a
/// checkmark reads as "pick one". The old sheets used a checkmark for both
/// while behaving like single-select, which is what hid the fact that
/// multi-select was unreachable.
class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.label,
    required this.selected,
    required this.isMulti,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isMulti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent.base;

    return Semantics(
      inMutuallyExclusiveGroup: !isMulti,
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: _kGutter),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        selected ? surface.textPrimary : surface.textSecondary,
                  ),
                ),
              ),
              if (isMulti)
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 22,
                  color: selected ? accent : surface.textTertiary,
                )
              else if (selected)
                Icon(Icons.check_rounded, size: 20, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// An active filter, in the empty state, that removes itself when tapped.
class _RemovableFilterChip extends StatelessWidget {
  const _RemovableFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return Semantics(
      button: true,
      label: 'Remove $label filter',
      excludeSemantics: true,
      child: Material(
        color: surface.surface2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.selectionClick();
            onRemove();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: _kMinTapTarget),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: surface.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: surface.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.close_rounded,
                    size: 15, color: surface.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
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
    final surface = context.surface;

    // A white radial glow is invisible on a light background, so the light
    // theme lost the header treatment entirely. Tint it with the accent there.
    final glow =
        surface.isLight ? context.accent.base.withAlpha(0x14) : _kHeroGlowColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.85),
          radius: 1.15,
          colors: [glow, glow.withAlpha(0)],
          stops: const [0.0, 0.72],
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: surface.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: surface.textTertiary),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: surface.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surface.borderSubtle),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            fact('per week', '${template.daysPerWeek} days'),
            VerticalDivider(
              width: 16,
              thickness: 1,
              color: surface.borderSubtle,
            ),
            fact('per session', min == max ? '$min min' : '$min-$max min'),
            VerticalDivider(
              width: 16,
              thickness: 1,
              color: surface.borderSubtle,
            ),
            fact('level', template.levelLabel),
          ],
        ),
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
    final accent = context.accent.base;
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
                ? 'Free \u2014 completing a program you already have'
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll,
                        ),
                      ),
                      onPressed: () => _chooseRoutines(context, ref),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Choose routines',
                          maxLines: 1,
                        ),
                      ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonPrimaryAll,
                      ),
                    ),
                    onPressed: () => _importAll(context, ref),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        missing.length == 1
                            ? 'Add routine'
                            : 'Add all ${missing.length}',
                        maxLines: 1,
                      ),
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
                    if (checked) {
                      _selected.remove(routine.slug);
                    } else {
                      _selected.add(routine.slug);
                    }
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
