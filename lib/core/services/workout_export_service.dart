import 'dart:io';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

/// Builds a CSV export of every completed set the user has ever logged.
///
/// One row per set — the most interoperable shape there is: it opens cleanly
/// in Sheets/Excel and mirrors the export format lifters already know from
/// Strong/Hevy. Free for everyone: it's the user's own training data, and a
/// local-first app should never hold it hostage.
class WorkoutExportService {
  WorkoutExportService(this._db);

  final AppDatabase _db;

  static const csvHeader = 'date,workout,exercise,set_number,set_type,'
      'weight_kg,reps,rpe,is_pr,estimated_1rm';

  /// Builds the full CSV string for [userId] (completed sessions only),
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

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final buffer = StringBuffer()..writeln(csvHeader);

    for (final row in rows) {
      final session = row.readTable(s);
      final exercise = row.readTable(ex);
      final set = row.readTable(ws);

      buffer.writeln([
        dateFormat.format(session.startedAt),
        escapeCsvField(session.name ?? 'Workout'),
        escapeCsvField(exercise.name),
        '${set.orderIndex + 1}', // stored 0-based, exported human 1-based
        set.setType,
        formatNumber(set.weightKg),
        '${set.reps}',
        set.rpe == null ? '' : formatNumber(set.rpe!),
        set.isPr ? 'true' : 'false',
        set.estimated1rm == null ? '' : formatNumber(set.estimated1rm!),
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
