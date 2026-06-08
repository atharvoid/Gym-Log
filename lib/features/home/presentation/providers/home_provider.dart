import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

/// Incremented by [ActiveWorkoutNotifier.finishWorkout] each time a session
/// is saved. [WorkoutHistoryNotifier] watches this to reset and reload.
final workoutCompletedSignalProvider = StateProvider<int>((ref) => 0);

// ── Pagination state ──────────────────────────────────────────────────────────

class WorkoutHistoryState {
  final List<WorkoutSessionPreview> items;
  final bool hasMore;
  final bool isLoadingMore;

  const WorkoutHistoryState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = true, // true on initial construction → shows spinner
  });

  WorkoutHistoryState copyWith({
    List<WorkoutSessionPreview>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      WorkoutHistoryState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class WorkoutHistoryNotifier extends StateNotifier<WorkoutHistoryState> {
  static const _pageSize = 10;

  final Ref _ref;

  WorkoutHistoryNotifier(Ref ref)
      : _ref = ref,
        // Start with isLoadingMore: true so the UI shows a spinner immediately
        super(const WorkoutHistoryState(isLoadingMore: true)) {
    // Reload from page 1 whenever a workout is completed
    ref.listen<int>(workoutCompletedSignalProvider, (_, __) => _reset());
    _loadPage(0, replace: true);
  }

  Future<void> _reset() async {
    state = const WorkoutHistoryState(isLoadingMore: true);
    await _loadPage(0, replace: true);
  }

  Future<void> _loadPage(int offset, {bool replace = false}) async {
    final user = _ref.read(authProvider);
    if (user == null) {
      state = const WorkoutHistoryState(isLoadingMore: false, hasMore: false);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      // Fetch pageSize+1 — if we get more than pageSize items, there is a next page
      final fetched = await db.workoutsDao.getSessionPreviewsForUser(
        user.id,
        limit: _pageSize + 1,
        offset: offset,
      );

      final hasMore = fetched.length > _pageSize;
      final pageItems = hasMore ? fetched.sublist(0, _pageSize) : fetched;

      state = state.copyWith(
        items: replace ? pageItems : [...state.items, ...pageItems],
        hasMore: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('[WorkoutHistoryNotifier] Error loading page: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Appends the next page. No-ops if already loading or no more pages.
  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _loadPage(state.items.length);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final workoutHistoryProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>(
  (ref) => WorkoutHistoryNotifier(ref),
);
