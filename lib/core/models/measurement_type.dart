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

  /// Authoritative measurement type resolver.
  /// Valid explicit metadata wins; otherwise legacy inference runs.
  static MeasurementType resolve({
    required String? explicitValue,
    required String? equipment,
    required String? exerciseName,
  }) {
    final parsed = tryParse(explicitValue);
    if (parsed != null) {
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
    if (nameNorm.contains('hold') ||
        nameNorm.contains('plank') ||
        nameNorm.contains('wall sit')) {
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
  /// Only [weightAndReps] and [distance] use the weight-slot column.
  bool get showsWeightColumn =>
      this == MeasurementType.weightAndReps || this == MeasurementType.distance;

  /// True when a reps / count / seconds column should be shown.
  /// [distance] stores its single metric in the weight slot, so it hides
  /// the reps slot.
  bool get showsRepsColumn =>
      this != MeasurementType.distance && this != MeasurementType.unknown;

  // ── Column labels ────────────────────────────────────────────────────────
  /// Header label for the reps-slot column.
  String get repsColumnLabel =>
      this == MeasurementType.duration ? 'SECS' : 'REPS';

  /// Accessibility label for the reps-slot input field.
  String get repsFieldSemanticLabel =>
      this == MeasurementType.duration ? 'Duration in seconds' : 'Reps';

  /// Fixed header label for the weight-slot column when the type is NOT
  /// [weightAndReps] (which uses the user's unit string instead).
  /// Null means: either show the user's unit label or hide the column.
  String? get fixedWeightColumnLabel =>
      this == MeasurementType.distance ? 'DIST' : null;
}
