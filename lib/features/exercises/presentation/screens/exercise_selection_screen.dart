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
/// Exercise rows use an estimated height of 64 for scrolling calculations.
const double _kEstimatedRowHeight = 64;
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

  /// Toggles the focus glow only on the focus↔blur boundary.
  void _onFocusChanged() {
    if (_searchFocus.hasFocus != _searchFocused) {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    }
  }

  /// `setState` runs ONLY on the empty↔non-empty boundary (Recent visibility +
  /// clear button) — not per keystroke — so the catalog filter+sort doesn't
  /// re-run on every character. The DB search is debounced 150ms.
  void _onQueryChanged() {
    final searching = _searchController.text.trim().isNotEmpty;
    if (searching != _isSearching) setState(() => _isSearching = searching);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
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

  /// Bucket letter for the scrubber — A–Z, everything else to '#'.
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
      isScrollControlled: true, // size to content (+ scroll) — never overflow
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
                // Scrollable so a long option list (Equipment has 8) never
                // overflows on short screens.
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
          style: AppText.sectionHeading(),
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
          // ── Search ─────────────────────────────────────────────────────
          // An input is a recessed surface: Surface-3 fill, hairline border by
          // default, a thicker accent edge + soft accent glow on focus. The
          // accent edge/glow are pulled from the live palette so the dynamic-accent
          // theme recolors search focus for free.
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
                  // Surface 3 is the design system's recessed input fill.
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

          // ── Filters ────────────────────────────────────────────────────
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
                    onSelected: (v) => setState(() => _muscleFilter = v),
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
                    onSelected: (v) => setState(() => _equipmentFilter = v),
                  ),
                ),
                if (hasFilters) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _muscleFilter = null;
                      _equipmentFilter = null;
                    }),
                    child: Text('Clear',
                        style: AppText.statLabel(color: accent.light)),
                  ),
                ],
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────────────
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
    final filtered = exercises.where(_matchesFilters).toList();

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

    if (recent.isEmpty && catalog.isEmpty) {
      return _EmptyState(isSearching: _isSearching, onCreate: _createCustom);
    }

    // Build the flat item list + a letter→firstItemIndex map for the scrubber.
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

    // Precompute letter offsets for O(1) jump positioning.
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

    final showRail = !_isSearching && catalog.length >= 15;

    final list = ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        right: showRail ? 24 : 0,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      itemCount: items.length,
      // RepaintBoundary on every row so scrolling doesn't repaint rows that
      // haven't changed. The thumbnail GIF in each row is the main paint cost.
      itemBuilder: (context, index) {
        final item = items[index];
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
            present: letterIndex.keys.toSet(),
            onLetter: (l) => _jumpToLetter(l, letterOffsets),
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

/// Fixed-height (64) exercise row — replaces the stock ListTile so the A–Z
/// scrubber can compute exact scroll offsets.
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ExerciseThumbnail(
                  gifUrl: exercise.gifUrl, size: 44, fastFrame: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.exerciseName()),
                    const SizedBox(height: 2),
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

/// A–Z scrubber rail (Hevy-style). Tap or drag to jump the list to a letter;
/// present letters are accented, absent ones dimmed. One haptic per letter
/// change (not per drag frame). The letter column is wrapped in a FittedBox so
/// it scales to the available height instead of overflowing on short screens.
class _AlphabetRail extends StatefulWidget {
  final Set<String> present;
  final ValueChanged<String> onLetter;
  const _AlphabetRail({required this.present, required this.onLetter});

  static const _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
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

/// Shimmer placeholder list — matches the real row geometry so the swap on
/// load doesn't pop.
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SkeletonBox(width: 44, height: 44, radius: 0),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 13),
                    SizedBox(height: 7),
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
    final fg = active ? accent.light : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: '$label filter${active ? ', active' : ''}',
      excludeSemantics: true,
      child: Material(
        color: active
            ? accent.base.withValues(alpha: 0.14)
            : AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
              border: active
                  ? Border.all(
                      color: accent.base.withValues(alpha: 0.45))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppText.statLabel(color: fg)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color:
                        active ? accent.light : AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
