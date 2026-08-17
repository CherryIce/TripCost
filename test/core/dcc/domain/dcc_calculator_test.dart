import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/dcc/domain/dcc_calculator.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

void main() {
  final catalog = CurrencyCatalog();
  final jpy = catalog.resolve('JPY');
  final cny = catalog.resolve('CNY');
  final now = DateTime.utc(2026, 8, 17, 8);
  final rate = RateSnapshotModel(
    metadata: SyncRecordMetadata(
      recordId: 'rate',
      syncVersion: 1,
      updatedAt: now,
    ),
    baseCurrency: jpy,
    quoteCurrency: cny,
    rate: DecimalValue.parse('0.047840625'),
    sourceType: RateSourceType.market,
    sourceName: 'Frankfurter v2',
    sourceTimestamp: now,
    fetchedAt: now,
    isCached: false,
  );
  const calculator = DccCalculator();

  test('matches the product DCC example', () {
    final result = calculator.calculate(
      localAmount: Money.parse('12800', jpy),
      merchantHomeQuote: Money.parse('648', cny),
      referenceRate: rate,
    );

    expect(result.merchantImpliedRate.toFixed(8), '0.05062500');
    expect(result.referenceAmount.amount.toFixed(2), '612.36');
    expect(result.extraAmount.amount.toFixed(2), '35.64');
    expect(
      (result.extraPercent * DecimalValue.parse('100')).toFixed(2),
      '5.82',
    );
  });

  test('explains zero, negative, same-currency and missing-rate inputs', () {
    final cases =
        <
          ({
            Money local,
            Money quote,
            RateSnapshotModel? rate,
            DccErrorCode code,
          })
        >[
          (
            local: Money.parse('0', jpy),
            quote: Money.parse('1', cny),
            rate: rate,
            code: DccErrorCode.nonPositiveLocalAmount,
          ),
          (
            local: Money.parse('1', jpy),
            quote: Money.parse('-1', cny),
            rate: rate,
            code: DccErrorCode.nonPositiveMerchantQuote,
          ),
          (
            local: Money.parse('1', cny),
            quote: Money.parse('1', cny),
            rate: rate,
            code: DccErrorCode.sameCurrency,
          ),
          (
            local: Money.parse('1', jpy),
            quote: Money.parse('1', cny),
            rate: null,
            code: DccErrorCode.missingRate,
          ),
        ];

    for (final item in cases) {
      expect(
        () => calculator.calculate(
          localAmount: item.local,
          merchantHomeQuote: item.quote,
          referenceRate: item.rate,
        ),
        throwsA(
          isA<DccCalculationException>().having(
            (error) => error.code,
            'code',
            item.code,
          ),
        ),
      );
    }
  });
}
