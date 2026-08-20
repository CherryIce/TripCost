import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';

final class ExpenseDraftSeed {
  const ExpenseDraftSeed({
    required this.transactionAmount,
    required this.rateSnapshot,
    required this.breakdown,
    this.receiptLocalPath,
  });

  final Money transactionAmount;
  final RateSnapshotModel rateSnapshot;
  final PaymentCostBreakdown breakdown;
  final String? receiptLocalPath;
}

final class ReceiptExpensePrefill {
  const ReceiptExpensePrefill({
    this.title,
    this.transactionAmount,
    this.occurredAt,
    this.receiptLocalPath,
    this.titleNeedsConfirmation = false,
    this.amountNeedsConfirmation = false,
    this.dateNeedsConfirmation = false,
  });

  final String? title;
  final Money? transactionAmount;
  final DateTime? occurredAt;
  final String? receiptLocalPath;
  final bool titleNeedsConfirmation;
  final bool amountNeedsConfirmation;
  final bool dateNeedsConfirmation;

  int get filledFieldCount => <Object?>[
    title,
    transactionAmount,
    occurredAt,
    receiptLocalPath,
  ].where((value) => value != null).length;
}

final class ExpenseEditorArguments {
  const ExpenseEditorArguments({this.seed, this.receiptPrefill, this.trip})
    : assert(seed == null || receiptPrefill == null);

  final ExpenseDraftSeed? seed;
  final ReceiptExpensePrefill? receiptPrefill;
  final TripModel? trip;
}

bool canReuseSeedRateSnapshot({
  required ExpenseDraftSeed seed,
  required Money transactionAmount,
  required Money referenceAmount,
}) {
  return seed.transactionAmount == transactionAmount &&
      seed.breakdown.referenceAmount == referenceAmount &&
      seed.rateSnapshot.baseCurrency == transactionAmount.currency &&
      seed.rateSnapshot.quoteCurrency == referenceAmount.currency;
}

bool canReuseSeedPaymentRule({
  required ExpenseDraftSeed seed,
  required String? paymentMethodId,
  required String billingCurrencyCode,
}) {
  final rule = seed.breakdown.paymentRule;
  return rule.paymentMethodId == paymentMethodId &&
      rule.billingCurrencyCode == billingCurrencyCode;
}

Money calculateEstimatedFinalAmount({
  required Money baseAmount,
  required Money taxAmount,
  required Money tipAmount,
  required Money discountAmount,
}) {
  if (taxAmount.currency != baseAmount.currency ||
      tipAmount.currency != baseAmount.currency ||
      discountAmount.currency != baseAmount.currency) {
    throw const FormatException('Expense adjustment currencies must match.');
  }
  return baseAmount + taxAmount + tipAmount - discountAmount;
}
