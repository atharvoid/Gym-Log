enum MeasurementType {
  weightAndReps('weight_and_reps'),
  repsOnly('reps_only'),
  duration('duration'),
  distance('distance');

  final String raw;
  const MeasurementType(this.raw);

  static MeasurementType fromString(String? val, {String? equipment}) {
    if (val != null && val.isNotEmpty) {
      final normalized = val.toLowerCase().trim();
      for (final type in values) {
        if (type.raw == normalized || type.name.toLowerCase() == normalized) {
          return type;
        }
      }
    }
    if (equipment != null && equipment.isNotEmpty) {
      final eq = equipment.toLowerCase().replaceAll(' ', '');
      if (eq == 'bodyweight' || eq == 'assisted') {
        return MeasurementType.repsOnly;
      }
    }
    return MeasurementType.weightAndReps;
  }

  bool get requiresWeight => this == MeasurementType.weightAndReps;
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
