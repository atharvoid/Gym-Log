import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env.dart';
import '../../exercises/exercise_naming.dart';
import '../database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

/// Bump this key whenever the JSON asset or URL format changes.
/// Incrementing forces all existing installs to re-run hydration on next launch.
/// v3: unified catalog (standard Hevy/Strong names + parent→child muscles),
/// upsert-by-exerciseDbId so existing rows are renamed/re-muscled in place and
/// GIF links are refreshed, with null gifUrl for exercises that have no GIF yet.
/// v4: improved import-name matching (rope/parallel-bars attachments stripped,
/// "Crossovers" plural, added "Iso-Lateral Row"). Re-runs hydration AND
/// reconcileCustomExercises so legacy "other"-tagged imports get merged into
/// the catalog on the next launch.
const _kHydrationKey = 'exercises_hydrated_v4';

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
  /// (no GIF), [isCustom] is set, and [createdBy] records the owner. Callers
  /// pass an inferred muscle split when one is available (see import service)
  /// so the exercise is never needlessly tagged "other".
  Future<int> createCustomExercise(
    String name, {
    required String userId,
    String bodyPart = 'other',
    String equipment = 'other',
    String target = 'other',
    String? secondaryMusclesJson,
  }) {
    return into(exercises).insert(ExercisesCompanion.insert(
      name: name,
      bodyPart: bodyPart,
      equipment: equipment,
      target: target,
      secondaryMuscles: Value(secondaryMusclesJson),
      isCustom: const Value(true),
      createdBy: Value(userId),
      seededAt: Value(DateTime.now()),
    ));
  }

  /// Reconciles user/import-created custom exercises against the canonical
  /// catalog. Runs once after hydration. For each custom exercise:
  ///
  ///   • If a catalog entry now represents the same movement (exact name,
  ///     movement+equipment, or an unambiguous movement match), the custom is
  ///     MERGED: its workout history is re-pointed to the catalog exercise and
  ///     the duplicate row is deleted. This removes the duplicates that earlier
  ///     imports created before the catalog used standard names.
  ///   • Otherwise, if the custom is still tagged "other", its muscle split is
  ///     back-filled from the same movement family in the catalog.
  ///
  /// Integer ids are only ever merged toward catalog rows, so foreign keys in
  /// workout_exercises / workout_sets stay valid throughout.
  Future<({int merged, int retagged})> reconcileCustomExercises() async {
    final customs =
        await (select(exercises)..where((t) => t.isCustom.equals(true))).get();
    if (customs.isEmpty) return (merged: 0, retagged: 0);

    final catalog =
        await (select(exercises)..where((t) => t.isCustom.equals(false))).get();

    final byExact = <String, int>{};
    final byMoveEquip = <String, int>{};
    final byMove = <String, List<int>>{};
    final hint = <String, Exercise>{};
    for (final e in catalog) {
      byExact.putIfAbsent(e.name.trim().toLowerCase(), () => e.id);
      final mk = ExerciseNaming.movementKey(e.name);
      if (mk.isEmpty) continue;
      byMoveEquip.putIfAbsent(
          '$mk|${ExerciseNaming.equipClassFromName(e.name)}', () => e.id);
      (byMove[mk] ??= <int>[]).add(e.id);
      hint.putIfAbsent(mk, () => e);
    }

    var merged = 0;
    var retagged = 0;
    await transaction(() async {
      for (final c in customs) {
        final mk = ExerciseNaming.movementKey(c.name);
        int? canonical = byExact[c.name.trim().toLowerCase()] ??
            byMoveEquip['$mk|${ExerciseNaming.equipClassFromName(c.name)}'];
        if (canonical == null && mk.isNotEmpty) {
          final list = byMove[mk];
          if (list != null && list.length == 1) canonical = list.first;
        }

        if (canonical != null && canonical != c.id) {
          // Merge: re-point history, then delete the duplicate custom row.
          await customUpdate(
            'UPDATE workout_exercises SET exercise_id = ? WHERE exercise_id = ?',
            variables: [Variable.withInt(canonical), Variable.withInt(c.id)],
            updates: {attachedDatabase.workoutExercises},
            updateKind: UpdateKind.update,
          );
          await customUpdate(
            'UPDATE workout_sets SET exercise_id = ? WHERE exercise_id = ?',
            variables: [Variable.withInt(canonical), Variable.withInt(c.id)],
            updates: {attachedDatabase.workoutSets},
            updateKind: UpdateKind.update,
          );
          await (delete(exercises)..where((t) => t.id.equals(c.id))).go();
          merged++;
        } else if (c.target.trim().toLowerCase() == 'other' ||
            c.target.trim().isEmpty) {
          final h = hint[mk];
          if (h != null) {
            await (update(exercises)..where((t) => t.id.equals(c.id))).write(
              ExercisesCompanion(
                bodyPart: Value(h.bodyPart),
                target: Value(h.target),
                secondaryMuscles: Value(h.secondaryMuscles),
              ),
            );
            retagged++;
          }
        }
      }
    });
    return (merged: merged, retagged: retagged);
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
      final root = jsonDecode(jsonString) as Map<String, dynamic>;
      final list = (root['exercises'] as List).cast<Map<String, dynamic>>();

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
          final hasGif = e['gif'] == true;
          final companion = ExercisesCompanion.insert(
            exerciseDbId: Value(id),
            name: e['name'] as String,
            bodyPart: e['bodyPart'] as String,
            equipment: e['equipment'] as String,
            target: e['target'] as String,
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

      // Merge any duplicate custom exercises that earlier imports created
      // before the catalog used standard names, and back-fill "other" muscles.
      final rec = await reconcileCustomExercises();
      if (rec.merged > 0 || rec.retagged > 0) {
        debugPrint('[ExercisesDao] Reconciled customs: '
            '${rec.merged} merged, ${rec.retagged} re-tagged.');
      }

      await prefs.setBool(_kHydrationKey, true);
      await prefs.remove('exercises_hydrated_v3');
      await prefs.remove('exercises_hydrated_v2');
      await prefs.remove('exercises_hydrated_v1');
      debugPrint(
          '[ExercisesDao] Hydration v4 complete: ${list.length} exercises.');
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
    await prefs.remove('exercises_hydrated_v3');
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
