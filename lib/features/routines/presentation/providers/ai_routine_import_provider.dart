import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/domain/ai_exercise_reconciler.dart';
import 'package:gymlog/features/routines/domain/ai_import_models.dart';
import 'package:gymlog/features/routines/domain/exercise_resolver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AiImportStatus {
  idle,
  compressing,
  analyzing,
  success,
  saving,
  error,
}

class AiRoutineImportState {
  const AiRoutineImportState({
    this.status = AiImportStatus.idle,
    this.reconciledRoutine,
    this.selectedImageBytes,
    this.selectedImageName,
    this.textInput = '',
    this.errorMessage,
  });

  final AiImportStatus status;
  final ReconciledRoutine? reconciledRoutine;
  final Uint8List? selectedImageBytes;
  final String? selectedImageName;
  final String textInput;
  final String? errorMessage;

  bool get isLoading =>
      status == AiImportStatus.compressing ||
      status == AiImportStatus.analyzing ||
      status == AiImportStatus.saving;

  bool get canAnalyze =>
      (selectedImageBytes != null || textInput.trim().isNotEmpty) && !isLoading;

  AiRoutineImportState copyWith({
    AiImportStatus? status,
    ReconciledRoutine? reconciledRoutine,
    Uint8List? selectedImageBytes,
    String? selectedImageName,
    String? textInput,
    String? errorMessage,
    bool clearImage = false,
  }) {
    return AiRoutineImportState(
      status: status ?? this.status,
      reconciledRoutine: reconciledRoutine ?? this.reconciledRoutine,
      selectedImageBytes:
          clearImage ? null : (selectedImageBytes ?? this.selectedImageBytes),
      selectedImageName:
          clearImage ? null : (selectedImageName ?? this.selectedImageName),
      textInput: textInput ?? this.textInput,
      errorMessage: errorMessage,
    );
  }
}

final aiRoutineImportProvider =
    StateNotifierProvider<AiRoutineImportNotifier, AiRoutineImportState>((ref) {
  return AiRoutineImportNotifier(ref);
});

class AiRoutineImportNotifier extends StateNotifier<AiRoutineImportState> {
  AiRoutineImportNotifier(this._ref) : super(const AiRoutineImportState());

  final Ref _ref;

  void setImage(Uint8List bytes, String name) {
    state = state.copyWith(
      selectedImageBytes: bytes,
      selectedImageName: name,
      errorMessage: null,
    );
  }

  void clearImage() {
    state = state.copyWith(
      clearImage: true,
      errorMessage: null,
    );
  }

  void setTextInput(String text) {
    state = state.copyWith(
      textInput: text,
      errorMessage: null,
    );
  }

  void reset() {
    state = const AiRoutineImportState();
  }

  /// Compresses input image (if present) and calls the Supabase edge function.
  /// Reconciles output against GymLog's local catalog.
  Future<bool> analyze() async {
    if (!state.canAnalyze) return false;

    state = state.copyWith(
      status: AiImportStatus.compressing,
      errorMessage: null,
    );

    try {
      String? base64Image;
      if (state.selectedImageBytes != null) {
        Uint8List compressed = state.selectedImageBytes!;
        try {
          final result = await FlutterImageCompress.compressWithList(
            compressed,
            minWidth: 1600,
            minHeight: 1600,
            quality: 85,
          );
          if (result.isNotEmpty) {
            compressed = result;
          }
        } catch (_) {
          // If compression fails, fall back to uncompressed bytes
        }
        base64Image = base64Encode(compressed);
      }

      state = state.copyWith(status: AiImportStatus.analyzing);

      final payload = <String, dynamic>{};
      if (base64Image != null) {
        payload['imageBase64'] = base64Image;
        payload['imageMimeType'] = 'image/jpeg';
      }
      if (state.textInput.trim().isNotEmpty) {
        payload['text'] = state.textInput.trim();
      }

      // Invoke Supabase Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'ai-import-routine',
        body: payload,
      );

      if (response.status != 200) {
        if (response.status == 429) {
          state = state.copyWith(
            status: AiImportStatus.error,
            errorMessage:
                'AI import is temporarily busy. Please wait a minute and try again.',
          );
          return false;
        }

        final data = response.data;
        final msg = data is Map ? data['error']?.toString() : null;
        state = state.copyWith(
          status: AiImportStatus.error,
          errorMessage: msg ?? 'Failed to analyze routine. Please try again.',
        );
        return false;
      }

      final rawData = response.data;
      if (rawData is! Map<String, dynamic>) {
        state = state.copyWith(
          status: AiImportStatus.error,
          errorMessage: 'Unrecognized response format from AI service.',
        );
        return false;
      }

      final rawRoutine = RawExtractedRoutine.fromJson(rawData);

      // Fetch local catalog for grounding
      final db = _ref.read(databaseProvider);
      final catalogExercises = await db.exercisesDao.getAllExercises();
      final resolvedCatalog = catalogExercises
          .map((e) => ResolvedExercise(
                id: e.id,
                name: e.name,
                target: e.target,
                equipment: e.equipment,
                bodyPart: e.bodyPart,
                gifUrl: e.gifUrl,
              ))
          .toList();

      final userUnit = _ref.read(weightUnitProvider);
      final reconciler = AiExerciseReconciler(catalog: resolvedCatalog);
      final reconciled =
          reconciler.reconcileRoutine(rawRoutine, targetUnit: userUnit);

      state = state.copyWith(
        status: AiImportStatus.success,
        reconciledRoutine: reconciled,
      );
      return true;
    } on FunctionException catch (e) {
      final msg = e.status == 429
          ? 'AI import is temporarily busy. Please wait a minute and try again.'
          : (e.details?.toString() ?? e.reasonPhrase ?? 'Service error');
      state = state.copyWith(
        status: AiImportStatus.error,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AiImportStatus.error,
        errorMessage:
            'Could not complete AI analysis. Please check your network.',
      );
      return false;
    }
  }

  // ── Review Screen Mutations ────────────────────────────────────────────────

  void updateRoutineName(String name) {
    if (state.reconciledRoutine == null) return;
    state = state.copyWith(
      reconciledRoutine:
          state.reconciledRoutine!.copyWith(routineName: name.trim()),
    );
  }

  void updateExercise(int dayIndex, int exIndex, ReconciledExercise updated) {
    if (state.reconciledRoutine == null) return;
    final routine = state.reconciledRoutine!;
    if (dayIndex >= routine.days.length) return;

    final day = routine.days[dayIndex];
    if (exIndex >= day.exercises.length) return;

    final updatedExercises = List<ReconciledExercise>.from(day.exercises);
    updatedExercises[exIndex] = updated;

    final updatedDays = List<ReconciledDay>.from(routine.days);
    updatedDays[dayIndex] = day.copyWith(exercises: updatedExercises);

    state = state.copyWith(
      reconciledRoutine: routine.copyWith(days: updatedDays),
    );
  }

  void linkExercise(int dayIndex, int exIndex, ExerciseSuggestion suggestion) {
    if (state.reconciledRoutine == null) return;
    final routine = state.reconciledRoutine!;
    if (dayIndex >= routine.days.length) return;
    final day = routine.days[dayIndex];
    if (exIndex >= day.exercises.length) return;

    final target = day.exercises[exIndex];
    final updated = target.copyWith(
      matchedExerciseId: suggestion.id,
      matchedExerciseName: suggestion.name,
      matchedEquipment: suggestion.equipment,
      matchedBodyPart: suggestion.bodyPart,
      matchedGifUrl: suggestion.gifUrl,
      status: ReconciliationStatus.verified,
      confidenceScore: 1.0,
      suggestions: const [],
    );
    updateExercise(dayIndex, exIndex, updated);
  }

  void removeExercise(int dayIndex, int exIndex) {
    if (state.reconciledRoutine == null) return;
    final routine = state.reconciledRoutine!;
    if (dayIndex >= routine.days.length) return;

    final day = routine.days[dayIndex];
    if (exIndex >= day.exercises.length) return;

    final updatedExercises = List<ReconciledExercise>.from(day.exercises)
      ..removeAt(exIndex);

    final updatedDays = List<ReconciledDay>.from(routine.days);
    updatedDays[dayIndex] = day.copyWith(exercises: updatedExercises);

    state = state.copyWith(
      reconciledRoutine: routine.copyWith(days: updatedDays),
    );
  }

  void reorderExercises(int dayIndex, int oldIndex, int newIndex) {
    if (state.reconciledRoutine == null) return;
    final routine = state.reconciledRoutine!;
    if (dayIndex >= routine.days.length) return;

    final day = routine.days[dayIndex];
    final exercises = [...day.exercises];
    if (oldIndex < 0 || oldIndex >= exercises.length) return;
    final target = newIndex.clamp(0, exercises.length - 1);
    final item = exercises.removeAt(oldIndex);
    exercises.insert(target, item);

    final updatedDays = List<ReconciledDay>.from(routine.days);
    updatedDays[dayIndex] = day.copyWith(exercises: exercises);

    state = state.copyWith(
      reconciledRoutine: routine.copyWith(days: updatedDays),
    );
  }

  void addExercise(int dayIndex, Exercise catalogExercise) {
    if (state.reconciledRoutine == null) return;
    final routine = state.reconciledRoutine!;
    if (dayIndex >= routine.days.length) return;

    final day = routine.days[dayIndex];
    final newReconciled = ReconciledExercise(
      rawName: catalogExercise.name,
      matchedExerciseId: catalogExercise.id,
      matchedExerciseName: catalogExercise.name,
      matchedEquipment: catalogExercise.equipment,
      matchedBodyPart: catalogExercise.bodyPart,
      matchedGifUrl: catalogExercise.gifUrl,
      status: ReconciliationStatus.verified,
      confidenceScore: 1.0,
      sets: 3,
    );

    final updated = List<ReconciledExercise>.from(day.exercises)
      ..add(newReconciled);

    final updatedDays = List<ReconciledDay>.from(routine.days);
    updatedDays[dayIndex] = day.copyWith(exercises: updated);

    state = state.copyWith(
      reconciledRoutine: routine.copyWith(days: updatedDays),
    );
  }

  /// Persists the reconciled routine atomically to SQLite and enqueues sync.
  Future<String?> saveRoutine() async {
    final routine = state.reconciledRoutine;
    if (routine == null) return null;

    state = state.copyWith(status: AiImportStatus.saving);

    try {
      final user = _ref.read(authProvider);
      final userId = user?.id ?? 'local_user';
      final db = _ref.read(databaseProvider);

      final routineId = await db.routinesDao.saveReconciledRoutine(
        userId: userId,
        routine: routine,
      );

      state = state.copyWith(status: AiImportStatus.idle);
      return routineId;
    } catch (e) {
      state = state.copyWith(
        status: AiImportStatus.error,
        errorMessage: 'Failed to save routine to database: $e',
      );
      return null;
    }
  }
}
