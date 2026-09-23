// [catalog_integrity.dart]
// Equipment-consistency checks over the Explore catalog.
//
// `explore_catalog_integrity_test` already proves every slot name resolves to
// a real Exercise Library entry. That is a NAMING guarantee, not a PHYSICAL
// one: a name can be perfectly valid and still be impossible to perform with
// the equipment its program advertises.
//
// This file closes that gap. It is pure Dart over the typed catalog, so it
// runs in a unit test with no database and no widget tree.
//
// It deliberately REPORTS rather than repairs. Rewriting a slot at read time
// would change somebody's program behind their back, and the real fix belongs
// upstream in `tool/data/gym_routines_database.json` plus a regenerate.

import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';

/// Equipment implied by an Exercise Library name.
///
/// [unspecified] is the honest default: most bodyweight movements carry no
/// marker at all ('Push Up', 'Towel Row', 'Air Squat'), so an absent marker
/// can never be treated as a violation.
enum SlotEquipment {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  unspecified,
}

/// Reads the equipment marker out of a canonical exercise name.
///
/// Parenthetical suffixes win over prefixes, because the library uses the
/// suffix as its formal qualifier: 'Bench Press (Dumbbell)'.
SlotEquipment slotEquipmentFor(String slotName) {
  final name = slotName.toLowerCase();

  if (name.contains('(barbell)')) return SlotEquipment.barbell;
  if (name.contains('(dumbbell)')) return SlotEquipment.dumbbell;
  if (name.contains('(machine)')) return SlotEquipment.machine;
  if (name.contains('(cable')) return SlotEquipment.cable;
  if (name.contains('(bodyweight)')) return SlotEquipment.bodyweight;

  if (name.startsWith('dumbbell ')) return SlotEquipment.dumbbell;
  if (name.startsWith('barbell ')) return SlotEquipment.barbell;
  if (name.startsWith('cable ')) return SlotEquipment.cable;

  return SlotEquipment.unspecified;
}

/// What a program's advertised equipment actually permits.
Set<SlotEquipment> allowedSlotEquipment(ProgramEquipment equipment) =>
    switch (equipment) {
      ProgramEquipment.fullGym => SlotEquipment.values.toSet(),
      ProgramEquipment.dumbbellOnly => const {
          SlotEquipment.dumbbell,
          SlotEquipment.bodyweight,
          SlotEquipment.unspecified,
        },
      ProgramEquipment.bodyweight => const {
          SlotEquipment.bodyweight,
          SlotEquipment.unspecified,
        },
    };

/// One slot a user cannot actually perform with the equipment they filtered
/// for.
class CatalogEquipmentIssue {
  const CatalogEquipmentIssue({
    required this.routineSlug,
    required this.programName,
    required this.routineName,
    required this.exerciseName,
    required this.programEquipment,
    required this.slotEquipment,
  });

  final String routineSlug;
  final String programName;
  final String routineName;
  final String exerciseName;
  final ProgramEquipment programEquipment;
  final SlotEquipment slotEquipment;

  /// Stable identity used to pin known violations in tests.
  String get key => '$routineSlug | $exerciseName';

  @override
  String toString() =>
      '${equipmentLabelFor(programEquipment)} program "$programName" '
      'routine "$routineName" requires $exerciseName '
      '(${slotEquipment.name})';
}

/// Every importable slot whose equipment exceeds what its program promises.
///
/// Conditioning notes are skipped: they are never imported as tracked
/// exercises and are already presented as optional text.
List<CatalogEquipmentIssue> catalogEquipmentIssues() {
  final issues = <CatalogEquipmentIssue>[];

  for (final routine in exploreRoutines) {
    final allowed = allowedSlotEquipment(routine.equipment);

    for (final slot in routine.importableSlots) {
      final slotEquipment = slotEquipmentFor(slot.name);
      if (allowed.contains(slotEquipment)) continue;

      issues.add(
        CatalogEquipmentIssue(
          routineSlug: routine.slug,
          programName: routine.programName,
          routineName: routine.name,
          exerciseName: slot.name,
          programEquipment: routine.equipment,
          slotEquipment: slotEquipment,
        ),
      );
    }
  }

  return issues;
}

/// Distinct importable exercise names used anywhere in the catalog, sorted.
List<String> allCatalogExerciseNames() {
  final names = <String>{
    for (final routine in exploreRoutines) ...routine.exerciseNames,
  }.toList()
    ..sort();
  return names;
}

/// Pairs of catalog names that describe the SAME movement.
///
/// Per-exercise history, personal records and the muscle map all key off the
/// exercise identity, so an alias silently splits a user's data in two.
/// Fix these in the source dataset and delete the entry.
const List<(String, String)> kKnownDuplicateExerciseAliases = [
  ('Inverted Row with Underhand Grip', 'Inverted Row - Underhand'),
];
