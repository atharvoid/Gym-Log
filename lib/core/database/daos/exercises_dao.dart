import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env.dart';
import '../database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

/// Bump this key whenever the JSON asset or URL format changes.
/// Incrementing forces all existing installs to re-run hydration on next launch.
const _kHydrationKey = 'exercises_hydrated_v2';

/// Base URL of the public storage bucket that hosts exercise GIFs.
/// Centralized in [Env] (overridable via --dart-define GIF_BUCKET_BASE).
const _kGifBase = Env.gifBucketBase;

@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  // ── Queries ────────────────────────────────────────────────────────────────

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<Exercise> getExerciseById(int id) =>
      (select(exercises)..where((t) => t.id.equals(id))).getSingle();

  Future<List<Exercise>> searchExercises(String query) {
    // Neutralize LIKE wildcards — exercise names never contain % or _,
    // so treating them as plain separators keeps search predictable.
    final sanitized = query.replaceAll('%', ' ').replaceAll('_', ' ').trim();
    return (select(exercises)
          ..where((t) => t.name.like('%$sanitized%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Exercise>> filterByBodyPart(String bodyPart) =>
      (select(exercises)..where((t) => t.bodyPart.equals(bodyPart))).get();

  Future<List<Exercise>> filterByEquipment(String equipment) =>
      (select(exercises)..where((t) => t.equipment.equals(equipment))).get();

  /// COUNT(*) in SQL — the old version loaded all ~1,300 rows just to count.
  Future<int> getExerciseCount() {
    final count = exercises.id.count();
    final query = selectOnly(exercises)..addColumns([count]);
    return query.getSingle().then((row) => row.read(count) ?? 0);
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> insertExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);

  Future<void> insertExercises(List<ExercisesCompanion> list) => batch(
      (b) => b.insertAll(exercises, list, mode: InsertMode.insertOrIgnore));

  /// Creates a user-defined exercise and returns its new row id.
  ///
  /// Used by CSV import when an incoming exercise name has no match in the
  /// bundled catalog — keeping the import lossless. [exerciseDbId] stays null
  /// (no GIF), [isCustom] is set, and [createdBy] records the owner.
  Future<int> createCustomExercise(
    String name, {
    required String userId,
    String bodyPart = 'other',
    String equipment = 'other',
    String target = 'other',
  }) {
    return into(exercises).insert(ExercisesCompanion.insert(
      name: name,
      bodyPart: bodyPart,
      equipment: equipment,
      target: target,
      isCustom: const Value(true),
      createdBy: Value(userId),
      seededAt: Value(DateTime.now()),
    ));
  }

  // ── Hydration Engine ───────────────────────────────────────────────────────

  /// One-time bulk seed from the bundled `assets/db/exercises.json`.
  ///
  /// Two-phase approach:
  ///   1. UPDATE — patches gifUrl on any existing JSON-sourced rows.
  ///      Handles re-runs after a URL format change without touching row IDs
  ///      (preserves all FK references in workout_exercises / workout_sets).
  ///   2. INSERT OR IGNORE — adds any rows that don't exist yet.
  ///
  /// Guarded by a SharedPreferences key. Bump [_kHydrationKey] to force
  /// re-execution on all existing installs.
  Future<void> hydrateFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kHydrationKey) == true) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/db/exercises.json');
      final root = jsonDecode(jsonString) as Map<String, dynamic>;
      final list = root['exercises'] as List<dynamic>;

      // ── Phase 1: Fix any stale gifUrls in-place ──────────────────────────
      // A single SQL UPDATE touches only JSON-sourced rows (exerciseDbId NOT
      // NULL) and rewrites their gifUrl to the canonical Supabase format.
      // Running before INSERT ensures even rows that survive insertOrIgnore
      // end up with the correct URL.
      await customStatement('''
        UPDATE exercises
        SET gif_url = '$_kGifBase/' || exercise_db_id || '.gif'
        WHERE exercise_db_id IS NOT NULL
      ''');
      debugPrint('[ExercisesDao] Phase 1: gifUrl patch applied.');

      // ── Phase 2: Insert exercises that don't exist yet ───────────────────
      final companions = list.map((e) {
        final id = e['id'] as String;
        return ExercisesCompanion.insert(
          exerciseDbId: Value(id),
          name: e['name'] as String,
          bodyPart: (e['bodyPart'] as String).toLowerCase(),
          equipment: (e['equipment'] as String).toLowerCase(),
          target: (e['target'] as String).toLowerCase(),
          gifUrl: Value('$_kGifBase/$id.gif'),
          secondaryMuscles: Value(jsonEncode(e['secondaryMuscles'])),
          instructions: Value(jsonEncode(e['instructions'])),
        );
      }).toList();

      const chunkSize = 100;
      for (int i = 0; i < companions.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, companions.length);
        await insertExercises(companions.sublist(i, end));
      }

      await prefs.setBool(_kHydrationKey, true);
      debugPrint(
          '[ExercisesDao] Hydration complete: ${companions.length} exercises.');
    } catch (e, st) {
      debugPrint('[ExercisesDao] hydrateFromJson failed: $e\n$st');
      await seedDefaultExercises();
    }
  }

  /// DEBUG UTILITY — call once from main.dart, then remove the call.
  ///
  /// Clears the hydration flag so [hydrateFromJson] re-runs on next launch.
  /// Does NOT delete any rows — existing workout history is fully preserved.
  /// The Phase-1 UPDATE in [hydrateFromJson] will patch stale gifUrls.
  Future<void> resetHydration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHydrationKey);
    // Also clear the old v1 key if it is present
    await prefs.remove('exercises_hydrated_v1');
    debugPrint(
        '[ExercisesDao] Hydration flag cleared — will re-run on next launch.');
  }

  // ── Default Seed (fallback only) ───────────────────────────────────────────

  /// Inserts 10 hardcoded exercises. Only called when JSON hydration fails.
  Future<void> seedDefaultExercises() async {
    final existing = await getAllExercises();
    if (existing.isNotEmpty) return;

    await insertExercises([
      ExercisesCompanion.insert(
          name: 'Barbell Bench Press',
          bodyPart: 'chest',
          equipment: 'barbell',
          target: 'pectorals'),
      ExercisesCompanion.insert(
          name: 'Barbell Squat',
          bodyPart: 'upper legs',
          equipment: 'barbell',
          target: 'quadriceps'),
      ExercisesCompanion.insert(
          name: 'Deadlift',
          bodyPart: 'back',
          equipment: 'barbell',
          target: 'spine'),
      ExercisesCompanion.insert(
          name: 'Pull-up',
          bodyPart: 'back',
          equipment: 'body weight',
          target: 'lats'),
      ExercisesCompanion.insert(
          name: 'Overhead Press',
          bodyPart: 'shoulders',
          equipment: 'barbell',
          target: 'delts'),
      ExercisesCompanion.insert(
          name: 'Dumbbell Lateral Raise',
          bodyPart: 'shoulders',
          equipment: 'dumbbell',
          target: 'delts'),
      ExercisesCompanion.insert(
          name: 'Tricep Pushdown',
          bodyPart: 'upper arms',
          equipment: 'cable',
          target: 'triceps'),
      ExercisesCompanion.insert(
          name: 'Bicep Curl',
          bodyPart: 'upper arms',
          equipment: 'dumbbell',
          target: 'biceps'),
      ExercisesCompanion.insert(
          name: 'Leg Press',
          bodyPart: 'upper legs',
          equipment: 'machine',
          target: 'quadriceps'),
      ExercisesCompanion.insert(
          name: 'Romanian Deadlift',
          bodyPart: 'upper legs',
          equipment: 'barbell',
          target: 'hamstrings'),
    ]);
  }
}
