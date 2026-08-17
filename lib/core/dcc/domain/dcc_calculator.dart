import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';

enum DccErrorCode {
  nonPositiveLocalAmount,
  nonPositiveMerchantQuote,
  sameCurrency,
  missingRate,
  currencyMismatch,
}

final class DccCalculationException implements Exception {
  const DccCalculationException(this.code);

  final DccErrorCode code;
}

final class DccAssessment {
  const DccAssessment({
    required this.localAmount,
    required this.merchantHomeQuote,
    required this.merchantImpliedRate,
    required this.referenceRate,
    required this.referenceAmount,
    required this.extraAmount,
    required this.extraPercent,
    required this.localCurrencyPaymentEstimate,
  });

  final Money localAmount;
  final Money merchantHomeQuote;
  final DecimalValue merchantImpliedRate;
  final DecimalValue referenceRate;
  final Money referenceAmount;
  final Money extraAmount;
  final DecimalValue extraPercent;
  final PaymentCostBreakdown? localCurrencyPaymentEstimate;
}

final class DccCalculator {
  const DccCalculator({PaymentCostEngine? paymentCostEngine})
    : _paymentCostEngine = paymentCostEngine ?? const PaymentCostEngine();

  final PaymentCostEngine _paymentCostEngine;

  DccAssessment calculate({
    required Money localAmount,
    required Money merchantHomeQuote,
    required RateSnapshotModel? referenceRate,
    PaymentRuleSnapshot? paymentRule,
  }) {
    if (localAmount.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const DccCalculationException(DccErrorCode.nonPositiveLocalAmount);
    }
    if (merchantHomeQuote.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const DccCalculationException(
        DccErrorCode.nonPositiveMerchantQuote,
      );
    }
    if (localAmount.currency == merchantHomeQuote.currency) {
      throw const DccCalculationException(DccErrorCode.sameCurrency);
    }
    if (referenceRate == null) {
      throw const DccCalculationException(DccErrorCode.missingRate);
    }
    if (referenceRate.baseCurrency != localAmount.currency ||
        referenceRate.quoteCurrency != merchantHomeQuote.currency) {
      throw const DccCalculationException(DccErrorCode.currencyMismatch);
    }

    final referenceAmount = Money(
      amount: localAmount.amount * referenceRate.rate,
      currency: merchantHomeQuote.currency,
    );
    final merchantImpliedRate = merchantHomeQuote.amount.divide(
      localAmount.amount,
    );
    final extraAmount = merchantHomeQuote - referenceAmount;
    final extraPercent =
        merchantHomeQuote.amount.divide(referenceAmount.amount) -
        DecimalValue.parse('1');
    final paymentEstimate = paymentRule == null
        ? null
        : _paymentCostEngine.calculate(
            transactionAmount: localAmount,
            rateSnapshot: referenceRate,
            paymentRule: paymentRule,
          );

    return DccAssessment(
      localAmount: localAmount,
      merchantHomeQuote: merchantHomeQuote,
      merchantImpliedRate: merchantImpliedRate,
      referenceRate: referenceRate.rate,
      referenceAmount: referenceAmount,
      extraAmount: extraAmount,
      extraPercent: extraPercent,
      localCurrencyPaymentEstimate: paymentEstimate,
    );
  }
}
