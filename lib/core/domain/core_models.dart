import 'dart:collection';

import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

enum RateSourceType { market, visa, mastercard, unionpay, manual }

enum PaymentMethodType { creditCard, debitCard, cash, wallet, custom }

enum PaymentNetwork { visa, mastercard, unionpay, jcb, other, unknown }

enum TransactionType { purchase, atm }

enum TripStatus { upcoming, active, archived }

enum ExpenseStatus { estimated, confirmed }

enum ExpenseEntryType { purchase, refund, partialRefund, voided }

enum SyncState { clean, pending, syncing, conflict, failed }

enum AppLanguageMode { system, simplifiedChinese, english }

final class SyncRecordMetadata {
  SyncRecordMetadata({
    required this.recordId,
    required this.syncVersion,
    required DateTime updatedAt,
    this.syncState = SyncState.pending,
    DateTime? deletedAt,
    DateTime? lastSyncedAt,
  }) : updatedAt = requireUtc(updatedAt, 'updatedAt'),
       deletedAt = requireOptionalUtc(deletedAt, 'deletedAt'),
       lastSyncedAt = requireOptionalUtc(lastSyncedAt, 'lastSyncedAt') {
    if (recordId.isEmpty) {
      throw const FormatException('recordId must not be empty.');
    }
    if (syncVersion < 1) {
      throw RangeError.range(syncVersion, 1, null, 'syncVersion');
    }
  }

  final String recordId;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final SyncState syncState;
}

final class RateSnapshotModel {
  RateSnapshotModel({
    required this.metadata,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.sourceType,
    required this.sourceName,
    required DateTime sourceTimestamp,
    required DateTime fetchedAt,
    required this.isCached,
  }) : sourceTimestamp = requireUtc(sourceTimestamp, 'sourceTimestamp'),
       fetchedAt = requireUtc(fetchedAt, 'fetchedAt') {
    if (rate.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('Exchange rate must be positive.');
    }
  }

  final SyncRecordMetadata metadata;
  final Currency baseCurrency;
  final Currency quoteCurrency;
  final DecimalValue rate;
  final RateSourceType sourceType;
  final String sourceName;
  final DateTime sourceTimestamp;
  final DateTime fetchedAt;
  final bool isCached;

  Map<String, Object?> toSnapshotJson() => <String, Object?>{
    'id': metadata.recordId,
    'baseCurrency': baseCurrency.code,
    'quoteCurrency': quoteCurrency.code,
    'rate': rate.toString(),
    'sourceType': sourceType.name,
    'sourceName': sourceName,
    'sourceTimestamp': sourceTimestamp.toIso8601String(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'isCached': isCached,
  };
}

final class PaymentRuleSnapshot {
  const PaymentRuleSnapshot({
    required this.paymentMethodId,
    required this.name,
    required this.type,
    required this.network,
    required this.billingCurrencyCode,
    required this.foreignFeePercent,
    required this.crossBorderFeePercent,
    required this.rateMarkupPercent,
    required this.fixedFee,
    required this.cashbackPercent,
    required this.minimumFee,
    required this.maximumFee,
    required this.cashExchangeRate,
    required this.supportedTransactionTypes,
  });

  final String paymentMethodId;
  final String name;
  final PaymentMethodType type;
  final PaymentNetwork network;
  final String billingCurrencyCode;
  final DecimalValue foreignFeePercent;
  final DecimalValue crossBorderFeePercent;
  final DecimalValue rateMarkupPercent;
  final DecimalValue fixedFee;
  final DecimalValue cashbackPercent;
  final DecimalValue? minimumFee;
  final DecimalValue? maximumFee;
  final DecimalValue? cashExchangeRate;
  final Set<TransactionType> supportedTransactionTypes;

  Map<String, Object?> toJson() => <String, Object?>{
    'paymentMethodId': paymentMethodId,
    'name': name,
    'type': type.name,
    'network': network.name,
    'billingCurrency': billingCurrencyCode,
    'foreignFeePercent': foreignFeePercent.toString(),
    'crossBorderFeePercent': crossBorderFeePercent.toString(),
    'rateMarkupPercent': rateMarkupPercent.toString(),
    'fixedFee': fixedFee.toString(),
    'cashbackPercent': cashbackPercent.toString(),
    'minimumFee': minimumFee?.toString(),
    'maximumFee': maximumFee?.toString(),
    'cashExchangeRate': cashExchangeRate?.toString(),
    'supportedTransactionTypes': <String>[
      for (final type in supportedTransactionTypes) type.name,
    ],
  };
}

final class PaymentMethodModel {
  PaymentMethodModel({
    required this.metadata,
    required this.name,
    required this.type,
    required this.network,
    required this.billingCurrency,
    required this.foreignFeePercent,
    required this.crossBorderFeePercent,
    required this.rateMarkupPercent,
    required this.fixedFee,
    required this.cashbackPercent,
    required this.minimumFee,
    required this.maximumFee,
    this.cashExchangeRate,
    required Set<TransactionType> supportedTransactionTypes,
    required DateTime createdAt,
    this.sourceUrl,
    DateTime? effectiveFrom,
    DateTime? lastVerifiedAt,
    this.notes,
  }) : supportedTransactionTypes = UnmodifiableSetView<TransactionType>(
         Set<TransactionType>.of(supportedTransactionTypes),
       ),
       createdAt = requireUtc(createdAt, 'createdAt'),
       effectiveFrom = requireOptionalUtc(effectiveFrom, 'effectiveFrom'),
       lastVerifiedAt = requireOptionalUtc(lastVerifiedAt, 'lastVerifiedAt') {
    if (name.trim().isEmpty) {
      throw const FormatException('Payment method name must not be empty.');
    }
    final percentageFields = <String, DecimalValue>{
      'foreignFeePercent': foreignFeePercent,
      'crossBorderFeePercent': crossBorderFeePercent,
      'rateMarkupPercent': rateMarkupPercent,
      'cashbackPercent': cashbackPercent,
    };
    for (final entry in percentageFields.entries) {
      if (entry.value.isNegative) {
        throw FormatException('${entry.key} must not be negative.');
      }
    }
    if (cashbackPercent.compareTo(DecimalValue.parse('100')) > 0) {
      throw const FormatException('cashbackPercent must not exceed 100.');
    }
    if (fixedFee.isNegative ||
        minimumFee?.isNegative == true ||
        maximumFee?.isNegative == true) {
      throw const FormatException('Payment fees must not be negative.');
    }
    if (minimumFee != null &&
        maximumFee != null &&
        minimumFee!.compareTo(maximumFee!) > 0) {
      throw const FormatException('minimumFee must not exceed maximumFee.');
    }
    if (cashExchangeRate != null &&
        cashExchangeRate!.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('cashExchangeRate must be positive.');
    }
    if (supportedTransactionTypes.isEmpty) {
      throw const FormatException(
        'At least one transaction type must be supported.',
      );
    }
  }

  final SyncRecordMetadata metadata;
  final String name;
  final PaymentMethodType type;
  final PaymentNetwork network;
  final Currency billingCurrency;
  final DecimalValue foreignFeePercent;
  final DecimalValue crossBorderFeePercent;
  final DecimalValue rateMarkupPercent;
  final DecimalValue fixedFee;
  final DecimalValue cashbackPercent;
  final DecimalValue? minimumFee;
  final DecimalValue? maximumFee;
  final DecimalValue? cashExchangeRate;
  final Set<TransactionType> supportedTransactionTypes;
  final String? sourceUrl;
  final DateTime? effectiveFrom;
  final DateTime? lastVerifiedAt;
  final String? notes;
  final DateTime createdAt;

  PaymentRuleSnapshot freezeRules() => PaymentRuleSnapshot(
    paymentMethodId: metadata.recordId,
    name: name,
    type: type,
    network: network,
    billingCurrencyCode: billingCurrency.code,
    foreignFeePercent: foreignFeePercent,
    crossBorderFeePercent: crossBorderFeePercent,
    rateMarkupPercent: rateMarkupPercent,
    fixedFee: fixedFee,
    cashbackPercent: cashbackPercent,
    minimumFee: minimumFee,
    maximumFee: maximumFee,
    cashExchangeRate: cashExchangeRate,
    supportedTransactionTypes: supportedTransactionTypes,
  );
}

final class TripModel {
  TripModel({
    required this.metadata,
    required this.name,
    required List<String> destinationCodes,
    required DateTime startDate,
    required DateTime endDate,
    required this.homeCurrency,
    required List<Currency> localCurrencies,
    required this.totalBudget,
    required this.participantCount,
    required this.defaultPaymentMethodId,
    required this.status,
    required DateTime createdAt,
    DateTime? offlinePackUpdatedAt,
  }) : destinationCodes = List<String>.unmodifiable(destinationCodes),
       localCurrencies = List<Currency>.unmodifiable(localCurrencies),
       startDate = requireUtc(startDate, 'startDate'),
       endDate = requireUtc(endDate, 'endDate'),
       createdAt = requireUtc(createdAt, 'createdAt'),
       offlinePackUpdatedAt = requireOptionalUtc(
         offlinePackUpdatedAt,
         'offlinePackUpdatedAt',
       ) {
    if (name.trim().isEmpty) {
      throw const FormatException('Trip name must not be empty.');
    }
    if (endDate.isBefore(startDate)) {
      throw const FormatException('Trip endDate must not precede startDate.');
    }
    if (localCurrencies.isEmpty) {
      throw const FormatException('Trip requires at least one local currency.');
    }
    if (totalBudget != null &&
        (totalBudget!.currency != homeCurrency ||
            totalBudget!.amount.isNegative)) {
      throw const FormatException('Trip budget is invalid.');
    }
    if (participantCount < 1) {
      throw RangeError.range(participantCount, 1, null, 'participantCount');
    }
  }

  final SyncRecordMetadata metadata;
  final String name;
  final List<String> destinationCodes;
  final DateTime startDate;
  final DateTime endDate;
  final Currency homeCurrency;
  final List<Currency> localCurrencies;
  final Money? totalBudget;
  final int participantCount;
  final String? defaultPaymentMethodId;
  final DateTime? offlinePackUpdatedAt;
  final TripStatus status;
  final DateTime createdAt;
}

final class ExpenseModel {
  ExpenseModel({
    required this.metadata,
    required this.tripId,
    required this.title,
    required this.category,
    required this.transactionAmount,
    required this.referenceAmount,
    required this.estimatedFinalAmount,
    required this.actualFinalAmount,
    required this.paymentMethodId,
    required this.paymentRuleSnapshot,
    required this.rateSnapshot,
    required this.taxAmount,
    required this.tipAmount,
    required this.discountAmount,
    required this.participantCount,
    required DateTime occurredAt,
    required this.receiptLocalPath,
    required this.notes,
    required this.budgetIncluded,
    required this.status,
    required DateTime createdAt,
    this.entryType = ExpenseEntryType.purchase,
    this.relatedExpenseId,
  }) : occurredAt = requireUtc(occurredAt, 'occurredAt'),
       createdAt = requireUtc(createdAt, 'createdAt') {
    if (title.trim().isEmpty) {
      throw const FormatException('Expense title must not be empty.');
    }
    if (participantCount < 1) {
      throw RangeError.range(participantCount, 1, null, 'participantCount');
    }
    if (referenceAmount.currency != estimatedFinalAmount.currency ||
        taxAmount.currency != referenceAmount.currency ||
        tipAmount.currency != referenceAmount.currency ||
        discountAmount.currency != referenceAmount.currency ||
        (actualFinalAmount != null &&
            actualFinalAmount!.currency != referenceAmount.currency)) {
      throw const FormatException('Expense home-currency amounts must match.');
    }
    if (rateSnapshot.baseCurrency != transactionAmount.currency ||
        rateSnapshot.quoteCurrency != referenceAmount.currency) {
      throw const FormatException('Expense rate snapshot currencies mismatch.');
    }
    if (paymentRuleSnapshot.billingCurrencyCode !=
        referenceAmount.currency.code) {
      throw const FormatException(
        'Expense payment snapshot currency mismatch.',
      );
    }
    if (entryType == ExpenseEntryType.purchase &&
        (transactionAmount.amount.compareTo(DecimalValue.zero) <= 0 ||
            referenceAmount.amount.compareTo(DecimalValue.zero) <= 0 ||
            estimatedFinalAmount.amount.compareTo(DecimalValue.zero) <= 0)) {
      throw const FormatException('Purchase amounts must be positive.');
    }
    if (entryType == ExpenseEntryType.purchase &&
        (taxAmount.amount.isNegative ||
            tipAmount.amount.isNegative ||
            discountAmount.amount.isNegative)) {
      throw const FormatException('Purchase adjustments must not be negative.');
    }
    if ((entryType == ExpenseEntryType.refund ||
            entryType == ExpenseEntryType.partialRefund) &&
        (relatedExpenseId == null ||
            estimatedFinalAmount.amount.compareTo(DecimalValue.zero) >= 0)) {
      throw const FormatException('Refund adjustment is invalid.');
    }
    if (entryType == ExpenseEntryType.voided && budgetIncluded) {
      throw const FormatException(
        'Voided expenses cannot count toward budget.',
      );
    }
  }

  final SyncRecordMetadata metadata;
  final String? tripId;
  final String title;
  final String category;
  final Money transactionAmount;
  final Money referenceAmount;
  final Money estimatedFinalAmount;
  final Money? actualFinalAmount;
  final String? paymentMethodId;
  final PaymentRuleSnapshot paymentRuleSnapshot;
  final RateSnapshotModel rateSnapshot;
  final Money taxAmount;
  final Money tipAmount;
  final Money discountAmount;
  final int participantCount;
  final DateTime occurredAt;
  final String? receiptLocalPath;
  final String? notes;
  final bool budgetIncluded;
  final ExpenseStatus status;
  final DateTime createdAt;
  final ExpenseEntryType entryType;
  final String? relatedExpenseId;
}

final class FeeCalibrationModel {
  FeeCalibrationModel({
    required this.metadata,
    required this.paymentMethodId,
    required this.expenseId,
    required this.referenceAmount,
    required this.actualFinalAmount,
    required this.effectiveMarkupPercent,
    required DateTime calculatedAt,
  }) : calculatedAt = requireUtc(calculatedAt, 'calculatedAt');

  final SyncRecordMetadata metadata;
  final String paymentMethodId;
  final String expenseId;
  final Money referenceAmount;
  final Money actualFinalAmount;
  final DecimalValue effectiveMarkupPercent;
  final DateTime calculatedAt;
}

final class UserSettingsModel {
  UserSettingsModel({
    required this.metadata,
    required this.defaultCurrency,
    required List<Currency> favoriteCurrencies,
    required this.languageMode,
    required this.refreshInterval,
    required this.wifiOnlyRefresh,
    required this.syncEnabled,
  }) : favoriteCurrencies = List<Currency>.unmodifiable(favoriteCurrencies) {
    if (refreshInterval <= Duration.zero) {
      throw const FormatException('Refresh interval must be positive.');
    }
  }

  final SyncRecordMetadata metadata;
  final Currency defaultCurrency;
  final List<Currency> favoriteCurrencies;
  final AppLanguageMode languageMode;
  final Duration refreshInterval;
  final bool wifiOnlyRefresh;
  final bool syncEnabled;
}

DateTime requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw FormatException('$field must be UTC.');
  }
  return value;
}

DateTime? requireOptionalUtc(DateTime? value, String field) {
  return value == null ? null : requireUtc(value, field);
}
