import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

final class DriftRateSnapshotRepository implements RateSnapshotRepository {
  DriftRateSnapshotRepository(
    this._database, {
    money.CurrencyCatalog? currencyCatalog,
    DateTime Function()? clock,
  }) : _currencyCatalog = currencyCatalog ?? money.CurrencyCatalog(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final money.CurrencyCatalog _currencyCatalog;
  final DateTime Function() _clock;

  @override
  Future<void> save(RateSnapshotModel snapshot) async {
    await _ensureCurrency(snapshot.baseCurrency);
    await _ensureCurrency(snapshot.quoteCurrency);
    await _database.coreDao.upsertRateSnapshot(
      RateSnapshotsCompanion.insert(
        id: snapshot.metadata.recordId,
        syncVersion: Value<int>(snapshot.metadata.syncVersion),
        updatedAt: snapshot.metadata.updatedAt,
        deletedAt: Value<DateTime?>(snapshot.metadata.deletedAt),
        baseCurrency: snapshot.baseCurrency.code,
        quoteCurrency: snapshot.quoteCurrency.code,
        rate: snapshot.rate.toString(),
        sourceType: snapshot.sourceType.name,
        sourceName: snapshot.sourceName,
        sourceTimestamp: snapshot.sourceTimestamp,
        fetchedAt: snapshot.fetchedAt,
        isCached: Value<bool>(snapshot.isCached),
      ),
    );
  }

  @override
  Future<RateSnapshotModel?> findById(String id) async {
    final row = await _database.coreDao.getRateSnapshot(id);
    return row == null || row.deletedAt != null ? null : _toDomain(row);
  }

  @override
  Future<RateSnapshotModel?> findLatest({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    RateSourceType? sourceType,
    DateTime? sourceAtOrBefore,
  }) async {
    final row = await _database.coreDao.latestRateSnapshot(
      baseCurrencyCode: _normalizeCode(baseCurrencyCode),
      quoteCurrencyCode: _normalizeCode(quoteCurrencyCode),
      sourceType: sourceType?.name,
      sourceAtOrBefore: sourceAtOrBefore,
    );
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> softDeleteForPairAndSource({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    required RateSourceType sourceType,
    required DateTime deletedAtUtc,
  }) async {
    requireUtc(deletedAtUtc, 'deletedAtUtc');
    await _database.coreDao.softDeleteRateSnapshotsForPairAndSource(
      baseCurrencyCode: _normalizeCode(baseCurrencyCode),
      quoteCurrencyCode: _normalizeCode(quoteCurrencyCode),
      sourceType: sourceType.name,
      deletedAt: deletedAtUtc,
    );
  }

  RateSnapshotModel _toDomain(RateSnapshot row) {
    return RateSnapshotModel(
      metadata: SyncRecordMetadata(
        recordId: row.id,
        syncVersion: row.syncVersion,
        updatedAt: row.updatedAt.toUtc(),
        deletedAt: row.deletedAt?.toUtc(),
      ),
      baseCurrency: _currencyCatalog.resolve(row.baseCurrency),
      quoteCurrency: _currencyCatalog.resolve(row.quoteCurrency),
      rate: DecimalValue.parse(row.rate),
      sourceType: RateSourceType.values.byName(row.sourceType),
      sourceName: row.sourceName,
      sourceTimestamp: row.sourceTimestamp.toUtc(),
      fetchedAt: row.fetchedAt.toUtc(),
      isCached: row.isCached,
    );
  }

  Future<void> _ensureCurrency(money.Currency currency) {
    return _database.coreDao.upsertCurrency(
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

String _normalizeCode(String value) {
  final normalized = value.trim().toUpperCase();
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
    throw FormatException('Invalid ISO 4217 code: $value');
  }
  return normalized;
}
