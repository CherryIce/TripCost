import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/trips/domain/trip_budget.dart';

import '../../../helpers/m5_fixtures.dart';

void main() {
  test('confirmed amount replaces estimate without double counting', () {
    final summary = const TripBudgetCalculator().calculate(
      trip: fixtureTrip(),
      expenses: <ExpenseModel>[
        fixtureExpense(
          estimate: '100',
          actual: '105',
          status: ExpenseStatus.confirmed,
        ),
        fixtureExpense(id: 'expense-2', estimate: '50'),
      ],
      now: DateTime.utc(2026, 8, 17),
    );

    expect(summary.confirmedSpent.amount.toString(), '105');
    expect(summary.estimatedSpent.amount.toString(), '50');
    expect(summary.spent.amount.toString(), '155');
    expect(summary.remaining!.amount.toString(), '845');
    expect(summary.remainingDays, 5);
    expect(summary.remainingPerDay!.amount.toFixed(2), '169.00');
  });

  test('refund reduces spend and voided entries are excluded', () {
    final summary = const TripBudgetCalculator().calculate(
      trip: fixtureTrip(),
      expenses: <ExpenseModel>[
        fixtureExpense(estimate: '100'),
        fixtureExpense(
          id: 'refund-1',
          estimate: '-40',
          actual: '-40',
          status: ExpenseStatus.confirmed,
          entryType: ExpenseEntryType.partialRefund,
          relatedExpenseId: 'expense-1',
        ),
        fixtureExpense(
          id: 'void-1',
          estimate: '900',
          budgetIncluded: false,
          entryType: ExpenseEntryType.voided,
        ),
      ],
      now: DateTime.utc(2026, 8, 17),
    );

    expect(summary.spent.amount.toString(), '60');
    expect(summary.remaining!.amount.toString(), '940');
  });

  test('zero and absent budgets remain usable', () {
    final zero = const TripBudgetCalculator().calculate(
      trip: fixtureTrip(budget: Money.parse('0', fixtureCny)),
      expenses: <ExpenseModel>[fixtureExpense()],
      now: DateTime.utc(2026, 8, 17),
    );
    final absentTrip = fixtureTrip();
    final absent = TripModel(
      metadata: absentTrip.metadata,
      name: absentTrip.name,
      destinationCodes: absentTrip.destinationCodes,
      startDate: absentTrip.startDate,
      endDate: absentTrip.endDate,
      homeCurrency: absentTrip.homeCurrency,
      localCurrencies: absentTrip.localCurrencies,
      totalBudget: null,
      participantCount: absentTrip.participantCount,
      defaultPaymentMethodId: absentTrip.defaultPaymentMethodId,
      status: absentTrip.status,
      createdAt: absentTrip.createdAt,
    );
    final noBudget = const TripBudgetCalculator().calculate(
      trip: absent,
      expenses: const <ExpenseModel>[],
      now: DateTime.utc(2026, 8, 17),
    );

    expect(zero.usedPercent, null);
    expect(zero.remaining!.amount.toString(), '-100');
    expect(noBudget.remaining, null);
    expect(noBudget.remainingPerDay, null);
  });

  test('date and archive rules produce stable list groups', () {
    final trip = fixtureTrip();
    expect(
      tripListSection(trip, DateTime.utc(2026, 8, 17)),
      TripListSection.active,
    );
    expect(
      tripListSection(trip, DateTime.utc(2026, 8, 1)),
      TripListSection.upcoming,
    );
    expect(
      tripListSection(trip, DateTime.utc(2026, 9, 1)),
      TripListSection.history,
    );
    expect(
      tripListSection(
        fixtureTrip(status: TripStatus.archived),
        DateTime.utc(2026, 8, 17),
      ),
      TripListSection.history,
    );
  });

  test('calendar date uses local year month and day near midnight', () {
    final localMidnight = DateTime(2026, 8, 18, 0, 15);

    expect(localCalendarDate(localMidnight), DateTime.utc(2026, 8, 18));
  });
}
