import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';
import 'package:uuid/uuid.dart';

final class DriftSyncStore implements CacheRepositoryObserver {
  DriftSyncStore(this._database, {DateTime Function()? clock, Uuid? uuid})
    : _clock = clock ?? (() => DateTime.now().toUtc()),
      _uuid = uuid ?? const Uuid();

  static const String runtimeId = 'cloudkit-private';
  static const int recordSchemaVersion = 1;

  final AppDatabase _database;
  final DateTime Function() _clock;
  final Uuid _uuid;

  @override
  Stream<void> watchChanges() => _database.coreDao.watchSyncState();

  Future<String> deviceId() async {
    final current = await _database.coreDao.getSyncRuntime(runtimeId);
    if (current != null) return current.deviceId;
    final value = _uuid.v4();
    await _database.coreDao.upsertSyncRuntime(
      SyncRuntimeEntriesCompanion.insert(
        id: runtimeId,
        deviceId: value,
        accountState: SyncAccountState.couldNotDetermine.name,
        phase: SyncPhase.idle.name,
      ),
    );
    _database.notifyCacheTable('sync_runtime_entries');
    return value;
  }

  Future<SyncRuntimeStatus> status() async {
    final current = await _database.coreDao.getSyncRuntime(runtimeId);
    if (current == null) {
      await deviceId();
      return const SyncRuntimeStatus(
        accountState: SyncAccountState.couldNotDetermine,
        phase: SyncPhase.idle,
        failureCount: 0,
      );
    }
    return _statusFromRow(current);
  }

  Future<String?> cursor() async {
    final current = await _database.coreDao.getSyncRuntime(runtimeId);
    return current?.cursor;
  }

  Future<void> resetCursor() async {
    final current = await _database.coreDao.getSyncRuntime(runtimeId);
    if (current == null || current.cursor == null) return;
    await _database.coreDao.upsertSyncRuntime(
      SyncRuntimeEntriesCompanion.insert(
        id: runtimeId,
        cursor: const Value<String?>(null),
        deviceId: current.deviceId,
        accountState: current.accountState,
        phase: current.phase,
        failureCount: Value<int>(current.failureCount),
        lastAttemptAt: Value<DateTime?>(current.lastAttemptAt),
        lastSuccessAt: Value<DateTime?>(current.lastSuccessAt),
        nextRetryAt: Value<DateTime?>(current.nextRetryAt),
        lastErrorCode: Value<String?>(current.lastErrorCode),
      ),
    );
    _database.notifyCacheTable('sync_runtime_entries');
  }

  Future<void> updateRuntime({
    required SyncAccountState accountState,
    required SyncPhase phase,
    int? failureCount,
    DateTime? lastAttemptAt,
    DateTime? lastSuccessAt,
    DateTime? nextRetryAt,
    String? lastErrorCode,
    bool clearRetry = false,
  }) async {
    final id = await deviceId();
    final current = await _database.coreDao.getSyncRuntime(runtimeId);
    await _database.coreDao.upsertSyncRuntime(
      SyncRuntimeEntriesCompanion.insert(
        id: runtimeId,
        cursor: Value<String?>(current?.cursor),
        deviceId: id,
        accountState: accountState.name,
        phase: phase.name,
        failureCount: Value<int>(failureCount ?? current?.failureCount ?? 0),
        lastAttemptAt: Value<DateTime?>(
          lastAttemptAt ?? current?.lastAttemptAt,
        ),
        lastSuccessAt: Value<DateTime?>(
          lastSuccessAt ?? current?.lastSuccessAt,
        ),
        nextRetryAt: Value<DateTime?>(
          clearRetry ? null : (nextRetryAt ?? current?.nextRetryAt),
        ),
        lastErrorCode: Value<String?>(
          clearRetry ? null : (lastErrorCode ?? current?.lastErrorCode),
        ),
      ),
    );
    _database.notifyCacheTable('sync_runtime_entries');
  }

  Future<List<CloudSyncRecord>> pendingRecords({int limit = 100}) async {
    final sourceDeviceId = await deviceId();
    final result = <CloudSyncRecord>[];
    for (final config in _configs) {
      final rows = await _database
          .customSelect(
            'SELECT * FROM "${config.tableName}" ORDER BY updated_at, id',
          )
          .get();
      for (final row in rows) {
        final data = Map<String, Object?>.from(row.data);
        final recordId = data['id'] as String;
        if (config.entityType == SyncEntityType.userSettings) {
          data.remove('last_transaction_currency');
        }
        final metadata = await _database.coreDao.getSyncMetadata(
          config.entityType.name,
          recordId,
        );
        final modifiedAt = _dateFromDb(data['updated_at'], 'updated_at');
        final pending =
            metadata == null ||
            metadata.lastSyncedAt == null ||
            modifiedAt.isAfter(metadata.lastSyncedAt!.toUtc()) ||
            metadata.syncState == SyncState.pending.name ||
            metadata.syncState == SyncState.failed.name;
        if (!pending || metadata?.syncState == SyncState.conflict.name) {
          continue;
        }
        data.remove('receipt_local_path');
        final needsNewChange =
            metadata?.changeId == null ||
            modifiedAt.isAfter(metadata!.updatedAt.toUtc());
        final changeId = needsNewChange ? _uuid.v4() : metadata.changeId!;
        if (needsNewChange) {
          await _database.coreDao.upsertSyncMetadata(
            SyncMetadataEntriesCompanion.insert(
              entityType: config.entityType.name,
              recordId: recordId,
              syncVersion: (data['sync_version'] as int?) ?? 1,
              syncState: SyncState.pending.name,
              updatedAt: modifiedAt,
              deletedAt: Value<DateTime?>(
                _optionalDateFromDb(data['deleted_at']),
              ),
              lastSyncedAt: Value<DateTime?>(metadata?.lastSyncedAt),
              deviceId: Value<String?>(sourceDeviceId),
              changeId: Value<String?>(changeId),
              lastSyncedPayloadJson: Value<String?>(
                metadata?.lastSyncedPayloadJson,
              ),
            ),
          );
        }
        result.add(
          CloudSyncRecord(
            id: recordId,
            entityType: config.entityType,
            payloadJson: jsonEncode(data),
            modifiedAtUtc: modifiedAt,
            deleted: data['deleted_at'] != null,
            schemaVersion: recordSchemaVersion,
            deviceId: sourceDeviceId,
            changeId: changeId,
          ),
        );
        if (result.length >= limit) return result;
      }
    }
    return result;
  }

  Future<void> markPushed(
    List<CloudSyncRecord> records,
    Set<String> acceptedKeys,
  ) async {
    final now = _clock().toUtc();
    await _database.transaction(() async {
      for (final record in records.where(
        (item) => acceptedKeys.contains(item.key),
      )) {
        final payload = record.payload;
        final local = await _rawRow(_config(record.entityType), record.id);
        if (local == null || !_payloadMatchesLocal(local, payload)) {
          continue;
        }
        await _database.coreDao.upsertSyncMetadata(
          SyncMetadataEntriesCompanion.insert(
            entityType: record.entityType.name,
            recordId: record.id,
            syncVersion: (payload['sync_version'] as int?) ?? 1,
            syncState: SyncState.clean.name,
            updatedAt: record.modifiedAtUtc,
            deletedAt: Value<DateTime?>(
              _optionalDateFromDb(payload['deleted_at']),
            ),
            lastSyncedAt: Value<DateTime?>(now),
            deviceId: Value<String?>(record.deviceId),
            changeId: Value<String?>(record.changeId),
            lastSyncedPayloadJson: Value<String?>(record.payloadJson),
          ),
        );
      }
    });
  }

  Future<void> applyPullBatch(
    List<CloudSyncRecord> records,
    String? nextCursor, {
    Set<String> locallyPushedKeys = const <String>{},
  }) async {
    final now = _clock().toUtc();
    final ordered = records.toList()
      ..sort(
        (left, right) => _config(
          left.entityType,
        ).applyOrder.compareTo(_config(right.entityType).applyOrder),
      );
    await _database.transaction(() async {
      for (final record in ordered) {
        if (record.schemaVersion != recordSchemaVersion) {
          throw const SyncFailure('unsupported-record-schema');
        }
        await _applyRecord(record, now, locallyPushedKeys);
      }
      final id = await deviceId();
      final current = await _database.coreDao.getSyncRuntime(runtimeId);
      await _database.coreDao.upsertSyncRuntime(
        SyncRuntimeEntriesCompanion.insert(
          id: runtimeId,
          cursor: Value<String?>(nextCursor),
          deviceId: id,
          accountState:
              current?.accountState ?? SyncAccountState.available.name,
          phase: SyncPhase.pulling.name,
          failureCount: Value<int>(current?.failureCount ?? 0),
          lastAttemptAt: Value<DateTime?>(current?.lastAttemptAt),
          lastSuccessAt: Value<DateTime?>(current?.lastSuccessAt),
          nextRetryAt: Value<DateTime?>(current?.nextRetryAt),
          lastErrorCode: Value<String?>(current?.lastErrorCode),
        ),
      );
    });
  }

  Future<List<SyncConflictModel>> unresolvedConflicts() async {
    final rows = await _database.coreDao.unresolvedSyncConflicts();
    return <SyncConflictModel>[
      for (final row in rows)
        SyncConflictModel(
          id: row.id,
          entityType: SyncEntityType.values.byName(row.entityType),
          recordId: row.recordId,
          fieldName: row.fieldName,
          localPayloadJson: row.localPayloadJson,
          remotePayloadJson: row.remotePayloadJson,
          detectedAt: row.detectedAt.toUtc(),
        ),
    ];
  }

  Future<void> resolveActualAmountConflict(
    SyncConflictModel conflict, {
    required bool useRemoteValue,
  }) async {
    if (conflict.entityType != SyncEntityType.expense ||
        conflict.fieldName != 'actual_final_amount') {
      throw const SyncFailure('unsupported-conflict');
    }
    final now = _clock().toUtc();
    final source = jsonDecode(
      useRemoteValue ? conflict.remotePayloadJson : conflict.localPayloadJson,
    );
    if (source is! Map<String, Object?>) {
      throw const SyncFailure('invalid-conflict-payload');
    }
    final local = await _rawRow(
      _config(SyncEntityType.expense),
      conflict.recordId,
    );
    if (local == null) throw const SyncFailure('missing-local-record');
    final merged = Map<String, Object?>.from(local)
      ..['actual_final_amount'] = source['actual_final_amount']
      ..['updated_at'] = _dateToDb(now)
      ..['sync_version'] = ((local['sync_version'] as int?) ?? 1) + 1;
    merged.remove('receipt_local_path');
    final device = await deviceId();
    final changeId = _uuid.v4();
    await _database.transaction(() async {
      await _upsertRaw(_config(SyncEntityType.expense), merged);
      await _database.coreDao.upsertSyncMetadata(
        SyncMetadataEntriesCompanion.insert(
          entityType: SyncEntityType.expense.name,
          recordId: conflict.recordId,
          syncVersion: merged['sync_version']! as int,
          syncState: SyncState.pending.name,
          updatedAt: now,
          deletedAt: Value<DateTime?>(
            _optionalDateFromDb(merged['deleted_at']),
          ),
          deviceId: Value<String?>(device),
          changeId: Value<String?>(changeId),
        ),
      );
      await _database.coreDao.resolveSyncConflict(conflict.id, now);
    });
  }

  Future<void> _applyRecord(
    CloudSyncRecord record,
    DateTime now,
    Set<String> locallyPushedKeys,
  ) async {
    final config = _config(record.entityType);
    final remotePayload = record.payload;
    if (remotePayload['id'] != record.id) {
      throw const SyncFailure('record-id-mismatch');
    }
    remotePayload.remove('receipt_local_path');
    final local = await _rawRow(config, record.id);
    final metadata = await _database.coreDao.getSyncMetadata(
      record.entityType.name,
      record.id,
    );
    if (metadata?.changeId == record.changeId) {
      if (local != null && _payloadMatchesLocal(local, remotePayload)) {
        await _writeCleanMetadata(record, remotePayload, now);
      }
      return;
    }

    final localModified = local == null
        ? null
        : _dateFromDb(local['updated_at'], 'updated_at');
    final localPending =
        local != null &&
        (metadata?.syncState == SyncState.pending.name ||
            metadata?.syncState == SyncState.failed.name ||
            metadata?.lastSyncedAt == null ||
            localModified!.isAfter(metadata!.lastSyncedAt!.toUtc()) ||
            locallyPushedKeys.contains(record.key));
    if (record.entityType == SyncEntityType.expense &&
        localPending &&
        local['actual_final_amount'] != null &&
        remotePayload['actual_final_amount'] != null &&
        local['actual_final_amount'] != remotePayload['actual_final_amount']) {
      final conflictId = '${record.key}:${record.changeId}';
      await _database.coreDao.insertSyncConflict(
        SyncConflictEntriesCompanion.insert(
          id: conflictId,
          entityType: record.entityType.name,
          recordId: record.id,
          fieldName: 'actual_final_amount',
          localPayloadJson: jsonEncode(local),
          remotePayloadJson: record.payloadJson,
          detectedAt: now,
        ),
      );
      await _database.coreDao.upsertSyncMetadata(
        SyncMetadataEntriesCompanion.insert(
          entityType: record.entityType.name,
          recordId: record.id,
          syncVersion: (local['sync_version'] as int?) ?? 1,
          syncState: SyncState.conflict.name,
          updatedAt: localModified!,
          deletedAt: Value<DateTime?>(_optionalDateFromDb(local['deleted_at'])),
          lastSyncedAt: Value<DateTime?>(metadata?.lastSyncedAt),
          deviceId: Value<String?>(metadata?.deviceId),
          changeId: Value<String?>(metadata?.changeId),
          lastSyncedPayloadJson: Value<String?>(
            metadata?.lastSyncedPayloadJson,
          ),
        ),
      );
      return;
    }

    final remoteWins =
        localModified == null ||
        record.modifiedAtUtc.isAfter(localModified) ||
        (record.modifiedAtUtc.isAtSameMomentAs(localModified) &&
            record.changeId.compareTo(metadata?.changeId ?? '') > 0);
    if (!remoteWins) return;

    if (record.deleted && remotePayload.length == 1 && local != null) {
      await _database.customStatement(
        'UPDATE "${config.tableName}" SET deleted_at = ?, updated_at = ? '
        'WHERE id = ?',
        <Object?>[
          _dateToDb(record.modifiedAtUtc),
          _dateToDb(record.modifiedAtUtc),
          record.id,
        ],
      );
      _notifyEntityChanged(config.entityType);
    } else {
      await _upsertRaw(config, remotePayload);
    }
    await _writeCleanMetadata(record, remotePayload, now);
  }

  Future<void> _writeCleanMetadata(
    CloudSyncRecord record,
    Map<String, Object?> payload,
    DateTime now,
  ) {
    return _database.coreDao.upsertSyncMetadata(
      SyncMetadataEntriesCompanion.insert(
        entityType: record.entityType.name,
        recordId: record.id,
        syncVersion: (payload['sync_version'] as int?) ?? 1,
        syncState: SyncState.clean.name,
        updatedAt: record.modifiedAtUtc,
        deletedAt: Value<DateTime?>(
          _optionalDateFromDb(payload['deleted_at']) ??
              (record.deleted ? record.modifiedAtUtc : null),
        ),
        lastSyncedAt: Value<DateTime?>(now),
        deviceId: Value<String?>(record.deviceId),
        changeId: Value<String?>(record.changeId),
        lastSyncedPayloadJson: Value<String?>(jsonEncode(payload)),
      ),
    );
  }

  Future<Map<String, Object?>?> _rawRow(_EntityConfig config, String id) async {
    final row = await _database
        .customSelect(
          'SELECT * FROM "${config.tableName}" WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    return row == null ? null : Map<String, Object?>.from(row.data);
  }

  bool _payloadMatchesLocal(
    Map<String, Object?> local,
    Map<String, Object?> payload,
  ) {
    for (final entry in payload.entries) {
      if (entry.key == 'receipt_local_path') continue;
      if (local[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> _upsertRaw(
    _EntityConfig config,
    Map<String, Object?> payload,
  ) async {
    final schemaRows = await _database
        .customSelect('PRAGMA table_info("${config.tableName}")')
        .get();
    final allowed = <String>{
      for (final row in schemaRows) row.data['name']! as String,
    };
    final values = Map<String, Object?>.from(payload)
      ..remove('receipt_local_path');
    if (values.isEmpty ||
        values.keys.any((key) => !allowed.contains(key)) ||
        values['id'] is! String) {
      throw const SyncFailure('invalid-record-payload');
    }
    final columns = values.keys.toList(growable: false);
    final updates = columns
        .where((column) => column != 'id')
        .map((column) => '"$column" = excluded."$column"')
        .join(', ');
    await _database.customStatement(
      'INSERT INTO "${config.tableName}" '
      '(${columns.map((column) => '"$column"').join(', ')}) '
      'VALUES (${List<String>.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates',
      <Object?>[for (final column in columns) values[column]],
    );
    _notifyEntityChanged(config.entityType);
  }

  void _notifyEntityChanged(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.rateSnapshot:
        _database.notifyCacheTable('rate_snapshots');
      case SyncEntityType.paymentMethod:
        _database.notifyCacheTable('payment_methods');
      case SyncEntityType.trip:
        _database.notifyCacheTable('trips');
      case SyncEntityType.expense:
        _database.notifyCacheTable('expenses');
      case SyncEntityType.userSettings:
        _database.notifyCacheTable('user_settings_records');
    }
  }

  SyncRuntimeStatus _statusFromRow(SyncRuntimeEntry row) {
    return SyncRuntimeStatus(
      accountState: SyncAccountState.values.byName(row.accountState),
      phase: SyncPhase.values.byName(row.phase),
      failureCount: row.failureCount,
      lastAttemptAt: row.lastAttemptAt?.toUtc(),
      lastSuccessAt: row.lastSuccessAt?.toUtc(),
      nextRetryAt: row.nextRetryAt?.toUtc(),
      lastErrorCode: row.lastErrorCode,
    );
  }
}

final class _EntityConfig {
  const _EntityConfig(this.entityType, this.tableName, this.applyOrder);

  final SyncEntityType entityType;
  final String tableName;
  final int applyOrder;
}

const List<_EntityConfig> _configs = <_EntityConfig>[
  _EntityConfig(SyncEntityType.rateSnapshot, 'rate_snapshots', 0),
  _EntityConfig(SyncEntityType.paymentMethod, 'payment_methods', 1),
  _EntityConfig(SyncEntityType.trip, 'trips', 2),
  _EntityConfig(SyncEntityType.expense, 'expenses', 3),
  _EntityConfig(SyncEntityType.userSettings, 'user_settings_records', 4),
];

_EntityConfig _config(SyncEntityType type) =>
    _configs.singleWhere((config) => config.entityType == type);

DateTime _dateFromDb(Object? value, String field) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  if (value is String) return DateTime.parse(value).toUtc();
  throw FormatException('$field is not a persisted UTC timestamp.');
}

DateTime? _optionalDateFromDb(Object? value) =>
    value == null ? null : _dateFromDb(value, 'optional timestamp');

int _dateToDb(DateTime value) =>
    value.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
