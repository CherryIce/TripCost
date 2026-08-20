import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/data/drift_payment_method_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/trips/data/drift_trip_repository.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() => database.close());

  test('round-trips trip configuration and sync metadata', () async {
    await DriftPaymentMethodRepository(database).save(fixturePaymentMethod());
    final repository = DriftTripRepository(database);
    await repository.save(fixtureTrip());

    final restored = await repository.findById('trip-1');
    expect(restored, isNotNull);
    expect(restored!.name, 'Tokyo week');
    expect(restored.destinationCodes, <String>['JP']);
    expect(restored.localCurrencies.single.code, 'JPY');
    expect(restored.totalBudget!.amount.toString(), '1000');
    expect(restored.defaultPaymentMethodId, 'payment-1');
    expect(restored.metadata.syncState, SyncState.pending);
  });

  test('round-trips ordered multi-country route stops', () async {
    final catalog = money.CurrencyCatalog();
    final cny = catalog.resolve('CNY');
    final jpy = catalog.resolve('JPY');
    final krw = catalog.resolve('KRW');
    final repository = DriftTripRepository(database);
    await repository.save(
      TripModel(
        metadata: fixtureMetadata('trip-route'),
        name: 'Japan and Korea',
        destinationCodes: const <String>['JP', 'KR'],
        startDate: DateTime.utc(2026, 8, 19),
        endDate: DateTime.utc(2026, 8, 28),
        stops: <TripStopModel>[
          TripStopModel(
            countryCode: 'JP',
            startDate: DateTime.utc(2026, 8, 19),
            endDate: DateTime.utc(2026, 8, 23),
            localCurrency: jpy,
          ),
          TripStopModel(
            countryCode: 'KR',
            startDate: DateTime.utc(2026, 8, 24),
            endDate: DateTime.utc(2026, 8, 28),
            localCurrency: krw,
          ),
        ],
        homeCurrency: cny,
        localCurrencies: <money.Currency>[jpy, krw],
        totalBudget: Money.parse('20000', cny),
        participantCount: 1,
        defaultPaymentMethodId: null,
        status: TripStatus.active,
        createdAt: DateTime.utc(2026, 8, 18),
      ),
    );

    final restored = await repository.findById('trip-route');
    expect(restored!.stops.map((stop) => stop.countryCode), <String>[
      'JP',
      'KR',
    ]);
    expect(restored.stops.first.endDate, DateTime.utc(2026, 8, 23));
    expect(restored.stops.last.startDate, DateTime.utc(2026, 8, 24));
    expect(restored.stops.map((stop) => stop.localCurrency.code), <String>[
      'JPY',
      'KRW',
    ]);
  });

  test('soft deletion hides the trip without deleting its row', () async {
    await DriftPaymentMethodRepository(database).save(fixturePaymentMethod());
    final repository = DriftTripRepository(database);
    await repository.save(fixtureTrip());
    await repository.softDelete('trip-1', DateTime.utc(2026, 8, 18));

    expect(await repository.findById('trip-1'), null);
    expect(await repository.listActive(), isEmpty);
    final row = await database.coreDao.getTrip('trip-1');
    expect(row!.deletedAt!.toUtc(), DateTime.utc(2026, 8, 18));
  });
}
