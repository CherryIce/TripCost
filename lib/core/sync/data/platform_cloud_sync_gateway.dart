import 'package:flutter/services.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart'
    as platform;
import 'package:trip_cost/core/sync/domain/sync_models.dart';

final class PlatformCloudSyncGateway implements CloudSyncGateway {
  PlatformCloudSyncGateway({platform.CloudSyncApi? api})
    : _api = api ?? platform.CloudSyncApi();

  static const int contractVersion = 1;

  final platform.CloudSyncApi _api;

  @override
  Future<SyncAccountState> accountStatus() async {
    try {
      final value = await _api.accountStatus();
      return SyncAccountState.values.byName(value.name);
    } on PlatformException catch (error) {
      throw SyncFailure(error.code, error.message);
    }
  }

  @override
  Future<CloudPushResult> pushChanges(List<CloudSyncRecord> records) async {
    try {
      final result = await _api.pushChanges(<platform.SyncRecord>[
        for (final record in records)
          platform.SyncRecord(
            contractVersion: contractVersion,
            id: record.id,
            recordType: record.entityType.name,
            payloadJson: record.payloadJson,
            modifiedAtUtc: record.modifiedAtUtc.toIso8601String(),
            deleted: record.deleted,
            schemaVersion: record.schemaVersion,
            deviceId: record.deviceId,
            changeId: record.changeId,
          ),
      ], null);
      _requireContract(result.contractVersion);
      return CloudPushResult(acceptedKeys: result.acceptedRecordIds.toSet());
    } on PlatformException catch (error) {
      throw SyncFailure(error.code, error.message);
    }
  }

  @override
  Future<CloudPullResult> pullChanges(String? cursor) async {
    try {
      final result = await _api.pullChanges(cursor);
      _requireContract(result.contractVersion);
      return CloudPullResult(
        records: <CloudSyncRecord>[
          for (final record in result.records)
            CloudSyncRecord(
              id: record.id,
              entityType: SyncEntityType.values.byName(record.recordType),
              payloadJson: record.payloadJson,
              modifiedAtUtc: DateTime.parse(record.modifiedAtUtc).toUtc(),
              deleted: record.deleted,
              schemaVersion: record.schemaVersion,
              deviceId: record.deviceId,
              changeId: record.changeId,
            ),
        ],
        cursor: result.cursor,
        hasMore: result.hasMore,
      );
    } on PlatformException catch (error) {
      throw SyncFailure(error.code, error.message);
    } on ArgumentError catch (error) {
      throw SyncFailure('invalid-remote-record', error.message?.toString());
    } on FormatException catch (error) {
      throw SyncFailure('invalid-remote-record', error.message);
    }
  }

  void _requireContract(int value) {
    if (value != contractVersion) {
      throw const SyncFailure('unsupported-contract');
    }
  }
}
