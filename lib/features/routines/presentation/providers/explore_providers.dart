// [explore_providers.dart]
// State and actions for the routine-first Explore screen.
//
// Everything here exists to make one sentence true: a user browses ROUTINES,
// optionally zooms out to the PROGRAM a routine belongs to, and imports
// either one without being lied to about what it costs.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymlog/core/database/daos/program_grouping.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/premium/library_quota.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/domain/exercise_resolver.dart';
import 'package:gymlog/features/routines/presentation/data/catalog_integrity.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';

// ---------------------------------------------------------------------------
// Tabs
// ---------------------------------------------------------------------------

/// Explore has two shelves. Routines is the default because a routine is the
/// unit a user can actually do on a given day; a program is the commitment.
enum ExploreTab { routines, programs }

final exploreTabProvider =
    StateProvider<ExploreTab>((ref) => ExploreTab.routines);

// ---------------------------------------------------------------------------
// Equipment capability
// ---------------------------------------------------------------------------

/// Everything a user with [owned] equipment can actually perform.
///
/// This is the fix for the filter that hid content: equipment describes what
/// a routine REQUIRES, so owning more must never show less.
Set<ProgramEquipment> performableWith(ProgramEquipment owned) {
  switch (owned) {
    case ProgramEquipment.fullGym:
      return ProgramEquipment.values.toSet();
    case ProgramEquipment.dumbbellOnly:
      return {ProgramEquipment.dumbbellOnly, ProgramEquipment.bodyweight};
    case ProgramEquipment.bodyweight:
      return {ProgramEquipment.bodyweight};
  }
}

/// Whether a routine requiring [required] can be done with [owned].
bool canPerform({
  required ProgramEquipment owned,
  required ProgramEquipment required_,
}) =>
    performableWith(owned).contains(required_);

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// Active Explore filters. Empty sets mean "no constraint", never "nothing".
class ExploreFilters {
  const ExploreFilters({
    this.query = '',
    this.levels = const <TemplateLevel>{},
    this.equipment,
    this.durations = const <RoutineDuration>{},
    this.categories = const <String>{},
  });

  final String query;
  final Set<TemplateLevel> levels;

  /// What the user OWNS, not what a routine requires. Null means unfiltered.
  final ProgramEquipment? equipment;

  final Set<RoutineDuration> durations;
  final Set<String> categories;

  bool get isEmpty =>
      query.trim().isEmpty &&
      levels.isEmpty &&
      equipment == null &&
      durations.isEmpty &&
      categories.isEmpty;

  int get activeCount =>
      (query.trim().isEmpty ? 0 : 1) +
      (levels.isEmpty ? 0 : 1) +
      (equipment == null ? 0 : 1) +
      (durations.isEmpty ? 0 : 1) +
      (categories.isEmpty ? 0 : 1);

  ExploreFilters copyWith({
    String? query,
    Set<TemplateLevel>? levels,
    ProgramEquipment? equipment,
    bool clearEquipment = false,
    Set<RoutineDuration>? durations,
    Set<String>? categories,
  }) =>
      ExploreFilters(
        query: query ?? this.query,
        levels: levels ?? this.levels,
        equipment: clearEquipment ? null : (equipment ?? this.equipment),
        durations: durations ?? this.durations,
        categories: categories ?? this.categories,
      );
}

/// Applies [filters] to [routines]. Pure, so it is unit tested directly.
List<ExploreRoutine> applyExploreFilters(
  List<ExploreRoutine> routines,
  ExploreFilters filters,
) {
  final query = filters.query.trim();
  return [
    for (final r in routines)
      if (_matchesFilters(r, filters, query)) r,
  ];
}

bool _matchesFilters(
  ExploreRoutine r,
  ExploreFilters filters,
  String query,
) {
  if (query.isNotEmpty && !r.matches(query)) return false;

  if (filters.levels.isNotEmpty &&
      !r.levels.any(filters.levels.contains)) {
    return false;
  }

  final owned = filters.equipment;
  if (owned != null && !canPerform(owned: owned, required_: r.equipment)) {
    return false;
  }

  if (filters.durations.isNotEmpty &&
      !filters.durations.contains(r.duration)) {
    return false;
  }

  if (filters.categories.isNotEmpty &&
      !filters.categories.contains(r.category)) {
    return false;
  }

  return true;
}

final exploreFiltersProvider =
    StateProvider<ExploreFilters>((ref) => const ExploreFilters());

/// The routine shelf, filtered.
final filteredExploreRoutinesProvider = Provider<List<ExploreRoutine>>((ref) {
  final filters = ref.watch(exploreFiltersProvider);
  return applyExploreFilters(exploreRoutines, filters);
});

/// The program shelf, filtered by whether ANY of a program's routines match.
/// Filtering programs by their own averaged facts is what produced the
/// misleading "60 min" badge on a program spanning 45 to 80 minute days.
final filteredExploreProgramsProvider = Provider<List<RoutineTemplate>>((ref) {
  final matching = ref.watch(filteredExploreRoutinesProvider);
  final slugs = <String>{for (final r in matching) r.programSlug};
  return [
    for (final t in exploreTemplates)
      if (slugs.contains(programSlugFor(t))) t,
  ];
});

// ---------------------------------------------------------------------------
// Exercise resolution
// ---------------------------------------------------------------------------

/// The name index, built once per app run from the bundled catalog.
/// Replaces one LIKE query per template slot.
final exerciseResolverProvider = FutureProvider<ExerciseResolver>((ref) async {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authProvider);
  final rows = await db.exercisesDao.getAllExercises(userId: user?.id);

  List<String> decodeSecondary(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) return parsed.map((e) => e.toString()).toList();
    } catch (_) {
      // A malformed cache entry must not break Explore.
    }
    return const [];
  }

  return ExerciseResolver(
    [
      for (final e in rows)
        ResolvedExercise(
          id: e.id,
          name: e.name,
          target: e.target,
          secondaryMuscles: decodeSecondary(e.secondaryMuscles),
          equipment: e.equipment,
          bodyPart: e.bodyPart,
        ),
    ],
    aliases: kKnownDuplicateExerciseAliases,
  );
});

/// Muscle groups for ONE routine. The old screen could only produce this for
/// a whole program, which is why every muscle lit up.
final routineMuscleProfileProvider =
    Provider.family<MuscleProfile, String>((ref, routineSlug) {
  final resolver = ref.watch(exerciseResolverProvider).valueOrNull;
  final routine = exploreRoutineBySlug[routineSlug];
  if (resolver == null || routine == null) {
    return (primary: <String>{}, secondary: <String>{});
  }
  return resolver.muscleProfileFor(routine.exerciseNames);
});

// ---------------------------------------------------------------------------
// Library state
// ---------------------------------------------------------------------------

/// The user's library, split into programs and standalone routines.
final libraryGroupingProvider = StreamProvider<LibraryGrouping>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) {
    return Stream.value((
      programs: <ProgramGroup>[],
      standalone: <ProgramRoutineRef>[],
    ));
  }
  final db = ref.watch(databaseProvider);
  return db.routinesDao.watchLibraryGrouping(user.id);
});

/// Program slugs already imported, so Explore can say "Imported" and offer
/// the missing days instead of creating a duplicate.
final ownedProgramSlugsProvider = Provider<Set<String>>((ref) {
  final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
  if (grouping == null) return const <String>{};
  return {
    for (final g in grouping.programs)
      if (g.programSlug != null) g.programSlug!,
  };
});

/// Day slugs owned across every imported program.
final ownedRoutineSlugsProvider = Provider<Set<String>>((ref) {
  final grouping = ref.watch(libraryGroupingProvider).valueOrNull;
  if (grouping == null) return const <String>{};
  return {
    for (final g in grouping.programs) ...g.ownedRoutineSlugs,
  };
});

// ---------------------------------------------------------------------------
// Import
// ---------------------------------------------------------------------------

/// What an import would cost, computed before the user commits to it.
class ImportCost {
  const ImportCost({
    required this.verdict,
    required this.kind,
    required this.routineCount,
    required this.remainingRoutineSlots,
    required this.usesProgramSlot,
  });

  final ImportVerdict verdict;
  final ImportKind kind;
  final int routineCount;
  final int remainingRoutineSlots;
  final bool usesProgramSlot;

  bool get isAllowed => verdict.isAllowed;
  String? get blockedCopy => importBlockedCopy(verdict);
}

/// Result of a completed import.
class ImportResult {
  const ImportResult({
    required this.createdRoutineIds,
    required this.unresolvedExercises,
    this.blockedBy,
  });

  final List<String> createdRoutineIds;

  /// Catalog slots that matched no exercise. Surfaced rather than swallowed.
  final List<String> unresolvedExercises;

  /// Set when the quota refused the import; nothing was written.
  final ImportVerdict? blockedBy;

  bool get didImport => blockedBy == null && createdRoutineIds.isNotEmpty;
  int get routineCount => createdRoutineIds.length;
}

final exploreImportControllerProvider = Provider<ExploreImportController>(
  ExploreImportController.new,
);

class ExploreImportController {
  ExploreImportController(this._ref);

  final Ref _ref;

  /// What importing [routines] as [kind] would cost right now.
  Future<ImportCost> quoteImport({
    required ImportKind kind,
    required int routineCount,
  }) async {
    final isPremium = _ref.read(isPremiumProvider);
    final grouping = _ref.read(libraryGroupingProvider).valueOrNull;
    final programs = grouping?.programs.length ?? 0;
    final standalone = grouping?.standalone.length ?? 0;

    final verdict = evaluateImport(
      isPremium: isPremium,
      kind: kind,
      ownedProgramCount: programs,
      standaloneRoutineCount: standalone,
      routineCount: routineCount,
    );

    return ImportCost(
      verdict: verdict,
      kind: kind,
      routineCount: routineCount,
      remainingRoutineSlots: remainingStandaloneRoutineSlots(
        isPremium: isPremium,
        standaloneRoutineCount: standalone,
      ),
      usesProgramSlot: kind == ImportKind.program && !isPremium,
    );
  }

  /// Imports a single routine on its own.
  ///
  /// If the user already owns the routine's program, this counts as filling
  /// in a day they skipped -- always free, and it joins the existing group
  /// rather than starting a stray one.
  Future<ImportResult> importRoutine(ExploreRoutine routine) async {
    final user = _ref.read(authProvider);
    if (user == null) {
      return const ImportResult(
        createdRoutineIds: [],
        unresolvedExercises: [],
      );
    }

    final ownsProgram =
        _ref.read(ownedProgramSlugsProvider).contains(routine.programSlug);
    final kind = ownsProgram
        ? ImportKind.routineIntoOwnedProgram
        : ImportKind.standaloneRoutine;

    final cost = await quoteImport(kind: kind, routineCount: 1);
    if (!cost.isAllowed) {
      return ImportResult(
        createdRoutineIds: const [],
        unresolvedExercises: const [],
        blockedBy: cost.verdict,
      );
    }

    final resolver = await _ref.read(exerciseResolverProvider.future);
    final day = _dayFor(routine, resolver);
    final dao = _ref.read(databaseProvider).routinesDao;

    final ids = ownsProgram
        ? await dao.addRoutinesToProgram(
            userId: user.id,
            programSlug: routine.programSlug,
            programName: routine.programName,
            programLabel: routine.programLabel,
            days: [day],
            totalRoutines: routine.routinesInProgram,
            orderIndexes: [routine.dayIndex],
          )
        : await dao.createProgramImport(
            userId: user.id,
            programSlug: routine.programSlug,
            programName: routine.programName,
            programLabel: routine.programLabel,
            days: [day],
            totalRoutines: routine.routinesInProgram,
          );

    return ImportResult(
      createdRoutineIds: ids,
      unresolvedExercises: resolver.unresolvedNames(routine.exerciseNames),
    );
  }

  /// Imports a program, or the subset of its routines the user chose.
  Future<ImportResult> importProgram({
    required String programSlug,
    required List<ExploreRoutine> routines,
  }) async {
    final user = _ref.read(authProvider);
    if (user == null || routines.isEmpty) {
      return const ImportResult(
        createdRoutineIds: [],
        unresolvedExercises: [],
      );
    }

    final ownsProgram = _ref.read(ownedProgramSlugsProvider).contains(programSlug);
    final kind =
        ownsProgram ? ImportKind.routineIntoOwnedProgram : ImportKind.program;

    final cost = await quoteImport(kind: kind, routineCount: routines.length);
    if (!cost.isAllowed) {
      return ImportResult(
        createdRoutineIds: const [],
        unresolvedExercises: const [],
        blockedBy: cost.verdict,
      );
    }

    final resolver = await _ref.read(exerciseResolverProvider.future);
    final ordered = [...routines]
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    final days = [for (final r in ordered) _dayFor(r, resolver)];
    final first = ordered.first;
    final dao = _ref.read(databaseProvider).routinesDao;

    final ids = ownsProgram
        ? await dao.addRoutinesToProgram(
            userId: user.id,
            programSlug: programSlug,
            programName: first.programName,
            programLabel: first.programLabel,
            days: days,
            totalRoutines: first.routinesInProgram,
            orderIndexes: [for (final r in ordered) r.dayIndex],
          )
        : await dao.createProgramImport(
            userId: user.id,
            programSlug: programSlug,
            programName: first.programName,
            programLabel: first.programLabel,
            days: days,
            totalRoutines: first.routinesInProgram,
          );

    final allNames = <String>[
      for (final r in ordered) ...r.exerciseNames,
    ];
    return ImportResult(
      createdRoutineIds: ids,
      unresolvedExercises: resolver.unresolvedNames(allNames),
    );
  }

  /// Builds one importable day. Conditioning notes carry no exercise, and
  /// slots the catalog names but the library lacks are skipped rather than
  /// blocking the whole import.
  ProgramImportDay _dayFor(ExploreRoutine routine, ExerciseResolver resolver) {
    final exercises = <RoutineDraftExercise>[];
    for (final slot in routine.importableSlots) {
      final exercise = resolver.resolve(slot.name);
      if (exercise == null) continue;
      exercises.add(RoutineDraftExercise(
        exerciseId: exercise.id,
        defaultSets: slot.sets,
        defaultReps: _firstRepNumber(slot.reps),
      ));
    }
    return ProgramImportDay(
      routineSlug: routine.slug.split('/').last,
      name: routine.name,
      exercises: exercises,
    );
  }
}

/// Reps ship as display strings such as `8-12`, `AMRAP` or `30s`. Take the
/// first number when there is one; otherwise leave the target unset rather
/// than inventing a rep count.
int? _firstRepNumber(String reps) {
  final match = RegExp(r'\d+').firstMatch(reps);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}
