enum PersonalRecordType {
  estimatedOneRepMax,
  maxWeight,
  maxReps,
  maxDuration,
  maxDistance,
  bestPace,
}

class PersonalRecord {
  final PersonalRecordType type;
  final int exerciseId;
  final String exerciseName;
  final double value;
  final String unit;
  final String setId;
  final double? previousValue;

  const PersonalRecord({
    required this.type,
    required this.exerciseId,
    required this.exerciseName,
    required this.value,
    required this.unit,
    required this.setId,
    this.previousValue,
  });

  /// Backwards compatibility getters for PrRecord callers.
  double get weightKg => (type == PersonalRecordType.estimatedOneRepMax ||
          type == PersonalRecordType.maxWeight)
      ? value
      : 0.0;

  int get reps => (type == PersonalRecordType.maxReps ||
          type == PersonalRecordType.maxDuration)
      ? value.toInt()
      : 0;

  double get estimated1rm =>
      type == PersonalRecordType.estimatedOneRepMax ? value : 0.0;

  double get previousBest1rm => previousValue ?? 0.0;
}

typedef PrRecord = PersonalRecord;
