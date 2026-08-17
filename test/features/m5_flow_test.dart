import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

import '../helpers/m4_fakes.dart';
import '../helpers/m5_fixtures.dart';

void main() {
  testWidgets('trip budget and ledger are reachable from the app shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupStateStoreProvider.overrideWithValue(_CompletedStore()),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
          networkStatusProvider.overrideWithValue(
            const FakeNetworkStatusProvider(),
          ),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(<PaymentMethodModel>[
              fixturePaymentMethod(),
            ]),
          ),
          tripRepositoryProvider.overrideWithValue(
            MemoryTripRepository(<TripModel>[fixtureTrip()]),
          ),
          expenseRepositoryProvider.overrideWithValue(
            MemoryExpenseRepository(<ExpenseModel>[fixtureExpense()]),
          ),
          feeCalibrationRepositoryProvider.overrideWithValue(
            MemoryFeeCalibrationRepository(),
          ),
        ],
        child: const TripCostApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    expect(find.text('Tokyo week'), findsOneWidget);
    expect(find.textContaining('100.00'), findsWidgets);

    await tester.tap(find.text('Tokyo week'));
    await tester.pumpAndSettle();
    expect(find.text('Spent'), findsOneWidget);
    expect(find.textContaining('100.00'), findsWidgets);
    expect(find.text('Remaining per day'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.book));
    await tester.pumpAndSettle();
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
  });
}

final class _CompletedStore implements StartupStateStore {
  @override
  Future<bool> isOnboardingComplete() async => true;

  @override
  Future<void> markOnboardingComplete() async {}
}
