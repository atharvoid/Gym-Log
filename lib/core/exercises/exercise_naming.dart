/// Canonical exercise-name normalisation, shared by the import matcher and the
/// custom-exercise reconciliation in [ExercisesDao]. Mirrors tool/gen_catalog.py
/// so the runtime agrees with the generated catalog.
///
/// The movement key strips equipment words and parentheticals and sorts the
/// remaining tokens, so "Bench Press (Barbell)" and "Barbell Bench Press" both
/// reduce to "bench press".
library;

abstract final class ExerciseNaming {
  static const _equipTokens = {
    'barbell', 'dumbbell', 'cable', 'machine', 'smith', 'kettlebell', 'bodyweight',
    'body', 'weight', 'weighted', 'olympic', 'sled', 'lever', 'leverage', 'band',
    'resistance', 'plate', 'gymnastic', 'rings', 'stability', 'medicine', 'ez',
    'assisted', 'trap', 'bar', 'ab', 'wheel', 'ball', 'hand', 'gripper', 'roller',
    'specialty', 'partner',
  };

  static const _phrase = <List<String>>[
    ['pull down', 'pulldown'], ['pull up', 'pullup'], ['chin up', 'chinup'],
    ['push up', 'pushup'], ['press up', 'pushup'], ['sit up', 'situp'],
    ['step up', 'stepup'], ['push-up', 'pushup'], ['pull-up', 'pullup'],
    ['chin-up', 'chinup'], ['sit-up', 'situp'], ['t-bar', 'tbar'], ['t bar', 'tbar'],
  ];

  static const _syn = {
    'presses': 'press', 'flyes': 'fly', 'flys': 'fly', 'flye': 'fly',
    'raises': 'raise', 'rows': 'row', 'curls': 'curl', 'extensions': 'extension',
    'dips': 'dip', 'squats': 'squat', 'lunges': 'lunge', 'pulldowns': 'pulldown',
    'pushups': 'pushup', 'situps': 'situp', 'chinups': 'chinup', 'pullups': 'pullup',
    'kickbacks': 'kickback', 'pushdowns': 'pushdown', 'thrusts': 'thrust',
    'crunches': 'crunch', 'bicep': 'biceps', 'tricep': 'triceps', 'calf': 'calves',
    'oh': 'overhead',
  };

  /// Sorted, equipment-stripped movement tokens joined by spaces.
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
  static String equipClassFromName(String name) {
    final paren = RegExp(r'\(([^)]*)\)').firstMatch(name);
    if (paren != null) {
      final c = equipClassOf(paren.group(1)!);
      if (c != 'other') return c;
    }
    for (final t
        in name.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), ' ').split(' ')) {
      if (const ['barbell', 'dumbbell', 'cable', 'kettlebell', 'smith'].contains(t)) {
        return t;
      }
      if (t == 'ez') return 'ez';
    }
    return 'other';
  }

  /// Equipment class from a raw equipment/qualifier string.
  static String equipClassOf(String raw) {
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
