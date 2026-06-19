import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import '../providers/exercises_provider.dart';
import '../widgets/create_exercise_dialog.dart';

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

/// Exercise list with live search, Recent section, and combinable
/// Muscle / Equipment filters.
///
/// Two modes, one screen:
///  * Selection (default): tapping pops with the chosen [Exercise].
///  * Browse (`browse: true`, route `/exercises/library`): tapping opens
///    the exercise detail with charts, records and form instructions.
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
  Timer? _searchDebounce;
  String? _muscleFilter;
  String? _equipmentFilter;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Driven by the controller's listener so it fires on programmatic clears too.
  /// `setState` runs ONLY when the empty↔non-empty boundary flips (which is all
  /// the UI needs — Recent visibility + the clear button) instead of on every
  /// keystroke, so a fast typist no longer re-filters + re-sorts the whole
  /// catalog per character. The DB search itself is debounced 150ms.
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

    return Scaffold(
      backgroundColor: AppColors.bgBase,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchController,
              style: AppText.body(color: AppColors.textPrimary),
              cursorColor: AppColors.accentPrimary,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search exercises…',
                hintStyle: AppText.body(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                suffixIcon: _isSearching
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: _searchController.clear,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // ── Filters ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
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

    final items = <_ListItem>[
      if (recent.isNotEmpty) ...[
        const _ListItem.header('RECENT'),
        ...recent.map(_ListItem.exercise),
        const _ListItem.header('ALL EXERCISES'),
      ],
      ...catalog.map(_ListItem.exercise),
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final header = item.headerLabel;
        if (header != null) {
          return Padding(
            key: ValueKey('h_$header'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Semantics(
              header: true,
              child: Text(header,
                  style: AppText.columnHeader(color: AppColors.textSecondary)),
            ),
          );
        }
        return _ExerciseRow(
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
    return ListTile(
      onTap: onTap,
      leading: RepaintBoundary(
        child: ExerciseThumbnail(gifUrl: exercise.gifUrl, size: 44),
      ),
      title: Text(
        exercise.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.exerciseName(),
      ),
      subtitle: Text(
        '${exercise.target} • ${exercise.equipment}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption(),
      ),
      trailing: browse
          ? const ExcludeSemantics(
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textTertiary),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreate;
  const _EmptyState({required this.isSearching, required this.onCreate});

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.accentText),
              label: Text('Create custom exercise',
                  style: AppText.statLabel(color: AppColors.accentText)),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SkeletonBox(width: 44, height: 44, radius: 10),
              SizedBox(width: 16),
              Expanded(
                child: Column(
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
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                      color: selected
                          ? AppColors.accentPrimary
                          : AppColors.textPrimary),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded,
                    size: 18, color: AppColors.accentPrimary),
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
    final fg = active ? AppColors.accentText : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: '$label filter${active ? ', active' : ''}',
      excludeSemantics: true,
      child: Material(
        color: active
            ? AppColors.accentPrimary.withValues(alpha: 0.14)
            : AppColors.surface3,
        borderRadius: AppRadius.badgeAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: AppRadius.badgeAll,
              border: active
                  ? Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.45))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppText.statLabel(color: fg)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: active ? AppColors.accentText : AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
