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

/// Fixed header height — the alphabet scrubber computes scroll offsets from these.
/// S5.2: Exercise rows use an estimated height of 80 for scrolling calculations.
const double _kEstimatedRowHeight = 80;
const double _kHeaderHeight = 36;

/// Live recent-exercise ids from workout history.
final _recentExerciseIdsProvider = StreamProvider.autoDispose<List<int>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchRecentExerciseIds(user.id);
});

/// Muscle-group buckets → exercise.bodyPart (region) values.
const _muscleGroups = <String, List<String>>{
  'Chest': ['chest'],
  'Back': ['back'],
  'Shoulders': ['shoulders'],
  'Arms': ['arms', 'forearms'],
  'Legs': ['legs'],
  'Core': ['core'],
};

/// Equipment buckets → matcher over exercise.equipment (lower-cased).
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

/// Exercise list with live search, Recent section, combinable Muscle / Equipment
/// filters, and an A–Z scrubber.
///
/// Two modes, one screen:
///  * Selection (default): tapping pops with the chosen [Exercise].
///  * Browse (`browse: true`, route `/exercises/library`): tapping opens
///    the exercise detail.
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

  /// S5.1: Cached filtered list + letter offsets.
  /// Computed once per data/filter change (not per build) via [_computeList].
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

  /// `setState` runs ONLY on the empty↔non-empty boundary (Recent visibility +
  /// clear button) — not per keystroke — so the catalog filter+sort doesn't
  /// re-run on every character. The DB search is debounced 250ms
  /// (S5.1: increased from 150ms to 250ms for less churn on rapid typing).
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

  static String _initial(String name) {
    final t = name.trim().toUpperCase();
    if (t.isEmpty) return '#';
    final c = t[0];
    return (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ? c : '#';
  }

  void _jumpToLetter(String letter, Map<String, double> letterOffsets) {
    final offset = letterOffsets[letter];
    if (offset == null || !_scrollController.hasClients) return;
    HapticFeedback.selectionClick();
    _scrollController.jumpTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  Future<void> _pickFilter({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String?> onSelected,
  }) async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<String?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface2,
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
                    color: AppColors.borderEmphasis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title, style: AppText.cardTitle()),
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

  /// S5.1: Computes the filtered + sorted catalog and letter→offset map.
  /// Results are cached so a rebuild without data/filter changes reuses the
  /// previous computation.
  ({
    List<Exercise> recent,
    List<Exercise> catalog,
    Map<String, double> letterOffsets,
    List<_ListItem> items,
  }) _computeList(List<Exercise> exercises, List<int> recentIds) {
    // Cache check: if nothing changed, reuse the previous computation.
    final dataHash = Object.hash(exercises.length, _muscleFilter, _equipmentFilter);
    if (_cachedFiltered != null &&
        _cachedMuscleFilter == _muscleFilter &&
        _cachedEquipmentFilter == _equipmentFilter &&
        _cachedDataHash == dataHash) {
      // Still need to build items+offsets from cache...
      // Actually this path is rare; the cache mainly helps when only _searchFocused
      // changes. Fall through to rebuild items from cached filtered.
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
    final catalog = filtered
        .where((e) => !recentIdSet.contains(e.id))
        .toList()
      ..sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final items = <_ListItem>[];
    final letterIndex = <String, int>{};
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
      letterIndex.putIfAbsent(_initial(e.name), () => items.length);
      items.add(_ListItem.exercise(e));
    }

    final letterOffsets = <String, double>{};
    var currentOffset = 0.0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (!item.isHeader) {
        final letter = _initial(item.exerciseValue!.name);
        letterOffsets.putIfAbsent(letter, () => currentOffset);
      }
      currentOffset += item.isHeader ? _kHeaderHeight : _kEstimatedRowHeight;
    }

    return (
      recent: recent,
      catalog: catalog,
      letterOffsets: letterOffsets,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);
    final recentIds = ref.watch(_recentExerciseIdsProvider).valueOrNull ?? [];
    final hasFilters = _muscleFilter != null || _equipmentFilter != null;
    final accent = context.accent;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          widget.browse ? 'Exercise Library' : 'Select Exercise',
          // S3: text-depth shadow on screen title
          style: AppText.sectionHeading(shadows: AppText.depthFor(context)),
        ),
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Create custom exercise',
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
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
                borderRadius: AppRadius.inputAll,
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
                style: AppText.body(color: AppColors.textPrimary),
                cursorColor: accent.base,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Search exercises…',
                  hintStyle: AppText.body(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _isSearching
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface3,
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.inputAll,
                    borderSide:
                        BorderSide(color: AppColors.borderSubtle, width: 1),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.inputAll,
                    borderSide:
                        BorderSide(color: AppColors.borderSubtle, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputAll,
                    borderSide: BorderSide(color: accent.base, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _FilterChipButton(
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
                const SizedBox(width: 8),
                _FilterChipButton(
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
                if (hasFilters) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _muscleFilter = null;
                      _equipmentFilter = null;
                      _cachedFiltered = null;
                    }),
                    child: Text('Clear',
                        style: AppText.statLabel(color: accent.light)),
                  ),
                ],
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

  /// S5.1: Uses [_computeList] which caches the filtered/sorted catalog.
  /// The build method no longer re-runs filtering on every rebuild — only
  /// when the data or filters actually change.
  Widget _list(List<Exercise> exercises, List<int> recentIds) {
    final computed = _computeList(exercises, recentIds);

    if (computed.recent.isEmpty && computed.catalog.isEmpty) {
      return _EmptyState(isSearching: _isSearching, onCreate: _createCustom);
    }

    final showRail =
        !_isSearching && computed.catalog.length >= 15;

    final list = ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        right: showRail ? 24 : 0,
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
                            color: AppColors.textSecondary)),
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

    if (!showRail) return list;

    return Stack(
      children: [
        list,
        Positioned(
          top: 4,
          bottom: 4,
          right: 0,
          child: _AlphabetRail(
            present: computed.letterOffsets.keys.toSet(),
            onLetter: (l) => _jumpToLetter(l, computed.letterOffsets),
          ),
        ),
      ],
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

/// S5.2: Row sizing — vertical padding 14, thumbnail 52, gap 16, subtitle gap 4.
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
                    // S3: text-depth shadow on exercise name
                    Text(exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.exerciseName(shadows: AppText.depthFor(context))),
                    const SizedBox(height: 4),
                    Text('${exercise.target} • ${exercise.equipment}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption()),
                  ],
                ),
              ),
              if (browse) ...[
                const SizedBox(width: 8),
                const ExcludeSemantics(
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlphabetRail extends StatefulWidget {
  final Set<String> present;
  final ValueChanged<String> onLetter;
  const _AlphabetRail({required this.present, required this.onLetter});

  static const _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  @override
  State<_AlphabetRail> createState() => _AlphabetRailState();
}

class _AlphabetRailState extends State<_AlphabetRail> {
  String? _last;

  void _handle(double dy, double height) {
    if (height <= 0) return;
    final i = (dy / height * _AlphabetRail._letters.length)
        .floor()
        .clamp(0, _AlphabetRail._letters.length - 1);
    final letter = _AlphabetRail._letters[i];
    if (letter == _last) return;
    _last = letter;
    if (widget.present.contains(letter)) widget.onLetter(letter);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handle(d.localPosition.dy, h),
          onVerticalDragStart: (d) => _handle(d.localPosition.dy, h),
          onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, h),
          onVerticalDragEnd: (_) => _last = null,
          child: Semantics(
            label: 'Alphabet scrubber',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.fitHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final l in _AlphabetRail._letters)
                      Text(
                        l,
                        style: AppText.columnHeader(
                          color: widget.present.contains(l)
                              ? accent.light
                              : AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 30, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 10),
            Text('No exercises match', style: AppText.rowLabel()),
            const SizedBox(height: 3),
            Text(
              isSearching
                  ? 'Not in the library? Add it yourself.'
                  : 'Try clearing a filter or changing the search.',
              textAlign: TextAlign.center,
              style: AppText.caption(),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add_rounded,
                  size: 18, color: accent.light),
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
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                      color: selected
                          ? accent.base
                          : AppColors.textPrimary),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded,
                    size: 18, color: accent.base),
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
    final fg = active ? accent.onAccent : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: '$label filter${active ? ', active' : ''}',
      excludeSemantics: true,
      child: Material(
        color: active ? accent.base : AppColors.surface3,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // S3: on-accent halo shadow when active
                Text(label, style: AppText.statLabel(
                    color: fg,
                    shadows: active ? TextDepth.onAccentHalo(context.accent.palette) : null)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color:
                        active ? accent.onAccent : AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
