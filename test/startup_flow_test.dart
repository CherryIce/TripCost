import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

import 'helpers/isolated_test_database.dart';
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

  testWidgets('first launch follows a Chinese device locale', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh', 'CN'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(_testApp(_FakeStartupStateStore()));
    await tester.pumpAndSettle();

    expect(find.text('快速看懂当地价格'), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('比较不同支付成本'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('持续掌握旅行预算'), findsOneWidget);
    expect(find.text('建议本位币'), findsOneWidget);
    expect(find.text('创建行程'), findsOneWidget);
    expect(find.text('添加支付方式'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-home-currency')));
    await tester.pumpAndSettle();
    for (final currency in CurrencyCatalog.knownCurrencies) {
      expect(find.textContaining(currency.name), findsNothing);
    }
  });

  testWidgets('persisted Chinese ignores an English device locale', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('en', 'US'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      _testApp(
        _FakeStartupStateStore(),
        initialLanguageMode: AppLanguageMode.simplifiedChinese,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('快速看懂当地价格'), findsOneWidget);
    expect(find.text('Understand prices instantly'), findsNothing);
  });

  testWidgets('persisted English ignores a Chinese device locale', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh', 'CN'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      _testApp(
        _FakeStartupStateStore(),
        initialLanguageMode: AppLanguageMode.english,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Understand prices instantly'), findsOneWidget);
    expect(find.text('快速看懂当地价格'), findsNothing);
  });
}

Widget _testApp(
  StartupStateStore store, {
  MemorySettingsRepository? settings,
  AppLanguageMode initialLanguageMode = AppLanguageMode.system,
}) {
  final database = createIsolatedTestDatabase();
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      initialAppLanguageModeProvider.overrideWithValue(initialLanguageMode),
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

  @override
  Future<void> resetOnboarding() async {
    isComplete = false;
  }
}

class _ThrowingStartupStateStore implements StartupStateStore {
  @override
  Future<bool> isOnboardingComplete() {
    throw StateError('preference store unavailable');
  }

  @override
  Future<void> markOnboardingComplete() async {}

  @override
  Future<void> resetOnboarding() async {}
}
