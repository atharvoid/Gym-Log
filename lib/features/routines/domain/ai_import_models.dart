import 'package:flutter/foundation.dart';

/// Reconciliation confidence status for an extracted exercise.
enum ReconciliationStatus {
  /// Confidently matched to a catalog exercise.
  verified,

  /// Moderate confidence match (needs user confirmation or swap).
  suggested,

  /// Novel or unrecognized exercise (will be created as custom or searched).
  unmatched,
}

/// Raw exercise data extracted by the multimodal model.
@immutable
class RawExtractedExercise {
  const RawExtractedExercise({
    required this.rawName,
    this.sets,
    this.reps,
    this.weight,
    this.weightUnit,
    this.restSeconds,
    this.notes,
  });

  final String rawName;
  final int? sets;
  final String? reps;
  final double? weight;
  final String? weightUnit;
  final int? restSeconds;
  final String? notes;

  factory RawExtractedExercise.fromJson(Map<String, dynamic> json) {
    int? parseSets(dynamic val) {
      if (val is int && val > 0) return val;
      if (val is num && val > 0) return val.toInt();
      if (val is String) {
        final parsed = int.tryParse(val);
        if (parsed != null && parsed > 0) return parsed;
      }
      return null;
    }

    double? parseWeight(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned);
      }
      return null;
    }

    return RawExtractedExercise(
      rawName: (json['rawName'] as String?)?.trim() ?? '',
      sets: parseSets(json['sets']),
      reps: (json['reps'] as String?)?.trim(),
      weight: parseWeight(json['weight']),
      weightUnit: (json['weightUnit'] as String?)?.trim().toLowerCase(),
      restSeconds: (json['restSeconds'] as num?)?.toInt(),
      notes: (json['notes'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rawName': rawName,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        if (weightUnit != null) 'weightUnit': weightUnit,
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (notes != null) 'notes': notes,
      };
}

/// Raw training day grouping extracted by the multimodal model.
@immutable
class RawExtractedDay {
  const RawExtractedDay({
    required this.dayName,
    required this.exercises,
  });

  final String dayName;
  final List<RawExtractedExercise> exercises;

  factory RawExtractedDay.fromJson(Map<String, dynamic> json) {
    final rawExercises = (json['exercises'] as List?) ?? [];
    return RawExtractedDay(
      dayName: (json['dayName'] as String?)?.trim() ?? 'Day 1',
      exercises: rawExercises
          .map((e) => RawExtractedExercise.fromJson(e as Map<String, dynamic>))
          .where((e) => e.rawName.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayName': dayName,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

/// Raw routine extracted by the multimodal model.
@immutable
class RawExtractedRoutine {
  const RawExtractedRoutine({
    required this.routineName,
    required this.days,
  });

  final String routineName;
  final List<RawExtractedDay> days;

  factory RawExtractedRoutine.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List?) ?? [];
    final daysList = rawDays
        .map((d) => RawExtractedDay.fromJson(d as Map<String, dynamic>))
        .where((d) => d.exercises.isNotEmpty)
        .toList();

    return RawExtractedRoutine(
      routineName:
          (json['routineName'] as String?)?.trim() ?? 'Imported Routine',
      days: daysList.isNotEmpty
          ? daysList
          : const [
              RawExtractedDay(
                dayName: 'Day 1',
                exercises: [],
              ),
            ],
    );
  }

  Map<String, dynamic> toJson() => {
        'routineName': routineName,
        'days': days.map((d) => d.toJson()).toList(),
      };
}

/// A suggested catalog candidate for an exercise that was not a perfect match.
@immutable
class ExerciseSuggestion {
  const ExerciseSuggestion({
    required this.id,
    required this.name,
    this.equipment = '',
    this.bodyPart = '',
    this.gifUrl,
    this.confidenceScore = 0.0,
  });

  final int id;
  final String name;
  final String equipment;
  final String bodyPart;
  final String? gifUrl;
  final double confidenceScore;
}

/// An exercise that has been resolved against GymLog's local catalog
/// and prepared for human review and atomic saving.
@immutable
class ReconciledExercise {
  const ReconciledExercise({
    required this.rawName,
    this.matchedExerciseId,
    this.matchedExerciseName,
    this.matchedEquipment,
    this.matchedBodyPart,
    this.matchedGifUrl,
    required this.status,
    this.confidenceScore = 0.0,
    this.sets = 3,
    this.isDefaultedSets = false,
    this.defaultReps,
    this.rawReps,
    this.defaultWeightKg,
    this.restSeconds,
    this.notes,
    this.suggestions = const [],
  });

  final String rawName;
  final int? matchedExerciseId;
  final String? matchedExerciseName;
  final String? matchedEquipment;
  final String? matchedBodyPart;
  final String? matchedGifUrl;
  final ReconciliationStatus status;
  final double confidenceScore;
  final int sets;
  final bool isDefaultedSets;
  final int? defaultReps;
  final String? rawReps;
  final double? defaultWeightKg;
  final int? restSeconds;
  final String? notes;
  final List<ExerciseSuggestion> suggestions;

  bool get isVerified => status == ReconciliationStatus.verified;
  bool get isSuggested => status == ReconciliationStatus.suggested;
  bool get isUnmatched => status == ReconciliationStatus.unmatched;

  /// Returns the display title: matched catalog name or original raw name.
  String get displayName => matchedExerciseName ?? rawName;

  ReconciledExercise copyWith({
    String? rawName,
    int? matchedExerciseId,
    String? matchedExerciseName,
    String? matchedEquipment,
    String? matchedBodyPart,
    String? matchedGifUrl,
    ReconciliationStatus? status,
    double? confidenceScore,
    int? sets,
    bool? isDefaultedSets,
    int? defaultReps,
    String? rawReps,
    double? defaultWeightKg,
    int? restSeconds,
    String? notes,
    List<ExerciseSuggestion>? suggestions,
  }) {
    return ReconciledExercise(
      rawName: rawName ?? this.rawName,
      matchedExerciseId: matchedExerciseId ?? this.matchedExerciseId,
      matchedExerciseName: matchedExerciseName ?? this.matchedExerciseName,
      matchedEquipment: matchedEquipment ?? this.matchedEquipment,
      matchedBodyPart: matchedBodyPart ?? this.matchedBodyPart,
      matchedGifUrl: matchedGifUrl ?? this.matchedGifUrl,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sets: sets ?? this.sets,
      isDefaultedSets: isDefaultedSets ?? this.isDefaultedSets,
      defaultReps: defaultReps ?? this.defaultReps,
      rawReps: rawReps ?? this.rawReps,
      defaultWeightKg: defaultWeightKg ?? this.defaultWeightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

/// A day of reconciled exercises.
@immutable
class ReconciledDay {
  const ReconciledDay({
    required this.dayName,
    required this.exercises,
  });

  final String dayName;
  final List<ReconciledExercise> exercises;

  ReconciledDay copyWith({
    String? dayName,
    List<ReconciledExercise>? exercises,
  }) {
    return ReconciledDay(
      dayName: dayName ?? this.dayName,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// A complete reconciled routine ready for user review.
@immutable
class ReconciledRoutine {
  const ReconciledRoutine({
    required this.routineName,
    required this.days,
  });

  final String routineName;
  final List<ReconciledDay> days;

  bool get isMultiDay => days.length > 1;

  ReconciledRoutine copyWith({
    String? routineName,
    List<ReconciledDay>? days,
  }) {
    return ReconciledRoutine(
      routineName: routineName ?? this.routineName,
      days: days ?? this.days,
    );
  }
}
