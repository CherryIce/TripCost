import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  test('tax tip and discount update the estimated final amount', () {
    final currency = CurrencyCatalog().resolve('CNY');

    final finalAmount = calculateEstimatedFinalAmount(
      baseAmount: Money.parse('100', currency),
      taxAmount: Money.parse('8', currency),
      tipAmount: Money.parse('12', currency),
      discountAmount: Money.parse('5', currency),
    );

    expect(finalAmount.amount.toString(), '115');
  });

  test('expense adjustments reject mixed currencies', () {
    final catalog = CurrencyCatalog();

    expect(
      () => calculateEstimatedFinalAmount(
        baseAmount: Money.parse('100', catalog.resolve('CNY')),
        taxAmount: Money.parse('8', catalog.resolve('USD')),
        tipAmount: Money.parse('0', catalog.resolve('CNY')),
        discountAmount: Money.parse('0', catalog.resolve('CNY')),
      ),
      throwsFormatException,
    );
  });

  test('seed snapshots are reused only while their inputs stay unchanged', () {
    final transaction = Money.parse('2000', fixtureJpy);
    final rate = fixtureRate();
    final breakdown = const PaymentCostEngine().calculate(
      transactionAmount: transaction,
      rateSnapshot: rate,
      paymentRule: fixturePaymentMethod().freezeRules(),
    );
    final seed = ExpenseDraftSeed(
      transactionAmount: transaction,
      rateSnapshot: rate,
      breakdown: breakdown,
    );

    expect(
      canReuseSeedRateSnapshot(
        seed: seed,
        transactionAmount: transaction,
        referenceAmount: breakdown.referenceAmount,
      ),
      isTrue,
    );
    expect(
      canReuseSeedRateSnapshot(
        seed: seed,
        transactionAmount: Money.parse('2100', fixtureJpy),
        referenceAmount: breakdown.referenceAmount,
      ),
      isFalse,
    );
    expect(
      canReuseSeedPaymentRule(
        seed: seed,
        paymentMethodId: 'payment-1',
        billingCurrencyCode: 'CNY',
      ),
      isTrue,
    );
    expect(
      canReuseSeedPaymentRule(
        seed: seed,
        paymentMethodId: 'payment-2',
        billingCurrencyCode: 'CNY',
      ),
      isFalse,
    );
  });
}
