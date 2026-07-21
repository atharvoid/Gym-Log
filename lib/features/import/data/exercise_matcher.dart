/// Matches an incoming exercise name (from a Hevy/Strong file) to a local
/// catalog exercise id. Pure Dart — the caller supplies a snapshot of the
/// catalog as [ExerciseRef]s.
///
/// Matching is movement- and equipment-aware, so naming-convention differences
/// resolve correctly:
///   • "Barbell Bench Press" (library/Strong word order) and
///     "Bench Press (Barbell)" (Hevy parenthetical) share the movement key
///     {bench, press} + equipment "barbell" and therefore link.
///   • Equipment is preserved, so "Bench Press (Dumbbell)" never links to the
///     barbell entry.
///   • When the import name omits equipment ("Triceps Pushdown") it links to
///     the single best movement match.
///
/// Anything with no movement match returns null, and the caller creates a
/// custom exercise — the same behaviour Hevy/Strong importers use.
library;

class ExerciseRef {
  const ExerciseRef(
    this.id,
    this.name, {
    this.measurementType,
    this.equipment,
  });

  final int id;
  final String name;
  final String? measurementType;
  final String? equipment;
}

class _Cand {
  const _Cand(this.ref, this.equip);
  final ExerciseRef ref;
  final String equip; // equipment class
}

class ExerciseMatcher {
  ExerciseMatcher(Iterable<ExerciseRef> library) {
    for (final e in library) {
      _byExact.putIfAbsent(e.name.trim().toLowerCase(), () => e);
      final key = movementKey(e.name);
      if (key.isNotEmpty) {
        (_byMovement[key] ??= <_Cand>[]).add(_Cand(e, equipFromName(e.name)));
      }
    }
  }

  final Map<String, ExerciseRef> _byExact = {};
  final Map<String, List<_Cand>> _byMovement = {};

  /// Returns the catalog id for [name], or null when there's no confident match.
  int? match(String name) => matchRef(name)?.id;

  /// Returns the full [ExerciseRef] for [name], or null when there's no confident match.
  ExerciseRef? matchRef(String name) {
    final exact = _byExact[name.trim().toLowerCase()];
    if (exact != null) return exact;

    final key = movementKey(name);
    if (key.isEmpty) return null;
    final cands = _byMovement[key];
    if (cands == null || cands.isEmpty) return null;

    final equip = equipFromName(name);
    final same = cands.where((c) => c.equip == equip).toList();
    if (same.isNotEmpty) return same.first.ref;

    // Equipment not specified in the incoming name → best-effort single family.
    if (equip == 'other') return cands.first.ref;

    // Equipment specified but no same-equipment catalog entry: only link when
    // the movement is unambiguous, otherwise stay null (→ custom) rather than
    // attach the wrong-equipment exercise.
    return cands.length == 1 ? cands.first.ref : null;
  }

  // ── Normalisation (mirrors tool/gen_catalog.py so the runtime agrees with
  //    the generated catalog) ─────────────────────────────────────────────

  static const _equipTokens = {
    'barbell',
    'dumbbell',
    'cable',
    'machine',
    'smith',
    'kettlebell',
    'bodyweight',
    'body',
    'weight',
    'weighted',
    'olympic',
    'sled',
    'lever',
    'leverage',
    'band',
    'resistance',
    'plate',
    'gymnastic',
    'rings',
    'stability',
    'medicine',
    'ez',
    'assisted',
    'trap',
    'bar',
    'ab',
    'wheel',
    'ball',
    'hand',
    'gripper',
    'roller',
    'specialty',
    'partner',
  };

  static const _phrase = <List<String>>[
    ['pull down', 'pulldown'],
    ['pull up', 'pullup'],
    ['chin up', 'chinup'],
    ['push up', 'pushup'],
    ['press up', 'pushup'],
    ['sit up', 'situp'],
    ['step up', 'stepup'],
    ['push-up', 'pushup'],
    ['pull-up', 'pullup'],
    ['chin-up', 'chinup'],
    ['sit-up', 'situp'],
    ['t-bar', 'tbar'],
    ['t bar', 'tbar'],
  ];

  static const _syn = {
    'presses': 'press',
    'flyes': 'fly',
    'flys': 'fly',
    'flye': 'fly',
    'raises': 'raise',
    'rows': 'row',
    'curls': 'curl',
    'extensions': 'extension',
    'dips': 'dip',
    'squats': 'squat',
    'lunges': 'lunge',
    'pulldowns': 'pulldown',
    'pushups': 'pushup',
    'situps': 'situp',
    'chinups': 'chinup',
    'pullups': 'pullup',
    'kickbacks': 'kickback',
    'pushdowns': 'pushdown',
    'thrusts': 'thrust',
    'crunches': 'crunch',
    'bicep': 'biceps',
    'tricep': 'triceps',
    'calf': 'calves',
    'oh': 'overhead',
  };

  /// The sorted, equipment-stripped movement tokens of a name, joined by spaces.
  /// "Bench Press (Barbell)" and "Barbell Bench Press" both → "bench press".
  static String movementKey(String name) {
    var s = name.toLowerCase();
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    for (final p in _phrase) {
      s = s.replaceAll(p[0], p[1]);
    }
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    final toks = <String>{};
    for (var t in s.split(RegExp(r'\s+'))) {
      if (t.isEmpty) continue;
      t = _syn[t] ?? t;
      if (t.isEmpty || _equipTokens.contains(t)) continue;
      toks.add(t);
    }
    final list = toks.toList()..sort();
    return list.join(' ');
  }

  /// Equipment class parsed from a name (parenthetical first, then any word).
  static String equipFromName(String name) {
    final paren = RegExp(r'\(([^)]*)\)').firstMatch(name);
    if (paren != null) {
      final c = _equipClass(paren.group(1)!);
      if (c != 'other') return c;
    }
    for (final t
        in name.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), ' ').split(' ')) {
      if (const ['barbell', 'dumbbell', 'cable', 'kettlebell', 'smith']
          .contains(t)) {
        return t;
      }
      if (t == 'ez') return 'ez';
    }
    return 'other';
  }

  static String _equipClass(String raw) {
    final d = raw.toLowerCase();
    if (d.contains('smith')) return 'smith';
    if (d.contains('ez')) return 'ez';
    if (d.contains('trap bar')) return 'trapbar';
    if (d.contains('barbell')) return 'barbell';
    if (d.contains('dumbbell')) return 'dumbbell';
    if (d.contains('kettlebell')) return 'kettlebell';
    if (d.contains('cable')) return 'cable';
    if (d.contains('band')) return 'band';
    if (d.contains('machine')) return 'machine';
    if (d.contains('bodyweight') || d.contains('body')) return 'bodyweight';
    return 'other';
  }
}
