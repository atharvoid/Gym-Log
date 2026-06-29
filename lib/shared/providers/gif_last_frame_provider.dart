import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bounded HTTP File Service that applies a per-request timeout.
class _BoundedHttpFileService extends HttpFileService {
  _BoundedHttpFileService();

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return super
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 10));
  }
}

/// Bounded CacheManager configuration for exercise GIFs.
class GymlogGifCacheManager {
  static final GymlogGifCacheManager _instance =
      GymlogGifCacheManager._internal();
  factory GymlogGifCacheManager() => _instance;

  late final CacheManager cacheManager;

  GymlogGifCacheManager._internal() {
    cacheManager = CacheManager(
      Config(
        'gymlog_gifs',
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 1000,
        fileService: _BoundedHttpFileService(),
      ),
    );
  }
}

/// Bounded concurrency semaphore to limit concurrent cache-fetch and decode.
class _SimpleSemaphore {
  final int maxConcurrency;
  int _activeCount = 0;
  final List<Completer<void>> _queue = [];

  _SimpleSemaphore(this.maxConcurrency);

  Future<void> acquire() async {
    if (_activeCount < maxConcurrency) {
      _activeCount++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    } else {
      _activeCount--;
    }
  }
}

final _gifConcurrencySemaphore = _SimpleSemaphore(4);

const _kMaxDecodeWidth = 360;

void _keepAliveOnSuccess(Ref ref) {
  final link = ref.keepAlive();
  Timer? releaseTimer;
  ref.onDispose(() => releaseTimer?.cancel());
  ref.onCancel(
      () => releaseTimer = Timer(const Duration(seconds: 60), link.close));
  ref.onResume(() => releaseTimer?.cancel());
}

final gifLastFrameProvider =
    FutureProvider.autoDispose.family<ui.Image?, String>((ref, gifUrl) async {
  ui.Image? resolvedImage;
  bool isDisposed = false;

  ref.onDispose(() {
    isDisposed = true;
    resolvedImage?.dispose();
  });

  await _gifConcurrencySemaphore.acquire();
  ui.Codec? codec;
  ui.Image? lastFrame;

  try {
    if (isDisposed) return null;

    final file = await GymlogGifCacheManager()
        .cacheManager
        .getSingleFile(gifUrl)
        .timeout(const Duration(seconds: 12));
    if (isDisposed) return null;

    final Uint8List bytes = await file.readAsBytes();
    if (isDisposed) return null;

    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _kMaxDecodeWidth,
      allowUpscaling: false,
    );
    if (isDisposed) return null;

    if (codec.frameCount == 0) return null;

    for (int i = 0; i < codec.frameCount; i++) {
      lastFrame?.dispose();
      if (isDisposed) return null;
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      lastFrame = frameInfo.image;
    }

    if (isDisposed) {
      lastFrame?.dispose();
      return null;
    }

    // Keep active reference for provider lifecycle disposal
    resolvedImage = lastFrame;
    _keepAliveOnSuccess(ref);
    return lastFrame;
  } catch (e, st) {
    debugPrint(
      '[gifLastFrameProvider] Failed to extract last frame.\n'
      '  URL  : $gifUrl\n'
      '  Error: $e\n$st',
    );
    lastFrame?.dispose();
    return null;
  } finally {
    codec?.dispose();
    _gifConcurrencySemaphore.release();
  }
});

final gifFirstFrameProvider =
    FutureProvider.autoDispose.family<ui.Image?, String>((ref, gifUrl) async {
  ui.Image? resolvedImage;
  bool isDisposed = false;

  ref.onDispose(() {
    isDisposed = true;
    resolvedImage?.dispose();
  });

  await _gifConcurrencySemaphore.acquire();
  ui.Codec? codec;
  ui.Image? frame;

  try {
    if (isDisposed) return null;

    final file = await GymlogGifCacheManager()
        .cacheManager
        .getSingleFile(gifUrl)
        .timeout(const Duration(seconds: 12));
    if (isDisposed) return null;

    final Uint8List bytes = await file.readAsBytes();
    if (isDisposed) return null;

    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _kMaxDecodeWidth,
      allowUpscaling: false,
    );
    if (isDisposed) return null;

    if (codec.frameCount == 0) return null;

    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    frame = frameInfo.image;

    if (isDisposed) {
      frame.dispose();
      return null;
    }

    resolvedImage = frame;
    _keepAliveOnSuccess(ref);
    return frame;
  } catch (e, st) {
    debugPrint(
      '[gifFirstFrameProvider] Failed to extract first frame.\n'
      '  URL  : $gifUrl\n'
      '  Error: $e\n$st',
    );
    frame?.dispose();
    return null;
  } finally {
    codec?.dispose();
    _gifConcurrencySemaphore.release();
  }
});
