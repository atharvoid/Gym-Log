enum MeasurementType {
  weightAndReps('weight_and_reps'),
  repsOnly('reps_only'),
  duration('duration'),
  distance('distance'),
  unknown('unknown');

  final String raw;
  const MeasurementType(this.raw);

  // Reviewed catalog lists/maps for mapping specific exercises to their types
  static const Map<String, MeasurementType> _explicitExceptions = {
    // Duration exercises
    'plank': MeasurementType.duration,
    'wall sit': MeasurementType.duration,
    'l-sit': MeasurementType.duration,
    'v-sit': MeasurementType.duration,
    'dead hang': MeasurementType.duration,
    'deadhang': MeasurementType.duration,
    'passive hang': MeasurementType.duration,
    'active hang': MeasurementType.duration,
    'bar hang': MeasurementType.duration,
    'scapular hang': MeasurementType.duration,
    'pec stretch': MeasurementType.duration,
    'chest stretch': MeasurementType.duration,
    'shoulder stretch': MeasurementType.duration,
    'lat stretch': MeasurementType.duration,
    'quad stretch': MeasurementType.duration,
    'hamstring stretch': MeasurementType.duration,
    'calf stretch': MeasurementType.duration,
    'hip flexor stretch': MeasurementType.duration,
    'biceps stretch': MeasurementType.duration,
    'triceps stretch': MeasurementType.duration,
    'static stretch': MeasurementType.duration,
    'stretch': MeasurementType.duration,

    // Reps-only exercises
    'push up': MeasurementType.repsOnly,
    'pushup': MeasurementType.repsOnly,
    'push-up': MeasurementType.repsOnly,
    'pull up': MeasurementType.repsOnly,
    'pullup': MeasurementType.repsOnly,
    'pull-up': MeasurementType.repsOnly,
    'chin up': MeasurementType.repsOnly,
    'chinup': MeasurementType.repsOnly,
    'chin-up': MeasurementType.repsOnly,
    'sit up': MeasurementType.repsOnly,
    'situp': MeasurementType.repsOnly,
    'sit-up': MeasurementType.repsOnly,
    'crunch': MeasurementType.repsOnly,
    'burpee': MeasurementType.repsOnly,
    'jumping jack': MeasurementType.repsOnly,
    'jumping-jack': MeasurementType.repsOnly,
    'squat jump': MeasurementType.repsOnly,
    'jump squat': MeasurementType.repsOnly,
  };

  /// Parses the input string, returning null for missing/unknown/invalid values.
  static MeasurementType? tryParse(String? val) {
    if (val == null || val.isEmpty) return null;
    final normalized = val.toLowerCase().trim();
    for (final type in values) {
      if (type.raw == normalized ||
          type.name.toLowerCase() == normalized ||
          (type == MeasurementType.weightAndReps &&
              normalized == 'weightandreps') ||
          (type == MeasurementType.repsOnly && normalized == 'repsonly')) {
        return type;
      }
    }
    return null;
  }

  /// Strict string parsing for stored [measurementType] raw values.
  /// Throws an ArgumentError if the input is missing or unrecognized.
  static MeasurementType fromString(String? val) {
    final parsed = tryParse(val);
    if (parsed == null) {
      throw ArgumentError('Invalid or unknown MeasurementType: "$val"');
    }
    return parsed;
  }

  static bool _isExplicitDurationName(String nameNorm) {
    final isOlympicOrDynamic = nameNorm.contains('raise') ||
        nameNorm.contains('wiper') ||
        nameNorm.contains('crunch') ||
        nameNorm.contains('clean') ||
        nameNorm.contains('snatch') ||
        nameNorm.contains('pull') ||
        nameNorm.contains('curl') ||
        nameNorm.contains('swing');

    if (isOlympicOrDynamic) {
      return false;
    }

    for (final entry in _explicitExceptions.entries) {
      if (entry.value == MeasurementType.duration &&
          nameNorm.contains(entry.key)) {
        return true;
      }
    }

    if (nameNorm.contains('hold') ||
        nameNorm.contains('plank') ||
        nameNorm.contains('wall sit') ||
        nameNorm.contains('dead hang') ||
        nameNorm.contains('deadhang') ||
        nameNorm.contains('stretch') ||
        nameNorm.contains('hang')) {
      return true;
    }
    return false;
  }

  /// Authoritative measurement type resolver.
  /// Valid explicit metadata wins; otherwise legacy inference runs.
  static MeasurementType resolve({
    required String? explicitValue,
    required String? equipment,
    required String? exerciseName,
  }) {
    final parsed = tryParse(explicitValue);
    final nameNorm = (exerciseName ?? '').toLowerCase().trim();
    if (parsed != null) {
      // If db default 'weight_and_reps' was stamped on an explicit duration exercise
      // (e.g. Plank, Dead Hang, Pec Stretch, or Weighted Front Plank), let duration win
      // so the Hold Timer is accessible.
      if (parsed == MeasurementType.weightAndReps &&
          _isExplicitDurationName(nameNorm)) {
        return MeasurementType.duration;
      }
      return parsed;
    }
    return inferLegacyMeasurementType(
      equipment: equipment,
      exerciseName: exerciseName,
    );
  }

  /// Legacy classifier for old database rows, catalog migration engines, and
  /// legacy imports where an explicit [measurementType] string is absent.
  static MeasurementType inferLegacyMeasurementType({
    required String? equipment,
    required String? exerciseName,
  }) {
    final String nameNorm = (exerciseName ?? '').toLowerCase().trim();
    final String eqNorm = (equipment ?? '')
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    // 1. Assisted/counterweight exercises remain weighted
    if (nameNorm.contains('assisted') ||
        nameNorm.contains('counterweight') ||
        eqNorm.contains('assisted') ||
        eqNorm.contains('counterweight')) {
      return MeasurementType.weightAndReps;
    }

    // 2. Check explicit name exceptions first
    for (final entry in _explicitExceptions.entries) {
      if (nameNorm.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. Check if name is explicitly duration
    if (_isExplicitDurationName(nameNorm)) {
      return MeasurementType.duration;
    }

    // 4. Bodyweight / no-equipment exercises default to reps-only (unless duration above)
    if (eqNorm == 'bodyweight' || eqNorm == 'none' || eqNorm == 'noequipment') {
      return MeasurementType.repsOnly;
    }

    // 5. Check other equipment keywords for weighted
    if (eqNorm.contains('barbell') ||
        eqNorm.contains('dumbbell') ||
        eqNorm.contains('cable') ||
        eqNorm.contains('machine') ||
        eqNorm.contains('kettlebell') ||
        eqNorm.contains('smith') ||
        eqNorm.contains('plate') ||
        eqNorm.contains('band')) {
      return MeasurementType.weightAndReps;
    }

    // 6. If name matches common bodyweight exercises
    if (nameNorm.contains('push') ||
        nameNorm.contains('pull') ||
        nameNorm.contains('chin') ||
        nameNorm.contains('dip') ||
        nameNorm.contains('crunch') ||
        nameNorm.contains('situp')) {
      return MeasurementType.repsOnly;
    }

    // 7. If we have a non-generic name, default to weightAndReps
    final isGeneric = nameNorm.isEmpty ||
        nameNorm == 'custom' ||
        nameNorm == 'custom exercise' ||
        nameNorm == 'unknown' ||
        nameNorm == 'exercise';
    if (!isGeneric) {
      return MeasurementType.weightAndReps;
    }

    // 8. If absolutely no metadata/match is found, default to unknown
    // (Missing metadata must never silently default to weighted)
    return MeasurementType.unknown;
  }

  bool get requiresWeight => this == MeasurementType.weightAndReps;
  bool get requiresReps =>
      this == MeasurementType.weightAndReps ||
      this == MeasurementType.repsOnly ||
      this == MeasurementType.duration;
  bool get supportsWeight => this == MeasurementType.weightAndReps;
  bool get contributesToWeightVolume => this == MeasurementType.weightAndReps;
  bool get supportsWeightPr => this == MeasurementType.weightAndReps;

  bool get isRepsOnly => this == MeasurementType.repsOnly;
  bool get isDuration => this == MeasurementType.duration;
  bool get isDistance => this == MeasurementType.distance;
  bool get isUnknown => this == MeasurementType.unknown;

  // ── Column visibility ────────────────────────────────────────────────────
  /// True when a weight / load / distance input column should be shown.
  /// Only [weightAndReps] and [distance] use the weight-slot column by default.
  bool get showsWeightColumn =>
      this == MeasurementType.weightAndReps || this == MeasurementType.distance;

  /// Returns true when a weight column should be displayed for the given
  /// [exerciseName]. Returns true for standard weighted/distance exercises and
  /// for weighted duration exercises (e.g., "Weighted Front Plank").
  bool showsWeightColumnFor([String? exerciseName]) {
    if (showsWeightColumn) return true;
    if (this == MeasurementType.duration && exerciseName != null) {
      return exerciseName.toLowerCase().contains('weighted');
    }
    return false;
  }

  /// True when a reps / count / seconds column should be shown.
  /// [distance] stores its single metric in the weight slot, so it hides
  /// the reps slot.
  bool get showsRepsColumn =>
      this != MeasurementType.distance && this != MeasurementType.unknown;

  // ── Column labels ────────────────────────────────────────────────────────
  /// Header label for the reps/duration-slot column.
  String get repsColumnLabel =>
      this == MeasurementType.duration ? 'TIME' : 'REPS';

  /// Accessibility label for the reps-slot input field.
  String get repsFieldSemanticLabel =>
      this == MeasurementType.duration ? 'Duration in seconds' : 'Reps';

  /// Fixed header label for the weight-slot column when the type is NOT
  /// [weightAndReps] (which uses the user's unit string instead).
  /// Null means: either show the user's unit label or hide the column.
  String? get fixedWeightColumnLabel =>
      this == MeasurementType.distance ? 'DIST' : null;

  /// Fixed header label for the weight-slot column taking [exerciseName] into account.
  String? fixedWeightColumnLabelFor(String? exerciseName, String unit) {
    if (this == MeasurementType.distance) return 'DIST';
    if (this == MeasurementType.duration &&
        exerciseName != null &&
        exerciseName.toLowerCase().contains('weighted')) {
      return '+${unit.toUpperCase()}';
    }
    return fixedWeightColumnLabel;
  }
}
