/// Pure-Dart domain models for the workout CSV import feature.
///
/// No Flutter or Drift imports — everything here is trivially unit-testable
/// and safe to run off the UI isolate. [WorkoutCsvParser] produces these;
/// [WorkoutImportService] maps them onto the local database.
library;

/// Which competitor app a CSV was exported from.
enum ImportSource {
  hevy('Hevy'),
  strong('Strong');

  const ImportSource(this.label);

  /// Human-facing name, e.g. shown in the preview ("Detected: Hevy").
  final String label;
}

/// Thrown when a file can't be recognised or parsed. The [message] is written
/// to be shown directly to the user.
class ImportException implements Exception {
  ImportException(this.message);
  final String message;

  @override
  String toString() => 'ImportException: $message';
}

/// Canonical GymLog set-type strings (mirrors the `workout_sets.setType`
/// column, which defaults to `normal`).
abstract final class SetTypes {
  static const normal = 'normal';
  static const warmup = 'warmup';
  static const dropset = 'dropset';
  static const failure = 'failure';
}

/// A single logged set, already normalised to GymLog conventions: weight in
/// kilograms and a contiguous 0-based [orderIndex] reflecting performed order.
class RawSet {
  const RawSet({
    required this.orderIndex,
    required this.setType,
    required this.weightKg,
    required this.reps,
    this.rpe,
  });

  final int orderIndex; // 0-based, contiguous within the exercise
  final String setType; // normal | warmup | dropset | failure
  final double weightKg; // always kilograms
  final int reps;
  final double? rpe;

  double get volumeKg => weightKg * reps;
}

/// One exercise within a session, preserving the order it appeared in the file.
class ParsedExercise {
  ParsedExercise({required this.name, this.notes, List<RawSet>? sets})
      : sets = sets ?? <RawSet>[];

  final String name;
  final String? notes;
  final List<RawSet> sets;
}

/// A full workout session reconstructed from the file.
class ParsedSession {
  ParsedSession({
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.notes = '',
    List<ParsedExercise>? exercises,
  }) : exercises = exercises ?? <ParsedExercise>[];

  final String name;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String notes;
  final List<ParsedExercise> exercises;

  int get setCount => exercises.fold(0, (sum, e) => sum + e.sets.length);

  double get totalVolumeKg => exercises.fold(
        0.0,
        (sum, e) => sum + e.sets.fold(0.0, (s, x) => s + x.volumeKg),
      );
}

/// Raw output of [WorkoutCsvParser.parse] — sessions plus any soft warnings.
class ImportParseResult {
  ImportParseResult({
    required this.source,
    required this.sessions,
    this.warnings = const [],
    this.weightUnitAssumed = false,
    this.assumedUnit = 'kg',
    this.skippedRows = 0,
  });

  final ImportSource source;
  final List<ParsedSession> sessions;
  final List<String> warnings;

  /// True when the file carried no unit information (e.g. some Strong exports
  /// drop the "Weight Unit" column) and a unit had to be assumed. The UI shows
  /// a unit toggle in that case.
  final bool weightUnitAssumed;
  final String assumedUnit; // 'kg' | 'lbs'
  final int skippedRows;
}

/// Dry-run preview, shown before anything is written to the database.
class ImportSummary {
  const ImportSummary({
    required this.source,
    required this.sessionCount,
    required this.duplicateCount,
    required this.setCount,
    required this.exerciseCount,
    required this.totalVolumeKg,
    required this.firstDate,
    required this.lastDate,
    required this.newExerciseNames,
    required this.warnings,
    required this.weightUnitAssumed,
    required this.assumedUnit,
  });

  final ImportSource source;
  final int sessionCount; // total sessions found in the file
  final int duplicateCount; // already present locally → will be skipped
  final int setCount;
  final int exerciseCount; // distinct exercises in the file
  final double totalVolumeKg;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Names with no catalog match — these become custom exercises on import.
  final List<String> newExerciseNames;
  final List<String> warnings;
  final bool weightUnitAssumed;
  final String assumedUnit;

  int get newSessionCount => sessionCount - duplicateCount;
  bool get hasAnythingToImport => newSessionCount > 0;
}

/// Result returned after a completed import.
class ImportResult {
  const ImportResult({
    required this.source,
    required this.sessionsImported,
    required this.sessionsSkipped,
    required this.setsImported,
    required this.exercisesMatched,
    required this.exercisesCreated,
    required this.prsDetected,
    required this.warnings,
  });

  final ImportSource source;
  final int sessionsImported;
  final int sessionsSkipped; // duplicates not re-imported
  final int setsImported;
  final int exercisesMatched; // resolved to an existing catalog exercise
  final List<String> exercisesCreated; // newly added custom exercises
  final int prsDetected;
  final List<String> warnings;
}

/// Stable key used to detect a session that's already been imported:
/// minute-resolution start time + lower-cased name. Re-importing the same
/// export is therefore idempotent, and in-file duplicates collapse too.
String importDedupKey(DateTime startedAt, String? name) =>
    '${startedAt.millisecondsSinceEpoch ~/ 60000}'
    '|${(name ?? '').trim().toLowerCase()}';
