import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/core/storage/data_reset_coordinator.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

abstract interface class WidgetSnapshotGateway {
  Future<void> write(String payloadJson);

  Future<void> clear();
}

final class PlatformWidgetSnapshotGateway implements WidgetSnapshotGateway {
  PlatformWidgetSnapshotGateway({SharedSnapshotApi? api})
    : _api = api ?? SharedSnapshotApi();

  final SharedSnapshotApi _api;

  @override
  Future<void> write(String payloadJson) {
    return _api.writeWidgetSnapshot(
      SharedSnapshot(
        contractVersion: WidgetSnapshotService.contractVersion,
        payloadJson: payloadJson,
      ),
    );
  }

  @override
  Future<void> clear() => _api.clearWidgetSnapshot();
}

final class WidgetSnapshotService implements SharedSnapshotStore {
  WidgetSnapshotService(
    this._database, {
    WidgetSnapshotGateway? gateway,
    DateTime Function()? clock,
  }) : _gateway = gateway ?? PlatformWidgetSnapshotGateway(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  static const int contractVersion = 1;
  static const Duration staleAfter = Duration(hours: 48);

  final AppDatabase _database;
  final WidgetSnapshotGateway _gateway;
  final DateTime Function() _clock;

  Future<void> refresh() async {
    final now = _clock().toUtc();
    final payload = <String, Object?>{
      'version': contractVersion,
      'generatedAtUtc': now.toIso8601String(),
      'languageCode': await _languageCode(),
      'rate': await _rateSummary(now),
      'trip': await _tripSummary(),
    };
    await _gateway.write(jsonEncode(payload));
  }

  @override
  Future<void> clear() => _gateway.clear();

  Future<String> _languageCode() async {
    try {
      final mode =
          (await DriftSettingsRepository(_database).load())?.languageMode ??
          AppLanguageMode.system;
      return switch (mode) {
        AppLanguageMode.simplifiedChinese => 'zh',
        AppLanguageMode.english => 'en',
        AppLanguageMode.system => _supportedLanguageCode(
          PlatformDispatcher.instance.locale.languageCode,
        ),
      };
    } on Object {
      return _supportedLanguageCode(
        PlatformDispatcher.instance.locale.languageCode,
      );
    }
  }

  Future<Map<String, Object?>?> _rateSummary(DateTime now) async {
    UserSettingsModel? settings;
    try {
      settings = await DriftSettingsRepository(_database).load();
    } on Object {
      // Older or partially restored databases can still show their latest rate.
    }
    final row = settings == null
        ? await _database
              .customSelect(
                'SELECT base_currency, quote_currency, rate, '
                'source_timestamp, is_cached FROM rate_snapshots '
                'WHERE deleted_at IS NULL '
                'ORDER BY fetched_at DESC LIMIT 1',
              )
              .getSingleOrNull()
        : await _database
              .customSelect(
                'SELECT base_currency, quote_currency, rate, '
                'source_timestamp, is_cached FROM rate_snapshots '
                'WHERE deleted_at IS NULL AND base_currency = ? '
                'AND quote_currency = ? '
                'ORDER BY fetched_at DESC LIMIT 1',
                variables: <Variable<Object>>[
                  Variable<String>(settings.lastTransactionCurrency.code),
                  Variable<String>(settings.defaultCurrency.code),
                ],
              )
              .getSingleOrNull();
    if (row == null) return null;
    final sourceAt = _dateFromDb(row.data['source_timestamp']);
    final rate = row.data['rate']! as String;
    return <String, Object?>{
      'baseCurrency': row.data['base_currency']! as String,
      'quoteCurrency': row.data['quote_currency']! as String,
      'amount': '1',
      'convertedAmount': rate,
      'rate': rate,
      'rateDate': sourceAt.toIso8601String().substring(0, 10),
      'isCached': _boolFromDb(row.data['is_cached']),
      'isStale': now.difference(sourceAt) > staleAfter,
    };
  }

  Future<Map<String, Object?>?> _tripSummary() async {
    final latestExpense = await _database
        .customSelect(
          'SELECT trip_id, title, home_currency, actual_final_amount, '
          'estimated_final_amount FROM expenses '
          'WHERE deleted_at IS NULL AND budget_included = 1 '
          'ORDER BY occurred_at DESC, created_at DESC LIMIT 1',
        )
        .getSingleOrNull();

    if (latestExpense != null) {
      final tripId = latestExpense.data['trip_id'] as String?;
      final homeCurrency = latestExpense.data['home_currency']! as String;
      final trip = tripId == null
          ? null
          : await _database
                .customSelect(
                  'SELECT name, home_currency, total_budget FROM trips '
                  'WHERE deleted_at IS NULL AND id = ? LIMIT 1',
                  variables: <Variable<Object>>[Variable<String>(tripId)],
                )
                .getSingleOrNull();
      final expenses = await _database
          .customSelect(
            trip == null
                ? tripId == null
                      ? 'SELECT actual_final_amount, estimated_final_amount '
                            'FROM expenses WHERE deleted_at IS NULL '
                            'AND budget_included = 1 AND trip_id IS NULL '
                            'AND home_currency = ?'
                      : 'SELECT actual_final_amount, estimated_final_amount '
                            'FROM expenses WHERE deleted_at IS NULL '
                            'AND budget_included = 1 AND trip_id = ?'
                : 'SELECT actual_final_amount, estimated_final_amount '
                      'FROM expenses WHERE deleted_at IS NULL '
                      'AND budget_included = 1 AND trip_id = ?',
            variables: <Variable<Object>>[
              Variable<String>(tripId ?? homeCurrency),
            ],
          )
          .get();
      final latestAmount =
          latestExpense.data['actual_final_amount'] ??
          latestExpense.data['estimated_final_amount'];
      return <String, Object?>{
        'name': trip?.data['name'] as String? ?? '',
        'homeCurrency': trip?.data['home_currency'] as String? ?? homeCurrency,
        'spent': _sumExpenses(expenses).toString(),
        'budget': trip?.data['total_budget'] as String?,
        'expenseCount': expenses.length,
        'latestExpenseTitle': latestExpense.data['title']! as String,
        'latestExpenseAmount': latestAmount as String?,
        'isUnassigned': trip == null,
      };
    }

    final trip = await _database
        .customSelect(
          'SELECT id, name, home_currency, total_budget FROM trips '
          "WHERE deleted_at IS NULL AND status IN ('active', 'upcoming') "
          "ORDER BY CASE status WHEN 'active' THEN 0 ELSE 1 END, start_date "
          'LIMIT 1',
        )
        .getSingleOrNull();
    if (trip == null) return null;
    return <String, Object?>{
      'name': trip.data['name']! as String,
      'homeCurrency': trip.data['home_currency']! as String,
      'spent': DecimalValue.zero.toString(),
      'budget': trip.data['total_budget'] as String?,
      'expenseCount': 0,
      'latestExpenseTitle': null,
      'latestExpenseAmount': null,
      'isUnassigned': false,
    };
  }

  DecimalValue _sumExpenses(List<QueryRow> expenses) {
    var spent = DecimalValue.zero;
    for (final expense in expenses) {
      final value =
          expense.data['actual_final_amount'] ??
          expense.data['estimated_final_amount'];
      if (value is String) spent += DecimalValue.parse(value);
    }
    return spent;
  }
}

DateTime _dateFromDb(Object? value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  if (value is String) return DateTime.parse(value).toUtc();
  throw const FormatException('Invalid Widget snapshot timestamp.');
}

bool _boolFromDb(Object? value) => value == true || value == 1;

String _supportedLanguageCode(String languageCode) =>
    languageCode.toLowerCase() == 'zh' ? 'zh' : 'en';
