// [routine_index.dart]
// A FLAT, ROUTINE-FIRST VIEW OF THE EXPLORE CATALOG.
//
// The catalog in `explore_catalog.dart` is program-shaped: a [RoutineTemplate]
// is really a program, and a single training day exists only as a nested
// [ProgramDay] with no identity of its own. That is the root cause of the
// Explore screen being program-only -- there is nothing to link to, filter,
// search, preview or import at the routine level.
//
// This file derives that missing level WITHOUT duplicating any data. The
// catalog stays the single source of truth and the generator keeps owning
// slot names; everything here is a projection of it, built once into a
// top-level `final` rather than recomputed on every widget build.
//
// It is pure Dart over pure data: no database, no providers, no widgets, so
// it is fully unit testable and safe to call from a build method.

import 'package:gymlog/features/routines/domain/routine_naming.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';

/// Upper bound of the "quick" band, in minutes, inclusive.
const int kQuickSessionCeiling = 45;

/// Upper bound of the "standard" band, in minutes, inclusive.
const int kStandardSessionCeiling = 65;

/// Session-length band, used for the Explore duration filter.
///
/// The catalog only estimated duration per PROGRAM, averaged across its days,
/// which flattened a real 45..80 minute spread into one number. Filtering on
/// time is meaningless until the estimate is per routine.
enum RoutineDuration { quick, standard, long }

extension RoutineDurationX on RoutineDuration {
  String get label => switch (this) {
        RoutineDuration.quick => 'Up to 45 min',
        RoutineDuration.standard => '45\u201365 min',
        RoutineDuration.long => '65 min+',
      };

  /// Short form for a filter chip.
  String get chipLabel => switch (this) {
        RoutineDuration.quick => 'Quick',
        RoutineDuration.standard => 'Standard',
        RoutineDuration.long => 'Long',
      };
}

/// Band for an estimated session length.
RoutineDuration durationBandFor(int minutes) {
  if (minutes <= kQuickSessionCeiling) return RoutineDuration.quick;
  if (minutes <= kStandardSessionCeiling) return RoutineDuration.standard;
  return RoutineDuration.long;
}

String templateLevelLabel(TemplateLevel level) => switch (level) {
      TemplateLevel.beginner => 'Beginner',
      TemplateLevel.intermediate => 'Intermediate',
      TemplateLevel.advanced => 'Advanced',
    };

String equipmentLabelFor(ProgramEquipment equipment) => switch (equipment) {
      ProgramEquipment.fullGym => 'Full Gym',
      ProgramEquipment.dumbbellOnly => 'Dumbbell Only',
      ProgramEquipment.bodyweight => 'No Equipment',
    };

/// One importable training day, promoted to a first-class catalog entity.
class ExploreRoutine {
  ExploreRoutine({
    required this.slug,
    required this.programSlug,
    required this.programName,
    required this.programLabel,
    required this.name,
    required this.dayIndex,
    required this.routinesInProgram,
    required this.focus,
    required this.category,
    required this.levels,
    required this.equipment,
    required this.slots,
    required this.isFromFeaturedProgram,
  });

  /// Stable identity, `<programSlug>/<routineSlug>`. Safe as a deep-link
  /// segment and as a migration key: it must not change once shipped.
  final String slug;

  final String programSlug;

  /// Canonical catalog name of the parent program: the import/source key.
  final String programName;

  /// Short, catalog-unique label for the parent program, e.g. `PPL 6d`.
  final String programLabel;

  /// Clean routine name with generated scaffolding stripped: `Upper A`,
  /// never `Day 1 - Upper A` and never `Upper & Lower Body \u00b7 Upper A`.
  final String name;

  /// Zero-based position within the parent program.
  final int dayIndex;

  final int routinesInProgram;
  final String focus;
  final String category;
  final List<TemplateLevel> levels;
  final ProgramEquipment equipment;
  final List<TemplateSlot> slots;
  final bool isFromFeaturedProgram;

  int get dayNumber => dayIndex + 1;

  /// True when the parent program has exactly one day, so importing the
  /// routine and importing the program are the same action.
  bool get isWholeProgram => routinesInProgram == 1;

  /// Name to use when the routine is shown OUTSIDE its program group, where
  /// `Upper A` alone would be ambiguous.
  String get qualifiedName => routineDisplayName(
        dayLabel: name,
        programPrefix: programLabel,
        prefixWithProgram: true,
      );

  /// Slots that become tracked exercises on import. Conditioning notes are
  /// excluded here exactly as they are on import.
  late final List<TemplateSlot> importableSlots =
      slots.where((slot) => !slot.isConditioningNote).toList(growable: false);

  late final List<String> exerciseNames =
      importableSlots.map((slot) => slot.name).toList(growable: false);

  late final List<String> conditioningNotes = slots
      .where((slot) => slot.isConditioningNote)
      .map((slot) => slot.name)
      .toList(growable: false);

  int get exerciseCount => importableSlots.length;

  /// Every set in the session, including conditioning finishers, because they
  /// cost the user real time. Matches the program-level accounting.
  late final int totalSets =
      slots.fold(0, (running, slot) => running + slot.sets);

  /// Same formula as [RoutineTemplate.estMinutes] -- ~2.8 min per working set
  /// plus warm-up, rounded to 5 -- but applied to THIS day instead of the
  /// program average.
  late final int estMinutes = (((totalSets * 2.8) + 8) / 5).round() * 5;

  RoutineDuration get duration => durationBandFor(estMinutes);

  TemplateLevel get primaryLevel {
    if (levels.isEmpty) return TemplateLevel.beginner;
    return levels.reduce((a, b) => a.index < b.index ? a : b);
  }

  String get levelLabel =>
      levels.map(templateLevelLabel).toSet().join(' \u00b7 ');

  String get equipmentLabel => equipmentLabelFor(equipment);

  /// Precomputed, lowercased search tokens. Built once per routine so search
  /// never re-tokenizes 70 routines on every keystroke.
  late final Set<String> searchTerms = {
    ..._tokenize(name),
    ..._tokenize(focus),
    ..._tokenize(category),
    ..._tokenize(programName),
    ..._tokenize(programLabel),
    ..._tokenize(equipmentLabel),
    for (final level in levels) ..._tokenize(templateLevelLabel(level)),
    for (final exercise in exerciseNames) ..._tokenize(exercise),
  };

  /// Prefix match on every query token, so `pu leg` finds `Push \u00b7 Legs`.
  bool matches(String query) {
    final tokens = _tokenize(query).toList(growable: false);
    if (tokens.isEmpty) return true;
    return tokens.every(
      (token) => searchTerms.any((term) => term.startsWith(token)),
    );
  }

  @override
  String toString() => 'ExploreRoutine($slug)';
}

/// Stable slug for a catalog program. Program names are unique across the
/// catalog, including their equipment variant, so the name is a safe source.
String programSlugFor(RoutineTemplate template) => slugify(template.name);

/// Every importable routine in the catalog, in program then day order.
final List<ExploreRoutine> exploreRoutines = _buildExploreRoutines();

final Map<String, ExploreRoutine> exploreRoutineBySlug = {
  for (final routine in exploreRoutines) routine.slug: routine,
};

final Map<String, RoutineTemplate> exploreProgramBySlug = {
  for (final template in exploreTemplates) programSlugFor(template): template,
};

final Map<String, List<ExploreRoutine>> exploreRoutinesByProgramSlug = () {
  final grouped = <String, List<ExploreRoutine>>{};
  for (final routine in exploreRoutines) {
    grouped
        .putIfAbsent(routine.programSlug, () => <ExploreRoutine>[])
        .add(routine);
  }
  return grouped;
}();

/// Catalog-unique short label per program, keyed by canonical program name.
final Map<String, String> exploreProgramLabels = uniqueProgramShortNames(
  exploreTemplates.map((template) => template.name).toList(growable: false),
);

List<ExploreRoutine> routinesForProgram(String programSlug) =>
    exploreRoutinesByProgramSlug[programSlug] ?? const <ExploreRoutine>[];

/// Single filter entry point for the Explore Routines tab.
///
/// An empty set means "no constraint on this axis", so the default call
/// returns the whole catalog.
List<ExploreRoutine> filterExploreRoutines({
  String query = '',
  Set<TemplateLevel> levels = const {},
  Set<ProgramEquipment> equipment = const {},
  Set<RoutineDuration> durations = const {},
  Set<String> categories = const {},
  Iterable<ExploreRoutine>? within,
}) {
  final source = within ?? exploreRoutines;
  return source.where((routine) {
    if (levels.isNotEmpty && !routine.levels.any(levels.contains)) return false;
    if (equipment.isNotEmpty && !equipment.contains(routine.equipment)) {
      return false;
    }
    if (durations.isNotEmpty && !durations.contains(routine.duration)) {
      return false;
    }
    if (categories.isNotEmpty && !categories.contains(routine.category)) {
      return false;
    }
    return routine.matches(query);
  }).toList(growable: false);
}

/// Programs whose declared cadence disagrees with how many routines they
/// actually contain. Surfaced rather than silently corrected, because the
/// fix belongs in the source dataset, not at read time.
List<RoutineTemplate> programsWithCadenceMismatch() =>
    exploreTemplates.where((template) {
      final cadence = programCadence(template.name);
      return cadence != null && cadence != template.days.length;
    }).toList(growable: false);

List<ExploreRoutine> _buildExploreRoutines() {
  final labels = exploreProgramLabels;
  final routines = <ExploreRoutine>[];
  final usedSlugs = <String>{};

  for (final template in exploreTemplates) {
    final programSlug = programSlugFor(template);
    final names = dedupeRoutineNames(
      template.days
          .map((day) => cleanRoutineLabel(day.label))
          .toList(growable: false),
    );

    for (var index = 0; index < template.days.length; index++) {
      final day = template.days[index];
      final base =
          routineSlug(programSlug: programSlug, dayLabel: names[index]);

      var slug = base;
      var attempt = 2;
      while (!usedSlugs.add(slug)) {
        slug = '$base-$attempt';
        attempt++;
      }

      routines.add(
        ExploreRoutine(
          slug: slug,
          programSlug: programSlug,
          programName: template.name,
          programLabel: labels[template.name] ?? template.shortName,
          name: names[index],
          dayIndex: index,
          routinesInProgram: template.days.length,
          focus: day.focus,
          category: template.category,
          levels: template.levels,
          equipment: template.equipment,
          slots: day.slots,
          isFromFeaturedProgram: template.featured,
        ),
      );
    }
  }

  return List.unmodifiable(routines);
}

final RegExp _tokenSplit = RegExp(r'[^a-z0-9]+');

const Set<String> _stopWords = {
  'the',
  'and',
  'for',
  'with',
  'per',
  'week',
  'days',
  'day',
};

Iterable<String> _tokenize(String value) => value
    .toLowerCase()
    .split(_tokenSplit)
    .where((token) => token.length > 1 && !_stopWords.contains(token));
