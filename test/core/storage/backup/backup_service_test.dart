import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/backup/backup_service.dart';
import 'package:trip_cost/core/storage/database/app_database.dart'
    hide Currency;
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

void main() {
  late Directory temporaryDirectory;
  late AppDatabase database;
  late DriftSettingsRepository settingsRepository;
  final now = DateTime.utc(2026, 8, 17, 8);
  final catalog = CurrencyCatalog();

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('m2-backup-');
    database = AppDatabase.inMemory();
    settingsRepository = DriftSettingsRepository(database);
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  UserSettingsModel settings(String currency, int version) {
    return UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: version,
        updatedAt: now.add(Duration(minutes: version)),
      ),
      defaultCurrency: catalog.resolve(currency),
      favoriteCurrencies: <Currency>[catalog.resolve('JPY')],
      languageMode: AppLanguageMode.system,
      refreshInterval: const Duration(hours: 6),
      wifiOnlyRefresh: false,
      syncEnabled: false,
    );
  }

  test('exports and restores a versioned database backup', () async {
    final service = BackupService(database, clock: () => now);
    final backup = File('${temporaryDirectory.path}/backup.json');
    await settingsRepository.save(settings('CNY', 1));
    await database.coreDao.upsertSyncMetadata(
      SyncMetadataEntriesCompanion.insert(
        entityType: 'userSettings',
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: 1,
        syncState: SyncState.clean.name,
        updatedAt: now,
        lastSyncedAt: Value<DateTime?>(now),
      ),
    );
    await service.exportTo(backup);
    await settingsRepository.save(settings('USD', 2));

    await service.restoreFrom(backup);

    final restored = await settingsRepository.load();
    expect(restored!.defaultCurrency.code, 'CNY');
    expect(restored.metadata.syncVersion, 1);
    expect(
      await database.coreDao.getSyncMetadata(
        'userSettings',
        DriftSettingsRepository.settingsRecordId,
      ),
      isNull,
    );
    final envelope =
        jsonDecode(await backup.readAsString()) as Map<String, Object?>;
    expect(envelope['formatVersion'], BackupService.formatVersion);
    expect(envelope['databaseSchemaVersion'], database.schemaVersion);
  });

  test(
    'rejects an unsupported version before replacing current data',
    () async {
      final service = BackupService(database, clock: () => now);
      final invalid = File('${temporaryDirectory.path}/invalid.json');
      await settingsRepository.save(settings('USD', 2));
      await invalid.writeAsString(
        jsonEncode(<String, Object?>{
          'format': 'local-accounting-backup',
          'formatVersion': 999,
          'databaseSchemaVersion': 1,
          'createdAt': now.toIso8601String(),
          'tables': <String, Object?>{},
        }),
      );

      await expectLater(
        service.restoreFrom(invalid),
        throwsA(isA<BackupValidationException>()),
      );

      final unchanged = await settingsRepository.load();
      expect(unchanged!.defaultCurrency.code, 'USD');
      expect(unchanged.metadata.syncVersion, 2);
    },
  );

  test('rolls back when validated backup rows violate the schema', () async {
    final service = BackupService(database, clock: () => now);
    final backup = File('${temporaryDirectory.path}/corrupt-row.json');
    await settingsRepository.save(settings('CNY', 1));
    await service.exportTo(backup);
    await settingsRepository.save(settings('USD', 2));
    final envelope =
        jsonDecode(await backup.readAsString()) as Map<String, Object?>;
    final tables = envelope['tables'] as Map<String, Object?>;
    final rows = tables['user_settings_records'] as List<Object?>;
    final row = rows.single as Map<String, Object?>;
    row['default_currency'] = 'ZZZ';
    await backup.writeAsString(jsonEncode(envelope));

    await expectLater(service.restoreFrom(backup), throwsA(anything));

    final unchanged = await settingsRepository.load();
    expect(unchanged!.defaultCurrency.code, 'USD');
    expect(unchanged.metadata.syncVersion, 2);
  });
}
