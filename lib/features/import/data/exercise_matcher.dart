/// Matches an incoming exercise name (from a Hevy/Strong file) to a local
/// catalog exercise id. Pure Dart — the caller supplies a snapshot of the
/// catalog as [ExerciseRef]s.
///
/// Matching is movement- and equipment-aware (via [ExerciseNaming]), so naming
/// conventions resolve correctly:
///   • "Barbell Bench Press" and "Bench Press (Barbell)" share movement key
///     {bench, press} + equipment "barbell" → link.
///   • "Bench Press (Dumbbell)" never links to the barbell entry.
///   • "Triceps Pushdown" (no equipment) links to the single movement match.
///
/// No movement match → null, and the caller creates a custom exercise.
library;

import 'package:gymlog/core/exercises/exercise_naming.dart';

class ExerciseRef {
  const ExerciseRef(this.id, this.name);
  final int id;
  final String name;
}

class _Cand {
  const _Cand(this.id, this.equip);
  final int id;
  final String equip;
}

class ExerciseMatcher {
  ExerciseMatcher(Iterable<ExerciseRef> library) {
    for (final e in library) {
      _byExact.putIfAbsent(e.name.trim().toLowerCase(), () => e.id);
      final key = ExerciseNaming.movementKey(e.name);
      if (key.isNotEmpty) {
        (_byMovement[key] ??= <_Cand>[])
            .add(_Cand(e.id, ExerciseNaming.equipClassFromName(e.name)));
      }
    }
  }

  final Map<String, int> _byExact = {};
  final Map<String, List<_Cand>> _byMovement = {};

  /// Returns the catalog id for [name], or null when there's no confident match.
  int? match(String name) {
    final exact = _byExact[name.trim().toLowerCase()];
    if (exact != null) return exact;

    final key = ExerciseNaming.movementKey(name);
    if (key.isEmpty) return null;
    final cands = _byMovement[key];
    if (cands == null || cands.isEmpty) return null;

    final equip = ExerciseNaming.equipClassFromName(name);
    final same = cands.where((c) => c.equip == equip).toList();
    if (same.isNotEmpty) return same.first.id;

    // Equipment unspecified in the import name → best-effort single family.
    if (equip == 'other') return cands.first.id;

    // Equipment specified but no same-equipment entry: only link when the
    // movement is unambiguous, else stay null (→ custom) to avoid a
    // wrong-equipment link.
    return cands.length == 1 ? cands.first.id : null;
  }

  /// Exposed for tests / callers that want the raw movement key.
  static String movementKey(String name) => ExerciseNaming.movementKey(name);

  /// Exposed for tests / callers that want the equipment class of a name.
  static String equipFromName(String name) =>
      ExerciseNaming.equipClassFromName(name);
}
