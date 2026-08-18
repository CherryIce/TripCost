import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/currencies/data/iso_currency_metadata.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/storage/database/app_database.dart' as db;

final class CurrencyDirectoryRepository implements CacheRepositoryObserver {
  CurrencyDirectoryRepository({
    required db.AppDatabase database,
    required FrankfurterRatesGateway gateway,
    IsoCurrencyMetadata? metadata,
    DateTime Function()? clock,
  }) : _database = database,
       _gateway = gateway,
       metadata = metadata ?? IsoCurrencyMetadata(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  final db.AppDatabase _database;
  final FrankfurterRatesGateway _gateway;
  final IsoCurrencyMetadata metadata;
  final DateTime Function() _clock;

  @override
  Stream<void> watchChanges() => _database.coreDao.watchActiveCurrencies();

  List<money.Currency> get fallbackCurrencies =>
      money.CurrencyCatalog.knownCurrencies;

  Future<List<money.Currency>> loadCached() async {
    final rows = await _database.coreDao.activeCurrencies();
    return List<money.Currency>.unmodifiable(
      rows.map(_fromRow).whereType<money.Currency>(),
    );
  }

  Future<List<money.Currency>> refresh() async {
    final remote = await _gateway.getCurrencies();
    final currencies = <money.Currency>[
      for (final item in remote)
        if (metadata.enrich(item) case final currency?) currency,
    ]..sort((left, right) => left.code.compareTo(right.code));
    if (currencies.isEmpty) {
      throw const FormatException(
        'Frankfurter returned no supported travel currencies.',
      );
    }
    final now = _clock().toUtc();
    await _database.transaction(() async {
      for (final currency in currencies) {
        await _database.coreDao.upsertCurrency(
          db.CurrenciesCompanion.insert(
            code: currency.code,
            numericCode: Value<String?>(currency.numericCode),
            name: currency.name,
            symbol: currency.symbol,
            minorUnits: currency.minorUnits,
            countryCodesJson: Value<String>(jsonEncode(currency.countryCodes)),
            updatedAt: now,
            deletedAt: const Value<DateTime?>(null),
          ),
        );
      }
      await _database.coreDao.softDeleteCurrenciesNotIn(
        currencies.map((currency) => currency.code),
        now,
      );
    });
    _database.notifyCacheTable('currencies');
    return List<money.Currency>.unmodifiable(currencies);
  }

  money.Currency? _fromRow(db.Currency row) {
    try {
      final decoded = jsonDecode(row.countryCodesJson);
      if (decoded is! List<Object?> || decoded.any((item) => item is! String)) {
        return null;
      }
      return money.Currency(
        code: row.code,
        numericCode: row.numericCode,
        name: row.name,
        symbol: row.symbol,
        minorUnits: row.minorUnits,
        countryCodes: decoded.cast<String>(),
      );
    } on Object {
      return null;
    }
  }
}
