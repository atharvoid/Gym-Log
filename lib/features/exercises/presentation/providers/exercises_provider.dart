import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';

part 'exercises_provider.g.dart';

@riverpod
class ExerciseList extends _$ExerciseList {
  @override
  Future<List<Exercise>> build() async {
    final db = ref.watch(databaseProvider);
    return db.exercisesDao.getAllExercises();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      final db = ref.read(databaseProvider);
      state = AsyncData(await db.exercisesDao.getAllExercises());
      return;
    }
    final db = ref.read(databaseProvider);
    state = AsyncData(await db.exercisesDao.searchExercises(query));
  }
}
