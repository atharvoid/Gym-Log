/// Canonical gym slang, acronyms, and shorthand mappings for AI routine import.
/// Maps commonly used abbreviations to standardized catalog search phrases.
class ExerciseAliasCatalog {
  ExerciseAliasCatalog._();

  static const Map<String, String> aliases = {
    // Acronyms
    'rdl': 'romanian deadlift',
    'db rdl': 'dumbbell romanian deadlift',
    'bb rdl': 'barbell romanian deadlift',
    'ohp': 'overhead press',
    'db ohp': 'dumbbell overhead press',
    'bb ohp': 'overhead press (barbell)',
    'cgbp': 'close grip barbell bench press',
    'sldl': 'straight leg deadlift',

    // Slang and Common Names
    'skulls': 'lying triceps extension',
    'skull crusher': 'lying triceps extension',
    'skull crushers': 'lying triceps extension',
    'skullcrushers': 'lying triceps extension',
    'skullcrusher': 'lying triceps extension',
    'pec deck': 'chest fly',
    'pec dec': 'chest fly',
    'lat pull': 'cable lat pulldown',
    'lat pulldown': 'cable lat pulldown',
    'lat pulldowns': 'cable lat pulldown',
    'chins': 'chin-up',
    'chin up': 'chin-up',
    'chin ups': 'chin-up',
    'pullup': 'pull-up',
    'pullups': 'pull-up',
    'pull up': 'pull-up',
    'pull ups': 'pull-up',
    'dips': 'chest dip',
    'tricep dips': 'triceps dip',
    'triceps pushdown': 'cable triceps pushdown',
    'tricep pushdown': 'cable triceps pushdown',
    'tricep pushdowns': 'cable triceps pushdown',
    'face pull': 'cable face pull',
    'face pulls': 'cable face pull',
    'facepull': 'cable face pull',
    'facepulls': 'cable face pull',
    'hypers': 'hyperextension',
    'hyperextensions': 'hyperextension',
    'back extensions': 'hyperextension',
    'seated row': 'cable seated row',
    'seated cable row': 'cable seated row',
    'cable row': 'cable seated row',
    'barbell row': 'bent over barbell row',
    'bb row': 'bent over barbell row',
    'bb rows': 'bent over barbell row',
    'dumbbell row': 'dumbbell bent over row',
    'db row': 'dumbbell bent over row',
    'db rows': 'dumbbell bent over row',
    'one arm db row': 'dumbbell bent over row',
    'single arm db row': 'dumbbell bent over row',

    // Chest variants
    'flat bench': 'barbell bench press',
    'flat bench press': 'barbell bench press',
    'bench': 'barbell bench press',
    'bench press': 'barbell bench press',
    'incline bench': 'incline barbell bench press',
    'incline bench press': 'incline barbell bench press',
    'inc bench': 'incline barbell bench press',
    'incline db bench': 'incline dumbbell bench press',
    'inc db bench': 'incline dumbbell bench press',
    'flat db bench': 'dumbbell bench press',
    'db bench': 'dumbbell bench press',
    'db bench press': 'dumbbell bench press',
    'decline bench': 'decline barbell bench press',
    'decline db bench': 'decline dumbbell bench press',

    // Delts and Shoulders
    'lateral raise': 'dumbbell lateral raise',
    'lateral raises': 'dumbbell lateral raise',
    'lat raise': 'dumbbell lateral raise',
    'lat raises': 'dumbbell lateral raise',
    'side raise': 'dumbbell lateral raise',
    'side raises': 'dumbbell lateral raise',
    'db lateral raise': 'dumbbell lateral raise',
    'cable lateral raise': 'cable lateral raise',
    'rear delt fly': 'dumbbell rear lateral raise',
    'rear delt flyes': 'dumbbell rear lateral raise',
    'rear delt flys': 'dumbbell rear lateral raise',
    'reverse fly': 'dumbbell rear lateral raise',

    // Arms
    'bicep curl': 'bicep curl (dumbbell)',
    'bicep curls': 'bicep curl (dumbbell)',
    'db curl': 'bicep curl (dumbbell)',
    'db curls': 'bicep curl (dumbbell)',
    'bb curl': 'barbell curl',
    'bb curls': 'barbell curl',
    'barbell curls': 'barbell curl',
    'hammer curl': 'hammer curls (dumbbell)',
    'hammer curls': 'hammer curls (dumbbell)',
    'preacher curl': 'dumbbell preacher curl',
    'preacher curls': 'dumbbell preacher curl',
    'ez bar curl': 'ez barbell curl',

    // Legs
    'squat': 'barbell squat',
    'squats': 'barbell squat',
    'back squat': 'barbell squat',
    'front squat': 'barbell front squat',
    'leg press': 'sled 45 leg press',
    'leg extension': 'leg extensions',
    'leg extensions': 'leg extensions',
    'quad extension': 'leg extensions',
    'leg curl': 'lying leg curl',
    'leg curls': 'lying leg curl',
    'hamstring curl': 'lying leg curl',
    'hamstring curls': 'lying leg curl',
    'seated leg curl': 'seated leg curl',
    'lying leg curl': 'lying leg curl',
    'calf raise': 'standing calf raise',
    'calf raises': 'standing calf raise',
    'standing calf raise': 'standing calf raise',
    'seated calf raise': 'seated calf raise',
    'bulgarian split squat': 'dumbbell bulgarian split squat',
    // Advanced Hypertrophy & Modern Variations
    'cross-body triceps extension': 'crossbody cable triceps extension',
    'crossbody triceps extension': 'crossbody cable triceps extension',
    'cable cross-body triceps extension': 'crossbody cable triceps extension',
    'cable crossbody triceps extension': 'crossbody cable triceps extension',
    'triceps pressdown': 'triceps pushdown (cable - rope)',
    'tricep pressdown': 'triceps pushdown (cable - rope)',
    'tricep pressdowns': 'triceps pushdown (cable - rope)',
    'overhead triceps extension': 'overhead triceps extension (cable)',
    'overhead tricep extension': 'overhead triceps extension (cable)',
    'cross-body cable y-raise': 'single arm lateral raise (cable)',
    'crossbody cable y-raise': 'single arm lateral raise (cable)',
    'cross-body cable y raise': 'single arm lateral raise (cable)',
    'crossbody cable y raise': 'single arm lateral raise (cable)',
    'cable y-raise': 'single arm lateral raise (cable)',
    'cable y raise': 'single arm lateral raise (cable)',
    'y-raise': 'dumbbell incline y-raise',
    'y raise': 'dumbbell incline y-raise',
    'press-around': 'cable chest press',
    'press around': 'cable chest press',
    'pec static stretch': 'chest stretch',
    'pec stretch': 'chest stretch',
  };

  /// Expands abbreviations like "db", "bb", "inc", "dec" and de-hyphenates compound gym terms.
  static String expandTokens(String input) {
    var cleaned = input
        .toLowerCase()
        // Replace hyphens in compounds with unified form or space
        .replaceAll('cross-body', 'crossbody')
        .replaceAll('y-raise', 'y raise')
        .replaceAll('t-bar', 't bar')
        .replaceAll('push-up', 'push up')
        .replaceAll('pull-up', 'pull up')
        .replaceAll('chin-up', 'chin up')
        .replaceAll('pressdown', 'pushdown')
        .replaceAll('pressdowns', 'pushdowns');

    if (aliases.containsKey(cleaned)) {
      return aliases[cleaned]!;
    }

    final tokens = cleaned.split(RegExp(r'\s+'));
    final mapped = tokens.map((token) {
      switch (token) {
        case 'db':
          return 'dumbbell';
        case 'bb':
          return 'barbell';
        case 'inc':
          return 'incline';
        case 'dec':
          return 'decline';
        case 'tricep':
          return 'triceps';
        case 'bicep':
          return 'biceps';
        default:
          return token;
      }
    }).toList();

    final expanded = mapped.join(' ');
    if (aliases.containsKey(expanded)) {
      return aliases[expanded]!;
    }
    return expanded;
  }
}
