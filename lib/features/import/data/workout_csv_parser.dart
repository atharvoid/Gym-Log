import 'package:intl/intl.dart';

import '../../../core/models/measurement_type.dart';
import '../domain/import_models.dart';
import 'csv_codec.dart';
import 'exercise_matcher.dart';

/// Turns a Hevy or Strong CSV/TSV export into a list of [ParsedSession]s.
abstract final class WorkoutCsvParser {
  static const _kgPerLb = 0.45359237; // matches core/utils/units.dart

  // 'd' (not 'dd') so single-digit days like "5 Jun 2025" parse too.
  static final DateFormat _hevyDate = DateFormat('d MMM yyyy, HH:mm');
  static final DateFormat _strongDate = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Metric-aware, locale-flexible decimal parser supporting commas, dots, and non-breaking spaces.
  static double? parseFlexibleDecimal(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;

    value = value.replaceAll('\u00A0', '').replaceAll(' ', '');

    final hasComma = value.contains(',');
    final hasDot = value.contains('.');

    if (hasComma && !hasDot) {
      value = value.replaceAll(',', '.');
    } else if (hasComma && hasDot) {
      final lastComma = value.lastIndexOf(',');
      final lastDot = value.lastIndexOf('.');

      if (lastComma > lastDot) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    }

    final parsed = double.tryParse(value);
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  /// Identifies the source app from the header cells, or null if unknown.
  static ImportSource? detectSource(List<String> header) {
    final h = header.map((c) => c.trim().toLowerCase()).toSet();
    if (h.contains('exercise_title') && h.contains('set_index')) {
      return ImportSource.hevy;
    }
    if (h.contains('exercise name') && h.contains('set order')) {
      return ImportSource.strong;
    }
    return null;
  }

  /// Parses [text]. [assumedStrongUnit] ('kg' | 'lbs') is used only when a
  /// Strong file omits its "Weight Unit" column. Throws [ImportException] on
  /// an empty or unrecognised file.
  static ImportParseResult parse(String text,
      {String assumedStrongUnit = 'kg'}) {
    if (text.trim().isEmpty) {
      throw ImportException('The file is empty.');
    }
    final delimiter = CsvCodec.detectDelimiter(text);
    final rows = CsvCodec.parse(text, delimiter: delimiter);
    if (rows.isEmpty) {
      throw ImportException('No rows were found in the file.');
    }

    final header = rows.first.map((c) => c.trim()).toList();
    final source = detectSource(header);
    if (source == null) {
      throw ImportException(
        "This doesn't look like a Hevy or Strong export. Open the app's "
        'export and choose the workout CSV, then try again.',
      );
    }

    final dataRows = rows.skip(1).toList();
    return source == ImportSource.hevy
        ? _parseHevy(header, dataRows)
        : _parseStrong(header, dataRows, _normUnit(assumedStrongUnit));
  }

  // ── Hevy ───────────────────────────────────────────────────────────────────

  static ImportParseResult _parseHevy(
      List<String> header, List<List<String>> rows) {
    final idx = _indexMap(header);
    final hasKg = idx.containsKey('weight_kg');
    final weightCol = hasKg
        ? 'weight_kg'
        : (idx.containsKey('weight_lbs') ? 'weight_lbs' : null);
    final unit = hasKg ? 'kg' : 'lbs';

    final builder = _SessionBuilder();
    final warnings = <String>[];
    var skipped = 0;

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowNum = i + 2; // Line 1 is header
      String cell(String key) => _cell(r, idx, key);

      final title = cell('title');
      final startStr = cell('start_time');
      final exName = cell('exercise_title');
      if (startStr.isEmpty || exName.isEmpty) {
        warnings.add('Row $rowNum skipped: date or exercise name is missing.');
        skipped++;
        continue;
      }
      final start = _tryDate(_hevyDate, startStr);
      if (start == null) {
        warnings.add('Row $rowNum skipped: date or exercise name is missing.');
        skipped++;
        continue;
      }

      final rawWeight =
          weightCol != null ? parseFlexibleDecimal(cell(weightCol)) : null;
      final bool rawWeightPresent =
          weightCol != null && cell(weightCol).trim().isNotEmpty;
      final weightKg = (rawWeight == null || rawWeight < 0)
          ? null
          : (unit == 'lbs' ? rawWeight * _kgPerLb : rawWeight);

      final repsRaw = parseFlexibleDecimal(cell('reps'));
      final bool rawRepsPresent = cell('reps').trim().isNotEmpty;
      final reps = (repsRaw == null || repsRaw <= 0) ? null : repsRaw.toInt();

      final distRaw = parseFlexibleDecimal(cell('distance_km'));
      final distanceMeters =
          (distRaw == null || distRaw <= 0) ? null : distRaw * 1000.0;

      final durRaw = parseFlexibleDecimal(cell('duration_seconds'));
      final durationSeconds =
          (durRaw == null || durRaw <= 0) ? null : durRaw.toInt();

      final explicitTypeStr = cell('measurement_type');
      MeasurementType? explicitType;
      if (explicitTypeStr.isNotEmpty) {
        try {
          explicitType = MeasurementType.fromString(explicitTypeStr);
        } catch (_) {}
      }

      final inferredMType = explicitType ??
          _inferMeasurementType(
            exerciseName: exName,
            weightKg: weightKg,
            reps: reps,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
          );

      final validationError = _validateRowMetrics(
        mType: inferredMType,
        weightKg: weightKg,
        reps: reps,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        rawWeightPresent: rawWeightPresent,
        rawRepsPresent: rawRepsPresent,
        exerciseName: exName,
      );

      if (validationError != null) {
        warnings.add('Row $rowNum skipped: $validationError');
        skipped++;
        continue;
      }

      final finalWeightKg =
          (inferredMType == MeasurementType.repsOnly) ? null : weightKg;

      builder.add(
        sessionName: title.isEmpty ? 'Workout' : title,
        startedAt: start,
        endedAt: _tryDate(_hevyDate, cell('end_time')),
        sessionNotes: cell('description'),
        exerciseName: exName,
        exerciseNotes: cell('exercise_notes'),
        setType: _normalizeHevySetType(cell('set_type')),
        csvRowNum: rowNum,
        weightKg: finalWeightKg,
        reps: reps,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        measurementType: inferredMType,
        rpe: parseFlexibleDecimal(cell('rpe')),
      );
    }

    return ImportParseResult(
      source: ImportSource.hevy,
      sessions: builder.sessions,
      warnings: warnings,
      weightUnitAssumed: false,
      assumedUnit: unit,
      skippedRows: skipped,
    );
  }

  // ── Strong ───────────────────────────────────────────────────────────────────

  static ImportParseResult _parseStrong(
      List<String> header, List<List<String>> rows, String assumedUnit) {
    final idx = _indexMap(header);
    final hasUnitCol = idx.containsKey('weight unit');

    final builder = _SessionBuilder();
    final warnings = <String>[];
    if (!hasUnitCol) {
      warnings.add('No "Weight Unit" column — weights were read as '
          '${assumedUnit.toUpperCase()}.');
    }
    var skipped = 0;

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowNum = i + 2;
      String cell(String key) => _cell(r, idx, key);

      final wkName = cell('workout name');
      final dateStr = cell('date');
      final exName = cell('exercise name');
      if (dateStr.isEmpty || exName.isEmpty) {
        warnings.add('Row $rowNum skipped: date or exercise name is missing.');
        skipped++;
        continue;
      }
      final start = _tryStrongDate(dateStr);
      if (start == null) {
        warnings.add('Row $rowNum skipped: date or exercise name is missing.');
        skipped++;
        continue;
      }

      final rawWeight = parseFlexibleDecimal(cell('weight'));
      final bool rawWeightPresent = cell('weight').trim().isNotEmpty;
      final rowUnit = hasUnitCol ? _normUnit(cell('weight unit')) : assumedUnit;
      final weightKg = (rawWeight == null || rawWeight < 0)
          ? null
          : (rowUnit == 'lbs' ? rawWeight * _kgPerLb : rawWeight);

      final repsRaw = parseFlexibleDecimal(cell('reps'));
      final bool rawRepsPresent = cell('reps').trim().isNotEmpty;
      final reps = (repsRaw == null || repsRaw <= 0) ? null : repsRaw.toInt();

      final secondsRaw = parseFlexibleDecimal(cell('seconds'));
      final durationSeconds =
          (secondsRaw == null || secondsRaw <= 0) ? null : secondsRaw.toInt();

      final distRaw = parseFlexibleDecimal(cell('distance'));
      final distUnit = cell('distance unit').trim().toLowerCase();
      final double? distanceMeters;
      if (distRaw == null || distRaw <= 0) {
        distanceMeters = null;
      } else if (distUnit.startsWith('km')) {
        distanceMeters = distRaw * 1000.0;
      } else if (distUnit.startsWith('mi')) {
        distanceMeters = distRaw * 1609.344;
      } else {
        distanceMeters = distRaw * 1.0;
      }

      final explicitTypeStr = cell('measurement_type');
      MeasurementType? explicitType;
      if (explicitTypeStr.isNotEmpty) {
        try {
          explicitType = MeasurementType.fromString(explicitTypeStr);
        } catch (_) {}
      }

      final inferredMType = explicitType ??
          _inferMeasurementType(
            exerciseName: exName,
            weightKg: weightKg,
            reps: reps,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
          );

      final validationError = _validateRowMetrics(
        mType: inferredMType,
        weightKg: weightKg,
        reps: reps,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        rawWeightPresent: rawWeightPresent,
        rawRepsPresent: rawRepsPresent,
        exerciseName: exName,
      );

      if (validationError != null) {
        warnings.add('Row $rowNum skipped: $validationError');
        skipped++;
        continue;
      }

      final setOrder = cell('set order').toLowerCase();
      final notes = cell('notes');
      final isWarmup =
          setOrder == 'w' || notes.trim().toLowerCase() == 'warmup';

      final duration = _parseDuration(cell('workout duration'));
      final finalWeightKg =
          (inferredMType == MeasurementType.repsOnly) ? null : weightKg;

      builder.add(
        sessionName: wkName.isEmpty ? 'Workout' : wkName,
        startedAt: start,
        endedAt: duration == null ? null : start.add(duration),
        sessionNotes: cell('workout notes'),
        exerciseName: exName,
        exerciseNotes: null,
        setType: isWarmup ? SetTypes.warmup : SetTypes.normal,
        csvRowNum: rowNum,
        weightKg: finalWeightKg,
        reps: reps,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        measurementType: inferredMType,
        rpe: parseFlexibleDecimal(cell('rpe')),
      );
    }

    return ImportParseResult(
      source: ImportSource.strong,
      sessions: builder.sessions,
      warnings: warnings,
      weightUnitAssumed: !hasUnitCol,
      assumedUnit: assumedUnit,
      skippedRows: skipped,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, int> _indexMap(List<String> header) {
    final m = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final k = header[i].trim().toLowerCase();
      m.putIfAbsent(k, () => i);
    }
    return m;
  }

  static String _cell(List<String> row, Map<String, int> idx, String key) {
    final i = idx[key];
    if (i == null || i >= row.length) return '';
    return row[i].trim();
  }

  static MeasurementType? _inferMeasurementType({
    required String exerciseName,
    required double? weightKg,
    required int? reps,
    required int? durationSeconds,
    required double? distanceMeters,
  }) {
    if (distanceMeters != null) {
      return MeasurementType.distance;
    }
    if (durationSeconds != null && reps == null && weightKg == null) {
      return MeasurementType.duration;
    }
    if (weightKg != null && reps != null) {
      return MeasurementType.weightAndReps;
    }
    final legacyInferred = MeasurementType.inferLegacyMeasurementType(
      exerciseName: exerciseName,
      equipment: ExerciseMatcher.equipFromName(exerciseName),
    );
    if (legacyInferred == MeasurementType.repsOnly && reps != null) {
      return MeasurementType.repsOnly;
    }
    if (reps != null && weightKg == null) {
      return MeasurementType.repsOnly;
    }
    return legacyInferred;
  }

  static String? _validateRowMetrics({
    required MeasurementType? mType,
    required double? weightKg,
    required int? reps,
    required int? durationSeconds,
    required double? distanceMeters,
    required bool rawWeightPresent,
    required bool rawRepsPresent,
    required String exerciseName,
  }) {
    if (mType == null) {
      return 'metrics are missing for $exerciseName.';
    }

    switch (mType) {
      case MeasurementType.weightAndReps:
        if (!rawWeightPresent || weightKg == null || weightKg < 0) {
          return 'weight is missing for $exerciseName.';
        }
        if (!rawRepsPresent || reps == null || reps <= 0) {
          return 'reps are missing for $exerciseName.';
        }
        return null;

      case MeasurementType.repsOnly:
        if (!rawRepsPresent || reps == null || reps <= 0) {
          return 'reps are missing for $exerciseName.';
        }
        return null;

      case MeasurementType.duration:
        if (durationSeconds == null || durationSeconds <= 0) {
          return 'duration is missing for $exerciseName.';
        }
        return null;

      case MeasurementType.distance:
        if (distanceMeters == null || distanceMeters <= 0) {
          return 'distance is missing for $exerciseName.';
        }
        return null;
    }
  }

  static String _normUnit(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('lb') ? 'lbs' : 'kg';
  }

  static String _normalizeHevySetType(String s) {
    switch (s.trim().toLowerCase()) {
      case 'warmup':
      case 'warm up':
      case 'warm-up':
        return SetTypes.warmup;
      case 'drop':
      case 'drop_set':
      case 'dropset':
        return SetTypes.dropset;
      case 'failure':
        return SetTypes.failure;
      default:
        return SetTypes.normal;
    }
  }

  static DateTime? _tryDate(DateFormat fmt, String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return fmt.parse(t);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _tryStrongDate(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t) ?? _tryDate(_strongDate, t);
  }

  static Duration? _parseDuration(String s) {
    final t = s.trim().toLowerCase();
    if (t.isEmpty) return null;
    int grab(String suffix) {
      final m = RegExp(r'(\d+)\s*' + suffix).firstMatch(t);
      return m == null ? 0 : int.parse(m.group(1)!);
    }

    final h = grab('h');
    final min = grab('m');
    final sec = grab('s');
    if (h == 0 && min == 0 && sec == 0) return null;
    return Duration(hours: h, minutes: min, seconds: sec);
  }
}

class _SessionBuilder {
  final List<ParsedSession> sessions = [];
  final Map<String, ParsedSession> _sessionByKey = {};
  final Map<String, Map<String, ParsedExercise>> _exByKey = {};

  void add({
    required String sessionName,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String sessionNotes,
    required String exerciseName,
    required String? exerciseNotes,
    required String setType,
    int csvRowNum = 0,
    required double? weightKg,
    required int? reps,
    int? durationSeconds,
    double? distanceMeters,
    MeasurementType? measurementType,
    required double? rpe,
  }) {
    final key = '$sessionName|${startedAt.millisecondsSinceEpoch}';
    final session = _sessionByKey.putIfAbsent(key, () {
      final s = ParsedSession(
        name: sessionName,
        startedAt: startedAt,
        endedAt: endedAt,
        notes: sessionNotes,
      );
      sessions.add(s);
      return s;
    });

    final exMap = _exByKey.putIfAbsent(key, () => <String, ParsedExercise>{});
    final ex = exMap.putIfAbsent(exerciseName, () {
      final e = ParsedExercise(
        name: exerciseName,
        notes: (exerciseNotes == null || exerciseNotes.isEmpty)
            ? null
            : exerciseNotes,
        measurementType: measurementType,
      );
      session.exercises.add(e);
      return e;
    });

    ex.sets.add(ImportedSet(
      orderIndex: ex.sets.length,
      setType: setType,
      csvRowNum: csvRowNum,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      measurementType: measurementType,
      rpe: rpe,
    ));
  }
}
