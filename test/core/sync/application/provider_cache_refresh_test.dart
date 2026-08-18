import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/payments/data/drift_payment_method_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/sync/data/drift_sync_store.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';
import 'package:trip_cost/core/trips/data/drift_trip_repository.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  test('CloudKit pull refreshes an already-built cached provider', () async {
    final database = AppDatabase.inMemory();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    await DriftPaymentMethodRepository(database).save(fixturePaymentMethod());
    await DriftTripRepository(database).save(fixtureTrip());
    final initial = await container.read(tripsControllerProvider.future);
    expect(initial.single.name, 'Tokyo week');

    final store = DriftSyncStore(database);
    final local = (await store.pendingRecords()).singleWhere(
      (record) => record.entityType == SyncEntityType.trip,
    );
    final remoteModifiedAt = DateTime.utc(2026, 8, 18, 8);
    final payload = local.payload
      ..['name'] = 'Synced Tokyo'
      ..['updated_at'] =
          remoteModifiedAt.millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
    await store.applyPullBatch(<CloudSyncRecord>[
      CloudSyncRecord(
        id: local.id,
        entityType: local.entityType,
        payloadJson: jsonEncode(payload),
        modifiedAtUtc: remoteModifiedAt,
        deleted: false,
        schemaVersion: DriftSyncStore.recordSchemaVersion,
        deviceId: 'remote-device',
        changeId: 'remote-change',
      ),
    ], 'remote-cursor');

    for (var attempt = 0; attempt < 10; attempt += 1) {
      await Future<void>.delayed(Duration.zero);
      if (container.read(tripsControllerProvider).value?.single.name ==
          'Synced Tokyo') {
        break;
      }
    }
    expect(
      container.read(tripsControllerProvider).value?.single.name,
      'Synced Tokyo',
    );
  });
}
