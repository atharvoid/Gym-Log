// [exercise_resolver.dart]
// Name -> exercise resolution and per-routine muscle profiles, computed in
// memory from the catalog the app has already loaded.
//
// THE PROBLEM THIS REPLACES
// The Explore screen resolved a template slot by querying the database:
//
//     for (final slot in template.previewSlots) {
//       final matches = await db.exercisesDao.searchExercises(slot.name);
//       ...
//     }
//
// One awaited LIKE query per slot, in sequence -- about 38 of them before a
// 6-day program's preview can paint. It then unioned the groups across every
// day, so the body map highlighted everything and told the user nothing.
//
// This builds an index once (~800 rows) and resolves every slot with no I/O
// at all, per routine rather than per program.
//
// Deliberately free of Drift and Flutter: it takes plain values, so it can be
// unit tested without a database and reused from any layer.

import 'package:gymlog/core/exercises/body_map.dart';

/// An exercise reduced to the fields resolution and muscle mapping need.
class ResolvedExercise {
  const ResolvedExercise({
    required this.id,
    required this.name,
    required this.target,
    this.secondaryMuscles = const <String>[],
    this.equipment = '',
    this.bodyPart = '',
  });

  final int id;
  final String name;

  /// Primary muscle, as stored in `exercises.target`.
  final String target;

  /// Decoded `exercises.secondary_muscles`.
  final List<String> secondaryMuscles;

  final String equipment;
  final String bodyPart;
}

/// Primary and secondary muscle groups trained by a set of exercises.
typedef MuscleProfile = ({Set<String> primary, Set<String> secondary});

const MuscleProfile _emptyProfile =
    (primary: <String>{}, secondary: <String>{});

/// A token must clear this share of the query's words before a fuzzy match is
/// accepted. Below it, resolving to nothing is safer than resolving to the
/// wrong lift -- a mis-resolved exercise silently corrupts a user's history.
const double _kFuzzyMatchFloor = 0.6;

/// Words that carry no identifying signal in an exercise name.
const Set<String> _kNoiseTokens = {
  'the',
  'with',
  'and',
  'a',
  'an',
  'of',
  'to',
  'variation',
};

final RegExp _parenthetical = RegExp(r'\([^)]*\)');
final RegExp _nonAlphanumeric = RegExp(r'[^a-z0-9]+');

/// Lowercases, strips punctuation and collapses whitespace.
String normalizeExerciseName(String raw) =>
    raw.toLowerCase().replaceAll(_nonAlphanumeric, ' ').trim();

/// Normalised form with any equipment parenthetical removed, so
/// `Floor Press (Barbell)` and `Floor Press` share a key.
String normalizeExerciseNameBase(String raw) =>
    normalizeExerciseName(raw.replaceAll(_parenthetical, ' '));

List<String> _tokens(String normalized) => normalized
    .split(' ')
    .where((t) => t.isNotEmpty && !_kNoiseTokens.contains(t))
    .toList();

/// Resolves catalog slot names to real exercises, and derives muscle groups.
class ExerciseResolver {
  ExerciseResolver(
    List<ResolvedExercise> exercises, {
    List<(String, String)> aliases = const [],
  }) {
    for (final e in exercises) {
      _byExactName.putIfAbsent(normalizeExerciseName(e.name), () => e);
      _byBaseName.putIfAbsent(normalizeExerciseNameBase(e.name), () => e);
      _tokenized.add((tokens: _tokens(normalizeExerciseName(e.name)), exercise: e));
    }
    for (final (a, b) in aliases) {
      final left = normalizeExerciseName(a);
      final right = normalizeExerciseName(b);
      final target = _byExactName[left] ?? _byExactName[right];
      if (target == null) continue;
      _byExactName.putIfAbsent(left, () => target);
      _byExactName.putIfAbsent(right, () => target);
    }
  }

  final Map<String, ResolvedExercise> _byExactName = {};
  final Map<String, ResolvedExercise> _byBaseName = {};
  final List<({List<String> tokens, ResolvedExercise exercise})> _tokenized = [];
  final Map<String, ResolvedExercise?> _cache = {};

  int get indexedCount => _byExactName.length;

  /// Best match for a catalog slot name, or null when nothing clears the
  /// confidence floor. Results are memoised: the same slot name appears in
  /// many programs.
  ResolvedExercise? resolve(String slotName) {
    final key = normalizeExerciseName(slotName);
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];
    final match = _resolveUncached(slotName, key);
    _cache[key] = match;
    return match;
  }

  ResolvedExercise? _resolveUncached(String slotName, String key) {
    final exact = _byExactName[key];
    if (exact != null) return exact;

    final base = normalizeExerciseNameBase(slotName);
    final byBase = _byBaseName[base] ?? _byExactName[base];
    if (byBase != null) return byBase;

    // Scored token overlap. Requires every scoring token to be a real word in
    // the candidate, and prefers the shortest candidate that qualifies so
    // "Bench Press" does not resolve to "Close Grip Bench Press".
    final wanted = _tokens(key);
    if (wanted.isEmpty) return null;

    ResolvedExercise? best;
    var bestScore = 0.0;
    var bestLength = 1 << 30;

    for (final candidate in _tokenized) {
      if (candidate.tokens.isEmpty) continue;
      var hits = 0;
      for (final token in wanted) {
        if (candidate.tokens.contains(token)) hits++;
      }
      if (hits == 0) continue;
      final score = hits / wanted.length;
      if (score < _kFuzzyMatchFloor) continue;
      final length = candidate.tokens.length;
      if (score > bestScore || (score == bestScore && length < bestLength)) {
        best = candidate.exercise;
        bestScore = score;
        bestLength = length;
      }
    }
    return best;
  }

  /// Slot names that resolve to nothing. These are catalog gaps: the routine
  /// will import with the exercise missing, so they are worth surfacing.
  List<String> unresolvedNames(Iterable<String> slotNames) => [
        for (final name in slotNames)
          if (resolve(name) == null) name,
      ];

  /// Muscle groups trained by [slotNames], as parent group names from
  /// body_map.dart -- exactly what RoutineMuscleGlyph and MuscleMap consume.
  ///
  /// A muscle that is primary anywhere never also appears as secondary, so a
  /// day that both presses and supports with the chest reads as a chest day.
  MuscleProfile muscleProfileFor(Iterable<String> slotNames) {
    final primary = <String>{};
    final secondary = <String>{};

    for (final name in slotNames) {
      final exercise = resolve(name);
      if (exercise == null) continue;
      final worked = workedGroupsFor(
        target: exercise.target,
        secondary: exercise.secondaryMuscles,
      );
      primary.addAll(worked.primary);
      secondary.addAll(worked.secondary);
    }

    secondary.removeAll(primary);
    if (primary.isEmpty && secondary.isEmpty) return _emptyProfile;
    return (primary: primary, secondary: secondary);
  }

  /// Resolved exercise ids for [slotNames], skipping anything unresolvable.
  /// This is what an import writes into the routine.
  List<int> exerciseIdsFor(Iterable<String> slotNames) => [
        for (final name in slotNames)
          if (resolve(name) != null) resolve(name)!.id,
      ];
}
