import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../domain/import_models.dart';
import 'exercise_matcher.dart';
import 'workout_csv_parser.dart';

/// Top-level helper function for compute() isolate execution.
ImportParseResult _parseCsvIsolate((String, String) args) {
  return WorkoutCsvParser.parse(args.$1, assumedStrongUnit: args.$2);
}

/// Orchestrates a Hevy/Strong CSV import end-to-end:
///   parse → resolve exercises (matching catalog, creating customs) → dedup →
///   persist each session in a transaction → run PR detection oldest-first.
///
/// All weights are stored in kilograms (the parser already converts), so the
/// user's display-unit preference is never touched. Imports are idempotent:
/// re-importing the same file skips sessions that already exist.
class WorkoutImportService {
  WorkoutImportService(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Dry run: parse the file and report what an import WOULD do, without
  /// writing anything. Throws [ImportException] for empty/unrecognised files.
  Future<ImportSummary> preview(
    String text, {
    required String userId,
    String assumedStrongUnit = 'kg',
  }) async {
    final parsed = await compute(
      _parseCsvIsolate,
      (text, assumedStrongUnit),
    );

    final matcher = await _buildMatcher();
    final distinctNames = _distinctExerciseNames(parsed.sessions);
    final newNames =
        distinctNames.where((n) => matcher.match(n) == null).toList();

    final existingKeys = await _existingSessionKeys(userId);
    var duplicates = 0;
    DateTime? first;
    DateTime? last;
    var sets = 0;
    var volume = 0.0;
    for (final s in parsed.sessions) {
      if (existingKeys.contains(importDedupKey(s.startedAt, s.name))) {
        duplicates++;
      }
      sets += s.setCount;
      volume += s.totalVolumeKg;
      if (first == null || s.startedAt.isBefore(first)) first = s.startedAt;
      if (last == null || s.startedAt.isAfter(last)) last = s.startedAt;
    }

    return ImportSummary(
      source: parsed.source,
      sessionCount: parsed.sessions.length,
      duplicateCount: duplicates,
      setCount: sets,
      exerciseCount: distinctNames.length,
      totalVolumeKg: volume,
      firstDate: first,
      lastDate: last,
      newExerciseNames: newNames,
      warnings: parsed.warnings,
      weightUnitAssumed: parsed.weightUnitAssumed,
      assumedUnit: parsed.assumedUnit,
    );
  }

  /// Performs the import. [onProgress] is called as each session is processed.
  Future<ImportResult> import(
    String text, {
    required String userId,
    String assumedStrongUnit = 'kg',
    void Function(int done, int total)? onProgress,
  }) async {
    final parsed = await compute(
      _parseCsvIsolate,
      (text, assumedStrongUnit),
    );

    // 1) Resolve every distinct exercise name to a catalog id, creating
    //    custom exercises (once each) for anything unmatched.
    final matcher = await _buildMatcher();
    final resolved = <String, int>{}; // lower-cased name → exercise id
    final created = <String>[];
    var matched = 0;

    Future<int> resolve(String name) async {
      final key = name.trim().toLowerCase();
      final cached = resolved[key];
      if (cached != null) return cached;
      final hit = matcher.match(name);
      if (hit != null) {
        resolved[key] = hit;
        matched++;
        return hit;
      }
      final id = await _db.exercisesDao.createCustomExercise(
        name.trim(),
        userId: userId,
        equipment: _equipmentFromName(name),
      );
      resolved[key] = id;
      created.add(name.trim());
      return id;
    }

    // 2) Dedup set, seeded from existing sessions and grown as we go so
    //    in-file duplicates also collapse.
    final seenKeys = await _existingSessionKeys(userId);

    // Oldest-first so PR detection attributes records correctly.
    final ordered = [...parsed.sessions]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    var imported = 0;
    var skipped = 0;
    var setsImported = 0;
    var prs = 0;
    final total = ordered.length;
    var done = 0;

    for (final s in ordered) {
      final key = importDedupKey(s.startedAt, s.name);
      if (seenKeys.contains(key)) {
        skipped++;
        onProgress?.call(++done, total);
        continue;
      }
      seenKeys.add(key);

      // Resolve ids up front (may create custom exercises outside the txn).
      final exerciseIds = <int>[];
      for (final e in s.exercises) {
        exerciseIds.add(await resolve(e.name));
      }

      final sessionId = _uuid.v4();
      var volume = 0.0;

      await _db.transaction(() async {
        await _db.into(_db.workoutSessions).insert(
              WorkoutSessionsCompanion.insert(
                id: Value(sessionId),
                userId: userId,
                name: Value(s.name),
                startedAt: s.startedAt,
                // endedAt must be non-null for the session to count as
                // "completed"; fall back to startedAt when unknown.
                endedAt: Value(s.endedAt ?? s.startedAt),
                notes: Value(s.notes),
                synced: const Value(false),
              ),
            );

        for (var ei = 0; ei < s.exercises.length; ei++) {
          final e = s.exercises[ei];
          final weId = _uuid.v4();
          await _db.into(_db.workoutExercises).insert(
                WorkoutExercisesCompanion.insert(
                  id: Value(weId),
                  sessionId: sessionId,
                  exerciseId: exerciseIds[ei],
                  orderIndex: ei,
                  notes: Value(e.notes),
                ),
              );
          for (final st in e.sets) {
            volume += st.volumeKg;
            setsImported++;
            await _db.into(_db.workoutSets).insert(
                  WorkoutSetsCompanion.insert(
                    id: Value(_uuid.v4()),
                    workoutExerciseId: weId,
                    exerciseId: exerciseIds[ei],
                    orderIndex: st.orderIndex,
                    setType: Value(st.setType),
                    weightKg: Value(st.weightKg),
                    reps: st.reps,
                    rpe: Value(st.rpe),
                    completedAt: Value(s.endedAt ?? s.startedAt),
                  ),
                );
          }
        }

        await (_db.update(_db.workoutSessions)
              ..where((t) => t.id.equals(sessionId)))
            .write(WorkoutSessionsCompanion(totalVolumeKg: Value(volume)));
      });

      // PR detection runs after the session is committed; earlier (older)
      // sessions are already persisted, so historical bests are correct.
      final found =
          await _db.workoutsDao.detectAndMarkPrs(sessionId, s.startedAt);
      prs += found.length;

      imported++;
      onProgress?.call(++done, total);
    }

    return ImportResult(
      source: parsed.source,
      sessionsImported: imported,
      sessionsSkipped: skipped,
      setsImported: setsImported,
      exercisesMatched: matched,
      exercisesCreated: created,
      prsDetected: prs,
      warnings: parsed.warnings,
    );
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  Future<ExerciseMatcher> _buildMatcher() async {
    final library = await _db.exercisesDao.getAllExercises();
    return ExerciseMatcher(library.map((e) => ExerciseRef(e.id, e.name)));
  }

  Future<Set<String>> _existingSessionKeys(String userId) async {
    final existing = await _db.workoutsDao.getSessionsForUser(userId);
    return existing.map((s) => importDedupKey(s.startedAt, s.name)).toSet();
  }

  static List<String> _distinctExerciseNames(List<ParsedSession> sessions) {
    final seen = <String>{};
    final names = <String>[];
    for (final s in sessions) {
      for (final e in s.exercises) {
        if (seen.add(e.name.trim().toLowerCase())) names.add(e.name.trim());
      }
    }
    return names;
  }

  /// Pulls a trailing "(Equipment)" qualifier off the name for a tidier custom
  /// exercise row, e.g. "Zercher Squat (Barbell)" → equipment "barbell".
  static String _equipmentFromName(String name) {
    final m = RegExp(r'\(([^)]*)\)\s*$').firstMatch(name.trim());
    final e = m?.group(1)?.trim().toLowerCase();
    return (e == null || e.isEmpty) ? 'other' : e;
  }
}
