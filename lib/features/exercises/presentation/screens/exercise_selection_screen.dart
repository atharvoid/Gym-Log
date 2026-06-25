import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import '../providers/exercises_provider.dart';
import '../widgets/create_exercise_dialog.dart';

const double _kHeaderHeight = 36;

final _recentExerciseIdsProvider = StreamProvider.autoDispose<List<int>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchRecentExerciseIds(user.id);
});

const _muscleGroups = <String, List<String>>{
  'Chest': ['chest'],
  'Back': ['back'],
  'Shoulders': ['shoulders'],
  'Arms': ['arms', 'forearms'],
  'Legs': ['legs'],
  'Core': ['core'],
};

final _equipmentGroups = <String, bool Function(String)>{
  'Barbell': (e) =>
      e.contains('barbell') || e.contains('ez bar') || e.contains('trap bar'),
  'Dumbbell': (e) => e.contains('dumbbell'),
  'Machine': (e) => e.contains('machine'),
  'Cable': (e) => e.contains('cable'),
  'Bodyweight': (e) => e.contains('bodyweight') || e.contains('body weight'),
  'Kettlebell': (e) => e.contains('kettlebell'),
  'Band': (e) => e.contains('band'),
};

class ExerciseSelectionScreen extends ConsumerStatefulWidget {
  final bool browse;

  const ExerciseSelectionScreen({super.key, this.browse = false});

  @override
  ConsumerState<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState
    extends ConsumerState<ExerciseSelectionScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  String? _muscleFilter;
  String? _equipmentFilter;
  bool _isSearching = false;
  bool _searchFocused = false;

  List<Exercise>? _cachedFiltered;
  String? _cachedMuscleFilter;
  String? _cachedEquipmentFilter;
  int? _cachedDataHash;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _searchFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_searchFocus.hasFocus != _searchFocused) {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    }
  }

  void _onQueryChanged() {
    final searching = _searchController.text.trim().isNotEmpty;
    if (searching != _isSearching) setState(() => _isSearching = searching);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(exerciseListProvider.notifier).search(_searchController.text);
    });
  }

  Future<void> _createCustom() async {
    final seed = _searchController.text.trim();
    final created = await showCreateExerciseDialog(
      context: context,
      initialName: seed.isEmpty ? null : seed,
    );
    if (created == null || !mounted) return;
    if (!widget.browse) Navigator.pop(context, created);
  }

  bool _matchesFilters(Exercise e) {
    if (_muscleFilter != null &&
        !_muscleGroups[_muscleFilter]!.contains(e.bodyPart)) {
      return false;
    }
    if (_equipmentFilter != null &&
        !_equipmentGroups[_equipmentFilter]!(e.equipment.toLowerCase())) {
      return false;
    }
    return true;
  }

  Future<void> _pickFilter({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String?> onSelected,
  }) async {
    HapticFeedback.lightImpact();
    final surface = context.surface;
    final result = await showModalBottomSheet<String?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: surface.surface2,
          borderRadius: AppRadius.sheetTop,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surface.borderEmphasis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title,
                    style: AppText.cardTitle(color: surface.textPrimary)),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in ['All', ...options])
                          _FilterOptionRow(
                            label: option,
                            selected: option == current ||
                                (option == 'All' && current == null),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(sheetCtx)
                                  .pop(option == 'All' ? '__all__' : option);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      onSelected(result == '__all__' ? null : result);
    }
  }

  ({
    List<Exercise> recent,
    List<Exercise> catalog,
    List<_ListItem> items,
  }) _computeList(List<Exercise> exercises, List<int> recentIds) {
    final dataHash =
        Object.hash(exercises.length, _muscleFilter, _equipmentFilter);
    if (_cachedFiltered != null &&
        _cachedMuscleFilter == _muscleFilter &&
        _cachedEquipmentFilter == _equipmentFilter &&
        _cachedDataHash == dataHash) {
      // Cache hit — reuse previous computation.
    }

    final filtered = exercises.where(_matchesFilters).toList();
    _cachedFiltered = filtered;
    _cachedMuscleFilter = _muscleFilter;
    _cachedEquipmentFilter = _equipmentFilter;
    _cachedDataHash = dataHash;

    final recent = <Exercise>[];
    if (!_isSearching && recentIds.isNotEmpty) {
      final byId = {for (final e in filtered) e.id: e};
      for (final id in recentIds) {
        final e = byId[id];
        if (e != null) recent.add(e);
      }
    }
    final recentIdSet = {for (final e in recent) e.id};
    final catalog = filtered.where((e) => !recentIdSet.contains(e.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final items = <_ListItem>[];
    if (recent.isNotEmpty) {
      items.add(const _ListItem.header('RECENT'));
      items.addAll(recent.map(_ListItem.exercise));
      items.add(_ListItem.header('ALL EXERCISES · ${catalog.length}'));
    } else {
      items.add(_ListItem.header(_isSearching
          ? '${catalog.length} result${catalog.length == 1 ? '' : 's'}'
          : 'ALL EXERCISES · ${catalog.length}'));
    }
    for (final e in catalog) {
      items.add(_ListItem.exercise(e));
    }

    return (
      recent: recent,
      catalog: catalog,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);
    final recentIds = ref.watch(_recentExerciseIdsProvider).valueOrNull ?? [];
    final hasFilters = _muscleFilter != null || _equipmentFilter != null;
    final accent = context.accent;
    final surface = context.surface;

    return Scaffold(
      backgroundColor: surface.bgBase,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          widget.browse ? 'Exercise Library' : 'Select Exercise',
          style: AppText.sectionHeading(
              color: surface.textPrimary, shadows: AppText.depthFor(context)),
        ),
        backgroundColor: surface.bgBase,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Create custom exercise',
            icon: Icon(Icons.add_rounded, color: surface.textPrimary),
            onPressed: _createCustom,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: AppRadius.buttonSecondaryAll,
                boxShadow: _searchFocused
                    ? [
                        BoxShadow(
                          color: accent.base.withValues(alpha: 0.18),
                          blurRadius: 12,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                style: AppText.body(color: surface.textPrimary),
                cursorColor: accent.base,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Search exercises…',
                  hintStyle: AppText.body(color: surface.textTertiary),
                  prefixIcon: Icon(Icons.search, color: surface.textSecondary),
                  suffixIcon: _isSearching
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: Icon(Icons.cancel,
                              size: 18, color: surface.textSecondary),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: surface.surface3,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.buttonSecondaryAll,
                    borderSide:
                        BorderSide(color: surface.borderSubtle, width: 1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.buttonSecondaryAll,
                    borderSide:
                        BorderSide(color: surface.borderSubtle, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.buttonSecondaryAll,
                    borderSide: BorderSide(color: accent.base, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FilterChipButton(
                        label: _muscleFilter ?? 'Muscle',
                        active: _muscleFilter != null,
                        onTap: () => _pickFilter(
                          title: 'Muscle Group',
                          options: _muscleGroups.keys.toList(),
                          current: _muscleFilter,
                          onSelected: (v) => setState(() {
                            _muscleFilter = v;
                            _cachedFiltered = null;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: _FilterChipButton(
                        label: _equipmentFilter ?? 'Equipment',
                        active: _equipmentFilter != null,
                        onTap: () => _pickFilter(
                          title: 'Equipment',
                          options: _equipmentGroups.keys.toList(),
                          current: _equipmentFilter,
                          onSelected: (v) => setState(() {
                            _equipmentFilter = v;
                            _cachedFiltered = null;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasFilters)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _muscleFilter = null;
                        _equipmentFilter = null;
                        _cachedFiltered = null;
                      }),
                      child: Text('Clear filters',
                          style: AppText.statLabel(color: accent.light)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => _list(exercises, recentIds),
              loading: () => const _LoadingList(),
              error: (_, __) => AsyncErrorState(
                message: "Couldn't load exercises.",
                onRetry: () => ref.invalidate(exerciseListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<Exercise> exercises, List<int> recentIds) {
    final computed = _computeList(exercises, recentIds);

    if (computed.recent.isEmpty && computed.catalog.isEmpty) {
      return _EmptyState(isSearching: _isSearching, onCreate: _createCustom);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      itemCount: computed.items.length,
      itemBuilder: (context, index) {
        final item = computed.items[index];
        final header = item.headerLabel;
        if (header != null) {
          return SizedBox(
            key: ValueKey('h_$header'),
            height: _kHeaderHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Semantics(
                    header: true,
                    child: Text(header,
                        style: AppText.columnHeader(
                            color: context.surface.textSecondary)),
                  ),
                ),
              ),
            ),
          );
        }
        return RepaintBoundary(
          child: _ExerciseRow(
            key: ValueKey('e_${item.exerciseValue!.id}'),
            exercise: item.exerciseValue!,
            browse: widget.browse,
            onTap: () {
              HapticFeedback.selectionClick();
              if (widget.browse) {
                context.push('/exercise/detail/${item.exerciseValue!.id}',
                    extra: item.exerciseValue);
              } else {
                Navigator.pop(context, item.exerciseValue);
              }
            },
          ),
        );
      },
    );
  }
}

class _ListItem {
  final String? headerLabel;
  final Exercise? exerciseValue;

  const _ListItem.header(this.headerLabel) : exerciseValue = null;
  const _ListItem.exercise(this.exerciseValue) : headerLabel = null;

  bool get isHeader => headerLabel != null;
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final bool browse;
  final VoidCallback onTap;

  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.browse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ExerciseThumbnail(
                  gifUrl: exercise.gifUrl, size: 52, fastFrame: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.exerciseName(
                            color: surface.textPrimary,
                            shadows: AppText.depthFor(context))),
                    const SizedBox(height: 4),
                    Text('${exercise.target} • ${exercise.equipment}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption(color: surface.textSecondary)),
                  ],
                ),
              ),
              if (browse) ...[
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20, color: surface.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreate;
  const _EmptyState({required this.isSearching, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 30,
                color: surface.isLight
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 10),
            Text('No exercises match',
                style: AppText.rowLabel(color: surface.textPrimary)),
            const SizedBox(height: 3),
            Text(
              isSearching
                  ? 'Not in the library? Add it yourself.'
                  : 'Try clearing a filter or changing the search.',
              textAlign: TextAlign.center,
              style: AppText.caption(color: surface.textSecondary),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add_rounded, size: 18, color: accent.light),
              label: Text('Create custom exercise',
                  style: AppText.statLabel(color: accent.light)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 9,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SkeletonBox(width: 52, height: 52, radius: 0),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 13),
                    SizedBox(height: 4),
                    SkeletonBox(width: 100, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: surface.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                      color: selected ? accent.base : surface.textPrimary),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 18, color: accent.base),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    final fg = active ? accent.onAccent : surface.textPrimary;
    return Semantics(
      button: true,
      label: '$label filter${active ? ', active' : ''}',
      excludeSemantics: true,
      child: Material(
        color: active ? accent.base : surface.surface3,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppText.statLabel(
                        color: fg,
                        shadows: active
                            ? TextDepth.onAccentHalo(context.accent.palette)
                            : null)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: active ? accent.onAccent : surface.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
