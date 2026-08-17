import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

enum PaymentCalculationOrder { standardV1 }

enum PaymentCostErrorCode {
  nonPositiveAmount,
  currencyMismatch,
  unsupportedTransactionType,
}

final class PaymentCostException implements Exception {
  const PaymentCostException(this.code);

  final PaymentCostErrorCode code;
}

final class PaymentCostBreakdown {
  const PaymentCostBreakdown({
    required this.paymentRule,
    required this.transactionAmount,
    required this.referenceAmount,
    required this.baseAmount,
    required this.rateMarkupAmount,
    required this.foreignFee,
    required this.crossBorderFee,
    required this.variableFeeAfterLimits,
    required this.fixedFee,
    required this.cashback,
    required this.estimatedCost,
    required this.usedRate,
    required this.usesActualCashRate,
    required this.order,
  });

  final PaymentRuleSnapshot paymentRule;
  final Money transactionAmount;
  final Money referenceAmount;
  final Money baseAmount;
  final Money rateMarkupAmount;
  final Money foreignFee;
  final Money crossBorderFee;
  final Money variableFeeAfterLimits;
  final Money fixedFee;
  final Money cashback;
  final Money estimatedCost;
  final DecimalValue usedRate;
  final bool usesActualCashRate;
  final PaymentCalculationOrder order;
}

final class PaymentComparisonItem {
  const PaymentComparisonItem({
    required this.breakdown,
    required this.differenceFromLowest,
  });

  final PaymentCostBreakdown breakdown;
  final Money differenceFromLowest;
}

final class PaymentCostEngine {
  const PaymentCostEngine({
    this.calculationOrder = PaymentCalculationOrder.standardV1,
  });

  final PaymentCalculationOrder calculationOrder;

  PaymentCostBreakdown calculate({
    required Money transactionAmount,
    required RateSnapshotModel rateSnapshot,
    required PaymentRuleSnapshot paymentRule,
    TransactionType transactionType = TransactionType.purchase,
  }) {
    if (transactionAmount.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const PaymentCostException(PaymentCostErrorCode.nonPositiveAmount);
    }
    if (rateSnapshot.baseCurrency != transactionAmount.currency ||
        rateSnapshot.quoteCurrency.code != paymentRule.billingCurrencyCode) {
      throw const PaymentCostException(PaymentCostErrorCode.currencyMismatch);
    }
    if (!paymentRule.supportedTransactionTypes.contains(transactionType)) {
      throw const PaymentCostException(
        PaymentCostErrorCode.unsupportedTransactionType,
      );
    }

    final quoteCurrency = rateSnapshot.quoteCurrency;
    final referenceAmount = Money(
      amount: transactionAmount.amount * rateSnapshot.rate,
      currency: quoteCurrency,
    );
    final usesActualCashRate =
        paymentRule.type == PaymentMethodType.cash &&
        paymentRule.cashExchangeRate != null;
    final usedRate = usesActualCashRate
        ? paymentRule.cashExchangeRate!
        : rateSnapshot.rate;
    final baseAmount = Money(
      amount: transactionAmount.amount * usedRate,
      currency: quoteCurrency,
    );
    final markupAmount = baseAmount.multiply(
      _percentage(paymentRule.rateMarkupPercent),
    );
    final feeBasis = baseAmount + markupAmount;
    final foreignFee = feeBasis.multiply(
      _percentage(paymentRule.foreignFeePercent),
    );
    final crossBorderFee = feeBasis.multiply(
      _percentage(paymentRule.crossBorderFeePercent),
    );
    final rawVariableFee = foreignFee + crossBorderFee;
    final variableFeeAfterLimits = Money(
      amount: _clamp(
        rawVariableFee.amount,
        minimum: paymentRule.minimumFee,
        maximum: paymentRule.maximumFee,
      ),
      currency: quoteCurrency,
    );
    final fixedFee = Money(
      amount: paymentRule.fixedFee,
      currency: quoteCurrency,
    );
    final cashback = feeBasis.multiply(
      _percentage(paymentRule.cashbackPercent),
    );
    final estimatedCost =
        feeBasis + variableFeeAfterLimits + fixedFee - cashback;

    return PaymentCostBreakdown(
      paymentRule: paymentRule,
      transactionAmount: transactionAmount,
      referenceAmount: referenceAmount,
      baseAmount: baseAmount,
      rateMarkupAmount: markupAmount,
      foreignFee: foreignFee,
      crossBorderFee: crossBorderFee,
      variableFeeAfterLimits: variableFeeAfterLimits,
      fixedFee: fixedFee,
      cashback: cashback,
      estimatedCost: estimatedCost,
      usedRate: usedRate,
      usesActualCashRate: usesActualCashRate,
      order: calculationOrder,
    );
  }

  List<PaymentComparisonItem> compare({
    required Money transactionAmount,
    required RateSnapshotModel rateSnapshot,
    required Iterable<PaymentRuleSnapshot> paymentRules,
    TransactionType transactionType = TransactionType.purchase,
  }) {
    final breakdowns = <PaymentCostBreakdown>[];
    for (final rule in paymentRules) {
      if (!rule.supportedTransactionTypes.contains(transactionType) ||
          rule.billingCurrencyCode != rateSnapshot.quoteCurrency.code) {
        continue;
      }
      breakdowns.add(
        calculate(
          transactionAmount: transactionAmount,
          rateSnapshot: rateSnapshot,
          paymentRule: rule,
          transactionType: transactionType,
        ),
      );
    }
    breakdowns.sort(
      (left, right) => left.estimatedCost.compareTo(right.estimatedCost),
    );
    if (breakdowns.isEmpty) {
      return const <PaymentComparisonItem>[];
    }
    final lowest = breakdowns.first.estimatedCost;
    return <PaymentComparisonItem>[
      for (final breakdown in breakdowns)
        PaymentComparisonItem(
          breakdown: breakdown,
          differenceFromLowest: breakdown.estimatedCost - lowest,
        ),
    ];
  }
}

DecimalValue _percentage(DecimalValue value) {
  return value.divide(DecimalValue.parse('100'));
}

DecimalValue _clamp(
  DecimalValue value, {
  DecimalValue? minimum,
  DecimalValue? maximum,
}) {
  if (minimum != null && value.compareTo(minimum) < 0) {
    return minimum;
  }
  if (maximum != null && value.compareTo(maximum) > 0) {
    return maximum;
  }
  return value;
}
