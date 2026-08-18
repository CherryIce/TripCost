import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

import 'helpers/isolated_test_database.dart';
import 'helpers/m4_fakes.dart';

void main() {
  testWidgets('shows four destinations and a separate scan action', (
    tester,
  ) async {
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          startupStateStoreProvider.overrideWithValue(
            _CompletedStartupStateStore(),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          expenseRepositoryProvider.overrideWithValue(
            MemoryExpenseRepository(),
          ),
          feeCalibrationRepositoryProvider.overrideWithValue(
            MemoryFeeCalibrationRepository(),
          ),
          networkStatusProvider.overrideWithValue(
            const FakeNetworkStatusProvider(),
          ),
        ],
        child: const TripCostApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.viewfinder), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.viewfinder));
    await tester.pumpAndSettle();
    expect(find.text('Scan a price'), findsWidgets);
  });
}

class _CompletedStartupStateStore implements StartupStateStore {
  @override
  Future<bool> isOnboardingComplete() async => true;

  @override
  Future<void> markOnboardingComplete() async {}

  @override
  Future<void> resetOnboarding() async {}
}
