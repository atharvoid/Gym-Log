/// Pure helpers for the workout muscle-split bar. Kept out of the generated
/// muscle_taxonomy.dart so they survive catalog regeneration, and unit-testable
/// without Flutter.
library;

import 'muscle_taxonomy.dart';

/// Collapses a {specific muscle → set count} map into {parent group → set
/// count} using [MuscleTaxonomy]. Specific muscles with no known parent
/// (parent == "Other") keep their own name so nothing is silently dropped.
/// Zero/negative counts are ignored.
Map<String, int> groupMuscleSetsByParent(Map<String, int> bySpecificMuscle) {
  final out = <String, int>{};
  bySpecificMuscle.forEach((muscle, sets) {
    if (sets <= 0) return;
    final parent = MuscleTaxonomy.parentOf(muscle);
    final key = parent == 'Other' ? muscle : parent;
    out[key] = (out[key] ?? 0) + sets;
  });
  return out;
}

/// Converts a list of weights to integer percentages that sum to EXACTLY 100
/// (largest-remainder method), so a split bar's labels never read 99% or 101%.
/// Returns all-zeros when the total is non-positive.
List<int> largestRemainderPercents(List<int> values) {
  final total = values.fold<int>(0, (a, b) => a + b);
  if (total <= 0) return List<int>.filled(values.length, 0);

  final raw = values.map((v) => v * 100 / total).toList();
  final floors = raw.map((r) => r.floor()).toList();
  var remainder = 100 - floors.fold<int>(0, (a, b) => a + b);

  // Hand the leftover points to the largest fractional parts first.
  final order = [for (var i = 0; i < values.length; i++) i]
    ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));

  final out = List<int>.of(floors);
  for (var k = 0; k < remainder && order.isNotEmpty; k++) {
    out[order[k % order.length]] += 1;
  }
  return out;
}
