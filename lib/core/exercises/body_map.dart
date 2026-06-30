import 'muscle_taxonomy.dart';

/// Side of the body used by the body-highlighter asset set.
enum BodySide { front, back }

/// Maps each [MuscleTaxonomy] parent group to the body-highlighter part slugs
/// that should light up when that group is worked. Slugs are reconciled against
/// `plan/manifest.json` (copied to `assets/body/manifest.json`).
///
/// If a slug is missing for a gender, [partsForGroups] drops it rather than
/// crashing; a `// TODO(manifest)` note marks intentionally mapped-but-missing
/// slugs.
const Map<String, List<(BodySide, String)>> kGroupToParts = {
  'Chest': [(BodySide.front, 'chest')],
  'Back': [
    (BodySide.back, 'trapezius'),
    (BodySide.back, 'upper-back'),
    (BodySide.back, 'lower-back'),
  ],
  'Shoulders': [
    (BodySide.front, 'deltoids'),
    (BodySide.back, 'deltoids'),
  ],
  'Biceps': [(BodySide.front, 'biceps')],
  'Triceps': [(BodySide.back, 'triceps')],
  'Forearms': [
    (BodySide.front, 'forearm'),
    (BodySide.back, 'forearm'),
  ],
  'Quadriceps': [(BodySide.front, 'quadriceps')],
  'Hamstrings': [(BodySide.back, 'hamstring')],
  'Glutes': [(BodySide.back, 'gluteal')],
  'Adductors': [
    (BodySide.front, 'adductors'),
    (BodySide.back, 'adductors'),
  ],
  'Abductors': [(BodySide.back, 'gluteal')],
  'Calves': [
    (BodySide.back, 'calves'),
    (BodySide.front, 'tibialis'),
    (BodySide.front, 'calves'),
  ],
  'Hip Flexors': [(BodySide.front, 'adductors')],
  'Core': [
    (BodySide.front, 'abs'),
    (BodySide.front, 'obliques'),
  ],
  'Neck': [
    (BodySide.front, 'neck'),
    (BodySide.back, 'neck'),
  ],
  'Full Body': [], // sentinel — the widget highlights every known part
};

/// Part slugs known to exist in the vendored asset set, by gender and side.
/// Generated from `assets/body/manifest.json`.
const Map<String, Map<BodySide, Set<String>>> _knownSlugs = {
  'male': {
    BodySide.front: {
      'abs',
      'adductors',
      'ankles',
      'biceps',
      'calves',
      'chest',
      'deltoids',
      'feet',
      'forearm',
      'hair',
      'hands',
      'head',
      'knees',
      'neck',
      'obliques',
      'quadriceps',
      'tibialis',
      'trapezius',
      'triceps',
    },
    BodySide.back: {
      'adductors',
      'ankles',
      'calves',
      'deltoids',
      'feet',
      'forearm',
      'gluteal',
      'hair',
      'hamstring',
      'hands',
      'head',
      'lower-back',
      'neck',
      'trapezius',
      'triceps',
      'upper-back',
    },
  },
  'female': {
    BodySide.front: {
      'abs',
      'adductors',
      'ankles',
      'biceps',
      'calves',
      'chest',
      'deltoids',
      'feet',
      'forearm',
      'hair',
      'hands',
      'head',
      'knees',
      'neck',
      'obliques',
      'quadriceps',
      'tibialis',
      'trapezius',
      'triceps',
    },
    BodySide.back: {
      'adductors',
      'calves',
      'deltoids',
      'feet',
      'forearm',
      'gluteal',
      'hair',
      'hamstring',
      'hands',
      'lower-back',
      'neck',
      'trapezius',
      'triceps',
      'upper-back',
    },
  },
};

/// Resolves primary/secondary muscle strings to parent groups, keeping the
/// primary group out of the secondary set.
({Set<String> primary, Set<String> secondary}) workedGroupsFor({
  required String target,
  required List<String> secondary,
}) {
  final primary = <String>{};
  final primaryGroup = MuscleTaxonomy.parentOf(target);
  if (primaryGroup != 'Other') {
    primary.add(primaryGroup);
  }

  final secondarySet = <String>{};
  for (final m in secondary) {
    final group = MuscleTaxonomy.parentOf(m);
    if (group != 'Other' && !primary.contains(group)) {
      secondarySet.add(group);
    }
  }
  return (primary: primary, secondary: secondarySet);
}

/// Returns the body part slugs that should be painted for [groups] on the given
/// [gender]. Missing slugs are dropped silently.
Set<(BodySide, String)> partsForGroups(
  Set<String> groups, {
  required String gender,
}) {
  final effectiveGender = gender == 'female' ? 'female' : 'male';
  final known = _knownSlugs[effectiveGender]!;
  final parts = <(BodySide, String)>{};

  if (groups.contains('Full Body')) {
    for (final side in BodySide.values) {
      for (final slug in known[side]!) {
        parts.add((side, slug));
      }
    }
    return parts;
  }

  for (final group in groups) {
    final mapped = kGroupToParts[group];
    if (mapped == null) continue;
    for (final entry in mapped) {
      if (known[entry.$1]!.contains(entry.$2)) {
        parts.add(entry);
      }
    }
  }
  return parts;
}

/// All known part slugs for a gender, useful when the widget wants to highlight
/// every muscle (e.g. the Full Body sentinel).
Set<(BodySide, String)> allKnownParts(String gender) {
  final effectiveGender = gender == 'female' ? 'female' : 'male';
  final known = _knownSlugs[effectiveGender]!;
  return {
    for (final side in BodySide.values)
      for (final slug in known[side]!) (side, slug),
  };
}
