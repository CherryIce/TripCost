import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/expenses/domain/expense_adjustment.dart';
import 'package:trip_cost/core/expenses/domain/expense_calibration.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:uuid/uuid.dart';

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<ExpenseModel>>(
      ExpensesController.new,
    );

final calibrationSummaryProvider =
    FutureProvider.family<CalibrationSummary, String>((
      ref,
      paymentMethodId,
    ) async {
      final repository = ref.watch(feeCalibrationRepositoryProvider);
      if (repository is CacheRepositoryObserver) {
        final subscription = (repository as CacheRepositoryObserver)
            .watchChanges()
            .listen((_) {
              ref.invalidateSelf();
            });
        ref.onDispose(subscription.cancel);
      }
      final values = await repository.listForPaymentMethod(paymentMethodId);
      return const ExpenseCalibrationCalculator().summarize(values.take(10));
    });

final class ExpensesController extends AsyncNotifier<List<ExpenseModel>> {
  StreamSubscription<void>? _cacheSubscription;

  @override
  Future<List<ExpenseModel>> build() {
    final repository = ref.watch(expenseRepositoryProvider);
    _observe(repository);
    return repository.listActive();
  }

  ExpenseModel? possibleDuplicate(ExpenseModel candidate) {
    final current = state.value;
    if (current == null) return null;
    return current
        .where((item) => isPossibleDuplicate(candidate, item))
        .firstOrNull;
  }

  Future<void> save(ExpenseModel expense) async {
    await ref.read(expenseRepositoryProvider).save(expense);
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> saveConfirmed(ExpenseModel expense) async {
    if (expense.status != ExpenseStatus.confirmed ||
        expense.entryType != ExpenseEntryType.purchase ||
        expense.actualFinalAmount == null ||
        expense.actualFinalAmount!.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException(
        'A confirmed expense requires an actual amount.',
      );
    }
    await _saveConfirmedExpense(expense);
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> recordActual(ExpenseModel expense, Money actual) async {
    final repository = ref.read(expenseRepositoryProvider);
    final current = await repository.findById(expense.metadata.recordId);
    if (current == null ||
        current.entryType != ExpenseEntryType.purchase ||
        actual.currency != current.referenceAmount.currency ||
        actual.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('The actual amount correction is invalid.');
    }
    final expenses = await repository.listActive();
    final summary = ExpenseAdjustmentSummary.from(
      original: current,
      expenses: expenses,
    );
    if (summary.refundedAmount.compareTo(actual.amount.abs()) > 0) {
      throw const FormatException(
        'The actual amount cannot be lower than the refunded amount.',
      );
    }
    final now = DateTime.now().toUtc();
    final updated = _copyExpense(
      current,
      metadata: SyncRecordMetadata(
        recordId: current.metadata.recordId,
        syncVersion: current.metadata.syncVersion + 1,
        updatedAt: now,
      ),
      actualFinalAmount: actual,
      status: ExpenseStatus.confirmed,
    );
    await _saveConfirmedExpense(updated);
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> _saveConfirmedExpense(ExpenseModel expense) async {
    final actual = expense.actualFinalAmount!;
    final paymentMethodId = expense.paymentMethodId;
    if (paymentMethodId == null) {
      await ref.read(expenseRepositoryProvider).save(expense);
      return;
    }
    final markup = const ExpenseCalibrationCalculator().effectiveMarkupPercent(
      referenceAmount: expense.referenceAmount,
      actualFinalAmount: actual,
    );
    final calibration = FeeCalibrationModel(
      metadata: SyncRecordMetadata(
        recordId: '${expense.metadata.recordId}:calibration',
        syncVersion: expense.metadata.syncVersion,
        updatedAt: expense.metadata.updatedAt,
      ),
      paymentMethodId: paymentMethodId,
      expenseId: expense.metadata.recordId,
      referenceAmount: expense.referenceAmount,
      actualFinalAmount: actual,
      effectiveMarkupPercent: markup,
      calculatedAt: expense.metadata.updatedAt,
    );
    await ref
        .read(expenseRepositoryProvider)
        .saveWithCalibration(expense, calibration);
  }

  Future<void> voidExpense(ExpenseModel expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    final current = await repository.findById(expense.metadata.recordId);
    if (current == null) {
      throw const FormatException('The expense no longer exists.');
    }
    final summary = ExpenseAdjustmentSummary.from(
      original: current,
      expenses: await repository.listActive(),
    );
    if (!summary.canVoid) {
      throw const FormatException('Only a pending expense can be voided.');
    }
    final now = DateTime.now().toUtc();
    await save(
      _copyExpense(
        current,
        metadata: SyncRecordMetadata(
          recordId: current.metadata.recordId,
          syncVersion: current.metadata.syncVersion + 1,
          updatedAt: now,
        ),
        budgetIncluded: false,
        entryType: ExpenseEntryType.voided,
      ),
    );
  }

  Future<void> createRefund({
    required ExpenseModel original,
    required Money homeAmount,
    required bool partial,
  }) async {
    final repository = ref.read(expenseRepositoryProvider);
    final current = await repository.findById(original.metadata.recordId);
    if (current == null) {
      throw const FormatException('The original expense no longer exists.');
    }
    final summary = ExpenseAdjustmentSummary.from(
      original: current,
      expenses: await repository.listActive(),
    );
    final originalHome = current.actualFinalAmount;
    final remaining = summary.remainingAmount;
    if (!summary.canRefund || originalHome == null || remaining == null) {
      throw const FormatException('Only a posted expense can be refunded.');
    }
    final requested = partial ? homeAmount.amount.abs() : remaining;
    if (homeAmount.currency != originalHome.currency ||
        requested.compareTo(DecimalValue.zero) <= 0 ||
        requested.compareTo(remaining) > 0) {
      throw const FormatException(
        'Refund amount exceeds the original expense.',
      );
    }
    final now = DateTime.now().toUtc();
    final resultingRefunded = summary.refundedAmount + requested;
    final entryType =
        resultingRefunded.compareTo(originalHome.amount.abs()) == 0
        ? ExpenseEntryType.refund
        : ExpenseEntryType.partialRefund;
    await save(
      _refundExpense(
        original: current,
        metadata: SyncRecordMetadata(
          recordId: const Uuid().v4(),
          syncVersion: 1,
          updatedAt: now,
        ),
        requested: requested,
        entryType: entryType,
        occurredAt: now,
        createdAt: now,
      ),
    );
  }

  Future<void> correctRefund({
    required ExpenseModel refund,
    required Money homeAmount,
  }) async {
    final repository = ref.read(expenseRepositoryProvider);
    final current = await repository.findById(refund.metadata.recordId);
    if (current == null ||
        (current.entryType != ExpenseEntryType.refund &&
            current.entryType != ExpenseEntryType.partialRefund) ||
        current.relatedExpenseId == null) {
      throw const FormatException('The refund correction is invalid.');
    }
    final original = await repository.findById(current.relatedExpenseId!);
    if (original == null ||
        original.entryType != ExpenseEntryType.purchase ||
        original.status != ExpenseStatus.confirmed ||
        original.actualFinalAmount == null ||
        homeAmount.currency != original.referenceAmount.currency ||
        homeAmount.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('The original expense is invalid.');
    }
    final all = await repository.listActive();
    final withoutCurrent = all.where(
      (item) => item.metadata.recordId != current.metadata.recordId,
    );
    final summary = ExpenseAdjustmentSummary.from(
      original: original,
      expenses: withoutCurrent,
    );
    final requested = homeAmount.amount.abs();
    final posted = original.actualFinalAmount!.amount.abs();
    final resultingRefunded = summary.refundedAmount + requested;
    if (resultingRefunded.compareTo(posted) > 0) {
      throw const FormatException(
        'The refunded amount cannot exceed the original expense.',
      );
    }
    final now = DateTime.now().toUtc();
    await save(
      _refundExpense(
        original: original,
        metadata: SyncRecordMetadata(
          recordId: current.metadata.recordId,
          syncVersion: current.metadata.syncVersion + 1,
          updatedAt: now,
        ),
        requested: requested,
        entryType: resultingRefunded.compareTo(posted) == 0
            ? ExpenseEntryType.refund
            : ExpenseEntryType.partialRefund,
        occurredAt: current.occurredAt,
        createdAt: current.createdAt,
      ),
    );
  }

  Future<void> delete(String id) async {
    await ref
        .read(expenseRepositoryProvider)
        .softDelete(id, DateTime.now().toUtc());
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<List<String>> clearReceiptImagesForTrip(String tripId) async {
    final repository = ref.read(expenseRepositoryProvider);
    final expenses = await repository.listForTrip(tripId);
    final withReceipts = expenses
        .where((expense) => expense.receiptLocalPath != null)
        .toList(growable: false);
    final now = DateTime.now().toUtc();
    for (final expense in withReceipts) {
      await repository.save(
        _copyExpense(
          expense,
          metadata: SyncRecordMetadata(
            recordId: expense.metadata.recordId,
            syncVersion: expense.metadata.syncVersion + 1,
            updatedAt: now,
          ),
          clearReceiptLocalPath: true,
        ),
      );
    }

    final failures = <String>[];
    final references = <String>{
      for (final expense in withReceipts) expense.receiptLocalPath!,
    };
    for (final reference in references) {
      try {
        await ref.read(receiptStorageProvider).delete(reference);
      } on Object {
        failures.add(reference);
      }
    }
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
    return List<String>.unmodifiable(failures);
  }

  DecimalValue remainingRefundAmount(ExpenseModel original) {
    final summary = ExpenseAdjustmentSummary.from(
      original: original,
      expenses: state.value ?? const <ExpenseModel>[],
    );
    return summary.remainingAmount ?? DecimalValue.zero;
  }

  Future<void> _reload() async {
    final cached = await ref.read(expenseRepositoryProvider).listActive();
    if (ref.mounted) state = AsyncData(cached);
  }

  void _observe(ExpenseRepository repository) {
    unawaited(_cacheSubscription?.cancel());
    _cacheSubscription = repository is CacheRepositoryObserver
        ? (repository as CacheRepositoryObserver).watchChanges().listen((_) {
            if (ref.mounted) unawaited(_reload());
          })
        : null;
    ref.onDispose(() => _cacheSubscription?.cancel());
  }
}

DecimalValue originalRefundableAmount(ExpenseModel original) {
  return (original.actualFinalAmount ?? original.estimatedFinalAmount).amount
      .abs();
}

DecimalValue refundedAmountFor(
  ExpenseModel original,
  Iterable<ExpenseModel> expenses,
) => ExpenseAdjustmentSummary.from(
  original: original,
  expenses: expenses,
).refundedAmount;

ExpenseModel _refundExpense({
  required ExpenseModel original,
  required SyncRecordMetadata metadata,
  required DecimalValue requested,
  required ExpenseEntryType entryType,
  required DateTime occurredAt,
  required DateTime createdAt,
}) {
  final originalHome = original.actualFinalAmount!;
  final negativeHome = Money(
    amount: -requested,
    currency: originalHome.currency,
  );
  final refundShare = requested.divide(originalHome.amount.abs());
  final negativeTransaction = Money(
    amount: -(original.transactionAmount.amount.abs() * refundShare),
    currency: original.transactionAmount.currency,
  );
  final negativeReference = Money(
    amount: negativeTransaction.amount * original.rateSnapshot.rate,
    currency: original.referenceAmount.currency,
  );
  final zeroHome = Money(
    amount: DecimalValue.zero,
    currency: original.referenceAmount.currency,
  );
  return ExpenseModel(
    metadata: metadata,
    tripId: original.tripId,
    title: original.title,
    category: original.category,
    transactionAmount: negativeTransaction,
    referenceAmount: negativeReference,
    estimatedFinalAmount: negativeHome,
    actualFinalAmount: negativeHome,
    paymentMethodId: original.paymentMethodId,
    paymentRuleSnapshot: original.paymentRuleSnapshot,
    rateSnapshot: original.rateSnapshot,
    taxAmount: zeroHome,
    tipAmount: zeroHome,
    discountAmount: zeroHome,
    participantCount: original.participantCount,
    occurredAt: occurredAt,
    receiptLocalPath: null,
    notes: original.notes,
    budgetIncluded: original.budgetIncluded,
    status: ExpenseStatus.confirmed,
    entryType: entryType,
    relatedExpenseId: original.metadata.recordId,
    createdAt: createdAt,
  );
}

ExpenseModel _copyExpense(
  ExpenseModel expense, {
  required SyncRecordMetadata metadata,
  Money? actualFinalAmount,
  ExpenseStatus? status,
  bool? budgetIncluded,
  ExpenseEntryType? entryType,
  bool clearReceiptLocalPath = false,
}) {
  return ExpenseModel(
    metadata: metadata,
    tripId: expense.tripId,
    title: expense.title,
    category: expense.category,
    transactionAmount: expense.transactionAmount,
    referenceAmount: expense.referenceAmount,
    estimatedFinalAmount: expense.estimatedFinalAmount,
    actualFinalAmount: actualFinalAmount ?? expense.actualFinalAmount,
    paymentMethodId: expense.paymentMethodId,
    paymentRuleSnapshot: expense.paymentRuleSnapshot,
    rateSnapshot: expense.rateSnapshot,
    taxAmount: expense.taxAmount,
    tipAmount: expense.tipAmount,
    discountAmount: expense.discountAmount,
    participantCount: expense.participantCount,
    occurredAt: expense.occurredAt,
    receiptLocalPath: clearReceiptLocalPath ? null : expense.receiptLocalPath,
    notes: expense.notes,
    budgetIncluded: budgetIncluded ?? expense.budgetIncluded,
    status: status ?? expense.status,
    entryType: entryType ?? expense.entryType,
    relatedExpenseId: expense.relatedExpenseId,
    createdAt: expense.createdAt,
  );
}
