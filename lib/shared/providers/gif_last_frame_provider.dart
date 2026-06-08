import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [gif_last_frame_provider.dart]
/// Decodes a GIF from the on-disk cache (populated by CachedNetworkImage) and
/// returns the last frame as a [MemoryImage] ready for use in [Image] widgets.
///
/// Why last frame?
///   Exercise GIFs typically end at the rest/start position — the same visual
///   as frame 0 for most clips. Showing the last frame guarantees a clean,
///   consistent still regardless of how far the animation advanced elsewhere.
///
/// Why Riverpod FutureProvider.family?
///   Results are keyed by URL and cached for the container lifetime.
///   Navigating away and back never re-decodes; the same [MemoryImage] is
///   returned immediately from Riverpod's internal cache.
///
/// Why flutter_cache_manager?
///   It shares the same on-disk cache as CachedNetworkImage (both use
///   DefaultCacheManager), so the GIF bytes are never re-downloaded.

final gifLastFrameProvider =
    FutureProvider.family<MemoryImage?, String>((ref, gifUrl) async {
  try {
    // ── 1. Pull bytes from the shared on-disk cache ───────────────────────────
    // getSingleFile returns the cached file if available, otherwise downloads.
    final file = await DefaultCacheManager().getSingleFile(gifUrl);
    final Uint8List bytes = await file.readAsBytes();

    // ── 2. Decode with dart:ui codec ─────────────────────────────────────────
    // instantiateImageCodec understands GIF animation natively and exposes
    // frameCount so we can seek precisely to the last frame.
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);

    if (codec.frameCount == 0) return null;

    // ── 3. Advance to the last frame ──────────────────────────────────────────
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    for (int i = 1; i < codec.frameCount; i++) {
      frameInfo = await codec.getNextFrame();
    }

    // ── 4. Encode last frame → PNG bytes → MemoryImage ────────────────────────
    // toByteData with PNG format gives us a self-contained, lossless snapshot
    // of the last frame that Image.memory can display without a codec.
    final ByteData? byteData = await frameInfo.image
        .toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    codec.dispose();

    return MemoryImage(byteData.buffer.asUint8List());
  } catch (e, st) {
    debugPrint(
      '[gifLastFrameProvider] Failed to extract last frame.\n'
      '  URL  : $gifUrl\n'
      '  Error: $e\n$st',
    );
    return null;
  }
});
