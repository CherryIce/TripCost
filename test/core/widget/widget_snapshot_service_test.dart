import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';
import 'package:trip_cost/core/widget/widget_snapshot_service.dart';

void main() {
  late AppDatabase database;
  late _FakeSnapshotGateway gateway;
  final now = DateTime.utc(2026, 8, 17, 8);

  setUp(() async {
    database = AppDatabase.inMemory();
    gateway = _FakeSnapshotGateway();
    await DatabaseBootstrapper(
      database,
      clock: () => now,
    ).seedCurrencyMetadata();
  });

  tearDown(() => database.close());

  test('writes minimal versioned rate and trip summary', () async {
    await database.coreDao.upsertRateSnapshot(
      RateSnapshotsCompanion.insert(
        id: 'rate-1',
        updatedAt: now,
        baseCurrency: 'JPY',
        quoteCurrency: 'CNY',
        rate: '0.05',
        sourceType: 'market',
        sourceName: 'Frankfurter',
        sourceTimestamp: now.subtract(const Duration(days: 3)),
        fetchedAt: now,
        isCached: const Value<bool>(true),
      ),
    );
    await database.coreDao.upsertTrip(
      TripsCompanion.insert(
        id: 'trip-1',
        updatedAt: now,
        name: 'Tokyo',
        destinationCodesJson: '["JP"]',
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        homeCurrency: 'CNY',
        localCurrenciesJson: '["JPY"]',
        totalBudget: const Value<String?>('1000'),
        status: 'active',
        createdAt: now,
      ),
    );

    await WidgetSnapshotService(
      database,
      gateway: gateway,
      clock: () => now,
    ).refresh();

    final payload = jsonDecode(gateway.payload!) as Map<String, Object?>;
    expect(payload['version'], 1);
    expect(payload['languageCode'], anyOf('en', 'zh'));
    expect((payload['rate']! as Map<String, Object?>)['isStale'], isTrue);
    expect((payload['trip']! as Map<String, Object?>)['name'], 'Tokyo');
    expect(gateway.clearCount, 0);
  });

  test('clear forwards to the App Group gateway', () async {
    await WidgetSnapshotService(database, gateway: gateway).clear();
    expect(gateway.clearCount, 1);
  });

  test(
    'writes the explicitly selected app language into the snapshot',
    () async {
      await database.coreDao.upsertUserSettings(
        UserSettingsRecordsCompanion.insert(
          id: 'app',
          updatedAt: now,
          defaultCurrency: 'CNY',
          favoriteCurrenciesJson: '[]',
          languageMode: 'english',
          refreshIntervalMinutes: 360,
        ),
      );

      await WidgetSnapshotService(
        database,
        gateway: gateway,
        clock: () => now,
      ).refresh();

      final payload = jsonDecode(gateway.payload!) as Map<String, Object?>;
      expect(payload['languageCode'], 'en');
    },
  );

  test('writes the rate for the currently selected currency pair', () async {
    await database.coreDao.upsertUserSettings(
      UserSettingsRecordsCompanion.insert(
        id: 'app',
        updatedAt: now,
        defaultCurrency: 'CNY',
        lastTransactionCurrency: const Value<String?>('JPY'),
        favoriteCurrenciesJson: '[]',
        languageMode: 'system',
        refreshIntervalMinutes: 360,
      ),
    );
    await database.coreDao.upsertRateSnapshot(
      RateSnapshotsCompanion.insert(
        id: 'selected-rate',
        updatedAt: now,
        baseCurrency: 'JPY',
        quoteCurrency: 'CNY',
        rate: '0.0478',
        sourceType: 'market',
        sourceName: 'Frankfurter',
        sourceTimestamp: now,
        fetchedAt: now.subtract(const Duration(minutes: 1)),
        isCached: const Value<bool>(true),
      ),
    );
    await database.coreDao.upsertRateSnapshot(
      RateSnapshotsCompanion.insert(
        id: 'newer-unrelated-rate',
        updatedAt: now,
        baseCurrency: 'USD',
        quoteCurrency: 'CNY',
        rate: '6.7372',
        sourceType: 'market',
        sourceName: 'Frankfurter',
        sourceTimestamp: now,
        fetchedAt: now,
        isCached: const Value<bool>(false),
      ),
    );

    await WidgetSnapshotService(
      database,
      gateway: gateway,
      clock: () => now,
    ).refresh();

    final payload = jsonDecode(gateway.payload!) as Map<String, Object?>;
    final rate = payload['rate']! as Map<String, Object?>;
    expect(rate['baseCurrency'], 'JPY');
    expect(rate['quoteCurrency'], 'CNY');
    expect(rate['rate'], '0.0478');
  });

  test('summarizes the latest standalone expense without a trip', () async {
    await database.coreDao.upsertExpense(
      ExpensesCompanion.insert(
        id: 'expense-1',
        updatedAt: now,
        title: 'Dinner',
        category: 'food',
        transactionAmount: '100',
        transactionCurrency: 'USD',
        referenceAmount: '673.66',
        homeCurrency: 'CNY',
        estimatedFinalAmount: '680',
        paymentRuleSnapshotJson: '{}',
        rateSnapshotJson: '{}',
        taxAmount: '0',
        tipAmount: '0',
        discountAmount: '0',
        occurredAt: now,
        status: 'estimated',
        createdAt: now,
      ),
    );

    await WidgetSnapshotService(
      database,
      gateway: gateway,
      clock: () => now,
    ).refresh();

    final payload = jsonDecode(gateway.payload!) as Map<String, Object?>;
    final trip = payload['trip']! as Map<String, Object?>;
    expect(trip['isUnassigned'], isTrue);
    expect(trip['spent'], '680');
    expect(trip['homeCurrency'], 'CNY');
    expect(trip['expenseCount'], 1);
    expect(trip['latestExpenseTitle'], 'Dinner');
  });
}

final class _FakeSnapshotGateway implements WidgetSnapshotGateway {
  String? payload;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
  }

  @override
  Future<void> write(String payloadJson) async {
    payload = payloadJson;
  }
}
