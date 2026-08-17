import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

final class DatabaseBootstrapper {
  DatabaseBootstrapper(this._database, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final DateTime Function() _clock;

  Future<void> seedCurrencyMetadata() async {
    final now = _clock().toUtc();
    await _database.transaction(() async {
      for (final currency in CurrencyCatalog.knownCurrencies) {
        await _database.coreDao.upsertCurrency(
          CurrenciesCompanion.insert(
            code: currency.code,
            numericCode: Value<String?>(currency.numericCode),
            name: currency.name,
            symbol: currency.symbol,
            minorUnits: currency.minorUnits,
            countryCodesJson: Value<String>(jsonEncode(currency.countryCodes)),
            updatedAt: now,
          ),
        );
      }
    });
  }
}
