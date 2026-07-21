import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/models/measurement_type.dart';
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

    final matcher = await _buildMatcher(userId);
    final (validatedSessions, warnings) =
        await _resolveAndValidateSessions(parsed, matcher);

    final distinctNames = _distinctExerciseNames(validatedSessions);
    final newNames =
        distinctNames.where((n) => matcher.match(n) == null).toList();

    final existingKeys = await _existingSessionKeys(userId);
    var duplicates = 0;
    DateTime? first;
    DateTime? last;
    var sets = 0;
    var volume = 0.0;
    for (final s in validatedSessions) {
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
      sessionCount: validatedSessions.length,
      duplicateCount: duplicates,
      setCount: sets,
      exerciseCount: distinctNames.length,
      totalVolumeKg: volume,
      firstDate: first,
      lastDate: last,
      newExerciseNames: newNames,
      warnings: warnings,
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

    final matcher = await _buildMatcher(userId);
    final (validatedSessions, warnings) =
        await _resolveAndValidateSessions(parsed, matcher);

    // 1) Resolve every distinct exercise name to a catalog id, creating
    //    custom exercises (once each) for anything unmatched.
    final resolved = <String, int>{}; // lower-cased name → exercise id
    final created = <String>[];
    var matched = 0;

    Future<int> resolve(String name, MeasurementType mType) async {
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
        measurementType: mType.raw,
      );
      resolved[key] = id;
      created.add(name.trim());
      return id;
    }

    // 2) Dedup set, seeded from existing sessions and grown as we go so
    //    in-file duplicates also collapse.
    final seenKeys = await _existingSessionKeys(userId);

    // Oldest-first so PR detection attributes records correctly.
    final ordered = [...validatedSessions]
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
        exerciseIds.add(await resolve(
            e.name, e.measurementType ?? MeasurementType.weightAndReps));
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
                    reps: st.reps ?? 0,
                    rpe: Value(st.rpe),
                    isPr: Value(st.isPr),
                    estimated1rm: Value(st.estimated1rm),
                    completedAt:
                        Value(st.completedAt ?? s.endedAt ?? s.startedAt),
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
      warnings: warnings,
    );
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  Future<(List<ParsedSession>, List<String>)> _resolveAndValidateSessions(
    ImportParseResult parsed,
    ExerciseMatcher matcher,
  ) async {
    final validatedSessions = <ParsedSession>[];
    final warnings = [...parsed.warnings];

    for (final s in parsed.sessions) {
      final validExercises = <ParsedExercise>[];
      for (final ex in s.exercises) {
        final matchedRef = matcher.matchRef(ex.name);

        // Resolve MeasurementType:
        MeasurementType? mType;
        // 1. Explicit CSV measurement_type
        for (final st in ex.sets) {
          if (st.measurementType != null) {
            mType = st.measurementType;
            break;
          }
        }
        // 2. Canonical matched exercise metadata
        if (mType == null &&
            matchedRef != null &&
            matchedRef.measurementType != null) {
          mType = MeasurementType.fromString(matchedRef.measurementType);
        }
        // 3. Imported column shape or legacy classifier
        mType ??= ex.measurementType ??
            (ex.sets.isNotEmpty ? ex.sets.first.measurementType : null) ??
            MeasurementType.weightAndReps;

        final validSets = <ImportedSet>[];
        for (final st in ex.sets) {
          double? finalWeight = st.weightKg;
          int? finalReps = st.reps;
          int? finalDuration = st.durationSeconds;
          double? finalDistance = st.distanceMeters;

          String? error;
          switch (mType) {
            case MeasurementType.weightAndReps:
              if (finalWeight == null || finalWeight < 0) {
                error = 'weight is missing for ${ex.name}.';
              } else if (finalReps == null || finalReps <= 0) {
                error = 'reps are missing for ${ex.name}.';
              }
              break;
            case MeasurementType.repsOnly:
              if (finalReps == null || finalReps <= 0) {
                error = 'reps are missing for ${ex.name}.';
              }
              finalWeight = null; // weight must remain null
              break;
            case MeasurementType.duration:
              if (finalDuration == null || finalDuration <= 0) {
                error = 'duration is missing for ${ex.name}.';
              }
              break;
            case MeasurementType.distance:
              if (finalDistance == null || finalDistance <= 0) {
                error = 'distance is missing for ${ex.name}.';
              }
              break;
          }

          if (error != null) {
            warnings.add('Row ${st.csvRowNum} skipped: $error');
          } else {
            validSets.add(ImportedSet(
              orderIndex: validSets.length,
              setType: st.setType,
              csvRowNum: st.csvRowNum,
              weightKg: finalWeight,
              reps: finalReps,
              durationSeconds: finalDuration,
              distanceMeters: finalDistance,
              measurementType: mType,
              rpe: st.rpe,
              isPr: st.isPr,
              prType: st.prType,
              estimated1rm: st.estimated1rm,
              completedAt: st.completedAt,
            ));
          }
        }

        if (validSets.isNotEmpty) {
          validExercises.add(ParsedExercise(
            name: ex.name,
            notes: ex.notes,
            measurementType: mType,
            sets: validSets,
          ));
        }
      }

      if (validExercises.isNotEmpty) {
        validatedSessions.add(ParsedSession(
          name: s.name,
          startedAt: s.startedAt,
          endedAt: s.endedAt,
          notes: s.notes,
          exercises: validExercises,
        ));
      }
    }

    return (validatedSessions, warnings);
  }

  Future<ExerciseMatcher> _buildMatcher(String userId) async {
    final library = await _db.exercisesDao.getAllExercises(userId: userId);
    return ExerciseMatcher(
      library.map((e) => ExerciseRef(
            e.id,
            e.name,
            measurementType: e.measurementType,
            equipment: e.equipment,
          )),
    );
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
