import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Maximum number of cached exercise media objects.
///
/// Sized against the catalog, not picked round (B19-F3). The bundled exercise
/// catalog is roughly 400 entries and the Exercise Library renders a thumbnail
/// for every row, each of which resolves through this cache. Any ceiling below
/// the catalog size means a single full scroll evicts entries by LRU faster
/// than it fills them, so the same GIFs are re-downloaded on every browse. The
/// previous value of 160 guaranteed exactly that.
const int kExerciseMediaMaxCacheObjects = 450;

/// Disk budget for cached exercise media.
///
/// [kExerciseMediaMaxCacheObjects] bounds the *count* of cached files, which is
/// what stops the thrash, but flutter_cache_manager has no byte ceiling at all
/// - so raising the count without also bounding bytes would swap one defect for
/// a worse one. At a typical 200-400 KB per exercise GIF, 450 objects lands
/// somewhere near 90-180 MB, which is too much temporary storage to take
/// silently. 120 MB is the cap; [ExerciseMediaCacheManager.performMaintenance]
/// enforces it oldest-first.
///
/// BLOCKED ON ARTIFACT: the per-GIF average is estimated, not measured. A real
/// figure from a populated cache on device would let this be tuned properly.
const int kExerciseMediaMaxCacheBytes = 120 * 1024 * 1024;

/// Sums the size of every file under [dirPath]. Top-level so it can run
/// through [compute] on a background isolate.
int _sumDirectorySizeSync(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return 0;
  int total = 0;
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File) {
      try {
        total += entity.lengthSync();
      } on FileSystemException {
        // File evicted between listing and measuring - skip it.
      }
    }
  }
  return total;
}

/// Dedicated, bounded CacheManager for exercise GIFs and media assets.
///
/// Configured with:
///  - 14-day stale period
///  - [kExerciseMediaMaxCacheObjects] max cache object count
///  - [kExerciseMediaMaxCacheBytes] disk budget, enforced by
///    [performMaintenance]
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
            maxNrOfCacheObjects: kExerciseMediaMaxCacheObjects,
            repo: JsonCacheInfoRepository(
              databaseName: 'exerciseMediaCache',
            ),
            fileService: HttpFileService(),
          ),
        );

  /// Resolves the on-disk directory backing this cache.
  ///
  /// flutter_cache_manager exposes no public accessor for its storage
  /// directory, so this reproduces its layout (`<temp>/<key>`). That
  /// assumption lives here, once, rather than being repeated at each call
  /// site - if the package ever changes its layout, this is the single place
  /// that needs updating, and callers log rather than silently reporting an
  /// empty cache.
  Future<Directory?> _resolveCacheDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(p.join(tempDir.path, key));
      if (!await cacheDir.exists()) return null;
      return cacheDir;
    } catch (e) {
      debugPrint('[ExerciseMediaCacheManager] cache dir resolve error: $e');
      return null;
    }
  }

  /// Maintenance sweep: enforces [kExerciseMediaMaxCacheBytes] by deleting the
  /// oldest cached media first.
  ///
  /// Stale-period and object-count eviction are handled by [Config]; this
  /// covers the dimension Config does not have - total bytes on disk. Deleting
  /// files directly is safe because `CacheStore` verifies that a cache
  /// object's file still exists before returning it and drops the record when
  /// it does not, so a swept file is treated as a cache miss and re-fetched.
  ///
  /// Returns the number of bytes reclaimed.
  Future<int> performMaintenance() async {
    try {
      final cacheDir = await _resolveCacheDirectory();
      if (cacheDir == null) return 0;

      final files = <File>[];
      await for (final entity
          in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) files.add(entity);
      }

      int total = 0;
      final stats = <File, FileStat>{};
      for (final file in files) {
        try {
          final stat = await file.stat();
          stats[file] = stat;
          total += stat.size;
        } on FileSystemException {
          // Vanished mid-sweep; nothing to reclaim.
        }
      }

      if (total <= kExerciseMediaMaxCacheBytes) return 0;

      final ordered = stats.keys.toList()
        ..sort((a, b) => stats[a]!.modified.compareTo(stats[b]!.modified));

      int reclaimed = 0;
      for (final file in ordered) {
        if (total - reclaimed <= kExerciseMediaMaxCacheBytes) break;
        final size = stats[file]!.size;
        try {
          await file.delete();
          reclaimed += size;
        } on FileSystemException catch (e) {
          debugPrint('[ExerciseMediaCacheManager] sweep skip ${file.path}: $e');
        }
      }

      if (reclaimed > 0) {
        debugPrint(
          '[ExerciseMediaCacheManager] swept ${reclaimed ~/ 1024} KB '
          'to stay under ${kExerciseMediaMaxCacheBytes ~/ (1024 * 1024)} MB.',
        );
      }
      return reclaimed;
    } catch (e) {
      debugPrint('[ExerciseMediaCacheManager] performMaintenance error: $e');
      return 0;
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

  /// Total size of cached exercise media in bytes.
  ///
  /// The directory walk runs through [compute] - on a full cache this is
  /// hundreds of `stat` calls, and it is invoked from Settings while the UI is
  /// interactive.
  Future<int> getCacheSizeBytes() async {
    try {
      final cacheDir = await _resolveCacheDirectory();
      if (cacheDir == null) return 0;
      return await compute(_sumDirectorySizeSync, cacheDir.path);
    } catch (e) {
      debugPrint('[ExerciseMediaCacheManager] getCacheSizeBytes error: $e');
      return 0;
    }
  }
}
