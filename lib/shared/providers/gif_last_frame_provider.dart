import 'dart:async';
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
///
/// Resource discipline:
///   * Frames are decoded at a bounded [_kMaxDecodeWidth] — the static branch
///     only ever renders list thumbnails (≤64dp), so decoding a source GIF at
///     full resolution wastes CPU and native memory for zero visual gain.
///   * Every intermediate [ui.Image] and the [ui.Codec] are disposed on ALL
///     paths (success, early-return, exception) via try/finally. Undisposed
///     codecs pin native buffers until a GC finalizer eventually runs.

/// Upper bound for decoded frame width. 360 physical px covers a 120dp
/// thumbnail at 3x — comfortably above anything the static branch renders.
const _kMaxDecodeWidth = 360;

final gifLastFrameProvider = FutureProvider.autoDispose
    .family<MemoryImage?, String>((ref, gifUrl) async {
  // Bound memory: keep the decoded frame ~60s after the last watcher detaches
  // (so a quick scroll-back doesn't re-decode), then release it. Re-decode
  // from the shared on-disk cache is cheap. This replaces an unbounded
  // per-URL PNG cache that grew with every distinct exercise a user logged.
  final link = ref.keepAlive();
  Timer? releaseTimer;
  ref.onDispose(() => releaseTimer?.cancel());
  ref.onCancel(
      () => releaseTimer = Timer(const Duration(seconds: 60), link.close));
  ref.onResume(() => releaseTimer?.cancel());

  ui.Codec? codec;
  ui.Image? lastFrame;
  try {
    // ── 1. Pull bytes from the shared on-disk cache ───────────────────────
    // getSingleFile returns the cached file if available, otherwise downloads.
    final file = await DefaultCacheManager().getSingleFile(gifUrl);
    final Uint8List bytes = await file.readAsBytes();

    // ── 2. Decode with dart:ui codec, capped at thumbnail scale ───────────
    // instantiateImageCodec understands GIF animation natively and exposes
    // frameCount so we can seek precisely to the last frame.
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _kMaxDecodeWidth,
      allowUpscaling: false, // small sources decode at native size
    );

    if (codec.frameCount == 0) return null;

    // ── 3. Advance to the last frame, releasing every frame we skip ───────
    for (int i = 0; i < codec.frameCount; i++) {
      lastFrame?.dispose();
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      lastFrame = frameInfo.image;
    }

    // ── 4. Encode last frame → PNG bytes → MemoryImage ────────────────────
    // PNG gives a self-contained, lossless snapshot Image.memory can display
    // without holding a codec, and keeps the Riverpod cache entry compact.
    final ByteData? byteData =
        await lastFrame!.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    return MemoryImage(byteData.buffer.asUint8List());
  } catch (e, st) {
    debugPrint(
      '[gifLastFrameProvider] Failed to extract last frame.\n'
      '  URL  : $gifUrl\n'
      '  Error: $e\n$st',
    );
    return null;
  } finally {
    lastFrame?.dispose();
    codec?.dispose();
  }
});

/// Like [gifLastFrameProvider] but decodes ONLY the first frame.
///
/// The last-frame provider walks every frame of the GIF (delta-encoded, so the
/// Nth frame needs all N decoded) — fine for a screen with a handful of GIFs,
/// but the Exercise Library scrolls ~400 thumbnails, and kicking off 400
/// full-animation decodes saturates the event loop and makes scrolling stutter.
/// For exercise GIFs frame 0 ≈ the last frame (the rest/start position), so the
/// still looks identical while skipping the per-frame work — the scrollable
/// catalog uses this instead.
final gifFirstFrameProvider = FutureProvider.autoDispose
    .family<MemoryImage?, String>((ref, gifUrl) async {
  final link = ref.keepAlive();
  Timer? releaseTimer;
  ref.onDispose(() => releaseTimer?.cancel());
  ref.onCancel(
      () => releaseTimer = Timer(const Duration(seconds: 60), link.close));
  ref.onResume(() => releaseTimer?.cancel());

  ui.Codec? codec;
  ui.Image? frame;
  try {
    final file = await DefaultCacheManager().getSingleFile(gifUrl);
    final Uint8List bytes = await file.readAsBytes();
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _kMaxDecodeWidth,
      allowUpscaling: false,
    );
    if (codec.frameCount == 0) return null;

    // Just the first frame — no loop through the animation.
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    frame = frameInfo.image;

    final ByteData? byteData =
        await frame.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return MemoryImage(byteData.buffer.asUint8List());
  } catch (e, st) {
    debugPrint(
      '[gifFirstFrameProvider] Failed to extract first frame.\n'
      '  URL  : $gifUrl\n'
      '  Error: $e\n$st',
    );
    return null;
  } finally {
    frame?.dispose();
    codec?.dispose();
  }
});
