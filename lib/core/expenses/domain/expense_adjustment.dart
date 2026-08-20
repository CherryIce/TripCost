import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';

enum ExpenseRefundState { none, partial, full, invalid }

final class ExpenseAdjustmentSummary {
  ExpenseAdjustmentSummary._({
    required this.original,
    required this.refunds,
    required this.refundedAmount,
    required this.refundState,
  });

  factory ExpenseAdjustmentSummary.from({
    required ExpenseModel original,
    required Iterable<ExpenseModel> expenses,
  }) {
    final refunds =
        expenses
            .where(
              (expense) =>
                  expense.metadata.deletedAt == null &&
                  expense.relatedExpenseId == original.metadata.recordId &&
                  (expense.entryType == ExpenseEntryType.refund ||
                      expense.entryType == ExpenseEntryType.partialRefund),
            )
            .toList()
          ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    var refundedAmount = DecimalValue.zero;
    var hasInvalidCurrency = false;
    var hasInvalidAmount = false;
    for (final refund in refunds) {
      final amount = refund.actualFinalAmount ?? refund.estimatedFinalAmount;
      if (amount.currency != original.referenceAmount.currency) {
        hasInvalidCurrency = true;
        continue;
      }
      if (amount.amount.compareTo(DecimalValue.zero) >= 0) {
        hasInvalidAmount = true;
      }
      refundedAmount += amount.amount.abs();
    }

    final postedAmount = original.actualFinalAmount?.amount.abs();
    final refundState = _refundState(
      hasRefunds: refunds.isNotEmpty,
      hasInvalidCurrency: hasInvalidCurrency,
      hasInvalidAmount: hasInvalidAmount,
      postedAmount: postedAmount,
      refundedAmount: refundedAmount,
    );
    return ExpenseAdjustmentSummary._(
      original: original,
      refunds: List<ExpenseModel>.unmodifiable(refunds),
      refundedAmount: refundedAmount,
      refundState: refundState,
    );
  }

  final ExpenseModel original;
  final List<ExpenseModel> refunds;
  final DecimalValue refundedAmount;
  final ExpenseRefundState refundState;

  DecimalValue? get postedAmount => original.actualFinalAmount?.amount.abs();

  DecimalValue? get remainingAmount {
    final posted = postedAmount;
    return posted == null ? null : posted - refundedAmount;
  }

  DecimalValue? get netAmount => remainingAmount;

  bool get hasRefunds => refunds.isNotEmpty;

  bool get canRecordActual =>
      original.entryType == ExpenseEntryType.purchase &&
      original.status == ExpenseStatus.estimated &&
      original.actualFinalAmount == null &&
      !hasRefunds;

  bool get canEditActual =>
      original.entryType == ExpenseEntryType.purchase &&
      original.status == ExpenseStatus.confirmed &&
      original.actualFinalAmount != null &&
      !hasRefunds;

  bool get canCorrectActual =>
      original.entryType == ExpenseEntryType.purchase &&
      original.status == ExpenseStatus.confirmed &&
      original.actualFinalAmount != null &&
      hasRefunds;

  bool get canVoid =>
      original.entryType == ExpenseEntryType.purchase &&
      original.status == ExpenseStatus.estimated &&
      original.actualFinalAmount == null &&
      !hasRefunds;

  bool get canRefund {
    final remaining = remainingAmount;
    return original.entryType == ExpenseEntryType.purchase &&
        original.status == ExpenseStatus.confirmed &&
        original.actualFinalAmount != null &&
        refundState != ExpenseRefundState.invalid &&
        remaining != null &&
        remaining.compareTo(DecimalValue.zero) > 0;
  }
}

ExpenseRefundState _refundState({
  required bool hasRefunds,
  required bool hasInvalidCurrency,
  required bool hasInvalidAmount,
  required DecimalValue? postedAmount,
  required DecimalValue refundedAmount,
}) {
  if (!hasRefunds) return ExpenseRefundState.none;
  if (hasInvalidCurrency || hasInvalidAmount || postedAmount == null) {
    return ExpenseRefundState.invalid;
  }
  final comparison = refundedAmount.compareTo(postedAmount);
  if (comparison > 0) return ExpenseRefundState.invalid;
  if (comparison == 0) return ExpenseRefundState.full;
  return ExpenseRefundState.partial;
}
