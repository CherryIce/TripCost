import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/expenses/domain/expense_calibration.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  const calculator = ExpenseCalibrationCalculator();

  test('calculates actual difference and effective markup exactly', () {
    final reference = Money.parse('100', fixtureCny);
    final actual = Money.parse('105', fixtureCny);

    expect(
      calculator
          .effectiveMarkupPercent(
            referenceAmount: reference,
            actualFinalAmount: actual,
          )
          .toString(),
      '5',
    );
    expect(
      calculator
          .difference(
            estimatedAmount: Money.parse('102', fixtureCny),
            actualFinalAmount: actual,
          )
          .amount
          .toString(),
      '3',
    );
  });

  test('requires three comparable records before suggesting a rule update', () {
    FeeCalibrationModel calibration(String id, String markup) {
      return FeeCalibrationModel(
        metadata: fixtureMetadata(id),
        paymentMethodId: 'payment-1',
        expenseId: 'expense-$id',
        referenceAmount: Money.parse('100', fixtureCny),
        actualFinalAmount: Money.parse('105', fixtureCny),
        effectiveMarkupPercent: DecimalValue.parse(markup),
        calculatedAt: DateTime.utc(2026, 8, 17),
      );
    }

    final two = calculator.summarize(<FeeCalibrationModel>[
      calibration('1', '2'),
      calibration('2', '4'),
    ]);
    final three = calculator.summarize(<FeeCalibrationModel>[
      calibration('1', '2'),
      calibration('2', '4'),
      calibration('3', '3'),
    ]);
    expect(two.canSuggestRuleUpdate, isFalse);
    expect(three.canSuggestRuleUpdate, isTrue);
    expect(three.minimumMarkupPercent.toString(), '2');
    expect(three.maximumMarkupPercent.toString(), '4');
  });

  test('duplicate detection uses identity fields and a short time window', () {
    final first = fixtureExpense();
    final close = fixtureExpense(
      id: 'expense-2',
      occurredAt: first.occurredAt.add(const Duration(minutes: 4)),
    );
    final late = fixtureExpense(
      id: 'expense-3',
      occurredAt: first.occurredAt.add(const Duration(minutes: 6)),
    );
    expect(isPossibleDuplicate(close, first), isTrue);
    expect(isPossibleDuplicate(late, first), isFalse);
  });
}
