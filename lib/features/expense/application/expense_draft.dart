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

final class ExpenseEditorArguments {
  const ExpenseEditorArguments({this.seed, this.trip});

  final ExpenseDraftSeed? seed;
  final TripModel? trip;
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
