import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/program_grouping.dart';
import 'package:gymlog/core/routines/program_membership.dart';

/// Grouping is a pure function, so these tests need no database.
void main() {
  final t0 = DateTime(2026, 1, 1, 9);

  ProgramRoutineRef ref({
    required String id,
    required String name,
    String? notes,
    String? sourceProgramName,
    int minutesOld = 0,
  }) =>
      ProgramRoutineRef(
        id: id,
        name: name,
        createdAt: t0.subtract(Duration(minutes: minutesOld)),
        notes: notes,
        sourceProgramName: sourceProgramName,
      );

  String meta({
    String slug = 'ppl-6day',
    String label = 'PPL 6d',
    required int order,
    int of = 6,
    String day = 'day',
  }) =>
      encodeProgramMembership(ProgramMembership(
        programSlug: slug,
        programLabel: label,
        orderIndex: order,
        totalRoutines: of,
        routineSlug: day,
      ));

  group('groupProgramRoutines', () {
    test('an empty library groups into nothing', () {
      final g = groupProgramRoutines([]);
      expect(g.programs, isEmpty);
      expect(g.standalone, isEmpty);
    });

    test('routines with no program stay standalone', () {
      final g = groupProgramRoutines([
        ref(id: '1', name: 'My Push Day'),
        ref(id: '2', name: 'Leg Burner'),
      ]);
      expect(g.programs, isEmpty);
      expect(g.standalone.map((r) => r.id), ['1', '2']);
    });

    test('members are returned in training-day order, not insert order', () {
      final g = groupProgramRoutines([
        ref(id: 'c', name: 'Legs A', notes: meta(order: 2, day: 'legs-a')),
        ref(id: 'a', name: 'Push A', notes: meta(order: 0, day: 'push-a')),
        ref(id: 'b', name: 'Pull A', notes: meta(order: 1, day: 'pull-a')),
      ]);
      expect(g.programs, hasLength(1));
      expect(g.programs.single.routines.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('a partial import knows how many days are missing', () {
      final g = groupProgramRoutines([
        ref(id: 'a', name: 'Push A', notes: meta(order: 0, day: 'push-a')),
        ref(id: 'b', name: 'Pull A', notes: meta(order: 1, day: 'pull-a')),
      ]);
      final p = g.programs.single;
      expect(p.importedCount, 2);
      expect(p.expectedRoutines, 6);
      expect(p.missingCount, 4);
      expect(p.isComplete, isFalse);
      expect(p.ownedRoutineSlugs, {'push-a', 'pull-a'});
    });

    test('a full import reports complete', () {
      final g = groupProgramRoutines([
        for (var i = 0; i < 6; i++)
          ref(id: '$i', name: 'Day $i', notes: meta(order: i, day: 'd$i')),
      ]);
      final p = g.programs.single;
      expect(p.importedCount, 6);
      expect(p.missingCount, 0);
      expect(p.isComplete, isTrue);
    });

    test('two different programs do not merge', () {
      final g = groupProgramRoutines([
        ref(id: 'a', name: 'Push A', notes: meta(slug: 'ppl', order: 0, of: 2)),
        ref(id: 'b', name: 'Pull A', notes: meta(slug: 'ppl', order: 1, of: 2)),
        ref(
          id: 'c',
          name: 'Upper A',
          notes: meta(slug: 'upper-lower', order: 0, of: 4),
        ),
      ]);
      expect(g.programs, hasLength(2));
      expect(
        g.programs.map((p) => p.key).toSet(),
        {'ppl', 'upper-lower'},
      );
    });

    test('legacy breadcrumb rows form a legacy group', () {
      final g = groupProgramRoutines([
        ref(
          id: 'a',
          name: 'Upper & Lower Body · Upper A',
          sourceProgramName: 'Upper & Lower Body',
        ),
        ref(
          id: 'b',
          name: 'Upper & Lower Body · Lower A',
          sourceProgramName: 'Upper & Lower Body',
        ),
      ]);
      final p = g.programs.single;
      expect(p.isLegacy, isTrue);
      expect(p.programSlug, isNull);
      expect(p.name, 'Upper & Lower Body');
      expect(p.importedCount, 2);
      expect(p.expectedRoutines, 2,
          reason: 'a legacy group cannot know about days it never recorded');
    });

    test('membership wins over a stale breadcrumb', () {
      final g = groupProgramRoutines([
        ref(
          id: 'a',
          name: 'Push A',
          notes: meta(slug: 'ppl-6day', order: 0),
          sourceProgramName: 'Push / Pull / Legs',
        ),
      ]);
      final p = g.programs.single;
      expect(p.isLegacy, isFalse);
      expect(p.key, 'ppl-6day');
      expect(p.name, 'Push / Pull / Legs',
          reason: 'the renameable breadcrumb is the display name');
    });

    test('falls back to the membership label when no breadcrumb exists', () {
      final g = groupProgramRoutines([
        ref(id: 'a', name: 'Push A', notes: meta(order: 0, label: 'PPL 6d')),
      ]);
      expect(g.programs.single.name, 'PPL 6d');
    });

    test('programs and standalone routines coexist', () {
      final g = groupProgramRoutines([
        ref(id: 'p1', name: 'Push A', notes: meta(order: 0, of: 2)),
        ref(id: 'p2', name: 'Pull A', notes: meta(order: 1, of: 2)),
        ref(id: 's1', name: 'Saturday Arms'),
      ]);
      expect(g.programs, hasLength(1));
      expect(g.programs.single.routines, hasLength(2));
      expect(g.standalone.map((r) => r.id), ['s1']);
    });

    test('newest program group sorts first', () {
      final g = groupProgramRoutines([
        ref(
          id: 'old',
          name: 'Old',
          notes: meta(slug: 'old-program', order: 0, of: 1),
          minutesOld: 500,
        ),
        ref(
          id: 'new',
          name: 'New',
          notes: meta(slug: 'new-program', order: 0, of: 1),
          minutesOld: 1,
        ),
      ]);
      expect(g.programs.map((p) => p.key), ['new-program', 'old-program']);
    });

    test('a whitespace-only breadcrumb does not create a phantom group', () {
      final g = groupProgramRoutines([
        ref(id: 'a', name: 'Solo', sourceProgramName: '   '),
      ]);
      expect(g.programs, isEmpty);
      expect(g.standalone, hasLength(1));
    });

    test('corrupt membership degrades to standalone, never crashes', () {
      final g = groupProgramRoutines([
        ref(id: 'a', name: 'Broken', notes: 'gymlog:program:v1 nonsense'),
      ]);
      expect(g.programs, isEmpty);
      expect(g.standalone, hasLength(1));
    });
  });

  group('quota inputs', () {
    test('a 6-day program counts as one program and zero standalone', () {
      final g = groupProgramRoutines([
        for (var i = 0; i < 6; i++)
          ref(id: '$i', name: 'Day $i', notes: meta(order: i, day: 'd$i')),
      ]);
      expect(g.programs.length, 1,
          reason: 'the old gate counted this as 6 and hit the paywall');
      expect(g.standalone.length, 0);
    });
  });
}
