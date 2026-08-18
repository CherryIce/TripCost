import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';

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
}
