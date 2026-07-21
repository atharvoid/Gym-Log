import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';

import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

part 'exercises_provider.g.dart';

/// Full, UNFILTERED exercise catalog keyed by id — an O(1) lookup for hot paths
/// that need to resolve an exercise by id on every rebuild (the active-workout
/// list rebuilds on every keystroke; a linear `.where()` over the whole catalog
/// per visible row was needless work).
///
/// Deliberately kept SEPARATE from [exerciseListProvider]: that list is mutated
/// in place by the picker's live search, so deriving the map from it would make
/// a logged exercise's thumbnail/detail-link vanish the moment the user typed a
/// search in the picker. This reads the catalog straight from the DAO, so the
/// id→Exercise mapping is always the complete library regardless of any search.
final exerciseCatalogByIdProvider =
    FutureProvider<Map<int, Exercise>>((ref) async {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authProvider);
  final all = await db.exercisesDao.getAllExercises(userId: user?.id);
  return {for (final e in all) e.id: e};
});

@riverpod
class ExerciseList extends _$ExerciseList {
  int _searchEpoch = 0;

  @override
  Future<List<Exercise>> build() async {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(authProvider);
    return db.exercisesDao.getAllExercises(userId: user?.id);
  }

  Future<void> search(String query) async {
    final epoch = ++_searchEpoch;
    final db = ref.read(databaseProvider);
    final user = ref.read(authProvider);
    final results = query.isEmpty
        ? await db.exercisesDao.getAllExercises(userId: user?.id)
        : await db.exercisesDao.searchExercises(query, userId: user?.id);
    if (epoch != _searchEpoch) return;
    state = AsyncData(results);
  }
}
