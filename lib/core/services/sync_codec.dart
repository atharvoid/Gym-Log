import 'dart:convert';
import 'dart:io';

/// Compact, transport-friendly encoding for sync payloads.
///
/// Entity JSON is gzip-compressed then base64-encoded so it travels as a
/// single text column and stays small on the wire — workout sessions with
/// many sets shrink dramatically, which matters on the Supabase free tier.
/// Decoding is the exact inverse and tolerates already-plain JSON as a
/// fallback (so a value written by an older/un-compressed path still loads).
class SyncCodec {
  const SyncCodec._();

  /// Map → JSON → gzip → base64 text.
  static String encode(Map<String, dynamic> data) {
    final jsonBytes = utf8.encode(jsonEncode(data));
    final gzipped = gzip.encode(jsonBytes);
    return base64Encode(gzipped);
  }

  /// base64 → gunzip → JSON → Map. Falls back to plain JSON if the input
  /// was never compressed.
  static Map<String, dynamic> decode(String payload) {
    try {
      final gzipped = base64Decode(payload);
      final jsonBytes = gzip.decode(gzipped);
      return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
    } catch (_) {
      return jsonDecode(payload) as Map<String, dynamic>;
    }
  }
}
