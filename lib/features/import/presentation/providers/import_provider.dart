import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/import/data/workout_import_service.dart';

/// Shared [WorkoutImportService] bound to the app's single database instance.
final workoutImportServiceProvider = Provider<WorkoutImportService>(
  (ref) => WorkoutImportService(ref.watch(databaseProvider)),
);
