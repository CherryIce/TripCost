import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/export/expense_export_service.dart';
import 'package:trip_cost/core/storage/backup/backup_service.dart';
import 'package:trip_cost/core/storage/data_reset_coordinator.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:trip_cost/features/settings/application/settings_data_service.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

void main() {
  late Directory root;
  late AppDatabase database;
  late _FakeGateway gateway;
  late _StartupStore startupStore;
  late SettingsDataService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('m8-settings-data-');
    database = AppDatabase.inMemory();
    await DatabaseBootstrapper(database).seedCurrencyMetadata();
    gateway = _FakeGateway();
    startupStore = _StartupStore();
    service = SettingsDataService(
      backupService: BackupService(
        database,
        clock: () => DateTime.utc(2026, 8, 17, 8),
      ),
      resetCoordinator: DataResetCoordinator(
        database: database,
        receiptStorage: ReceiptStorage(rootDirectory: () async => root),
        sharedSnapshotStore: _SnapshotStore(),
        clock: () => DateTime.utc(2026, 8, 17, 8),
      ),
      platformGateway: gateway,
      startupStateStore: startupStore,
      temporaryDirectory: () async => root,
      clock: () => DateTime.utc(2026, 8, 17, 8),
    );
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  test('creates and shares a local versioned backup', () async {
    final backup = await service.createBackup();
    await service.shareBackup(backup);

    expect(await backup.exists(), isTrue);
    expect(await backup.readAsString(), contains('local-accounting-backup'));
    expect(gateway.sharedPaths, <String>[backup.path]);
  });

  test('invalid picked backup leaves the current database intact', () async {
    final invalid = File('${root.path}/invalid.json');
    await invalid.writeAsString('{"format":"wrong"}');
    gateway.pickedPath = invalid.path;

    await expectLater(
      service.pickAndRestoreBackup(),
      throwsA(isA<BackupValidationException>()),
    );

    final currencies = await database.select(database.currencies).get();
    expect(currencies, isNotEmpty);
  });

  test('full reset clears database and resets onboarding state', () async {
    final confirmation = service.requestFullReset();

    await service.clearAllData(confirmation);

    expect(await database.select(database.currencies).get(), isEmpty);
    expect(startupStore.complete, isFalse);
  });
}

final class _FakeGateway implements DocumentPlatformGateway {
  String? pickedPath;
  List<String>? sharedPaths;

  @override
  Future<String> generatePdf(Map<String, Object?> document) =>
      throw UnimplementedError();

  @override
  Future<String?> pickBackupFile() async => pickedPath;

  @override
  Future<void> shareFiles(List<String> paths) async {
    sharedPaths = paths;
  }
}

final class _SnapshotStore implements SharedSnapshotStore {
  @override
  Future<void> clear() async {}
}

final class _StartupStore implements StartupStateStore {
  bool complete = true;

  @override
  Future<bool> isOnboardingComplete() async => complete;

  @override
  Future<void> markOnboardingComplete() async {
    complete = true;
  }

  @override
  Future<void> resetOnboarding() async {
    complete = false;
  }
}
