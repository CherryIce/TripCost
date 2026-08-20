import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/expenses/domain/expense_adjustment.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  test('pending expense can be posted or voided but cannot be refunded', () {
    final original = fixtureExpense();
    final summary = ExpenseAdjustmentSummary.from(
      original: original,
      expenses: <ExpenseModel>[original],
    );

    expect(summary.refundState, ExpenseRefundState.none);
    expect(summary.canRecordActual, isTrue);
    expect(summary.canVoid, isTrue);
    expect(summary.canRefund, isFalse);
  });

  test('refund state is derived from cumulative linked adjustments', () {
    final original = fixtureExpense(
      actual: '100',
      status: ExpenseStatus.confirmed,
    );
    final partial = fixtureExpense(
      id: 'refund-1',
      estimate: '-40',
      actual: '-40',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.partialRefund,
      relatedExpenseId: original.metadata.recordId,
    );
    final finalRefund = fixtureExpense(
      id: 'refund-2',
      estimate: '-60',
      actual: '-60',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.refund,
      relatedExpenseId: original.metadata.recordId,
    );

    final partialSummary = ExpenseAdjustmentSummary.from(
      original: original,
      expenses: <ExpenseModel>[original, partial],
    );
    final fullSummary = ExpenseAdjustmentSummary.from(
      original: original,
      expenses: <ExpenseModel>[original, partial, finalRefund],
    );

    expect(partialSummary.refundState, ExpenseRefundState.partial);
    expect(partialSummary.netAmount.toString(), '60');
    expect(partialSummary.canRefund, isTrue);
    expect(fullSummary.refundState, ExpenseRefundState.full);
    expect(fullSummary.netAmount.toString(), '0');
    expect(fullSummary.canRefund, isFalse);
    expect(fullSummary.canCorrectActual, isTrue);
  });

  test('refunds greater than the posted amount are marked invalid', () {
    final original = fixtureExpense(
      actual: '100',
      status: ExpenseStatus.confirmed,
    );
    final refund = fixtureExpense(
      id: 'refund-1',
      estimate: '-101',
      actual: '-101',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.refund,
      relatedExpenseId: original.metadata.recordId,
    );

    final summary = ExpenseAdjustmentSummary.from(
      original: original,
      expenses: <ExpenseModel>[original, refund],
    );

    expect(summary.refundState, ExpenseRefundState.invalid);
    expect(summary.canRefund, isFalse);
  });
}
