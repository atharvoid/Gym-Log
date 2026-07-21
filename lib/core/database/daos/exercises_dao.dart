import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env.dart';
import '../../models/measurement_type.dart';
import '../database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

/// Bump this key whenever the JSON asset or URL format changes.
/// Incrementing forces all existing installs to re-run hydration on next launch.
/// v3: unified catalog (standard Hevy/Strong names + parent→child muscles),
/// upsert-by-exerciseDbId so existing rows are renamed/re-muscled in place and
/// GIF links are refreshed, with null gifUrl for exercises that have no GIF yet.
const _kHydrationKey = 'exercises_hydrated_v7';

/// Base URL of the public storage bucket that hosts exercise GIFs.
/// Centralized in [Env] (overridable via --dart-define GIF_BUCKET_BASE).
const _kGifBase = Env.gifBucketBase;

/// Top-level so it can run in a `compute()` isolate. Decodes the bundled
/// exercise catalog JSON into a list of plain maps (primitives only, so the
/// result is sendable back to the UI isolate).
List<Map<String, dynamic>> _decodeExerciseCatalog(String jsonString) {
  final root = jsonDecode(jsonString) as Map<String, dynamic>;
  return (root['exercises'] as List).cast<Map<String, dynamic>>();
}

@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  // ── Queries ────────────────────────────────────────────────────────────────

  Future<List<Exercise>> getAllExercises({String? userId}) {
    if (userId == null || userId.isEmpty) {
      return (select(exercises)..where((t) => t.isCustom.not())).get();
    }
    return (select(exercises)
          ..where((t) => t.isCustom.not() | t.createdBy.equals(userId)))
        .get();
  }

  Future<Exercise> getExerciseById(int id) =>
      (select(exercises)..where((t) => t.id.equals(id))).getSingle();

  Future<List<Exercise>> searchExercises(String query, {String? userId}) {
    // Neutralize LIKE wildcards — exercise names never contain % or _,
    // so treating them as plain separators keeps search predictable.
    final sanitized = query.replaceAll('%', ' ').replaceAll('_', ' ').trim();
    if (userId == null || userId.isEmpty) {
      return (select(exercises)
            ..where((t) => t.name.like('%$sanitized%') & t.isCustom.not())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();
    }
    return (select(exercises)
          ..where((t) =>
              t.name.like('%$sanitized%') &
              (t.isCustom.not() | t.createdBy.equals(userId)))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Case-insensitive exact-name existence check — guards the manual
  /// "Create custom exercise" flow against duplicating a catalog entry.
  Future<bool> exerciseNameExists(String name, {String? userId}) async {
    if (userId == null || userId.isEmpty) {
      final rows = await customSelect(
        'SELECT 1 FROM exercises WHERE LOWER(name) = LOWER(?) AND is_custom = 0 LIMIT 1',
        variables: [Variable.withString(name.trim())],
        readsFrom: {exercises},
      ).get();
      return rows.isNotEmpty;
    }
    final rows = await customSelect(
      'SELECT 1 FROM exercises WHERE LOWER(name) = LOWER(?) AND (is_custom = 0 OR created_by = ?) LIMIT 1',
      variables: [
        Variable.withString(name.trim()),
        Variable.withString(userId)
      ],
      readsFrom: {exercises},
    ).get();
    return rows.isNotEmpty;
  }

  Future<List<Exercise>> filterByBodyPart(String bodyPart, {String? userId}) {
    if (userId == null || userId.isEmpty) {
      return (select(exercises)
            ..where((t) => t.bodyPart.equals(bodyPart) & t.isCustom.not()))
          .get();
    }
    return (select(exercises)
          ..where((t) =>
              t.bodyPart.equals(bodyPart) &
              (t.isCustom.not() | t.createdBy.equals(userId))))
        .get();
  }

  Future<List<Exercise>> filterByEquipment(String equipment, {String? userId}) {
    if (userId == null || userId.isEmpty) {
      return (select(exercises)
            ..where((t) => t.equipment.equals(equipment) & t.isCustom.not()))
          .get();
    }
    return (select(exercises)
          ..where((t) =>
              t.equipment.equals(equipment) &
              (t.isCustom.not() | t.createdBy.equals(userId))))
        .get();
  }

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
    String? measurementType,
  }) {
    final resolvedType = measurementType ??
        MeasurementType.inferLegacyMeasurementType(
                equipment: equipment, exerciseName: name)
            .raw;
    return into(exercises).insert(ExercisesCompanion.insert(
      name: name,
      bodyPart: bodyPart,
      equipment: equipment,
      target: target,
      measurementType: Value(resolvedType),
      isCustom: const Value(true),
      createdBy: Value(userId),
      seededAt: Value(DateTime.now()),
    ));
  }

  // ── Hydration Engine ───────────────────────────────────────────────────────

  /// One-time bulk seed/refresh from the bundled `assets/db/exercises.json`.
  ///
  /// Upserts every catalog entry keyed by `exerciseDbId`: existing rows are
  /// updated in place (standard name, parent→child muscles, refreshed GIF)
  /// while their integer id — and therefore every workout FK — is preserved;
  /// missing rows are inserted. Entries without a GIF yet get a null gifUrl.
  /// User-created custom exercises (null exerciseDbId) are never touched.
  ///
  /// Guarded by a SharedPreferences key. Bump [_kHydrationKey] to force
  /// re-execution on all existing installs.
  Future<void> hydrateFromJson() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kHydrationKey) == true) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/db/exercises.json');
      // Parse the 822-entry catalog in a BACKGROUND isolate. jsonDecode of a
      // ~470 KB string blocks the UI isolate long enough to drop frames on a
      // first-launch scroll; compute() moves the parse off the main thread.
      // The result is plain maps of primitives — cheap to ship across the
      // isolate boundary. The Drift inserts below already run on Drift's own
      // background executor (NativeDatabase.createInBackground).
      final list = await compute(_decodeExerciseCatalog, jsonString);

      // Upsert keyed by exerciseDbId. Existing catalog rows are UPDATED in
      // place — renamed to the standard name, re-muscled, and GIF refreshed —
      // while their integer id is preserved, so every workout_exercises /
      // workout_sets foreign key stays valid. New exercises are inserted.
      // User-created custom exercises (exerciseDbId IS NULL) never collide and
      // are left untouched. gifUrl is null for exercises that have no GIF yet,
      // so the UI shows a clean fallback instead of a broken image.
      await transaction(() async {
        for (final e in list) {
          final id = e['id'] as String;
          final name = e['name'] as String;
          final hasGif = e['gif'] == true;
          final equipment = e['equipment'] as String;
          final rawMType = e['measurementType'] as String?;
          final mType = rawMType != null && rawMType.isNotEmpty
              ? MeasurementType.fromString(rawMType).raw
              : MeasurementType.inferLegacyMeasurementType(
                      equipment: equipment, exerciseName: name)
                  .raw;
          final companion = ExercisesCompanion.insert(
            exerciseDbId: Value(id),
            name: name,
            bodyPart: e['bodyPart'] as String,
            equipment: equipment,
            target: e['target'] as String,
            measurementType: Value(mType),
            secondaryMuscles:
                Value(jsonEncode(e['secondaryMuscles'] ?? const <String>[])),
            instructions:
                Value(jsonEncode(e['instructions'] ?? const <String>[])),
            gifUrl: hasGif ? Value('$_kGifBase/$id.gif') : const Value(null),
          );
          await into(exercises).insert(
            companion,
            onConflict: DoUpdate(
              (_) => companion,
              target: [exercises.exerciseDbId],
            ),
          );
        }
      });

      await prefs.setBool(_kHydrationKey, true);
      await prefs.remove('exercises_hydrated_v4');
      await prefs.remove('exercises_hydrated_v3');
      await prefs.remove('exercises_hydrated_v2');
      await prefs.remove('exercises_hydrated_v1');
      debugPrint(
          '[ExercisesDao] Hydration v5 complete: ${list.length} exercises.');
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
    // Also clear older keys if present
    await prefs.remove('exercises_hydrated_v2');
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
