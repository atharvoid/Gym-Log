import 'dart:io';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';
import '../models/measurement_type.dart';

/// Builds a versioned, metric-aware CSV export of every completed set logged by the user.
class WorkoutExportService {
  WorkoutExportService(this._db);

  final AppDatabase _db;

  static const csvHeader =
      'gymlog_schema_version,workout_id,workout_name,workout_started_at,'
      'workout_ended_at,workout_notes,exercise_id,exercise_name,'
      'measurement_type,set_index,set_type,weight_kg,reps,duration_seconds,'
      'distance_meters,rpe,is_pr,pr_type,estimated_1rm,completed_at';

  static const csvHeaderV1 =
      'date,workout,exercise,set_number,set_type,weight_kg,reps,rpe,is_pr,estimated_1rm';

  /// Builds the full version 2 CSV string for [userId] (completed sessions only),
  /// ordered chronologically, then by exercise order, then set order.
  Future<String> buildCsv(String userId) async {
    final s = _db.workoutSessions;
    final we = _db.workoutExercises;
    final ws = _db.workoutSets;
    final ex = _db.exercises;

    final rows = await (_db.select(ws).join([
      innerJoin(we, we.id.equalsExp(ws.workoutExerciseId)),
      innerJoin(s, s.id.equalsExp(we.sessionId)),
      innerJoin(ex, ex.id.equalsExp(ws.exerciseId)),
    ])
          ..where(s.userId.equals(userId) & s.endedAt.isNotNull())
          ..orderBy([
            OrderingTerm.asc(s.startedAt),
            OrderingTerm.asc(we.orderIndex),
            OrderingTerm.asc(ws.orderIndex),
          ]))
        .get();

    final buffer = StringBuffer()..writeln(csvHeader);

    for (final row in rows) {
      final session = row.readTable(s);
      final exercise = row.readTable(ex);
      final set = row.readTable(ws);

      final mType = MeasurementType.fromString(exercise.measurementType);

      final String weightKgStr;
      final String repsStr;
      final String durationStr;
      final String distanceStr;

      switch (mType) {
        case MeasurementType.weightAndReps:
          weightKgStr = set.weightKg != null ? formatNumber(set.weightKg!) : '';
          repsStr = set.reps > 0 ? '${set.reps}' : '';
          durationStr = '';
          distanceStr = '';
          break;
        case MeasurementType.repsOnly:
          weightKgStr = '';
          repsStr = set.reps > 0 ? '${set.reps}' : '';
          durationStr = '';
          distanceStr = '';
          break;
        case MeasurementType.duration:
          weightKgStr = '';
          repsStr = '';
          durationStr = set.reps > 0 ? '${set.reps}' : '';
          distanceStr = '';
          break;
        case MeasurementType.distance:
          weightKgStr = '';
          repsStr = '';
          durationStr = '';
          distanceStr = set.weightKg != null ? formatNumber(set.weightKg!) : '';
          break;
      }

      final String prTypeStr;
      if (!set.isPr) {
        prTypeStr = 'none';
      } else if (set.estimated1rm != null) {
        prTypeStr = 'estimated_1rm';
      } else {
        switch (mType) {
          case MeasurementType.repsOnly:
            prTypeStr = 'max_reps';
            break;
          case MeasurementType.duration:
            prTypeStr = 'max_duration';
            break;
          case MeasurementType.distance:
            prTypeStr = 'max_distance';
            break;
          case MeasurementType.weightAndReps:
            prTypeStr = 'max_weight';
            break;
        }
      }

      buffer.writeln([
        '2', // gymlog_schema_version
        session.id,
        escapeCsvField(session.name ?? 'Workout'),
        session.startedAt.toUtc().toIso8601String(),
        session.endedAt?.toUtc().toIso8601String() ?? '',
        escapeCsvField(session.notes),
        '${exercise.id}',
        escapeCsvField(exercise.name),
        mType.raw,
        '${set.orderIndex}',
        set.setType,
        weightKgStr,
        repsStr,
        durationStr,
        distanceStr,
        set.rpe == null ? '' : formatNumber(set.rpe!),
        set.isPr ? 'true' : 'false',
        prTypeStr,
        set.estimated1rm == null ? '' : formatNumber(set.estimated1rm!),
        set.completedAt?.toUtc().toIso8601String() ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Writes the CSV to a temp file ready for the platform share sheet.
  Future<File> writeCsvFile(String userId) async {
    final csv = await buildCsv(userId);
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(dir.path, 'gymlog_export_$stamp.csv'));
    return file.writeAsString(csv);
  }

  /// RFC-4180 field escaping: quote when the value contains a comma, quote,
  /// or newline; double any embedded quotes.
  static String escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// 82.5 → "82.5", 80.0 → "80" — no float noise in the export.
  static String formatNumber(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
