import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/expenses/domain/expense_adjustment.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';

import '../../../helpers/m4_fakes.dart';
import '../../../helpers/m5_fixtures.dart';

void main() {
  test('actual correction cannot be lower than cumulative refunds', () async {
    final original = fixtureExpense(
      actual: '100',
      status: ExpenseStatus.confirmed,
    );
    final refund = fixtureExpense(
      id: 'refund-1',
      estimate: '-100',
      actual: '-100',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.refund,
      relatedExpenseId: original.metadata.recordId,
    );
    final repository = MemoryExpenseRepository(<ExpenseModel>[
      original,
      refund,
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(expensesControllerProvider.future);

    await expectLater(
      container
          .read(expensesControllerProvider.notifier)
          .recordActual(original, Money.parse('99', fixtureCny)),
      throwsA(isA<FormatException>()),
    );

    expect(
      (await repository.findById(
        original.metadata.recordId,
      ))!.actualFinalAmount!.amount.toString(),
      '100',
    );
  });

  test(
    'pending expense cannot be refunded and posted expense cannot be voided',
    () async {
      final pending = fixtureExpense();
      final posted = fixtureExpense(
        id: 'posted',
        actual: '100',
        status: ExpenseStatus.confirmed,
      );
      final repository = MemoryExpenseRepository(<ExpenseModel>[
        pending,
        posted,
      ]);
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(expensesControllerProvider.future);
      final controller = container.read(expensesControllerProvider.notifier);

      await expectLater(
        controller.createRefund(
          original: pending,
          homeAmount: Money.parse('100', fixtureCny),
          partial: false,
        ),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        controller.voidExpense(posted),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'a partial input equal to the remaining amount becomes a full refund',
    () async {
      final original = fixtureExpense(
        actual: '100',
        status: ExpenseStatus.confirmed,
      );
      final repository = MemoryExpenseRepository(<ExpenseModel>[original]);
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(expensesControllerProvider.future);

      await container
          .read(expensesControllerProvider.notifier)
          .createRefund(
            original: original,
            homeAmount: Money.parse('100', fixtureCny),
            partial: true,
          );

      final refund = repository.values.singleWhere(
        (item) => item.relatedExpenseId == original.metadata.recordId,
      );
      expect(refund.entryType, ExpenseEntryType.refund);
      final summary = ExpenseAdjustmentSummary.from(
        original: original,
        expenses: repository.values,
      );
      expect(summary.refundState, ExpenseRefundState.full);
    },
  );

  test('correcting a full refund can restore a partial refund state', () async {
    final original = fixtureExpense(
      actual: '100',
      status: ExpenseStatus.confirmed,
    );
    final refund = fixtureExpense(
      id: 'refund-1',
      estimate: '-100',
      actual: '-100',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.refund,
      relatedExpenseId: original.metadata.recordId,
    );
    final repository = MemoryExpenseRepository(<ExpenseModel>[
      original,
      refund,
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(expensesControllerProvider.future);

    await container
        .read(expensesControllerProvider.notifier)
        .correctRefund(
          refund: refund,
          homeAmount: Money.parse('40', fixtureCny),
        );

    final corrected = (await repository.findById(refund.metadata.recordId))!;
    expect(corrected.entryType, ExpenseEntryType.partialRefund);
    expect(corrected.actualFinalAmount!.amount.toString(), '-40');
  });
}

ProviderContainer _container(ExpenseRepository repository) => ProviderContainer(
  overrides: [
    expenseRepositoryProvider.overrideWithValue(repository),
    feeCalibrationRepositoryProvider.overrideWithValue(
      MemoryFeeCalibrationRepository(),
    ),
  ],
);
