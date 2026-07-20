enum MeasurementType {
  weightAndReps('weight_and_reps'),
  repsOnly('reps_only'),
  duration('duration'),
  distance('distance');

  final String raw;
  const MeasurementType(this.raw);

  /// Strict string parsing for stored [measurementType] raw values.
  /// Does NOT perform arbitrary equipment inference at render time.
  static MeasurementType fromString(String? val) {
    if (val != null && val.isNotEmpty) {
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
    }
    return MeasurementType.weightAndReps;
  }

  /// Legacy classifier for old database rows, catalog migration engines, and
  /// legacy imports where an explicit [measurementType] string is absent.
  static MeasurementType inferLegacyMeasurementType({
    required String? equipment,
    required String? exerciseName,
  }) {
    if (equipment != null && equipment.isNotEmpty) {
      final eqNorm = equipment
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('-', '');
      if (eqNorm == 'bodyweight' ||
          eqNorm == 'none' ||
          eqNorm == 'noequipment') {
        if (exerciseName != null) {
          final nameNorm = exerciseName.toLowerCase();
          if (nameNorm.contains('plank') ||
              nameNorm.contains('wall sit') ||
              nameNorm.contains('hold')) {
            return MeasurementType.duration;
          }
        }
        return MeasurementType.repsOnly;
      }
    }
    // Assisted counterweight machines, cables, dumbbells, barbells, etc.
    // all require numeric weight input.
    return MeasurementType.weightAndReps;
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

  // ── Column visibility ────────────────────────────────────────────────────
  /// True when a weight / load / distance input column should be shown.
  /// Only [weightAndReps] and [distance] use the weight-slot column.
  bool get showsWeightColumn =>
      this == MeasurementType.weightAndReps || this == MeasurementType.distance;

  /// True when a reps / count / seconds column should be shown.
  /// [distance] stores its single metric in the weight slot, so it hides
  /// the reps slot.
  bool get showsRepsColumn => this != MeasurementType.distance;

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
