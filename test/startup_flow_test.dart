import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

import 'helpers/m4_fakes.dart';

void main() {
  testWidgets('first launch opens onboarding and completion enters home', (
    tester,
  ) async {
    final store = _FakeStartupStateStore();
    final settings = MemorySettingsRepository();

    await tester.pumpWidget(_testApp(store, settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('Understand prices instantly'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(store.isComplete, isTrue);
    expect(settings.value?.defaultCurrency.code, 'USD');
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Understand the real cost'), findsWidgets);
  });

  testWidgets('returning user goes directly to home', (tester) async {
    final store = _FakeStartupStateStore(isComplete: true);

    await tester.pumpWidget(_testApp(store));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('local preference read failure falls back to onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_ThrowingStartupStateStore()));
    await tester.pumpAndSettle();

    expect(find.text('Understand prices instantly'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('three onboarding pages can be completed', (tester) async {
    final store = _FakeStartupStateStore();

    await tester.pumpWidget(_testApp(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Compare the cost to pay'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Keep every trip on budget'), findsOneWidget);

    await tester.tap(find.text('Start exploring'));
    await tester.pumpAndSettle();
    expect(store.isComplete, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });
}

Widget _testApp(StartupStateStore store, {MemorySettingsRepository? settings}) {
  return ProviderScope(
    overrides: [
      startupStateStoreProvider.overrideWithValue(store),
      rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
      settingsRepositoryProvider.overrideWithValue(
        settings ?? MemorySettingsRepository(),
      ),
      tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
      expenseRepositoryProvider.overrideWithValue(MemoryExpenseRepository()),
      feeCalibrationRepositoryProvider.overrideWithValue(
        MemoryFeeCalibrationRepository(),
      ),
      networkStatusProvider.overrideWithValue(
        const FakeNetworkStatusProvider(),
      ),
    ],
    child: const TripCostApp(),
  );
}

class _FakeStartupStateStore implements StartupStateStore {
  _FakeStartupStateStore({this.isComplete = false});

  bool isComplete;

  @override
  Future<bool> isOnboardingComplete() async => isComplete;

  @override
  Future<void> markOnboardingComplete() async {
    isComplete = true;
  }
}

class _ThrowingStartupStateStore implements StartupStateStore {
  @override
  Future<bool> isOnboardingComplete() {
    throw StateError('preference store unavailable');
  }

  @override
  Future<void> markOnboardingComplete() async {}
}
