import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

final class DriftTripRepository implements TripRepository {
  DriftTripRepository(
    this._database, {
    money.CurrencyCatalog? currencyCatalog,
    DateTime Function()? clock,
  }) : _currencyCatalog = currencyCatalog ?? money.CurrencyCatalog(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  static const _entityType = 'trip';

  final AppDatabase _database;
  final money.CurrencyCatalog _currencyCatalog;
  final DateTime Function() _clock;

  @override
  Future<void> save(TripModel trip) async {
    await _database.transaction(() async {
      await _ensureCurrencies(<money.Currency>{
        trip.homeCurrency,
        ...trip.localCurrencies,
      });
      await _database.coreDao.upsertTrip(
        TripsCompanion.insert(
          id: trip.metadata.recordId,
          syncVersion: Value<int>(trip.metadata.syncVersion),
          updatedAt: trip.metadata.updatedAt,
          deletedAt: Value<DateTime?>(trip.metadata.deletedAt),
          name: trip.name,
          destinationCodesJson: jsonEncode(trip.destinationCodes),
          startDate: trip.startDate,
          endDate: trip.endDate,
          homeCurrency: trip.homeCurrency.code,
          localCurrenciesJson: jsonEncode(<String>[
            for (final currency in trip.localCurrencies) currency.code,
          ]),
          totalBudget: Value<String?>(trip.totalBudget?.amount.toString()),
          participantCount: Value<int>(trip.participantCount),
          defaultPaymentMethodId: Value<String?>(trip.defaultPaymentMethodId),
          offlinePackUpdatedAt: Value<DateTime?>(trip.offlinePackUpdatedAt),
          status: trip.status.name,
          createdAt: trip.createdAt,
        ),
      );
      await _saveMetadata(trip.metadata);
    });
  }

  @override
  Future<List<TripModel>> listActive() async {
    final rows = await _database.coreDao.activeTrips();
    return Future.wait(<Future<TripModel>>[
      for (final row in rows) _toDomain(row),
    ]);
  }

  @override
  Future<TripModel?> findById(String id) async {
    final row = await _database.coreDao.getTrip(id);
    return row == null || row.deletedAt != null ? null : _toDomain(row);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    requireUtc(deletedAtUtc, 'deletedAtUtc');
    await _database.transaction(() async {
      final row = await _database.coreDao.getTrip(id);
      if (row == null) return;
      await _database.coreDao.softDeleteTrip(id, deletedAtUtc);
      await _saveMetadata(
        SyncRecordMetadata(
          recordId: id,
          syncVersion: row.syncVersion + 1,
          updatedAt: deletedAtUtc,
          deletedAt: deletedAtUtc,
        ),
      );
    });
  }

  Future<TripModel> _toDomain(Trip row) async {
    final metadataRow = await _database.coreDao.getSyncMetadata(
      _entityType,
      row.id,
    );
    final localCodes = _decodeStringList(row.localCurrenciesJson);
    return TripModel(
      metadata: _metadataFrom(row, metadataRow),
      name: row.name,
      destinationCodes: _decodeStringList(row.destinationCodesJson),
      startDate: row.startDate.toUtc(),
      endDate: row.endDate.toUtc(),
      homeCurrency: _currencyCatalog.resolve(row.homeCurrency),
      localCurrencies: <money.Currency>[
        for (final code in localCodes) _currencyCatalog.resolve(code),
      ],
      totalBudget: row.totalBudget == null
          ? null
          : Money.parse(
              row.totalBudget!,
              _currencyCatalog.resolve(row.homeCurrency),
            ),
      participantCount: row.participantCount,
      defaultPaymentMethodId: row.defaultPaymentMethodId,
      offlinePackUpdatedAt: row.offlinePackUpdatedAt?.toUtc(),
      status: TripStatus.values.byName(row.status),
      createdAt: row.createdAt.toUtc(),
    );
  }

  SyncRecordMetadata _metadataFrom(Trip row, SyncMetadataEntry? metadata) {
    return SyncRecordMetadata(
      recordId: row.id,
      syncVersion: row.syncVersion,
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
      lastSyncedAt: metadata?.lastSyncedAt?.toUtc(),
      syncState: metadata == null
          ? SyncState.pending
          : SyncState.values.byName(metadata.syncState),
    );
  }

  Future<void> _saveMetadata(SyncRecordMetadata metadata) {
    return _database.coreDao.upsertSyncMetadata(
      SyncMetadataEntriesCompanion.insert(
        entityType: _entityType,
        recordId: metadata.recordId,
        syncVersion: metadata.syncVersion,
        syncState: metadata.syncState.name,
        updatedAt: metadata.updatedAt,
        deletedAt: Value<DateTime?>(metadata.deletedAt),
        lastSyncedAt: Value<DateTime?>(metadata.lastSyncedAt),
        changeId: const Value<String?>(null),
      ),
    );
  }

  Future<void> _ensureCurrencies(Set<money.Currency> currencies) async {
    for (final currency in currencies) {
      await _database.coreDao.upsertCurrency(
        CurrenciesCompanion.insert(
          code: currency.code,
          numericCode: Value<String?>(currency.numericCode),
          name: currency.name,
          symbol: currency.symbol,
          minorUnits: currency.minorUnits,
          countryCodesJson: Value<String>(jsonEncode(currency.countryCodes)),
          updatedAt: _clock().toUtc(),
        ),
      );
    }
  }
}

List<String> _decodeStringList(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is! List<Object?> || decoded.any((value) => value is! String)) {
    throw const FormatException('Expected a JSON string list.');
  }
  return decoded.cast<String>();
}
