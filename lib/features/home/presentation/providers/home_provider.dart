import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

// ── Pagination state ──────────────────────────────────────────────────────────

class WorkoutHistoryState {
  final List<WorkoutSessionPreview> items;
  final bool hasMore;
  final bool isLoadingMore;

  /// True only before the very first page resolves — drives the skeleton.
  final bool isInitialLoad;

  const WorkoutHistoryState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = true,
    this.isInitialLoad = true,
  });

  WorkoutHistoryState copyWith({
    List<WorkoutSessionPreview>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoad,
  }) =>
      WorkoutHistoryState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Paginated, fully **reactive** workout feed.
///
/// Subscribes to a Drift revision stream over the workout tables, so the
/// feed reloads itself after every finish / edit / delete — there is no
/// manual invalidation signal to forget. The reload re-fetches the window
/// the user has already scrolled (not just page 1), so the scroll position
/// survives database writes.
class WorkoutHistoryNotifier extends StateNotifier<WorkoutHistoryState> {
  static const _pageSize = 10;

  final Ref _ref;
  StreamSubscription<void>? _revisionSub;

  WorkoutHistoryNotifier(Ref ref)
      : _ref = ref,
        super(const WorkoutHistoryState()) {
    final user = _ref.read(authProvider);
    if (user == null) {
      state = const WorkoutHistoryState(
        isLoadingMore: false,
        hasMore: false,
        isInitialLoad: false,
      );
      return;
    }

    // Drift emits the current snapshot immediately on listen, which doubles
    // as the initial load — then re-emits after any workout-table write.
    _revisionSub = _ref
        .read(databaseProvider)
        .workoutsDao
        .watchHistoryRevision(user.id)
        .listen((_) => _reloadVisibleWindow());
  }

  @override
  void dispose() {
    _revisionSub?.cancel();
    super.dispose();
  }

  Future<void> _reloadVisibleWindow() async {
    final user = _ref.read(authProvider);
    if (user == null) return;

    // Refresh at least one page, but keep everything already on screen.
    final target =
        state.items.length < _pageSize ? _pageSize : state.items.length;

    try {
      final db = _ref.read(databaseProvider);
      final fetched = await db.workoutsDao.getSessionPreviewsForUser(
        user.id,
        limit: target + 1,
        offset: 0,
      );

      if (!mounted) return;
      final hasMore = fetched.length > target;
      state = state.copyWith(
        items: hasMore ? fetched.sublist(0, target) : fetched,
        hasMore: hasMore,
        isLoadingMore: false,
        isInitialLoad: false,
      );
    } catch (e) {
      debugPrint('[WorkoutHistoryNotifier] reload failed: $e');
      if (mounted) {
        state = state.copyWith(isLoadingMore: false, isInitialLoad: false);
      }
    }
  }

  /// Appends the next page. No-ops if already loading or no more pages.
  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;
    final user = _ref.read(authProvider);
    if (user == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final db = _ref.read(databaseProvider);
      final fetched = await db.workoutsDao.getSessionPreviewsForUser(
        user.id,
        limit: _pageSize + 1,
        offset: state.items.length,
      );

      if (!mounted) return;
      final hasMore = fetched.length > _pageSize;
      state = state.copyWith(
        items: [
          ...state.items,
          ...hasMore ? fetched.sublist(0, _pageSize) : fetched,
        ],
        hasMore: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('[WorkoutHistoryNotifier] fetchNextPage failed: $e');
      if (mounted) state = state.copyWith(isLoadingMore: false);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final workoutHistoryProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>(
  (ref) => WorkoutHistoryNotifier(ref),
);
