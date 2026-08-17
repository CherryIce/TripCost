import 'dart:convert';

enum SyncEntityType { rateSnapshot, paymentMethod, trip, expense, userSettings }

enum SyncAccountState { available, noAccount, restricted, couldNotDetermine }

enum SyncPhase {
  disabled,
  idle,
  pushing,
  pulling,
  succeeded,
  waitingRetry,
  failed,
}

final class CloudSyncRecord {
  CloudSyncRecord({
    required this.id,
    required this.entityType,
    required this.payloadJson,
    required this.modifiedAtUtc,
    required this.deleted,
    required this.schemaVersion,
    required this.deviceId,
    required this.changeId,
  });

  final String id;
  final SyncEntityType entityType;
  final String payloadJson;
  final DateTime modifiedAtUtc;
  final bool deleted;
  final int schemaVersion;
  final String deviceId;
  final String changeId;

  String get key => '${entityType.name}:$id';

  Map<String, Object?> get payload {
    final value = jsonDecode(payloadJson);
    if (value is! Map<String, Object?>) {
      throw const FormatException('Sync payload must be a JSON object.');
    }
    return value;
  }
}

final class CloudPushResult {
  const CloudPushResult({required this.acceptedKeys});

  final Set<String> acceptedKeys;
}

final class CloudPullResult {
  const CloudPullResult({
    required this.records,
    required this.cursor,
    required this.hasMore,
  });

  final List<CloudSyncRecord> records;
  final String? cursor;
  final bool hasMore;
}

abstract interface class CloudSyncGateway {
  Future<SyncAccountState> accountStatus();

  Future<CloudPushResult> pushChanges(List<CloudSyncRecord> records);

  Future<CloudPullResult> pullChanges(String? cursor);
}

final class SyncRuntimeStatus {
  const SyncRuntimeStatus({
    required this.accountState,
    required this.phase,
    required this.failureCount,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.nextRetryAt,
    this.lastErrorCode,
  });

  final SyncAccountState accountState;
  final SyncPhase phase;
  final int failureCount;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final DateTime? nextRetryAt;
  final String? lastErrorCode;
}

final class SyncConflictModel {
  SyncConflictModel({
    required this.id,
    required this.entityType,
    required this.recordId,
    required this.fieldName,
    required this.localPayloadJson,
    required this.remotePayloadJson,
    required this.detectedAt,
  });

  final String id;
  final SyncEntityType entityType;
  final String recordId;
  final String fieldName;
  final String localPayloadJson;
  final String remotePayloadJson;
  final DateTime detectedAt;

  String? get localValue => _fieldValue(localPayloadJson);
  String? get remoteValue => _fieldValue(remotePayloadJson);

  String? _fieldValue(String encoded) {
    final value = jsonDecode(encoded);
    return value is Map<String, Object?> ? value[fieldName] as String? : null;
  }
}

final class SyncFailure implements Exception {
  const SyncFailure(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() =>
      'SyncFailure($code${message == null ? '' : ': $message'})';
}
