import 'dart:convert';
import 'dart:io';

class SyncDecodedPayload {
  final int schemaVersion;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> body;

  const SyncDecodedPayload({
    required this.schemaVersion,
    required this.entityType,
    required this.entityId,
    required this.body,
  });
}

/// Compact, transport-friendly encoding for sync payloads.
///
/// Entity JSON is wrapped in a versioned envelope, gzip-compressed, then
/// base64-encoded so it travels as a single text column and stays small on the wire.
class SyncCodec {
  const SyncCodec._();

  static const currentSchemaVersion = 2;

  /// Map → Version 2 Envelope → JSON → gzip → base64 text.
  static String encode(
    Map<String, dynamic> data, {
    String entityType = '',
    String entityId = '',
    int schemaVersion = currentSchemaVersion,
  }) {
    final envelope = {
      'schemaVersion': schemaVersion,
      'entityType': entityType,
      'entityId': entityId,
      'body': data,
    };
    final jsonBytes = utf8.encode(jsonEncode(envelope));
    final gzipped = gzip.encode(jsonBytes);
    return base64Encode(gzipped);
  }

  /// base64 → gunzip → JSON → Map envelope.
  /// Throws FormatException for corrupt payload,
  /// UnsupportedError for schemaVersion > currentSchemaVersion.
  static SyncDecodedPayload decode(String payload) {
    Map<String, dynamic> map;
    try {
      try {
        final gzipped = base64Decode(payload);
        final jsonBytes = gzip.decode(gzipped);
        map = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      } catch (_) {
        map = jsonDecode(payload) as Map<String, dynamic>;
      }
    } catch (e) {
      throw FormatException('Decode error: invalid format or corrupt JSON: $e');
    }

    if (map.containsKey('schemaVersion')) {
      final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
      if (version > currentSchemaVersion) {
        throw UnsupportedError(
            'Unsupported schemaVersion $version (current version is $currentSchemaVersion)');
      }
      final body = map['body'];
      if (body == null || body is! Map<String, dynamic>) {
        throw const FormatException(
            'Invalid payload envelope: missing or non-map body');
      }
      return SyncDecodedPayload(
        schemaVersion: version,
        entityType: (map['entityType'] as String?) ?? '',
        entityId: (map['entityId'] as String?) ?? '',
        body: body,
      );
    } else {
      // Legacy unversioned payload
      return SyncDecodedPayload(
        schemaVersion: 1,
        entityType: '',
        entityId: '',
        body: map,
      );
    }
  }
}
