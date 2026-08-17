import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

final class DriftPaymentMethodRepository implements PaymentMethodRepository {
  DriftPaymentMethodRepository(
    this._database, {
    money.CurrencyCatalog? currencyCatalog,
    DateTime Function()? clock,
  }) : _currencyCatalog = currencyCatalog ?? money.CurrencyCatalog(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final money.CurrencyCatalog _currencyCatalog;
  final DateTime Function() _clock;

  @override
  Future<void> save(PaymentMethodModel paymentMethod) async {
    await _ensureCurrency(paymentMethod.billingCurrency);
    await _database.coreDao.upsertPaymentMethod(
      PaymentMethodsCompanion.insert(
        id: paymentMethod.metadata.recordId,
        syncVersion: Value<int>(paymentMethod.metadata.syncVersion),
        updatedAt: paymentMethod.metadata.updatedAt,
        deletedAt: Value<DateTime?>(paymentMethod.metadata.deletedAt),
        name: paymentMethod.name,
        type: paymentMethod.type.name,
        network: paymentMethod.network.name,
        billingCurrency: paymentMethod.billingCurrency.code,
        foreignFeePercent: paymentMethod.foreignFeePercent.toString(),
        crossBorderFeePercent: paymentMethod.crossBorderFeePercent.toString(),
        rateMarkupPercent: paymentMethod.rateMarkupPercent.toString(),
        fixedFee: paymentMethod.fixedFee.toString(),
        cashbackPercent: paymentMethod.cashbackPercent.toString(),
        minimumFee: Value<String?>(paymentMethod.minimumFee?.toString()),
        maximumFee: Value<String?>(paymentMethod.maximumFee?.toString()),
        cashExchangeRate: Value<String?>(
          paymentMethod.cashExchangeRate?.toString(),
        ),
        supportedTxnTypesJson: jsonEncode(<String>[
          for (final type in paymentMethod.supportedTransactionTypes) type.name,
        ]),
        sourceUrl: Value<String?>(paymentMethod.sourceUrl),
        effectiveFrom: Value<DateTime?>(paymentMethod.effectiveFrom),
        lastVerifiedAt: Value<DateTime?>(paymentMethod.lastVerifiedAt),
        notes: Value<String?>(paymentMethod.notes),
        createdAt: paymentMethod.createdAt,
      ),
    );
  }

  @override
  Future<List<PaymentMethodModel>> listActive() async {
    final rows = await _database.coreDao.activePaymentMethods();
    return <PaymentMethodModel>[for (final row in rows) _toDomain(row)];
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    requireUtc(deletedAtUtc, 'deletedAtUtc');
    await _database.coreDao.softDeletePaymentMethod(id, deletedAtUtc);
  }

  PaymentMethodModel _toDomain(PaymentMethod row) {
    final decodedTypes = jsonDecode(row.supportedTxnTypesJson);
    if (decodedTypes is! List<Object?> ||
        decodedTypes.any((value) => value is! String)) {
      throw const FormatException('Expected transaction type string list.');
    }
    return PaymentMethodModel(
      metadata: SyncRecordMetadata(
        recordId: row.id,
        syncVersion: row.syncVersion,
        updatedAt: row.updatedAt.toUtc(),
        deletedAt: row.deletedAt?.toUtc(),
      ),
      name: row.name,
      type: PaymentMethodType.values.byName(row.type),
      network: PaymentNetwork.values.byName(row.network),
      billingCurrency: _currencyCatalog.resolve(row.billingCurrency),
      foreignFeePercent: DecimalValue.parse(row.foreignFeePercent),
      crossBorderFeePercent: DecimalValue.parse(row.crossBorderFeePercent),
      rateMarkupPercent: DecimalValue.parse(row.rateMarkupPercent),
      fixedFee: DecimalValue.parse(row.fixedFee),
      cashbackPercent: DecimalValue.parse(row.cashbackPercent),
      minimumFee: row.minimumFee == null
          ? null
          : DecimalValue.parse(row.minimumFee!),
      maximumFee: row.maximumFee == null
          ? null
          : DecimalValue.parse(row.maximumFee!),
      cashExchangeRate: row.cashExchangeRate == null
          ? null
          : DecimalValue.parse(row.cashExchangeRate!),
      supportedTransactionTypes: <TransactionType>{
        for (final value in decodedTypes.cast<String>())
          TransactionType.values.byName(value),
      },
      sourceUrl: row.sourceUrl,
      effectiveFrom: row.effectiveFrom?.toUtc(),
      lastVerifiedAt: row.lastVerifiedAt?.toUtc(),
      notes: row.notes,
      createdAt: row.createdAt.toUtc(),
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
