// [program_grouping.dart]
// Program grouping for the routine library.
//
// A multi-day program is stored as N independent routines. This file is what
// makes them behave like one thing: it groups them, orders them, counts them
// for the free-tier gate, renames them, and deletes them together.
//
// It is an EXTENSION on RoutinesDao rather than an edit to it. The DAO is
// ~700 lines and every routine surface in the app depends on it; bolting the
// program model on from the outside keeps that blast radius at zero and lets
// the old import path keep working untouched while the new Explore screen
// moves over.
//
// The grouping itself ([groupProgramRoutines]) is a pure function over plain
// records, so it is unit-testable without spinning up SQLite.

import 'package:drift/drift.dart';

import '../../routines/program_membership.dart';
import '../database.dart';
import 'routines_dao.dart';

/// The minimum spacing between two imported routines' timestamps.
///
/// The library is ordered `createdAt DESC`. The old import loop wrote every
/// row inside the same millisecond, so SQLite returned them in an arbitrary
/// order that in practice came out reversed -- a 6-day program read Day 6
/// first. Spacing the stamps makes day order deterministic without changing
/// a single query.
const Duration kImportStampSpacing = Duration(milliseconds: 10);

/// A routine reduced to just the fields grouping cares about, so the grouping
/// logic never depends on Drift and can be tested as plain Dart.
class ProgramRoutineRef {
  const ProgramRoutineRef({
    required this.id,
    required this.name,
    required this.createdAt,
    this.notes,
    this.sourceProgramName,
  });

  factory ProgramRoutineRef.fromRoutine(Routine r) => ProgramRoutineRef(
        id: r.id,
        name: r.name,
        createdAt: r.createdAt,
        notes: r.notes,
        sourceProgramName: r.sourceProgramName,
      );

  final String id;
  final String name;
  final DateTime createdAt;
  final String? notes;
  final String? sourceProgramName;

  ProgramMembership? get membership => decodeProgramMembership(notes);
}

/// A set of routines the user imported together, presented as one unit.
class ProgramGroup {
  const ProgramGroup({
    required this.key,
    required this.name,
    required this.routines,
    required this.expectedRoutines,
    required this.isLegacy,
  });

  /// Stable grouping key. The program slug for adopted groups; a
  /// `legacy:<name>` sentinel for rows that predate membership metadata.
  final String key;

  /// Program name shown as the group heading. Renameable.
  final String name;

  /// Member routines, already in training-day order.
  final List<ProgramRoutineRef> routines;

  /// How many routines the source program shipped with. Drives
  /// "4 of 6 days imported".
  final int expectedRoutines;

  /// True when this group was inferred from the old `sourceProgramName`
  /// breadcrumb rather than a real membership record. Legacy groups cannot
  /// offer "add the missing days" because nothing records which days exist.
  final bool isLegacy;

  /// The program slug, or null for a legacy group.
  String? get programSlug => isLegacy ? null : key;

  int get importedCount => routines.length;

  int get missingCount {
    final missing = expectedRoutines - routines.length;
    return missing < 0 ? 0 : missing;
  }

  bool get isComplete => missingCount == 0;

  /// Day slugs the user already owns, for diffing against the catalog.
  Set<String> get ownedRoutineSlugs => {
        for (final r in routines)
          if (r.membership != null) r.membership!.routineSlug,
      };

  /// Newest member, used to sort groups in the library.
  DateTime get latestCreatedAt => routines
      .map((r) => r.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}

/// The library split into programs and loose routines.
typedef LibraryGrouping = ({
  List<ProgramGroup> programs,
  List<ProgramRoutineRef> standalone,
});

/// Finds a group by its key.
///
/// Deliberately a plain loop: `Iterable.firstOrNull` lives in
/// package:collection, and this file is intentionally dependency-free beyond
/// drift and its own siblings.
ProgramGroup? _groupByKey(LibraryGrouping grouping, String key) {
  for (final g in grouping.programs) {
    if (g.key == key) return g;
  }
  return null;
}

/// Groups a user's routines into programs plus standalone routines.
///
/// Three tiers, in order of trust:
///  1. a decodable membership record -> a real group, keyed by program slug
///  2. only the legacy `sourceProgramName` breadcrumb -> a legacy group
///  3. neither -> a standalone routine
///
/// Groups are ordered by their most recent member, and standalone routines
/// stay in the order they arrived. Pure: no database, no clock, no I/O.
LibraryGrouping groupProgramRoutines(List<ProgramRoutineRef> routines) {
  final byKey = <String, List<ProgramRoutineRef>>{};
  final legacyKeys = <String>{};
  final standalone = <ProgramRoutineRef>[];

  for (final r in routines) {
    final m = r.membership;
    if (m != null) {
      byKey.putIfAbsent(m.programSlug, () => []).add(r);
      continue;
    }
    final legacy = r.sourceProgramName;
    if (legacy != null && legacy.trim().isNotEmpty) {
      final key = 'legacy:${legacy.trim()}';
      legacyKeys.add(key);
      byKey.putIfAbsent(key, () => []).add(r);
      continue;
    }
    standalone.add(r);
  }

  final groups = <ProgramGroup>[];
  for (final entry in byKey.entries) {
    final isLegacy = legacyKeys.contains(entry.key);
    final members = sortByProgramOrder(entry.value, (r) => r.membership);

    // Expected size: the largest total any member claims, never smaller than
    // what we can actually see.
    var expected = members.length;
    for (final r in members) {
      final total = r.membership?.totalRoutines ?? 0;
      if (total > expected) expected = total;
    }

    groups.add(ProgramGroup(
      key: entry.key,
      name: _groupName(entry.key, members, isLegacy),
      routines: members,
      expectedRoutines: expected,
      isLegacy: isLegacy,
    ));
  }

  groups.sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));
  return (programs: groups, standalone: standalone);
}

/// Heading for a group. `sourceProgramName` wins because that is the column a
/// rename writes to; the membership label is the fallback for rows whose
/// breadcrumb was never set.
String _groupName(
  String key,
  List<ProgramRoutineRef> members,
  bool isLegacy,
) {
  if (isLegacy) return key.substring('legacy:'.length);
  for (final r in members) {
    final n = r.sourceProgramName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
  }
  for (final r in members) {
    final label = r.membership?.programLabel;
    if (label != null && label.trim().isNotEmpty) return label.trim();
  }
  return 'Program';
}

/// One training day being imported.
class ProgramImportDay {
  const ProgramImportDay({
    required this.routineSlug,
    required this.name,
    required this.exercises,
  });

  /// Stable slug within the program, e.g. `push-a`.
  final String routineSlug;

  /// Clean, standalone-readable name, e.g. `Push A` -- NOT
  /// `Push / Pull / Legs - Push A`.
  final String name;

  final List<RoutineDraftExercise> exercises;
}

extension ProgramGroupingDao on RoutinesDao {
  /// Every routine for a user, grouped into programs and loose routines.
  Future<LibraryGrouping> getLibraryGrouping(String userId) async {
    final rows = await getRoutinesForUser(userId);
    return groupProgramRoutines(
      [for (final r in rows) ProgramRoutineRef.fromRoutine(r)],
    );
  }

  /// Reactive version of [getLibraryGrouping].
  Stream<LibraryGrouping> watchLibraryGrouping(String userId) {
    return watchRoutinesForUser(userId).map(
      (rows) => groupProgramRoutines(
        [for (final r in rows) ProgramRoutineRef.fromRoutine(r)],
      ),
    );
  }

  /// Programs the user owns. Feeds the free-tier program slot.
  Future<int> countOwnedPrograms(String userId) async =>
      (await getLibraryGrouping(userId)).programs.length;

  /// Routines not attached to any program. Feeds the free-tier routine slots.
  Future<int> countStandaloneRoutines(String userId) async =>
      (await getLibraryGrouping(userId)).standalone.length;

  /// Slugs of programs the user already owns, so Explore can mark them
  /// "Imported" and offer the missing days instead of a duplicate import.
  Future<Set<String>> ownedProgramSlugs(String userId) async {
    final grouping = await getLibraryGrouping(userId);
    return {
      for (final g in grouping.programs)
        if (g.programSlug != null) g.programSlug!,
    };
  }

  /// Day slugs owned within one program.
  Future<Set<String>> ownedRoutineSlugsForProgram(
    String userId,
    String programSlug,
  ) async {
    final grouping = await getLibraryGrouping(userId);
    for (final g in grouping.programs) {
      if (g.programSlug == programSlug) return g.ownedRoutineSlugs;
    }
    return const <String>{};
  }

  /// Imports [days] as a program the user owns.
  ///
  /// Replaces `createRoutinesForProgram`, and fixes three things at once:
  /// day order, clean names, and durable grouping. Returns the new routine
  /// ids in day order.
  ///
  /// [totalRoutines] is the program's full size even when the user is only
  /// importing a subset, so the group can offer the days they skipped.
  Future<List<String>> createProgramImport({
    required String userId,
    required String programSlug,
    required String programName,
    required String programLabel,
    required List<ProgramImportDay> days,
    int? totalRoutines,
  }) async {
    assert(days.isNotEmpty, 'createProgramImport requires at least one day');
    final total = totalRoutines ?? days.length;

    // Ordering: the library sorts createdAt DESC, so Day 1 must carry the
    // LATEST stamp to appear first. Spacing the stamps keeps the whole
    // program contiguous and makes the order deterministic.
    final base = DateTime.now();
    final ids = <String>[];

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final id = await createRoutineWithDays(
        userId: userId,
        name: day.name,
        days: [RoutineDayDraft(name: day.name, exercises: day.exercises)],
        sourceProgramName: programName,
      );

      final membership = ProgramMembership(
        programSlug: programSlug,
        programLabel: programLabel,
        orderIndex: i,
        totalRoutines: total,
        routineSlug: day.routineSlug,
      );

      await (update(routines)..where((t) => t.id.equals(id))).write(
        RoutinesCompanion(
          notes: Value(withProgramMembership(null, membership)),
          createdAt: Value(base.subtract(kImportStampSpacing * i)),
        ),
      );

      // renameRoutine re-exports the row and enqueues the cloud upsert, so
      // the patched notes and timestamp are what actually syncs. Without
      // this the outbox would still hold the pre-patch snapshot.
      await renameRoutine(id, day.name);
      ids.add(id);
    }
    return ids;
  }

  /// Adds days the user skipped to a program they already own. Always free
  /// under the quota model -- completing your own program is not an upsell.
  Future<List<String>> addRoutinesToProgram({
    required String userId,
    required String programSlug,
    required String programName,
    required String programLabel,
    required List<ProgramImportDay> days,
    required int totalRoutines,
    required List<int> orderIndexes,
  }) async {
    assert(days.length == orderIndexes.length,
        'every day needs its position in the program');
    final base = DateTime.now();
    final ids = <String>[];

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final id = await createRoutineWithDays(
        userId: userId,
        name: day.name,
        days: [RoutineDayDraft(name: day.name, exercises: day.exercises)],
        sourceProgramName: programName,
      );

      final membership = ProgramMembership(
        programSlug: programSlug,
        programLabel: programLabel,
        orderIndex: orderIndexes[i],
        totalRoutines: totalRoutines,
        routineSlug: day.routineSlug,
      );

      await (update(routines)..where((t) => t.id.equals(id))).write(
        RoutinesCompanion(
          notes: Value(withProgramMembership(null, membership)),
          createdAt: Value(base.subtract(kImportStampSpacing * i)),
        ),
      );
      await renameRoutine(id, day.name);
      ids.add(id);
    }
    return ids;
  }

  /// Renames a program. Writes the breadcrumb on every member so the group
  /// heading changes as one.
  Future<void> renameProgram({
    required String userId,
    required String groupKey,
    required String newName,
  }) async {
    final grouping = await getLibraryGrouping(userId);
    final group = _groupByKey(grouping, groupKey);
    if (group == null) return;

    for (final r in group.routines) {
      await (update(routines)..where((t) => t.id.equals(r.id))).write(
        RoutinesCompanion(
          sourceProgramName: Value(newName),
          updatedAt: Value(DateTime.now()),
        ),
      );
      // Re-enqueue the cloud upsert with the new breadcrumb.
      await renameRoutine(r.id, r.name);
    }
  }

  /// Deletes a whole program and every routine in it. Workout history
  /// survives by design -- sessions reference exercises, not routines.
  Future<int> deleteProgram({
    required String userId,
    required String groupKey,
  }) async {
    final grouping = await getLibraryGrouping(userId);
    final group = _groupByKey(grouping, groupKey);
    if (group == null) return 0;
    for (final r in group.routines) {
      await deleteRoutine(r.id);
    }
    return group.routines.length;
  }

  /// Pulls one routine out of its program, leaving it standalone. The user's
  /// own notes survive.
  Future<void> detachRoutineFromProgram(String routineId) async {
    final row = await (select(routines)..where((t) => t.id.equals(routineId)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(routines)..where((t) => t.id.equals(routineId))).write(
      RoutinesCompanion(
        notes: Value(withoutProgramMembership(row.notes)),
        sourceProgramName: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await renameRoutine(routineId, row.name);
  }

  /// One-shot cleanup for routines imported before this release.
  ///
  /// Turns `Upper & Lower Body - Upper A` into `Upper A` and adopts the row
  /// into a real program group, keeping the original name in the membership
  /// record so the rename can be undone for 7 days.
  ///
  /// Idempotent: rows that already carry membership are skipped, so running
  /// it twice is a no-op. Returns how many routines were renamed.
  Future<int> migrateLegacyProgramNames({
    required String userId,
    required String Function(String programName, String routineName) cleanName,
    required String Function(String value) slugify,
  }) async {
    final grouping = await getLibraryGrouping(userId);
    var migrated = 0;

    for (final group in grouping.programs) {
      if (!group.isLegacy) continue;

      final programName = group.name;
      final programSlug = 'legacy-${slugify(programName)}';
      final ordered = [...group.routines]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (var i = 0; i < ordered.length; i++) {
        final r = ordered[i];
        if (r.membership != null) continue;

        final cleaned = cleanName(programName, r.name);
        final membership = ProgramMembership(
          programSlug: programSlug,
          programLabel: programName,
          orderIndex: i,
          totalRoutines: ordered.length,
          routineSlug: slugify(cleaned.isEmpty ? r.name : cleaned),
          // Always recorded, even when the name did not change, so undo
          // restores the exact original string in every case.
          importedAs: r.name,
        );

        await (update(routines)..where((t) => t.id.equals(r.id))).write(
          RoutinesCompanion(
            name: Value(cleaned.isEmpty ? r.name : cleaned),
            notes: Value(withProgramMembership(r.notes, membership)),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await renameRoutine(r.id, cleaned.isEmpty ? r.name : cleaned);
        if (cleaned.isNotEmpty && cleaned != r.name) migrated++;
      }
    }
    return migrated;
  }

  /// Restores every name the cleanup migration changed, and clears the undo
  /// record so the banner cannot fire twice. Returns how many were restored.
  Future<int> undoLegacyProgramNameMigration(String userId) async {
    final grouping = await getLibraryGrouping(userId);
    var restored = 0;

    for (final group in grouping.programs) {
      for (final r in group.routines) {
        final m = r.membership;
        if (m == null || !m.wasMigrated) continue;
        final original = m.importedAs!;

        await (update(routines)..where((t) => t.id.equals(r.id))).write(
          RoutinesCompanion(
            name: Value(original),
            notes: Value(
              withProgramMembership(r.notes, m.copyWith(clearImportedAs: true)),
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await renameRoutine(r.id, original);
        restored++;
      }
    }
    return restored;
  }

  /// Whether any routine still carries an undoable rename.
  Future<bool> hasUndoableRename(String userId) async {
    final grouping = await getLibraryGrouping(userId);
    for (final g in grouping.programs) {
      for (final r in g.routines) {
        if (r.membership?.wasMigrated ?? false) return true;
      }
    }
    return false;
  }

  /// Drops the undo records once the window has closed, so the original
  /// names stop taking up room in every synced payload.
  Future<void> clearRenameUndoHistory(String userId) async {
    final grouping = await getLibraryGrouping(userId);
    for (final g in grouping.programs) {
      for (final r in g.routines) {
        final m = r.membership;
        if (m == null || !m.wasMigrated) continue;
        await (update(routines)..where((t) => t.id.equals(r.id))).write(
          RoutinesCompanion(
            notes: Value(
              withProgramMembership(r.notes, m.copyWith(clearImportedAs: true)),
            ),
          ),
        );
      }
    }
  }
}
