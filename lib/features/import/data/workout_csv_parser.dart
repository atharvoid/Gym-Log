import 'package:intl/intl.dart';

import '../domain/import_models.dart';
import 'csv_codec.dart';

/// Turns a Hevy or Strong CSV/TSV export into a list of [ParsedSession]s.
///
/// Reconciled against a real Hevy export and the canonical Strong schema:
///   • Hevy  — comma-delimited, fully quoted, unit baked into the header
///     name (`weight_kg` OR `weight_lbs`), explicit `set_type`, 0-based
///     `set_index`, dates like `30 Jun 2025, 19:56`.
///   • Strong — semicolon-delimited (comma on some exports), a separate
///     `Weight Unit` column (occasionally absent → must be assumed), warmups
///     flagged via `Set Order = "w"` or `Notes = "Warmup"`, dates like
///     `2025-06-30 19:56:00`.
///
/// Performed order is taken from row order within each exercise (the only
/// reliable signal across both apps), so [RawSet.orderIndex] is always a
/// contiguous 0-based sequence.
abstract final class WorkoutCsvParser {
  static const _kgPerLb = 0.45359237; // matches core/utils/units.dart

  // 'd' (not 'dd') so single-digit days like "5 Jun 2025" parse too.
  static final DateFormat _hevyDate = DateFormat('d MMM yyyy, HH:mm');
  static final DateFormat _strongDate = DateFormat('yyyy-MM-dd HH:mm:ss');

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
  static ImportParseResult parse(String text, {String assumedStrongUnit = 'kg'}) {
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
    final weightCol = hasKg ? 'weight_kg' : 'weight_lbs';
    final unit = hasKg ? 'kg' : 'lbs';

    final builder = _SessionBuilder();
    var skipped = 0;

    for (final r in rows) {
      String cell(String key) => _cell(r, idx, key);

      final title = cell('title');
      final startStr = cell('start_time');
      final exName = cell('exercise_title');
      if (startStr.isEmpty || exName.isEmpty) {
        skipped++;
        continue;
      }
      final start = _tryDate(_hevyDate, startStr);
      final reps = int.tryParse(cell('reps'));
      final weight = _num(cell(weightCol));
      if (start == null || reps == null || weight == null) {
        skipped++;
        continue;
      }

      final weightKg = unit == 'lbs' ? weight * _kgPerLb : weight;
      builder.add(
        sessionName: title.isEmpty ? 'Workout' : title,
        startedAt: start,
        endedAt: _tryDate(_hevyDate, cell('end_time')),
        sessionNotes: cell('description'),
        exerciseName: exName,
        exerciseNotes: cell('exercise_notes'),
        setType: _normalizeHevySetType(cell('set_type')),
        weightKg: weightKg,
        reps: reps,
        rpe: _num(cell('rpe')),
      );
    }

    return ImportParseResult(
      source: ImportSource.hevy,
      sessions: builder.sessions,
      warnings: [
        if (skipped > 0)
          '$skipped row${skipped == 1 ? '' : 's'} skipped (missing weight, reps, or date).',
      ],
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
    var skipped = 0;

    for (final r in rows) {
      String cell(String key) => _cell(r, idx, key);

      final wkName = cell('workout name');
      final dateStr = cell('date');
      final exName = cell('exercise name');
      if (dateStr.isEmpty || exName.isEmpty) {
        skipped++;
        continue;
      }
      final start = _tryStrongDate(dateStr);
      final reps = int.tryParse(cell('reps'));
      if (start == null || reps == null) {
        skipped++;
        continue;
      }

      final weight = _num(cell('weight')) ?? 0;
      final rowUnit = hasUnitCol ? _normUnit(cell('weight unit')) : assumedUnit;
      final weightKg = rowUnit == 'lbs' ? weight * _kgPerLb : weight;

      final setOrder = cell('set order').toLowerCase();
      final notes = cell('notes');
      final isWarmup = setOrder == 'w' || notes.trim().toLowerCase() == 'warmup';

      final duration = _parseDuration(cell('workout duration'));
      builder.add(
        sessionName: wkName.isEmpty ? 'Workout' : wkName,
        startedAt: start,
        endedAt: duration == null ? null : start.add(duration),
        sessionNotes: cell('workout notes'),
        exerciseName: exName,
        exerciseNotes: null, // Strong's per-set "Notes" isn't an exercise note
        setType: isWarmup ? SetTypes.warmup : SetTypes.normal,
        weightKg: weightKg,
        reps: reps,
        rpe: _num(cell('rpe')),
      );
    }

    return ImportParseResult(
      source: ImportSource.strong,
      sessions: builder.sessions,
      warnings: [
        if (!hasUnitCol)
          'No "Weight Unit" column — weights were read as '
              '${assumedUnit.toUpperCase()}.',
        if (skipped > 0)
          '$skipped row${skipped == 1 ? '' : 's'} skipped (missing reps or date).',
      ],
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

  /// Parses a number, tolerating a European decimal comma ("47,5" → 47.5)
  /// when there's no '.' present.
  static double? _num(String s) {
    var t = s.trim();
    if (t.isEmpty) return null;
    if (t.contains(',') && !t.contains('.')) t = t.replaceAll(',', '.');
    return double.tryParse(t);
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

  /// Parses Strong's workout-duration string: "62m", "1h 2m", "2h 38m",
  /// "56s", "1h". Returns null when nothing recognisable is present.
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

/// Accumulates rows into ordered sessions → exercises → sets, keyed by
/// (session name + start time) and then by exercise name. Insertion order is
/// preserved so the imported workout reads exactly like the source file.
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
    required double weightKg,
    required int reps,
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
      );
      session.exercises.add(e);
      return e;
    });

    ex.sets.add(RawSet(
      orderIndex: ex.sets.length, // contiguous performed order
      setType: setType,
      weightKg: weightKg,
      reps: reps,
      rpe: rpe,
    ));
  }
}
