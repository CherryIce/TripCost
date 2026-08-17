import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/expenses/data/drift_expense_repository.dart';
import 'package:trip_cost/core/expenses/domain/expense_calibration.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/payments/data/drift_payment_method_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/trips/data/drift_trip_repository.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftExpenseRepository expenses;

  setUp(() async {
    database = AppDatabase.inMemory();
    await DriftPaymentMethodRepository(database).save(fixturePaymentMethod());
    await DriftTripRepository(database).save(fixtureTrip());
    expenses = DriftExpenseRepository(database);
  });

  tearDown(() => database.close());

  test('round-trips immutable rate and payment snapshots', () async {
    await expenses.save(fixtureExpense());
    final restored = await expenses.findById('expense-1');

    expect(restored, isNotNull);
    expect(restored!.rateSnapshot.rate.toString(), '0.05');
    expect(restored.paymentRuleSnapshot.foreignFeePercent.toString(), '1');
    expect(restored.entryType, ExpenseEntryType.purchase);
    expect(restored.metadata.syncState, SyncState.pending);
  });

  test(
    'actual amount and fee calibration persist in one transaction',
    () async {
      final original = fixtureExpense();
      final actual = Money.parse('105', fixtureCny);
      final confirmed = ExpenseModel(
        metadata: fixtureMetadata('expense-1', 2),
        tripId: original.tripId,
        title: original.title,
        category: original.category,
        transactionAmount: original.transactionAmount,
        referenceAmount: original.referenceAmount,
        estimatedFinalAmount: original.estimatedFinalAmount,
        actualFinalAmount: actual,
        paymentMethodId: original.paymentMethodId,
        paymentRuleSnapshot: original.paymentRuleSnapshot,
        rateSnapshot: original.rateSnapshot,
        taxAmount: original.taxAmount,
        tipAmount: original.tipAmount,
        discountAmount: original.discountAmount,
        participantCount: original.participantCount,
        occurredAt: original.occurredAt,
        receiptLocalPath: null,
        notes: null,
        budgetIncluded: true,
        status: ExpenseStatus.confirmed,
        createdAt: original.createdAt,
      );
      final calibration = FeeCalibrationModel(
        metadata: fixtureMetadata('calibration-1'),
        paymentMethodId: 'payment-1',
        expenseId: 'expense-1',
        referenceAmount: original.referenceAmount,
        actualFinalAmount: actual,
        effectiveMarkupPercent: const ExpenseCalibrationCalculator()
            .effectiveMarkupPercent(
              referenceAmount: original.referenceAmount,
              actualFinalAmount: actual,
            ),
        calculatedAt: DateTime.utc(2026, 8, 18),
      );

      await expenses.saveWithCalibration(confirmed, calibration);

      final restored = await expenses.findById('expense-1');
      final values = await DriftFeeCalibrationRepository(
        database,
      ).listForPaymentMethod('payment-1');
      expect(restored!.actualFinalAmount!.amount.toString(), '105');
      expect(restored.status, ExpenseStatus.confirmed);
      expect(values.single.effectiveMarkupPercent.toString(), '5');
      expect(values.single.referenceAmount.currency.code, 'CNY');
    },
  );

  test('refund relation and negative amount survive persistence', () async {
    final refund = fixtureExpense(
      id: 'refund-1',
      estimate: '-40',
      actual: '-40',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.partialRefund,
      relatedExpenseId: 'expense-1',
    );
    await expenses.save(fixtureExpense());
    await expenses.save(refund);

    final restored = await expenses.findById('refund-1');
    expect(restored!.entryType, ExpenseEntryType.partialRefund);
    expect(restored.relatedExpenseId, 'expense-1');
    expect(restored.estimatedFinalAmount.amount.toString(), '-40');
  });

  test('expense save rolls back when calibration persistence fails', () async {
    final expense = fixtureExpense();
    final invalidCalibration = FeeCalibrationModel(
      metadata: fixtureMetadata('invalid-calibration'),
      paymentMethodId: 'missing-payment',
      expenseId: expense.metadata.recordId,
      referenceAmount: expense.referenceAmount,
      actualFinalAmount: Money.parse('105', fixtureCny),
      effectiveMarkupPercent: const ExpenseCalibrationCalculator()
          .effectiveMarkupPercent(
            referenceAmount: expense.referenceAmount,
            actualFinalAmount: Money.parse('105', fixtureCny),
          ),
      calculatedAt: DateTime.utc(2026, 8, 18),
    );

    await expectLater(
      expenses.saveWithCalibration(expense, invalidCalibration),
      throwsA(anything),
    );
    expect(await expenses.findById(expense.metadata.recordId), null);
  });
}
