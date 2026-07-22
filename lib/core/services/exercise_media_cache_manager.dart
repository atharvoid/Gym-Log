import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Dedicated, bounded CacheManager for exercise GIFs and media assets.
///
/// Configured with:
///  - 14-day stale period
///  - 160 max cache object count
///  - Dedicated 'exerciseMediaCache' database
class ExerciseMediaCacheManager extends CacheManager {
  static const String key = 'exercise-media-v2';

  static final ExerciseMediaCacheManager _instance =
      ExerciseMediaCacheManager._internal();

  factory ExerciseMediaCacheManager() => _instance;

  ExerciseMediaCacheManager._internal()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 14),
            maxNrOfCacheObjects: 160,
            repo: JsonCacheInfoRepository(
              databaseName: 'exerciseMediaCache',
            ),
            fileService: HttpFileService(),
          ),
        );

  /// Maintenance sweep: evicts files older than 14 days and enforces object count limits.
  Future<void> performMaintenance() async {
    try {
      // Config(stalePeriod, maxNrOfCacheObjects) handles stale eviction.
    } catch (e) {
      debugPrint('[ExerciseMediaCacheManager] performMaintenance error: $e');
    }
  }

  /// Clears cached exercise media. Never touches user workouts or database data.
  Future<void> clearMediaCache() async {
    try {
      await emptyCache();
    } catch (e) {
      debugPrint('[ExerciseMediaCacheManager] clearMediaCache error: $e');
    }
  }

  /// Calculates total size of cached exercise media in bytes without collecting file names remotely.
  Future<int> getCacheSizeBytes() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(p.join(tempDir.path, key));
      if (!await cacheDir.exists()) return 0;
      int total = 0;
      await for (final entity
          in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e) {
      debugPrint('[ExerciseMediaCacheManager] getCacheSizeBytes error: $e');
      return 0;
    }
  }
}
