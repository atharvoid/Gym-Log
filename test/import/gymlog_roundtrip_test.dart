import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/import/domain/import_models.dart';
import 'package:gymlog/features/import/data/workout_csv_parser.dart';

void main() {
  // Mirrors WorkoutExportService.csvHeader so export → import round-trips
  // losslessly (date, ended_at, workout, workout_notes, …).
  const gymlogCsv = 'date,ended_at,workout,workout_notes,exercise,set_number,'
      'set_type,weight_kg,reps,rpe,is_pr,estimated_1rm\n'
      '2026-01-15 08:30,2026-01-15 09:15,Push Day,Felt strong,'
      'Bench Press (Barbell),1,warmup,40,10,,false,\n'
      '2026-01-15 08:30,2026-01-15 09:15,Push Day,Felt strong,'
      'Bench Press (Barbell),2,normal,60,8,8,true,75\n'
      '2026-01-15 08:30,2026-01-15 09:15,Push Day,Felt strong,'
      'Triceps Pushdown (Cable),1,normal,25,15,,false,';

  test('detects and parses GymLog\'s own export losslessly', () {
    final r = WorkoutCsvParser.parse(gymlogCsv);
    expect(r.source, ImportSource.gymlog);
    expect(r.sessions.length, 1);

    final s = r.sessions.single;
    expect(s.name, 'Push Day');
    expect(s.notes, 'Felt strong'); // workout notes survive
    expect(s.endedAt, isNotNull); // session end time survives
    expect(s.endedAt!.difference(s.startedAt), const Duration(minutes: 45));
    expect(s.exercises.length, 2);
    expect(s.setCount, 3);
    expect(s.totalVolumeKg, closeTo(40 * 10 + 60 * 8 + 25 * 15, 0.01));

    final bench = s.exercises.first;
    expect(bench.name, 'Bench Press (Barbell)');
    expect(bench.sets.first.setType, SetTypes.warmup);
    expect(bench.sets[1].rpe, 8);
  });
}
