import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

final class CalibrationSummary {
  const CalibrationSummary({
    required this.count,
    required this.minimumMarkupPercent,
    required this.maximumMarkupPercent,
  });

  final int count;
  final DecimalValue? minimumMarkupPercent;
  final DecimalValue? maximumMarkupPercent;

  bool get canSuggestRuleUpdate => count >= 3;
}

final class ExpenseCalibrationCalculator {
  const ExpenseCalibrationCalculator();

  DecimalValue effectiveMarkupPercent({
    required Money referenceAmount,
    required Money actualFinalAmount,
  }) {
    if (referenceAmount.currency != actualFinalAmount.currency) {
      throw const FormatException('Calibration currencies must match.');
    }
    if (referenceAmount.amount.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('Reference amount must be positive.');
    }
    return (actualFinalAmount.amount.divide(referenceAmount.amount) -
            DecimalValue.parse('1')) *
        DecimalValue.parse('100');
  }

  Money difference({
    required Money estimatedAmount,
    required Money actualFinalAmount,
  }) {
    return actualFinalAmount - estimatedAmount;
  }

  DecimalValue differencePercent({
    required Money estimatedAmount,
    required Money actualFinalAmount,
  }) {
    if (estimatedAmount.amount.isZero) return DecimalValue.zero;
    return (actualFinalAmount.amount.divide(estimatedAmount.amount) -
            DecimalValue.parse('1')) *
        DecimalValue.parse('100');
  }

  CalibrationSummary summarize(Iterable<FeeCalibrationModel> calibrations) {
    final values = <DecimalValue>[
      for (final item in calibrations) item.effectiveMarkupPercent,
    ];
    values.sort();
    return CalibrationSummary(
      count: values.length,
      minimumMarkupPercent: values.firstOrNull,
      maximumMarkupPercent: values.lastOrNull,
    );
  }
}

bool isPossibleDuplicate(
  ExpenseModel candidate,
  ExpenseModel existing, {
  Duration tolerance = const Duration(minutes: 5),
}) {
  if (candidate.metadata.recordId == existing.metadata.recordId ||
      candidate.entryType != ExpenseEntryType.purchase ||
      existing.entryType != ExpenseEntryType.purchase) {
    return false;
  }
  final difference = candidate.occurredAt.difference(existing.occurredAt).abs();
  return candidate.tripId == existing.tripId &&
      candidate.transactionAmount == existing.transactionAmount &&
      candidate.title.trim().toLowerCase() ==
          existing.title.trim().toLowerCase() &&
      difference <= tolerance;
}
