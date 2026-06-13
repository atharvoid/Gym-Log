/// Matches an incoming exercise name (from a Hevy/Strong file) to a local
/// catalog exercise id. Pure Dart — no DB dependency; the caller supplies a
/// snapshot of the catalog as [ExerciseRef]s.
///
/// Matching is deliberately CONSERVATIVE: only exact (case-insensitive) and
/// punctuation/spacing-normalised matches are considered confident. Crucially
/// the equipment qualifier is preserved during normalisation, so
/// "Bench Press (Dumbbell)" never collapses onto "Bench Press (Barbell)".
/// Anything that doesn't match cleanly returns null, and the caller creates a
/// custom exercise — lossless, and the same behaviour Hevy/Strong importers use.
library;

class ExerciseRef {
  const ExerciseRef(this.id, this.name);
  final int id;
  final String name;
}

class ExerciseMatcher {
  ExerciseMatcher(Iterable<ExerciseRef> library) {
    for (final e in library) {
      _byExact.putIfAbsent(e.name.trim().toLowerCase(), () => e.id);
      final norm = normalize(e.name);
      if (norm.isNotEmpty) _byNormalized.putIfAbsent(norm, () => e.id);
    }
  }

  final Map<String, int> _byExact = {};
  final Map<String, int> _byNormalized = {};

  /// Returns the catalog id for [name], or null when there's no confident
  /// match (caller then creates a custom exercise).
  int? match(String name) {
    final exact = _byExact[name.trim().toLowerCase()];
    if (exact != null) return exact;
    final norm = normalize(name);
    if (norm.isEmpty) return null;
    return _byNormalized[norm];
  }

  /// Lower-cases, replaces any non-alphanumeric run with a single space, and
  /// trims. Equipment text inside parentheses is KEPT (its letters survive),
  /// so equipment variants stay distinct:
  ///   "Bench Press (Dumbbell)" → "bench press dumbbell"
  ///   "Bench Press (Barbell)"  → "bench press barbell"
  static String normalize(String name) {
    final lower = name.toLowerCase();
    final buf = StringBuffer();
    var prevSpace = true; // collapse leading space
    for (final code in lower.codeUnits) {
      final isAlnum = (code >= 0x30 && code <= 0x39) || // 0-9
          (code >= 0x61 && code <= 0x7a); // a-z
      if (isAlnum) {
        buf.writeCharCode(code);
        prevSpace = false;
      } else if (!prevSpace) {
        buf.write(' ');
        prevSpace = true;
      }
    }
    return buf.toString().trim();
  }
}
