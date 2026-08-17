import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';

void main() {
  final catalog = CurrencyCatalog();
  final jpy = catalog.resolve('JPY');
  final cny = catalog.resolve('CNY');
  final now = DateTime.utc(2026, 8, 17, 8);
  final rate = RateSnapshotModel(
    metadata: SyncRecordMetadata(
      recordId: 'rate-1',
      syncVersion: 1,
      updatedAt: now,
    ),
    baseCurrency: jpy,
    quoteCurrency: cny,
    rate: DecimalValue.parse('0.04784'),
    sourceType: RateSourceType.market,
    sourceName: 'Frankfurter v2',
    sourceTimestamp: now,
    fetchedAt: now,
    isCached: false,
  );
  const engine = PaymentCostEngine();

  test(
    'standard order applies markup, fees, limits, fixed fee and cashback',
    () {
      final result = engine.calculate(
        transactionAmount: Money.parse('12800', jpy),
        rateSnapshot: rate,
        paymentRule: _rule(
          id: 'card',
          foreignFee: '1.5',
          crossBorderFee: '1',
          markup: '2',
          fixedFee: '3',
          cashback: '0.5',
          minimumFee: '20',
        ),
      );

      expect(result.referenceAmount.amount.toFixed(4), '612.3520');
      expect(result.rateMarkupAmount.amount.toFixed(4), '12.2470');
      expect(result.foreignFee.amount.toFixed(4), '9.3690');
      expect(result.crossBorderFee.amount.toFixed(4), '6.2460');
      expect(result.variableFeeAfterLimits.amount.toFixed(2), '20.00');
      expect(result.cashback.amount.toFixed(4), '3.1230');
      expect(result.estimatedCost.amount.toFixed(4), '644.4760');
      expect(result.order, PaymentCalculationOrder.standardV1);
    },
  );

  test('cash actual exchange rate takes priority over market reference', () {
    final result = engine.calculate(
      transactionAmount: Money.parse('12800', jpy),
      rateSnapshot: rate,
      paymentRule: _rule(
        id: 'cash',
        type: PaymentMethodType.cash,
        cashRate: '0.05',
      ),
    );

    expect(result.usesActualCashRate, isTrue);
    expect(result.baseAmount.amount.toFixed(2), '640.00');
    expect(result.referenceAmount.amount.toFixed(4), '612.3520');
    expect(result.estimatedCost.amount.toFixed(2), '640.00');
  });

  test('comparison sorts estimates and reports differences from lowest', () {
    final items = engine.compare(
      transactionAmount: Money.parse('10000', jpy),
      rateSnapshot: rate,
      paymentRules: <PaymentRuleSnapshot>[
        _rule(id: 'two-percent', foreignFee: '2'),
        _rule(id: 'zero-fee'),
      ],
    );

    expect(items.map((item) => item.breakdown.paymentRule.paymentMethodId), [
      'zero-fee',
      'two-percent',
    ]);
    expect(items.first.differenceFromLowest.amount, DecimalValue.zero);
    expect(items.last.differenceFromLowest.amount.toFixed(4), '9.5680');
  });

  test('rejects unsupported transaction type and non-positive amounts', () {
    expect(
      () => engine.calculate(
        transactionAmount: Money.parse('100', jpy),
        rateSnapshot: rate,
        paymentRule: _rule(id: 'purchase-only'),
        transactionType: TransactionType.atm,
      ),
      throwsA(
        isA<PaymentCostException>().having(
          (error) => error.code,
          'code',
          PaymentCostErrorCode.unsupportedTransactionType,
        ),
      ),
    );
    expect(
      () => engine.calculate(
        transactionAmount: Money.parse('0', jpy),
        rateSnapshot: rate,
        paymentRule: _rule(id: 'card'),
      ),
      throwsA(isA<PaymentCostException>()),
    );
  });
}

PaymentRuleSnapshot _rule({
  required String id,
  PaymentMethodType type = PaymentMethodType.creditCard,
  String foreignFee = '0',
  String crossBorderFee = '0',
  String markup = '0',
  String fixedFee = '0',
  String cashback = '0',
  String? minimumFee,
  String? maximumFee,
  String? cashRate,
}) {
  return PaymentRuleSnapshot(
    paymentMethodId: id,
    name: id,
    type: type,
    network: PaymentNetwork.unknown,
    billingCurrencyCode: 'CNY',
    foreignFeePercent: DecimalValue.parse(foreignFee),
    crossBorderFeePercent: DecimalValue.parse(crossBorderFee),
    rateMarkupPercent: DecimalValue.parse(markup),
    fixedFee: DecimalValue.parse(fixedFee),
    cashbackPercent: DecimalValue.parse(cashback),
    minimumFee: minimumFee == null ? null : DecimalValue.parse(minimumFee),
    maximumFee: maximumFee == null ? null : DecimalValue.parse(maximumFee),
    cashExchangeRate: cashRate == null ? null : DecimalValue.parse(cashRate),
    supportedTransactionTypes: const <TransactionType>{
      TransactionType.purchase,
    },
  );
}
