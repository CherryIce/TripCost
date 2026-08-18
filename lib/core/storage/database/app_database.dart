import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:trip_cost/core/storage/database/core_dao.dart';
import 'package:trip_cost/core/storage/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Currencies,
    RateSnapshots,
    PaymentMethods,
    Trips,
    Expenses,
    FeeCalibrations,
    UserSettingsRecords,
    SyncMetadataEntries,
    SyncRuntimeEntries,
    SyncConflictEntries,
  ],
  daos: <Type>[CoreDao],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  factory AppDatabase.open() => AppDatabase(_openConnection());

  final StreamController<String> _cacheChanges =
      StreamController<String>.broadcast();

  static const List<String> backupTableOrder = <String>[
    'currencies',
    'rate_snapshots',
    'payment_methods',
    'trips',
    'expenses',
    'fee_calibrations',
    'user_settings_records',
    'sync_metadata_entries',
  ];

  @override
  int get schemaVersion => 4;

  Stream<void> watchCacheTable(String tableName) => _cacheChanges.stream
      .where((changedTable) => changedTable == tableName)
      .map<void>((_) {});

  void notifyCacheTable(String tableName) {
    if (!_cacheChanges.isClosed) _cacheChanges.add(tableName);
  }

  void notifyAllCacheTables() {
    for (final table in backupTableOrder) {
      notifyCacheTable(table);
    }
    notifyCacheTable('sync_runtime_entries');
    notifyCacheTable('sync_conflict_entries');
  }

  @override
  Future<void> close() async {
    await _cacheChanges.close();
    await super.close();
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: _upgrade,
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _upgrade(Migrator migrator, int from, int to) async {
    if (from > to || from < 1) {
      throw StateError('Unsupported database migration: $from -> $to');
    }
    if (from < 2) {
      await migrator.addColumn(paymentMethods, paymentMethods.cashExchangeRate);
    }
    if (from < 3) {
      await migrator.addColumn(expenses, expenses.entryType);
      await migrator.addColumn(expenses, expenses.relatedExpenseId);
    }
    if (from < 4) {
      await migrator.addColumn(
        syncMetadataEntries,
        syncMetadataEntries.deviceId,
      );
      await migrator.addColumn(
        syncMetadataEntries,
        syncMetadataEntries.changeId,
      );
      await migrator.addColumn(
        syncMetadataEntries,
        syncMetadataEntries.lastSyncedPayloadJson,
      );
      await migrator.createTable(syncRuntimeEntries);
      await migrator.createTable(syncConflictEntries);
    }
  }

  Future<Map<String, List<Map<String, Object?>>>> exportRawData() async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in backupTableOrder) {
      final rows = await customSelect('SELECT * FROM "$table"').get();
      result[table] = <Map<String, Object?>>[
        for (final row in rows) Map<String, Object?>.from(row.data),
      ];
    }
    return result;
  }

  Future<void> replaceRawData(
    Map<String, List<Map<String, Object?>>> data,
  ) async {
    final actualTables = data.keys.toSet();
    final expectedTables = backupTableOrder.toSet();
    if (!actualTables.containsAll(expectedTables) ||
        !expectedTables.containsAll(actualTables)) {
      throw const FormatException('Backup table set does not match schema v1.');
    }

    await transaction(() async {
      await customStatement('PRAGMA defer_foreign_keys = ON');
      for (final table in backupTableOrder.reversed) {
        await customStatement('DELETE FROM "$table"');
      }
      for (final table in backupTableOrder) {
        for (final row in data[table]!) {
          if (row.isEmpty) {
            throw const FormatException('Backup contains an empty row.');
          }
          final columns = row.keys.toList(growable: false);
          if (columns.any((column) => !_sqlIdentifier.hasMatch(column))) {
            throw const FormatException('Backup contains an invalid column.');
          }
          final quotedColumns = columns.map((column) => '"$column"').join(', ');
          final placeholders = List<String>.filled(
            columns.length,
            '?',
          ).join(', ');
          await customStatement(
            'INSERT INTO "$table" ($quotedColumns) VALUES ($placeholders)',
            <Object?>[for (final column in columns) row[column]],
          );
        }
      }
    });
    notifyAllCacheTables();
  }

  static final RegExp _sqlIdentifier = RegExp(r'^[a-z][a-z0-9_]*$');
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documents = await getApplicationDocumentsDirectory();
    final databaseFile = File(path.join(documents.path, 'core.sqlite'));
    return NativeDatabase.createInBackground(databaseFile);
  });
}
