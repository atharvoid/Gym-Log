import 'ai_import_models.dart';
import 'exercise_resolver.dart';
import '../data/exercise_alias_catalog.dart';

/// Reconciles raw AI-extracted exercises against GymLog's local catalog.
/// Implements a 4-tier cascade:
///  Tier 1: Canonical Gym Slang and Alias Dictionary
///  Tier 2: Equipment and Movement Isolation
///  Tier 3: Tokenized Fuzzy Scoring Floor (_kFuzzyMatchFloor = 0.6)
///  Tier 4: Zero-loss Unmatched Flagging (ready for Custom Exercise creation)
class AiExerciseReconciler {
  AiExerciseReconciler({
    required List<ResolvedExercise> catalog,
  }) : _resolver = ExerciseResolver(catalog);

  final ExerciseResolver _resolver;

  /// Reconciles a single raw extracted exercise into a [ReconciledExercise].
  ReconciledExercise reconcileExercise(
    RawExtractedExercise raw, {
    String targetUnit = 'kg',
  }) {
    final rawNameInput = raw.rawName.trim();
    if (rawNameInput.isEmpty) {
      return ReconciledExercise(
        rawName: 'Unknown Exercise',
        status: ReconciliationStatus.unmatched,
        sets: raw.sets != null && raw.sets! > 0 ? raw.sets! : 3,
        isDefaultedSets: raw.sets == null,
      );
    }

    final cleanedRawName = _cleanRawName(rawNameInput);
    final effectiveName =
        cleanedRawName.isNotEmpty ? cleanedRawName : rawNameInput;

    // Tier 1: Canonical Alias Expansion
    final expandedName = ExerciseAliasCatalog.expandTokens(effectiveName);

    // Tier 2 & 3: Movement + Equipment-Aware Catalog Match with Suggestions
    final resExpanded = _resolver.resolveWithSuggestions(expandedName);
    final resCleaned = _resolver.resolveWithSuggestions(effectiveName);
    final matched = resExpanded.match ?? resCleaned.match;
    final candidateSuggestions = resExpanded.suggestions.isNotEmpty
        ? resExpanded.suggestions
        : resCleaned.suggestions;

    final suggestions = candidateSuggestions
        .map((s) => ExerciseSuggestion(
              id: s.exercise.id,
              name: s.exercise.name,
              equipment: s.exercise.equipment,
              bodyPart: s.exercise.bodyPart,
              gifUrl: s.exercise.gifUrl,
              confidenceScore: s.score,
            ))
        .toList();

    ReconciliationStatus status = ReconciliationStatus.unmatched;
    double confidence = 0.0;
    ResolvedExercise? targetExercise;

    if (matched != null) {
      final inputEquipment =
          _detectEquipment(effectiveName) ?? _detectEquipment(expandedName);
      final matchedEquip = matched.equipment.toLowerCase();

      // Check equipment compatibility
      final isEquipConflict = inputEquipment != null &&
          matchedEquip.isNotEmpty &&
          inputEquipment != matchedEquip &&
          inputEquipment != 'other' &&
          matchedEquip != 'other';

      if (!isEquipConflict) {
        targetExercise = matched;
        final exactNormalized = normalizeExerciseName(matched.name);
        final inputNormalized = normalizeExerciseName(expandedName);

        if (exactNormalized == inputNormalized ||
            ExerciseAliasCatalog.aliases
                .containsKey(effectiveName.toLowerCase())) {
          status = ReconciliationStatus.verified;
          confidence = 1.0;
        } else {
          status = ReconciliationStatus.verified;
          confidence = 0.85;
        }
      }
    }

    // Parse sets: if null or <= 0, default to 3 and flag isDefaultedSets
    final isDefaulted = raw.sets == null || raw.sets! <= 0;
    final sets = isDefaulted ? 3 : raw.sets!;

    // Parse reps
    final defaultReps = _parseRepresentativeReps(raw.reps);

    // Parse and convert weight
    final defaultWeightKg = _parseWeightInKg(
      weight: raw.weight,
      weightUnit: raw.weightUnit,
      targetUnit: targetUnit,
    );

    return ReconciledExercise(
      rawName: effectiveName,
      matchedExerciseId: targetExercise?.id,
      matchedExerciseName: targetExercise?.name,
      matchedEquipment: targetExercise?.equipment,
      matchedBodyPart: targetExercise?.bodyPart,
      matchedGifUrl: targetExercise?.gifUrl,
      status: status,
      confidenceScore: confidence,
      sets: sets,
      isDefaultedSets: isDefaulted,
      defaultReps: defaultReps,
      rawReps: raw.reps,
      defaultWeightKg: defaultWeightKg,
      restSeconds: raw.restSeconds,
      notes: raw.notes,
      suggestions: suggestions,
    );
  }

  static String _cleanRawName(String raw) {
    var s = raw.trim();
    // Strip superset tags e.g. "A1. ", "B2. ", "1. ", "2a. "
    s = s.replaceAll(
        RegExp(r'^[A-Za-z]?[0-9]+[a-z]?[\.\)\-]\s*', caseSensitive: false), '');
    // Strip coach styles e.g. "N1-Style ", "RP-Style "
    s = s.replaceAll(
        RegExp(r'^(n1-style|rp-style|joe bennett style)\s*',
            caseSensitive: false),
        '');
    // Strip ROM cues e.g. "Squeeze-Only ", "Stretch-Only "
    s = s.replaceAll(
        RegExp(r'^(squeeze-only|stretch-only)\s*', caseSensitive: false), '');
    // Strip muscle annotations e.g. "(Side Delt)", "(Upper Pec)"
    s = s.replaceAll(
        RegExp(
            r'\((side delt|front delt|rear delt|lats|chest|pecs|upper pec|long head|biceps|triceps)[^\)]*\)',
            caseSensitive: false),
        '');
    // Strip trailing durations like " 30s", " 45s"
    s = s.replaceAll(RegExp(r'\s+[0-9]+s$', caseSensitive: false), '');
    return s.trim();
  }

  /// Reconciles an entire multi-day or single-day extracted routine.
  ReconciledRoutine reconcileRoutine(
    RawExtractedRoutine rawRoutine, {
    String targetUnit = 'kg',
  }) {
    final reconciledDays = rawRoutine.days.map((day) {
      final reconciledExercises = day.exercises
          .map((e) => reconcileExercise(e, targetUnit: targetUnit))
          .toList();
      return ReconciledDay(
        dayName: day.dayName,
        exercises: reconciledExercises,
      );
    }).toList();

    return ReconciledRoutine(
      routineName: rawRoutine.routineName,
      days: reconciledDays,
    );
  }

  // ── Helper parsing methods ─────────────────────────────────────────────────

  static String? _detectEquipment(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dumbbell') || lower.contains(' db')) return 'dumbbell';
    if (lower.contains('barbell') || lower.contains(' bb')) return 'barbell';
    if (lower.contains('cable')) return 'cable';
    if (lower.contains('machine') || lower.contains('smith')) return 'machine';
    if (lower.contains('kettlebell')) return 'kettlebell';
    if (lower.contains('bodyweight') || lower.contains('body weight')) {
      return 'bodyweight';
    }
    return null;
  }

  static int? _parseRepresentativeReps(String? repsString) {
    if (repsString == null || repsString.trim().isEmpty) return null;
    final trimmed = repsString.trim();

    // Check for ranges: "8-12", "8 - 12", "8-10"
    final rangeMatch =
        RegExp(r'(\d+)\s*[-\u2013\u2014]\s*(\d+)').firstMatch(trimmed);
    if (rangeMatch != null) {
      final low = int.tryParse(rangeMatch.group(1)!);
      final high = int.tryParse(rangeMatch.group(2)!);
      if (low != null && high != null) {
        return ((low + high) / 2).round();
      }
    }

    // Check for comma lists (e.g. "12, 10, 8, 6") -> take first or average
    if (trimmed.contains(',')) {
      final parts = trimmed
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      if (parts.isNotEmpty) {
        return parts.first;
      }
    }

    // Single number extraction
    final numberMatch = RegExp(r'\d+').firstMatch(trimmed);
    if (numberMatch != null) {
      return int.tryParse(numberMatch.group(0)!);
    }

    return null;
  }

  static double? _parseWeightInKg({
    required double? weight,
    required String? weightUnit,
    required String targetUnit,
  }) {
    if (weight == null || weight <= 0) return null;
    final explicitUnit = weightUnit?.toLowerCase().trim();

    final isPounds = explicitUnit == 'lbs' ||
        explicitUnit == 'lb' ||
        (explicitUnit == null && (targetUnit == 'lbs' || targetUnit == 'lb'));

    if (isPounds) {
      final kg = weight * 0.45359237;
      return (kg * 2).roundToDouble() / 2; // round to nearest 0.5 kg
    }

    return (weight * 2).roundToDouble() / 2;
  }
}
