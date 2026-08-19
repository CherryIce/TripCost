import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/database/app_database.dart'
    hide Currency;
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';
import 'package:trip_cost/core/sync/data/drift_sync_store.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';

void main() {
  late AppDatabase database;
  late DriftSyncStore store;
  final first = DateTime.utc(2026, 8, 17, 8);
  var now = first;

  setUp(() async {
    database = AppDatabase.inMemory();
    await DatabaseBootstrapper(
      database,
      clock: () => first,
    ).seedCurrencyMetadata();
    store = DriftSyncStore(database, clock: () => now);
  });

  tearDown(() => database.close());

  test('outbox is idempotent and never includes receipt local path', () async {
    await _insertExpense(
      database,
      first,
      actual: '100',
      receipt: 'private/receipt.jpg',
    );

    final firstBatch = await store.pendingRecords();
    final expense = firstBatch.singleWhere(
      (record) => record.entityType == SyncEntityType.expense,
    );
    expect(expense.payload.containsKey('receipt_local_path'), isFalse);

    final retryBatch = await store.pendingRecords();
    expect(
      retryBatch.singleWhere((record) => record.key == expense.key).changeId,
      expense.changeId,
    );

    now = first.add(const Duration(minutes: 1));
    await store.markPushed(firstBatch, <String>{
      for (final item in firstBatch) item.key,
    });
    expect(await store.pendingRecords(), isEmpty);
  });

  test('last transaction currency remains a device-local setting', () async {
    final catalog = CurrencyCatalog();
    await DriftSettingsRepository(database).save(
      UserSettingsModel(
        metadata: SyncRecordMetadata(
          recordId: DriftSettingsRepository.settingsRecordId,
          syncVersion: 1,
          updatedAt: first,
        ),
        defaultCurrency: catalog.resolve('CNY'),
        lastTransactionCurrency: catalog.resolve('USD'),
        favoriteCurrencies: const <Currency>[],
        languageMode: AppLanguageMode.system,
        refreshInterval: const Duration(hours: 6),
        wifiOnlyRefresh: false,
        syncEnabled: true,
      ),
    );

    final settingsRecord = (await store.pendingRecords()).singleWhere(
      (record) => record.entityType == SyncEntityType.userSettings,
    );
    expect(
      settingsRecord.payload.containsKey('last_transaction_currency'),
      isFalse,
    );
  });

  test('push acknowledgement cannot clean a newer local generation', () async {
    await _insertExpense(database, first, actual: '100');
    final firstBatch = await store.pendingRecords();
    final pushed = firstBatch.single;

    now = first.add(const Duration(minutes: 1));
    await _insertExpense(database, now, actual: '105');
    await store.markPushed(firstBatch, <String>{pushed.key});
    await store.applyPullBatch(<CloudSyncRecord>[pushed], 'echo-cursor');

    final pending = await store.pendingRecords();
    expect(pending, hasLength(1));
    expect(pending.single.changeId, isNot(pushed.changeId));
    expect(
      (await database.coreDao.getExpense('expense-1'))!.actualFinalAmount,
      '105',
    );
  });

  test('remote actual after a local push still creates a conflict', () async {
    await _insertExpense(database, first, actual: '100');
    final batch = await store.pendingRecords();
    final pushed = batch.single;
    await store.markPushed(batch, <String>{pushed.key});
    final remoteAt = first.add(const Duration(minutes: 1));
    final remotePayload = pushed.payload
      ..['actual_final_amount'] = '110'
      ..['updated_at'] = remoteAt.millisecondsSinceEpoch ~/ 1000;

    await store.applyPullBatch(
      <CloudSyncRecord>[
        CloudSyncRecord(
          id: pushed.id,
          entityType: pushed.entityType,
          payloadJson: jsonEncode(remotePayload),
          modifiedAtUtc: remoteAt,
          deleted: false,
          schemaVersion: pushed.schemaVersion,
          deviceId: 'remote-device',
          changeId: 'remote-change',
        ),
      ],
      'remote-cursor',
      locallyPushedKeys: <String>{pushed.key},
    );

    final conflicts = await store.unresolvedConflicts();
    expect(conflicts, hasLength(1));
    expect(conflicts.single.localValue, '100');
    expect(conflicts.single.remoteValue, '110');
  });

  test('older remote value cannot revive a newer local tombstone', () async {
    final deletedAt = first.add(const Duration(minutes: 2));
    await _insertTrip(database, deletedAt, deletedAt: deletedAt);
    final raw = await database
        .customSelect("SELECT * FROM trips WHERE id = 'trip-1'")
        .getSingle();
    final oldPayload = Map<String, Object?>.from(raw.data)
      ..['deleted_at'] = null
      ..['updated_at'] = first.millisecondsSinceEpoch ~/ 1000;

    await store.applyPullBatch(<CloudSyncRecord>[
      CloudSyncRecord(
        id: 'trip-1',
        entityType: SyncEntityType.trip,
        payloadJson: jsonEncode(oldPayload),
        modifiedAtUtc: first,
        deleted: false,
        schemaVersion: 1,
        deviceId: 'remote-device',
        changeId: 'remote-old',
      ),
    ], 'cursor-1');

    final row = await database.coreDao.getTrip('trip-1');
    expect(row!.deletedAt!.toUtc(), deletedAt);
    expect(await store.cursor(), 'cursor-1');
  });

  test('posted amount conflict keeps both values until resolution', () async {
    await _insertExpense(database, first, actual: '100');
    await database.coreDao.upsertSyncMetadata(
      SyncMetadataEntriesCompanion.insert(
        entityType: SyncEntityType.expense.name,
        recordId: 'expense-1',
        syncVersion: 1,
        syncState: SyncState.clean.name,
        updatedAt: first.subtract(const Duration(minutes: 1)),
        lastSyncedAt: Value<DateTime?>(
          first.subtract(const Duration(minutes: 1)),
        ),
        changeId: const Value<String?>('local-old'),
      ),
    );
    final row = await database
        .customSelect("SELECT * FROM expenses WHERE id = 'expense-1'")
        .getSingle();
    final remoteAt = first.add(const Duration(minutes: 1));
    final remotePayload = Map<String, Object?>.from(row.data)
      ..remove('receipt_local_path')
      ..['actual_final_amount'] = '110'
      ..['updated_at'] = remoteAt.millisecondsSinceEpoch ~/ 1000;

    await store.applyPullBatch(<CloudSyncRecord>[
      CloudSyncRecord(
        id: 'expense-1',
        entityType: SyncEntityType.expense,
        payloadJson: jsonEncode(remotePayload),
        modifiedAtUtc: remoteAt,
        deleted: false,
        schemaVersion: 1,
        deviceId: 'remote-device',
        changeId: 'remote-new',
      ),
    ], 'cursor-conflict');

    final conflicts = await store.unresolvedConflicts();
    expect(conflicts, hasLength(1));
    expect(conflicts.single.localValue, '100');
    expect(conflicts.single.remoteValue, '110');
    expect(
      (await database.coreDao.getExpense('expense-1'))!.actualFinalAmount,
      '100',
    );

    now = remoteAt.add(const Duration(minutes: 1));
    await store.resolveActualAmountConflict(
      conflicts.single,
      useRemoteValue: true,
    );
    expect(
      (await database.coreDao.getExpense('expense-1'))!.actualFinalAmount,
      '110',
    );
    expect(await store.unresolvedConflicts(), isEmpty);
    expect(
      (await database.coreDao.getSyncMetadata(
        'expense',
        'expense-1',
      ))!.syncState,
      SyncState.pending.name,
    );
  });
}

Future<void> _insertTrip(
  AppDatabase database,
  DateTime updatedAt, {
  DateTime? deletedAt,
}) {
  return database.coreDao.upsertTrip(
    TripsCompanion.insert(
      id: 'trip-1',
      updatedAt: updatedAt,
      deletedAt: Value<DateTime?>(deletedAt),
      name: 'Tokyo',
      destinationCodesJson: '["JP"]',
      startDate: updatedAt,
      endDate: updatedAt.add(const Duration(days: 2)),
      homeCurrency: 'CNY',
      localCurrenciesJson: '["JPY"]',
      status: 'active',
      createdAt: updatedAt,
    ),
  );
}

Future<void> _insertExpense(
  AppDatabase database,
  DateTime updatedAt, {
  required String actual,
  String? receipt,
}) {
  return database.coreDao.upsertExpense(
    ExpensesCompanion.insert(
      id: 'expense-1',
      updatedAt: updatedAt,
      title: 'Lunch',
      category: 'food',
      transactionAmount: '2000',
      transactionCurrency: 'JPY',
      referenceAmount: '100',
      homeCurrency: 'CNY',
      estimatedFinalAmount: '100',
      actualFinalAmount: Value<String?>(actual),
      paymentRuleSnapshotJson: '{}',
      rateSnapshotJson: '{}',
      taxAmount: '0',
      tipAmount: '0',
      discountAmount: '0',
      occurredAt: updatedAt,
      receiptLocalPath: Value<String?>(receipt),
      status: 'confirmed',
      createdAt: updatedAt,
    ),
  );
}
