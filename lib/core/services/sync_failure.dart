enum SyncFailureReason {
  decodeFailure,
  unsupportedVersion,
  invalidPayload,
  localConstraintFailure,
  ownershipMismatch,
  networkFailure,
}

class SyncFailureRecord {
  final String objectId;
  final String entityType;
  final String entityId;
  final String userId;
  final SyncFailureReason reason;
  final int attempts;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String sanitizedDiagnostic;

  const SyncFailureRecord({
    required this.objectId,
    required this.entityType,
    required this.entityId,
    required this.userId,
    required this.reason,
    required this.attempts,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.sanitizedDiagnostic,
  });
}
