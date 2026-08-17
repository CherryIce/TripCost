import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';

final class ExpenseDraftSeed {
  const ExpenseDraftSeed({
    required this.transactionAmount,
    required this.rateSnapshot,
    required this.breakdown,
  });

  final Money transactionAmount;
  final RateSnapshotModel rateSnapshot;
  final PaymentCostBreakdown breakdown;
}

final class ExpenseEditorArguments {
  const ExpenseEditorArguments({this.seed, this.trip});

  final ExpenseDraftSeed? seed;
  final TripModel? trip;
}
