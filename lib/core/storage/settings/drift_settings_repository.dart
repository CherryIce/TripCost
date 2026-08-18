import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';

final class DriftSettingsRepository
    implements SettingsRepository, CacheRepositoryObserver {
  DriftSettingsRepository(
    this._database, {
    money.CurrencyCatalog? currencyCatalog,
  }) : _currencyCatalog = currencyCatalog ?? money.CurrencyCatalog();

  static const String settingsRecordId = 'app';

  final AppDatabase _database;
  final money.CurrencyCatalog _currencyCatalog;

  @override
  Stream<void> watchChanges() =>
      _database.coreDao.watchUserSettings(settingsRecordId);

  @override
  Future<UserSettingsModel?> load() async {
    final row = await _database.coreDao.getUserSettings(settingsRecordId);
    if (row == null || row.deletedAt != null) {
      return null;
    }
    final favoriteCodes = _decodeStringList(row.favoriteCurrenciesJson);
    return UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: row.id,
        syncVersion: row.syncVersion,
        updatedAt: row.updatedAt.toUtc(),
        deletedAt: row.deletedAt?.toUtc(),
      ),
      defaultCurrency: _currencyCatalog.resolve(row.defaultCurrency),
      favoriteCurrencies: <money.Currency>[
        for (final code in favoriteCodes) _currencyCatalog.resolve(code),
      ],
      languageMode: AppLanguageMode.values.byName(row.languageMode),
      refreshInterval: Duration(minutes: row.refreshIntervalMinutes),
      wifiOnlyRefresh: row.wifiOnlyRefresh,
      syncEnabled: row.syncEnabled,
    );
  }

  @override
  Future<void> save(UserSettingsModel settings) async {
    await DatabaseBootstrapper(_database).seedCurrencyMetadata();
    await _ensureCurrencies(<money.Currency>{
      settings.defaultCurrency,
      ...settings.favoriteCurrencies,
    });
    await _database.coreDao.upsertUserSettings(
      UserSettingsRecordsCompanion.insert(
        id: settings.metadata.recordId,
        defaultCurrency: settings.defaultCurrency.code,
        favoriteCurrenciesJson: jsonEncode(<String>[
          for (final currency in settings.favoriteCurrencies) currency.code,
        ]),
        languageMode: settings.languageMode.name,
        refreshIntervalMinutes: settings.refreshInterval.inMinutes,
        wifiOnlyRefresh: Value<bool>(settings.wifiOnlyRefresh),
        syncEnabled: Value<bool>(settings.syncEnabled),
        syncVersion: Value<int>(settings.metadata.syncVersion),
        updatedAt: settings.metadata.updatedAt,
        deletedAt: Value<DateTime?>(settings.metadata.deletedAt),
      ),
    );
    _database.notifyCacheTable('user_settings_records');
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
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  List<String> _decodeStringList(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! List<Object?> || decoded.any((value) => value is! String)) {
      throw const FormatException('Expected a JSON string list.');
    }
    return decoded.cast<String>();
  }
}
