import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
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

  Future<void> recordActual(ExpenseModel expense, Money actual) async {
    final now = DateTime.now().toUtc();
    final updated = _copyExpense(
      expense,
      metadata: SyncRecordMetadata(
        recordId: expense.metadata.recordId,
        syncVersion: expense.metadata.syncVersion + 1,
        updatedAt: now,
      ),
      actualFinalAmount: actual,
      status: ExpenseStatus.confirmed,
    );
    final paymentMethodId = expense.paymentMethodId;
    if (paymentMethodId == null) {
      await ref.read(expenseRepositoryProvider).save(updated);
    } else {
      final markup = const ExpenseCalibrationCalculator()
          .effectiveMarkupPercent(
            referenceAmount: expense.referenceAmount,
            actualFinalAmount: actual,
          );
      final calibration = FeeCalibrationModel(
        metadata: SyncRecordMetadata(
          recordId: '${expense.metadata.recordId}:calibration',
          syncVersion: expense.metadata.syncVersion + 1,
          updatedAt: now,
        ),
        paymentMethodId: paymentMethodId,
        expenseId: expense.metadata.recordId,
        referenceAmount: expense.referenceAmount,
        actualFinalAmount: actual,
        effectiveMarkupPercent: markup,
        calculatedAt: now,
      );
      await ref
          .read(expenseRepositoryProvider)
          .saveWithCalibration(updated, calibration);
    }
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> voidExpense(ExpenseModel expense) async {
    final now = DateTime.now().toUtc();
    await save(
      _copyExpense(
        expense,
        metadata: SyncRecordMetadata(
          recordId: expense.metadata.recordId,
          syncVersion: expense.metadata.syncVersion + 1,
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
    final originalHome =
        original.actualFinalAmount ?? original.estimatedFinalAmount;
    if (homeAmount.currency != originalHome.currency ||
        homeAmount.amount.compareTo(DecimalValue.zero) <= 0 ||
        homeAmount.amount.compareTo(originalHome.amount.abs()) > 0) {
      throw const FormatException(
        'Refund amount exceeds the original expense.',
      );
    }
    final now = DateTime.now().toUtc();
    final negativeHome = Money(
      amount: -homeAmount.amount.abs(),
      currency: homeAmount.currency,
    );
    final refundShare = homeAmount.amount.divide(originalHome.amount.abs());
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
    await save(
      ExpenseModel(
        metadata: SyncRecordMetadata(
          recordId: const Uuid().v4(),
          syncVersion: 1,
          updatedAt: now,
        ),
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
        occurredAt: now,
        receiptLocalPath: null,
        notes: original.notes,
        budgetIncluded: original.budgetIncluded,
        status: ExpenseStatus.confirmed,
        entryType: partial
            ? ExpenseEntryType.partialRefund
            : ExpenseEntryType.refund,
        relatedExpenseId: original.metadata.recordId,
        createdAt: now,
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

ExpenseModel _copyExpense(
  ExpenseModel expense, {
  required SyncRecordMetadata metadata,
  Money? actualFinalAmount,
  ExpenseStatus? status,
  bool? budgetIncluded,
  ExpenseEntryType? entryType,
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
    receiptLocalPath: expense.receiptLocalPath,
    notes: expense.notes,
    budgetIncluded: budgetIncluded ?? expense.budgetIncluded,
    status: status ?? expense.status,
    entryType: entryType ?? expense.entryType,
    relatedExpenseId: expense.relatedExpenseId,
    createdAt: expense.createdAt,
  );
}
