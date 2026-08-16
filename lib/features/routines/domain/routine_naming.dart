// [routine_naming.dart]
// Canonical naming rules for routines imported from an Explore program.
//
// WHY THIS EXISTS
// The Explore import path used to derive a routine name at runtime with
// `RegExp(r'^Day \d+\s*-\s*')` and then prefix it with the program name. That
// had three failure modes, all visible in My Routines:
//
//   1. Labels that did not match the pattern ("Workout A1") kept their raw
//      form, so the list mixed "Upper A" with "Workout A1".
//   2. The prefix used the full program name, producing the reported
//      "Upper & Lower Body \u00b7 Upper A" / "Upper & Lower Body \u00b7 Lower A" wall.
//   3. Splitting the program name on ' - ' dropped the equipment variant, so
//      "Starter Full Body \u00b7 Dumbbell" and "Starter Full Body \u00b7 No Equipment"
//      both shortened to "Starter Full Body" and became indistinguishable.
//
// Two more surfaced only once this ran against all 16 real catalog programs:
//
//   4. A curated short name long enough to push its equipment suffix past
//      [kMaxProgramShortNameLength] lost the suffix to truncation -- exactly
//      the failure in (3), reintroduced by the cap. Curated names must leave
//      room for " DB" / " BW".
//   5. Two programs can share a base name and differ only by cadence
//      ("Push / Pull / Legs" at 6 and at 3 days a week). A pure per-name
//      function cannot detect that; [uniqueProgramShortNames] resolves it
//      against the whole catalog.
//
// Everything here is pure, synchronous and deterministic so it can be unit
// tested without a database, a widget tree or a golden file.

/// Hard ceiling for a generated routine name, in characters.
const int kMaxRoutineNameLength = 32;

/// Hard ceiling for a program short name used as a routine name prefix.
const int kMaxProgramShortNameLength = 12;

/// Curated short names for the shipped catalog programs. Anything not listed
/// falls back to [_initialsFor].
///
/// INVARIANT: every value here must be at most
/// `kMaxProgramShortNameLength - 3` characters, so a " DB" or " BW" equipment
/// suffix still fits without truncation. `routine_naming_test` asserts it.
const Map<String, String> kProgramShortNames = {
  'Push / Pull / Legs': 'PPL',
  'Upper & Lower Body': 'Upper/Low',
  'Classic Push & Pull Split': 'Push/Pull',
  'Body-Part Split': 'Body-Part',
  'Starter Full Body': 'Full Body',
  'Power + Size': 'Power+Size',
  'Power & Hypertrophy': 'Power/Hyp',
  'Linear Strength Builder': 'Linear',
  'Fat-Loss Circuit': 'Fat-Loss',
  'HIIT Fat-Loss': 'HIIT',
};

/// Equipment variant suffixes, abbreviated so they survive the 12-char cap.
/// A full-gym program carries no suffix because it is the default.
const Map<String, String> kEquipmentShortNames = {
  'dumbbell': 'DB',
  'dumbbell only': 'DB',
  'no equipment': 'BW',
  'bodyweight': 'BW',
  'full gym': '',
};

final RegExp _dayPrefix = RegExp(r'^Day\s+\d+\s*[-\u2013\u2014:]\s*');
final RegExp _workoutPrefix =
    RegExp(r'^Workout\s+[A-Za-z]\d*\s*[-\u2013\u2014:]\s*');
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _nonSlug = RegExp(r'[^a-z0-9]+');
final RegExp _slugEdges = RegExp(r'^-+|-+$');
final RegExp _nonAlphanumeric = RegExp(r'[^A-Za-z0-9]');
final RegExp _cadence =
    RegExp(r'-\s*(\d+)\s*Days?\s*/\s*Week', caseSensitive: false);

/// Strips generated scaffolding from a catalog day label.
///
/// "Day 1 - Upper A"              -> "Upper A"
/// "Day 3 - Full Body A (repeat)" -> "Full Body A (repeat)"
/// "Workout A1 - Push"            -> "Push"
/// "Workout A1"                   -> "Workout A1"  (already a real name)
String cleanRoutineLabel(String rawLabel) {
  var label = rawLabel.replaceAll(_whitespace, ' ').trim();
  if (label.isEmpty) return '';

  final withoutDay = label.replaceFirst(_dayPrefix, '').trim();
  if (withoutDay.isNotEmpty) label = withoutDay;

  final withoutWorkout = label.replaceFirst(_workoutPrefix, '').trim();
  if (withoutWorkout.isNotEmpty) label = withoutWorkout;

  return label;
}

/// Splits a catalog program name into its display base and equipment variant.
///
/// "Starter Full Body - 3 Days/Week \u00b7 Dumbbell"
///   -> (base: "Starter Full Body", variant: "Dumbbell")
({String base, String variant}) splitProgramName(String programName) {
  var name = programName.replaceAll(_whitespace, ' ').trim();
  var variant = '';

  final variantIndex = name.indexOf(' \u00b7 ');
  if (variantIndex > 0) {
    variant = name.substring(variantIndex + 3).trim();
    name = name.substring(0, variantIndex).trim();
  }

  final cadenceIndex = name.indexOf(' - ');
  if (cadenceIndex > 0) {
    name = name.substring(0, cadenceIndex).trim();
  }

  return (base: name, variant: variant);
}

/// Sessions per week declared by a catalog program name, or null when the
/// name carries no cadence.
///
/// "Push / Pull / Legs - 6 Days/Week" -> 6
int? programCadence(String programName) {
  final match = _cadence.firstMatch(programName);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

/// A short, unique, human label for a program, safe to use as a name prefix
/// or a chip. Never longer than [kMaxProgramShortNameLength].
///
/// This is intentionally pure and per-name. When two programs in the same
/// catalog collapse to the same label, use [uniqueProgramShortNames] instead.
String programShortName(String programName) {
  final parts = splitProgramName(programName);
  var short = kProgramShortNames[parts.base] ?? _initialsFor(parts.base);

  if (parts.variant.isNotEmpty) {
    final abbreviated = kEquipmentShortNames[parts.variant.toLowerCase()];
    final suffix = abbreviated ?? parts.variant;
    if (suffix.isNotEmpty) short = '$short $suffix';
  }

  return _truncate(short, kMaxProgramShortNameLength);
}

/// Resolves short names across a whole catalog so no two programs share one.
///
/// Cadence is appended ONLY where [programShortName] is ambiguous, so the
/// common case stays clean:
///
///   Push / Pull / Legs - 6 Days/Week            -> "PPL 6d"
///   Push / Pull / Legs - 3 Days/Week            -> "PPL 3d"
///   Push / Pull / Legs - 6 Days/Week \u00b7 Dumbbell  -> "PPL DB"   (already unique)
///
/// Returns a map keyed by the ORIGINAL program name, in input order.
Map<String, String> uniqueProgramShortNames(List<String> programNames) {
  final grouped = <String, List<String>>{};
  for (final name in programNames) {
    grouped.putIfAbsent(programShortName(name), () => <String>[]).add(name);
  }

  final proposed = <String, String>{};
  for (final entry in grouped.entries) {
    final isAmbiguous = entry.value.length > 1;
    for (final name in entry.value) {
      final cadence = isAmbiguous ? programCadence(name) : null;
      proposed[name] = cadence == null
          ? entry.key
          : _withCadenceSuffix(entry.key, cadence);
    }
  }

  final taken = <String>{};
  final resolved = <String, String>{};
  for (final name in programNames) {
    final base = proposed[name] ?? programShortName(name);
    var label = base;
    var attempt = 2;
    while (!taken.add(label) && attempt < 100) {
      label = _truncate('$base $attempt', kMaxProgramShortNameLength);
      attempt++;
    }
    resolved[name] = label;
  }

  return resolved;
}

/// The name written to `routines.name` when a day is imported.
///
/// Routines imported into a program group do NOT get a prefix -- the group
/// header already says which program they belong to. A prefix is only added
/// when the routine is pulled out on its own and would otherwise be ambiguous
/// in a flat list.
String routineDisplayName({
  required String dayLabel,
  String? programPrefix,
  bool prefixWithProgram = false,
}) {
  final label = cleanRoutineLabel(dayLabel);
  if (label.isEmpty) return 'Routine';

  if (!prefixWithProgram) return _truncate(label, kMaxRoutineNameLength);

  final prefix = (programPrefix ?? '').trim();
  if (prefix.isEmpty) return _truncate(label, kMaxRoutineNameLength);

  return _truncate('$prefix \u00b7 $label', kMaxRoutineNameLength);
}

/// Lowercase, hyphenated, ASCII-safe slug fragment.
String slugify(String value) {
  final lowered = value.toLowerCase().replaceAll(_nonSlug, '-');
  return lowered.replaceAll(_slugEdges, '');
}

/// Stable identity for a catalog routine, e.g. `ppl-6day-gym/push-a`.
/// Used as the migration key and the deep-link segment, so it must not change
/// once a version of the catalog has shipped.
String routineSlug({required String programSlug, required String dayLabel}) {
  final program = slugify(programSlug);
  final label = slugify(cleanRoutineLabel(dayLabel));
  if (label.isEmpty) return program;
  return '$program/$label';
}

/// Guarantees unique names inside a single program import by suffixing
/// repeats: ["Push", "Pull", "Push"] -> ["Push", "Pull", "Push 2"].
List<String> dedupeRoutineNames(List<String> names) {
  final counts = <String, int>{};
  final result = <String>[];

  for (final name in names) {
    final key = name.toLowerCase();
    final occurrence = (counts[key] ?? 0) + 1;
    counts[key] = occurrence;
    result.add(occurrence == 1 ? name : '$name $occurrence');
  }

  return result;
}

String _withCadenceSuffix(String short, int cadence) {
  final suffix = '${cadence}d';
  final room = kMaxProgramShortNameLength - suffix.length - 1;
  final base = short.length <= room ? short : _truncate(short, room);
  return '$base $suffix';
}

String _initialsFor(String base) {
  if (base.length <= kMaxProgramShortNameLength) return base;

  final initials = base
      .split(_whitespace)
      .map((word) => word.replaceAll(_nonAlphanumeric, ''))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase())
      .join();

  return initials.isEmpty
      ? _truncate(base, kMaxProgramShortNameLength)
      : initials;
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  return '${value.substring(0, max - 1).trimRight()}\u2026';
}
