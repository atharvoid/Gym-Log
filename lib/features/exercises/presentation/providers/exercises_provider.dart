import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';

part 'exercises_provider.g.dart';

@riverpod
class ExerciseList extends _$ExerciseList {
  /// Monotonic counter that drops stale async search results — fast typing
  /// must never let an older (slower) query overwrite a newer one.
  int _searchEpoch = 0;

  @override
  Future<List<Exercise>> build() async {
    final db = ref.watch(databaseProvider);
    return db.exercisesDao.getAllExercises();
  }

  Future<void> search(String query) async {
    final epoch = ++_searchEpoch;
    final db = ref.read(databaseProvider);
    final results = query.isEmpty
        ? await db.exercisesDao.getAllExercises()
        : await db.exercisesDao.searchExercises(query);
    if (epoch != _searchEpoch) return; // stale — a newer search superseded us
    state = AsyncData(results);
  }
}
