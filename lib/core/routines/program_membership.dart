/// Inline program-membership metadata for imported routines.
///
/// GymLog imports a multi-day program as N independent routines, one per
/// training day. The database has no `programs` table yet — adding one means
/// regenerating the 277 KB `database.g.dart`, which cannot ship in the same
/// change as the UI that depends on grouping. Until then, membership is
/// encoded as a single machine-readable line at the top of `Routines.notes`:
///
///     gymlog:program:v1 slug=ppl-6day-gym; label=PPL%206d; order=0; of=6; day=push-a
///
/// Why `notes`:
///  • it already round-trips through cloud sync (`exportRoutineJson`), so
///    grouping follows the user to a new device with no sync work at all
///  • migrating to a real `programs` table later is one backfill read
///  • it is trivially strippable, so users never see it
///
/// Values are percent-encoded, so a `;`, `=` or newline inside a program
/// name can never corrupt the record.
library;

/// Marker that opens the metadata line. Versioned so a future `v2` layout
/// can be introduced without ever misreading a `v1` row.
const String kProgramMetaTag = 'gymlog:program:v1';

/// Sort key used for routines whose membership could not be decoded — they
/// fall to the end of a group instead of jumping to the front.
const int _kUnorderedSortKey = 1 << 20;

/// Describes where one imported routine sits inside its source program.
class ProgramMembership {
  const ProgramMembership({
    required this.programSlug,
    required this.programLabel,
    required this.orderIndex,
    required this.totalRoutines,
    required this.routineSlug,
    this.importedAs,
  });

  /// Stable slug of the source program, e.g. `push-pull-legs-6-days-week`.
  /// This is the grouping key — it never changes, even after the user
  /// renames the program.
  final String programSlug;

  /// Short user-facing program name at import time, e.g. `PPL 6d`. Stored
  /// alongside the slug purely so a group can render a heading before its
  /// routines have been read.
  final String programLabel;

  /// 0-based position of this routine within the program.
  final int orderIndex;

  /// How many routines the program shipped with. Lets My Routines say
  /// "4 of 6 days imported" and offer to add the missing ones.
  final int totalRoutines;

  /// Stable slug of this routine within the program, e.g. `push-a`.
  /// Used to detect which days the user already owns.
  final String routineSlug;

  /// The routine's original name before the one-shot cleanup migration
  /// renamed it. Present only on migrated rows, and only until the undo
  /// window closes.
  final String? importedAs;

  /// 1-based day number, for display.
  int get dayNumber => orderIndex + 1;

  /// Whether this row was renamed by the cleanup migration and can be undone.
  bool get wasMigrated => importedAs != null && importedAs!.isNotEmpty;

  ProgramMembership copyWith({
    String? programSlug,
    String? programLabel,
    int? orderIndex,
    int? totalRoutines,
    String? routineSlug,
    String? importedAs,
    bool clearImportedAs = false,
  }) {
    return ProgramMembership(
      programSlug: programSlug ?? this.programSlug,
      programLabel: programLabel ?? this.programLabel,
      orderIndex: orderIndex ?? this.orderIndex,
      totalRoutines: totalRoutines ?? this.totalRoutines,
      routineSlug: routineSlug ?? this.routineSlug,
      importedAs: clearImportedAs ? null : (importedAs ?? this.importedAs),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramMembership &&
          other.programSlug == programSlug &&
          other.programLabel == programLabel &&
          other.orderIndex == orderIndex &&
          other.totalRoutines == totalRoutines &&
          other.routineSlug == routineSlug &&
          other.importedAs == importedAs;

  @override
  int get hashCode => Object.hash(programSlug, programLabel, orderIndex,
      totalRoutines, routineSlug, importedAs);

  @override
  String toString() =>
      'ProgramMembership($programSlug #${orderIndex + 1}/$totalRoutines $routineSlug)';
}

String _enc(String v) => Uri.encodeComponent(v);

String _dec(String v) {
  try {
    return Uri.decodeComponent(v);
  } catch (_) {
    // A hand-edited or truncated value should never take the app down.
    return v;
  }
}

/// Renders [m] as the single metadata line stored in `Routines.notes`.
String encodeProgramMembership(ProgramMembership m) {
  final fields = <String>[
    'slug=${_enc(m.programSlug)}',
    'label=${_enc(m.programLabel)}',
    'order=${m.orderIndex}',
    'of=${m.totalRoutines}',
    'day=${_enc(m.routineSlug)}',
    if (m.wasMigrated) 'was=${_enc(m.importedAs!)}',
  ];
  return '$kProgramMetaTag ${fields.join('; ')}';
}

/// Reads membership out of a routine's raw [notes].
///
/// Returns null when the routine is standalone **or** when the line is
/// malformed: a corrupt record degrades to "standalone routine", never to a
/// crash or a phantom group.
ProgramMembership? decodeProgramMembership(String? notes) {
  if (notes == null || notes.isEmpty) return null;
  for (final line in notes.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith(kProgramMetaTag)) continue;
    final body = trimmed.substring(kProgramMetaTag.length).trim();
    if (body.isEmpty) return null;

    final fields = <String, String>{};
    for (final field in body.split(';')) {
      final eq = field.indexOf('=');
      if (eq <= 0) continue;
      fields[field.substring(0, eq).trim()] = field.substring(eq + 1).trim();
    }

    final slug = fields['slug'];
    final day = fields['day'];
    if (slug == null || slug.isEmpty) return null;
    if (day == null || day.isEmpty) return null;

    final order = int.tryParse(fields['order'] ?? '');
    if (order == null || order < 0) return null;

    final of = int.tryParse(fields['of'] ?? '');
    final was = fields['was'];

    return ProgramMembership(
      programSlug: _dec(slug),
      programLabel: _dec(fields['label'] ?? ''),
      orderIndex: order,
      // A missing or nonsensical total must never make the group look
      // smaller than the rows we can actually see.
      totalRoutines: (of == null || of < order + 1) ? order + 1 : of,
      routineSlug: _dec(day),
      importedAs: (was == null || was.isEmpty) ? null : _dec(was),
    );
  }
  return null;
}

/// Whether [notes] carries a readable membership record.
bool hasProgramMembership(String? notes) =>
    decodeProgramMembership(notes) != null;

/// The part of [notes] the user actually wrote, with the metadata line
/// removed. Every surface that displays notes must go through this.
String userVisibleNotes(String? notes) {
  if (notes == null || notes.isEmpty) return '';
  return notes
      .split('\n')
      .where((l) => !l.trim().startsWith(kProgramMetaTag))
      .join('\n')
      .trim();
}

/// Returns [notes] with [m] written in, replacing any existing metadata line
/// and preserving whatever the user typed underneath it.
String withProgramMembership(String? notes, ProgramMembership m) {
  final rest = userVisibleNotes(notes);
  final line = encodeProgramMembership(m);
  return rest.isEmpty ? line : '$line\n$rest';
}

/// Strips membership entirely — used when a routine is pulled out of its
/// program and becomes standalone. The user's own notes survive.
String withoutProgramMembership(String? notes) => userVisibleNotes(notes);

/// Orders [items] by their program day number.
///
/// Items whose membership cannot be decoded sort last, and ties keep their
/// original relative order, so this is a stable sort in both directions.
List<T> sortByProgramOrder<T>(
  List<T> items,
  ProgramMembership? Function(T item) membershipOf,
) {
  final keyed = <({int order, int index, T item})>[];
  for (var i = 0; i < items.length; i++) {
    final m = membershipOf(items[i]);
    keyed.add(
        (order: m?.orderIndex ?? _kUnorderedSortKey, index: i, item: items[i]));
  }
  keyed.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    return byOrder != 0 ? byOrder : a.index.compareTo(b.index);
  });
  return [for (final k in keyed) k.item];
}
