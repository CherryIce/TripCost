import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/rates/data/drift_rate_snapshot_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

final class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(
    this._database, {
    money.CurrencyCatalog? currencyCatalog,
  }) : _currencyCatalog = currencyCatalog ?? money.CurrencyCatalog();

  static const _entityType = 'expense';

  final AppDatabase _database;
  final money.CurrencyCatalog _currencyCatalog;

  @override
  Future<void> save(ExpenseModel expense) {
    return _database.transaction(() => _save(expense));
  }

  @override
  Future<void> saveWithCalibration(
    ExpenseModel expense,
    FeeCalibrationModel calibration,
  ) {
    return _database.transaction(() async {
      await _save(expense);
      await DriftFeeCalibrationRepository(
        _database,
        currencyCatalog: _currencyCatalog,
      ).save(calibration);
    });
  }

  Future<void> _save(ExpenseModel expense) async {
    await DriftRateSnapshotRepository(
      _database,
      currencyCatalog: _currencyCatalog,
    ).save(expense.rateSnapshot);
    await _database.coreDao.upsertExpense(
      ExpensesCompanion.insert(
        id: expense.metadata.recordId,
        syncVersion: Value<int>(expense.metadata.syncVersion),
        updatedAt: expense.metadata.updatedAt,
        deletedAt: Value<DateTime?>(expense.metadata.deletedAt),
        tripId: Value<String?>(expense.tripId),
        title: expense.title,
        category: expense.category,
        transactionAmount: expense.transactionAmount.amount.toString(),
        transactionCurrency: expense.transactionAmount.currency.code,
        referenceAmount: expense.referenceAmount.amount.toString(),
        homeCurrency: expense.referenceAmount.currency.code,
        estimatedFinalAmount: expense.estimatedFinalAmount.amount.toString(),
        actualFinalAmount: Value<String?>(
          expense.actualFinalAmount?.amount.toString(),
        ),
        paymentMethodId: Value<String?>(expense.paymentMethodId),
        paymentRuleSnapshotJson: jsonEncode(
          expense.paymentRuleSnapshot.toJson(),
        ),
        rateSnapshotId: Value<String?>(expense.rateSnapshot.metadata.recordId),
        rateSnapshotJson: jsonEncode(expense.rateSnapshot.toSnapshotJson()),
        taxAmount: expense.taxAmount.amount.toString(),
        tipAmount: expense.tipAmount.amount.toString(),
        discountAmount: expense.discountAmount.amount.toString(),
        participantCount: Value<int>(expense.participantCount),
        occurredAt: expense.occurredAt,
        receiptLocalPath: Value<String?>(expense.receiptLocalPath),
        notes: Value<String?>(expense.notes),
        budgetIncluded: Value<bool>(expense.budgetIncluded),
        status: expense.status.name,
        entryType: Value<String>(expense.entryType.name),
        relatedExpenseId: Value<String?>(expense.relatedExpenseId),
        createdAt: expense.createdAt,
      ),
    );
    await _saveMetadata(expense.metadata);
  }

  @override
  Future<List<ExpenseModel>> listActive() async {
    final rows = await _database.coreDao.activeExpenses();
    return Future.wait(<Future<ExpenseModel>>[
      for (final row in rows) _toDomain(row),
    ]);
  }

  @override
  Future<List<ExpenseModel>> listForTrip(String tripId) async {
    final rows = await _database.coreDao.activeExpensesForTrip(tripId);
    return Future.wait(<Future<ExpenseModel>>[
      for (final row in rows) _toDomain(row),
    ]);
  }

  @override
  Future<ExpenseModel?> findById(String id) async {
    final row = await _database.coreDao.getExpense(id);
    return row == null || row.deletedAt != null ? null : _toDomain(row);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    requireUtc(deletedAtUtc, 'deletedAtUtc');
    await _database.transaction(() async {
      final row = await _database.coreDao.getExpense(id);
      if (row == null) return;
      await _database.coreDao.softDeleteExpense(id, deletedAtUtc);
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

  Future<ExpenseModel> _toDomain(Expense row) async {
    final homeCurrency = _currencyCatalog.resolve(row.homeCurrency);
    final transactionCurrency = _currencyCatalog.resolve(
      row.transactionCurrency,
    );
    final metadata = await _database.coreDao.getSyncMetadata(
      _entityType,
      row.id,
    );
    return ExpenseModel(
      metadata: SyncRecordMetadata(
        recordId: row.id,
        syncVersion: row.syncVersion,
        updatedAt: row.updatedAt.toUtc(),
        deletedAt: row.deletedAt?.toUtc(),
        lastSyncedAt: metadata?.lastSyncedAt?.toUtc(),
        syncState: metadata == null
            ? SyncState.pending
            : SyncState.values.byName(metadata.syncState),
      ),
      tripId: row.tripId,
      title: row.title,
      category: row.category,
      transactionAmount: Money.parse(
        row.transactionAmount,
        transactionCurrency,
      ),
      referenceAmount: Money.parse(row.referenceAmount, homeCurrency),
      estimatedFinalAmount: Money.parse(row.estimatedFinalAmount, homeCurrency),
      actualFinalAmount: row.actualFinalAmount == null
          ? null
          : Money.parse(row.actualFinalAmount!, homeCurrency),
      paymentMethodId: row.paymentMethodId,
      paymentRuleSnapshot: _paymentRuleFromJson(row.paymentRuleSnapshotJson),
      rateSnapshot: _rateSnapshotFromJson(row.rateSnapshotJson),
      taxAmount: Money.parse(row.taxAmount, homeCurrency),
      tipAmount: Money.parse(row.tipAmount, homeCurrency),
      discountAmount: Money.parse(row.discountAmount, homeCurrency),
      participantCount: row.participantCount,
      occurredAt: row.occurredAt.toUtc(),
      receiptLocalPath: row.receiptLocalPath,
      notes: row.notes,
      budgetIncluded: row.budgetIncluded,
      status: ExpenseStatus.values.byName(row.status),
      entryType: ExpenseEntryType.values.byName(row.entryType),
      relatedExpenseId: row.relatedExpenseId,
      createdAt: row.createdAt.toUtc(),
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

  PaymentRuleSnapshot _paymentRuleFromJson(String encoded) {
    final json = _decodeMap(encoded);
    final transactionTypes = json['supportedTransactionTypes'];
    if (transactionTypes is! List<Object?> ||
        transactionTypes.any((value) => value is! String)) {
      throw const FormatException('Invalid payment rule transaction types.');
    }
    DecimalValue? optionalDecimal(String key) {
      final value = json[key];
      return value == null ? null : DecimalValue.parse(value as String);
    }

    return PaymentRuleSnapshot(
      paymentMethodId: json['paymentMethodId'] as String,
      name: json['name'] as String,
      type: PaymentMethodType.values.byName(json['type'] as String),
      network: PaymentNetwork.values.byName(json['network'] as String),
      billingCurrencyCode: json['billingCurrency'] as String,
      foreignFeePercent: DecimalValue.parse(
        json['foreignFeePercent'] as String,
      ),
      crossBorderFeePercent: DecimalValue.parse(
        json['crossBorderFeePercent'] as String,
      ),
      rateMarkupPercent: DecimalValue.parse(
        json['rateMarkupPercent'] as String,
      ),
      fixedFee: DecimalValue.parse(json['fixedFee'] as String),
      cashbackPercent: DecimalValue.parse(json['cashbackPercent'] as String),
      minimumFee: optionalDecimal('minimumFee'),
      maximumFee: optionalDecimal('maximumFee'),
      cashExchangeRate: optionalDecimal('cashExchangeRate'),
      supportedTransactionTypes: <TransactionType>{
        for (final value in transactionTypes.cast<String>())
          TransactionType.values.byName(value),
      },
    );
  }

  RateSnapshotModel _rateSnapshotFromJson(String encoded) {
    final json = _decodeMap(encoded);
    final base = _currencyCatalog.resolve(json['baseCurrency'] as String);
    final quote = _currencyCatalog.resolve(json['quoteCurrency'] as String);
    final sourceTimestamp = DateTime.parse(
      json['sourceTimestamp'] as String,
    ).toUtc();
    final fetchedAt = DateTime.parse(json['fetchedAt'] as String).toUtc();
    return RateSnapshotModel(
      metadata: SyncRecordMetadata(
        recordId: json['id'] as String,
        syncVersion: 1,
        updatedAt: fetchedAt,
        syncState: SyncState.clean,
      ),
      baseCurrency: base,
      quoteCurrency: quote,
      rate: DecimalValue.parse(json['rate'] as String),
      sourceType: RateSourceType.values.byName(json['sourceType'] as String),
      sourceName: json['sourceName'] as String,
      sourceTimestamp: sourceTimestamp,
      fetchedAt: fetchedAt,
      isCached: json['isCached'] as bool,
    );
  }
}

final class DriftFeeCalibrationRepository implements FeeCalibrationRepository {
  DriftFeeCalibrationRepository(
    this._database, {
    money.CurrencyCatalog? currencyCatalog,
  }) : _currencyCatalog = currencyCatalog ?? money.CurrencyCatalog();

  static const _entityType = 'feeCalibration';

  final AppDatabase _database;
  final money.CurrencyCatalog _currencyCatalog;

  @override
  Future<void> save(FeeCalibrationModel calibration) async {
    await _database.coreDao.upsertFeeCalibration(
      FeeCalibrationsCompanion.insert(
        id: calibration.metadata.recordId,
        syncVersion: Value<int>(calibration.metadata.syncVersion),
        updatedAt: calibration.metadata.updatedAt,
        deletedAt: Value<DateTime?>(calibration.metadata.deletedAt),
        paymentMethodId: calibration.paymentMethodId,
        expenseId: calibration.expenseId,
        referenceAmount: calibration.referenceAmount.amount.toString(),
        actualFinalAmount: calibration.actualFinalAmount.amount.toString(),
        effectiveMarkupPercent: calibration.effectiveMarkupPercent.toString(),
        calculatedAt: calibration.calculatedAt,
      ),
    );
    await _database.coreDao.upsertSyncMetadata(
      SyncMetadataEntriesCompanion.insert(
        entityType: _entityType,
        recordId: calibration.metadata.recordId,
        syncVersion: calibration.metadata.syncVersion,
        syncState: calibration.metadata.syncState.name,
        updatedAt: calibration.metadata.updatedAt,
        deletedAt: Value<DateTime?>(calibration.metadata.deletedAt),
        lastSyncedAt: Value<DateTime?>(calibration.metadata.lastSyncedAt),
      ),
    );
  }

  @override
  Future<List<FeeCalibrationModel>> listForPaymentMethod(
    String paymentMethodId,
  ) async {
    final rows = await _database.coreDao.calibrationsForPaymentMethod(
      paymentMethodId,
    );
    final result = <FeeCalibrationModel>[];
    for (final row in rows) {
      final expense = await _database.coreDao.getExpense(row.expenseId);
      if (expense == null) continue;
      final currency = _currencyCatalog.resolve(expense.homeCurrency);
      result.add(
        FeeCalibrationModel(
          metadata: SyncRecordMetadata(
            recordId: row.id,
            syncVersion: row.syncVersion,
            updatedAt: row.updatedAt.toUtc(),
            deletedAt: row.deletedAt?.toUtc(),
          ),
          paymentMethodId: row.paymentMethodId,
          expenseId: row.expenseId,
          referenceAmount: Money.parse(row.referenceAmount, currency),
          actualFinalAmount: Money.parse(row.actualFinalAmount, currency),
          effectiveMarkupPercent: DecimalValue.parse(
            row.effectiveMarkupPercent,
          ),
          calculatedAt: row.calculatedAt.toUtc(),
        ),
      );
    }
    return result;
  }
}

Map<String, Object?> _decodeMap(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return decoded;
}
