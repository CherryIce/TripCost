import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

enum TripListSection { active, upcoming, history }

TripListSection tripListSection(TripModel trip, DateTime now) {
  final today = _dateOnlyUtc(now);
  if (trip.status == TripStatus.archived || trip.endDate.isBefore(today)) {
    return TripListSection.history;
  }
  if (trip.startDate.isAfter(today)) return TripListSection.upcoming;
  return TripListSection.active;
}

TripStatus tripStatusForDates({
  required DateTime startDate,
  required DateTime endDate,
  required DateTime now,
  bool archived = false,
}) {
  if (archived) return TripStatus.archived;
  return startDate.isAfter(_dateOnlyUtc(now))
      ? TripStatus.upcoming
      : TripStatus.active;
}

final class TripBudgetSummary {
  const TripBudgetSummary({
    required this.totalBudget,
    required this.confirmedSpent,
    required this.estimatedSpent,
    required this.spent,
    required this.remaining,
    required this.remainingPerDay,
    required this.currentDailyAverage,
    required this.elapsedDays,
    required this.remainingDays,
    required this.totalDays,
    required this.categoryTotals,
    required this.paymentMethodTotals,
  });

  final Money? totalBudget;
  final Money confirmedSpent;
  final Money estimatedSpent;
  final Money spent;
  final Money? remaining;
  final Money? remainingPerDay;
  final Money currentDailyAverage;
  final int elapsedDays;
  final int remainingDays;
  final int totalDays;
  final Map<String, Money> categoryTotals;
  final Map<String, Money> paymentMethodTotals;

  DecimalValue? get usedPercent {
    final budget = totalBudget;
    if (budget == null || budget.amount.compareTo(DecimalValue.zero) <= 0) {
      return null;
    }
    return spent.amount
        .divide(budget.amount, precision: 6)
        .multiply(DecimalValue.parse('100'));
  }
}

final class TripBudgetCalculator {
  const TripBudgetCalculator();

  TripBudgetSummary calculate({
    required TripModel trip,
    required Iterable<ExpenseModel> expenses,
    required DateTime now,
  }) {
    final zero = Money(amount: DecimalValue.zero, currency: trip.homeCurrency);
    var confirmed = zero;
    var estimated = zero;
    final categories = <String, Money>{};
    final paymentMethods = <String, Money>{};

    for (final expense in expenses) {
      if (expense.tripId != trip.metadata.recordId ||
          !expense.budgetIncluded ||
          expense.entryType == ExpenseEntryType.voided) {
        continue;
      }
      final amount = expense.actualFinalAmount ?? expense.estimatedFinalAmount;
      if (amount.currency != trip.homeCurrency) continue;
      if (expense.actualFinalAmount != null ||
          expense.status == ExpenseStatus.confirmed) {
        confirmed = confirmed + amount;
      } else {
        estimated = estimated + amount;
      }
      categories.update(
        expense.category,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      final paymentKey = expense.paymentMethodId ?? '';
      paymentMethods.update(
        paymentKey,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    final spent = confirmed + estimated;
    final today = _dateOnlyUtc(now);
    final totalDays = trip.endDate.difference(trip.startDate).inDays + 1;
    final elapsedDays = today.isBefore(trip.startDate)
        ? 0
        : today.isAfter(trip.endDate)
        ? totalDays
        : today.difference(trip.startDate).inDays + 1;
    final remainingDays = today.isAfter(trip.endDate)
        ? 0
        : today.isBefore(trip.startDate)
        ? totalDays
        : trip.endDate.difference(today).inDays + 1;
    final remaining = trip.totalBudget == null
        ? null
        : trip.totalBudget! - spent;
    final remainingPerDay = remaining == null || remainingDays == 0
        ? null
        : remaining.divide(DecimalValue.parse(remainingDays.toString()));
    final currentDailyAverage = elapsedDays == 0
        ? zero
        : spent.divide(DecimalValue.parse(elapsedDays.toString()));

    return TripBudgetSummary(
      totalBudget: trip.totalBudget,
      confirmedSpent: confirmed,
      estimatedSpent: estimated,
      spent: spent,
      remaining: remaining,
      remainingPerDay: remainingPerDay,
      currentDailyAverage: currentDailyAverage,
      elapsedDays: elapsedDays,
      remainingDays: remainingDays,
      totalDays: totalDays,
      categoryTotals: Map<String, Money>.unmodifiable(categories),
      paymentMethodTotals: Map<String, Money>.unmodifiable(paymentMethods),
    );
  }
}

DateTime _dateOnlyUtc(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

extension on DecimalValue {
  DecimalValue multiply(DecimalValue other) => this * other;
}
