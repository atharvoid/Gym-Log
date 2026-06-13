import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';

/// Read-only previous-session sets for the active workout's PREVIOUS column.
///
/// Returns the ordered sets from the most recent COMPLETED session in which
/// this exercise appears — the exact "15kg x 12" reference Hevy shows beside
/// each row. Keyed by exercise id; Riverpod caches per id for the screen's
/// lifetime so scrolling never re-queries.
///
/// Deliberately additive and side-effect-free: it reuses the EXISTING
/// `WorkoutsDao.getPreviousSessionSets` query and never touches the active
/// workout state machine, the input data flow, or the DAO. Passing '' as the
/// current-session id excludes nothing, which is correct — the active session
/// is in-memory only and not yet persisted, so it can't be its own baseline.
final previousSessionSetsProvider =
    FutureProvider.family<List<WorkoutSet>, int>((ref, exerciseId) async {
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.getPreviousSessionSets(exerciseId, '');
});
