import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

import 'helpers/isolated_test_database.dart';
import 'helpers/m4_fakes.dart';

const _captureKey = Key('app-store-preview-capture');

void main() {
  setUpAll(_loadCupertinoFonts);

  for (final device in _previewDevices) {
    testWidgets('captures English App Store screens for ${device.name}', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = device.devicePixelRatio;
      tester.view.physicalSize = device.physicalSize;
      tester.view.padding = const FakeViewPadding();
      tester.view.viewPadding = const FakeViewPadding();

      await _pumpPreviewApp(tester);
      await tester.tap(find.text('Trips').last);
      await tester.pumpAndSettle();
      await _capture(tester, device, '01-plan');

      await _pumpPreviewApp(tester);
      await tester.tap(find.byIcon(CupertinoIcons.viewfinder));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
      await _capture(tester, device, '02-scan');

      await _pumpPreviewApp(tester);
      await tester.tap(find.byKey(const Key('compare-payment-button')));
      await tester.pumpAndSettle();
      await _capture(tester, device, '03-compare');

      await _pumpPreviewApp(tester);
      await tester.tap(find.text('Ledger').last);
      await tester.pumpAndSettle();
      await _capture(tester, device, '04-ledger');
    });
  }
}

Future<void> _pumpPreviewApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  final database = createIsolatedTestDatabase();
  final data = _PreviewData.create();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        startupStateStoreProvider.overrideWithValue(
          const _CompletedStartupStateStore(),
        ),
        initialAppLanguageModeProvider.overrideWithValue(
          AppLanguageMode.english,
        ),
        systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
        rateRepositoryProvider.overrideWithValue(_previewRateRepository()),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(data.settings),
        ),
        paymentMethodRepositoryProvider.overrideWithValue(
          MemoryPaymentMethodRepository(data.paymentMethods),
        ),
        tripRepositoryProvider.overrideWithValue(
          MemoryTripRepository(<TripModel>[data.trip]),
        ),
        expenseRepositoryProvider.overrideWithValue(
          MemoryExpenseRepository(data.expenses),
        ),
        feeCalibrationRepositoryProvider.overrideWithValue(
          MemoryFeeCalibrationRepository(),
        ),
        networkStatusProvider.overrideWithValue(
          const FakeNetworkStatusProvider(),
        ),
      ],
      child: const RepaintBoundary(key: _captureKey, child: TripCostApp()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(
  WidgetTester tester,
  _PreviewDevice device,
  String screen,
) async {
  await tester.pump(const Duration(milliseconds: 250));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: device.devicePixelRatio);
    expect(image.width, device.physicalSize.width.round());
    expect(image.height, device.physicalSize.height.round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Failed to encode $screen.');
    final file = File(
      '${Directory.current.path}/artifacts/app-store-previews/raw/'
      '${device.name}/$screen.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
  });
}

Future<void> _loadCupertinoFonts() async {
  Future<ByteData> fontData() async {
    final bytes = await File('/System/Library/Fonts/SFNS.ttf').readAsBytes();
    return ByteData.sublistView(bytes);
  }

  await Future.wait(<Future<void>>[
    (FontLoader('CupertinoSystemText')..addFont(fontData())).load(),
    (FontLoader('CupertinoSystemDisplay')..addFont(fontData())).load(),
    (FontLoader(
          const TextStyle(
            fontFamily: CupertinoIcons.iconFont,
            package: CupertinoIcons.iconFontPackage,
          ).fontFamily!,
        )..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load(),
  ]);
}

ExchangeRateRepository _previewRateRepository() {
  final now = DateTime.now().toUtc();
  return ExchangeRateRepository(
    marketGateway: _PreviewRateGateway(now),
    snapshotRepository: MemoryRateSnapshotRepository(),
    clock: () => now,
    idFactory: () => 'preview-rate',
  );
}

final class _PreviewRateGateway implements FrankfurterRatesGateway {
  const _PreviewRateGateway(this.now);

  final DateTime now;

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async => const [];

  @override
  Future<FrankfurterRateDto> getRate({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    DateTime? date,
  }) async {
    final rate = switch ((baseCurrencyCode, quoteCurrencyCode)) {
      ('JPY', 'USD') => DecimalValue.parse('0.00675'),
      ('USD', 'JPY') => DecimalValue.parse('148.148148'),
      _ => DecimalValue.parse('1'),
    };
    return FrankfurterRateDto(
      date: date ?? now,
      baseCurrencyCode: baseCurrencyCode,
      quoteCurrencyCode: quoteCurrencyCode,
      rate: rate,
    );
  }

  @override
  Future<List<FrankfurterRateDto>> getRates({
    required String baseCurrencyCode,
    required Iterable<String> quoteCurrencyCodes,
    DateTime? date,
  }) async => <FrankfurterRateDto>[
    for (final quote in quoteCurrencyCodes)
      await getRate(
        baseCurrencyCode: baseCurrencyCode,
        quoteCurrencyCode: quote,
        date: date,
      ),
  ];
}

final class _PreviewData {
  const _PreviewData({
    required this.settings,
    required this.paymentMethods,
    required this.trip,
    required this.expenses,
  });

  factory _PreviewData.create() {
    final catalog = CurrencyCatalog();
    final usd = catalog.resolve('USD');
    final jpy = catalog.resolve('JPY');
    final krw = catalog.resolve('KRW');
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final tripStart = today.subtract(const Duration(days: 3));
    final tripEnd = today.add(const Duration(days: 4));
    final travelRewards = _paymentMethod(
      id: 'travel-rewards',
      name: 'Travel Rewards',
      currency: usd,
      foreignFee: '0',
      rateMarkup: '0.2',
      cashback: '1.5',
      createdAt: today.subtract(const Duration(days: 60)),
    );
    final everydayCard = _paymentMethod(
      id: 'everyday-card',
      name: 'Everyday Card',
      currency: usd,
      foreignFee: '3',
      rateMarkup: '0.5',
      cashback: '0.5',
      createdAt: today.subtract(const Duration(days: 40)),
    );
    final trip = TripModel(
      metadata: _metadata('tokyo-kyoto', today),
      name: 'Tokyo & Seoul',
      destinationCodes: const <String>['JP', 'KR'],
      startDate: tripStart,
      endDate: tripEnd,
      stops: <TripStopModel>[
        TripStopModel(
          countryCode: 'JP',
          startDate: tripStart,
          endDate: today,
          localCurrency: jpy,
        ),
        TripStopModel(
          countryCode: 'KR',
          startDate: today.add(const Duration(days: 1)),
          endDate: tripEnd,
          localCurrency: krw,
        ),
      ],
      homeCurrency: usd,
      localCurrencies: <Currency>[jpy, krw],
      totalBudget: Money.parse('3200', usd),
      participantCount: 2,
      defaultPaymentMethodId: travelRewards.metadata.recordId,
      offlinePackUpdatedAt: today.subtract(const Duration(days: 2)),
      status: TripStatus.active,
      createdAt: today.subtract(const Duration(days: 90)),
    );
    final expenses = <ExpenseModel>[
      _expense(
        id: 'hotel',
        title: 'Shinjuku hotel',
        category: 'hotel',
        localAmount: '94000',
        referenceAmount: '640.00',
        occurredAt: today.subtract(const Duration(days: 3)),
        usd: usd,
        jpy: jpy,
        method: travelRewards,
      ),
      _expense(
        id: 'sushi',
        title: 'Sushi dinner',
        category: 'food',
        localAmount: '12800',
        referenceAmount: '86.40',
        occurredAt: today.subtract(const Duration(days: 2)),
        usd: usd,
        jpy: jpy,
        method: travelRewards,
      ),
      _expense(
        id: 'train',
        title: 'Shinkansen tickets',
        category: 'transport',
        localAmount: '31800',
        referenceAmount: '214.20',
        occurredAt: today.subtract(const Duration(days: 1)),
        usd: usd,
        jpy: jpy,
        method: everydayCard,
      ),
      _expense(
        id: 'museum',
        title: 'Museum passes',
        category: 'tickets',
        localAmount: '7800',
        referenceAmount: '52.65',
        occurredAt: today.subtract(const Duration(hours: 6)),
        usd: usd,
        jpy: jpy,
        method: travelRewards,
      ),
      _expense(
        id: 'breakfast',
        title: 'Coffee & breakfast',
        category: 'food',
        localAmount: '4100',
        referenceAmount: '27.70',
        occurredAt: today.subtract(const Duration(hours: 3)),
        usd: usd,
        jpy: jpy,
        method: travelRewards,
      ),
      _expense(
        id: 'gifts',
        title: 'Gifts',
        category: 'shopping',
        localAmount: '17500',
        referenceAmount: '118.10',
        occurredAt: today.subtract(const Duration(hours: 1)),
        usd: usd,
        jpy: jpy,
        method: everydayCard,
      ),
    ];
    return _PreviewData(
      settings: UserSettingsModel(
        metadata: _metadata('settings', today),
        defaultCurrency: usd,
        lastTransactionCurrency: jpy,
        favoriteCurrencies: <Currency>[usd, jpy],
        languageMode: AppLanguageMode.english,
        refreshInterval: const Duration(hours: 12),
        wifiOnlyRefresh: false,
        syncEnabled: false,
      ),
      paymentMethods: <PaymentMethodModel>[travelRewards, everydayCard],
      trip: trip,
      expenses: expenses,
    );
  }

  final UserSettingsModel settings;
  final List<PaymentMethodModel> paymentMethods;
  final TripModel trip;
  final List<ExpenseModel> expenses;
}

PaymentMethodModel _paymentMethod({
  required String id,
  required String name,
  required Currency currency,
  required String foreignFee,
  required String rateMarkup,
  required String cashback,
  required DateTime createdAt,
}) => PaymentMethodModel(
  metadata: _metadata(id, createdAt),
  name: name,
  type: PaymentMethodType.creditCard,
  network: PaymentNetwork.visa,
  billingCurrency: currency,
  foreignFeePercent: DecimalValue.parse(foreignFee),
  crossBorderFeePercent: DecimalValue.zero,
  rateMarkupPercent: DecimalValue.parse(rateMarkup),
  fixedFee: DecimalValue.zero,
  cashbackPercent: DecimalValue.parse(cashback),
  minimumFee: null,
  maximumFee: null,
  supportedTransactionTypes: const <TransactionType>{TransactionType.purchase},
  createdAt: createdAt,
);

ExpenseModel _expense({
  required String id,
  required String title,
  required String category,
  required String localAmount,
  required String referenceAmount,
  required DateTime occurredAt,
  required Currency usd,
  required Currency jpy,
  required PaymentMethodModel method,
}) {
  final reference = Money.parse(referenceAmount, usd);
  final rate = RateSnapshotModel(
    metadata: _metadata('rate-$id', occurredAt),
    baseCurrency: jpy,
    quoteCurrency: usd,
    rate: DecimalValue.parse('0.00675'),
    sourceType: RateSourceType.market,
    sourceName: 'Daily reference rate',
    sourceTimestamp: occurredAt,
    fetchedAt: occurredAt,
    isCached: false,
  );
  return ExpenseModel(
    metadata: _metadata(id, occurredAt),
    tripId: 'tokyo-kyoto',
    title: title,
    category: category,
    transactionAmount: Money.parse(localAmount, jpy),
    referenceAmount: reference,
    estimatedFinalAmount: reference,
    actualFinalAmount: reference,
    paymentMethodId: method.metadata.recordId,
    paymentRuleSnapshot: method.freezeRules(),
    rateSnapshot: rate,
    taxAmount: Money(amount: DecimalValue.zero, currency: usd),
    tipAmount: Money(amount: DecimalValue.zero, currency: usd),
    discountAmount: Money(amount: DecimalValue.zero, currency: usd),
    participantCount: 2,
    occurredAt: occurredAt,
    receiptLocalPath: null,
    notes: null,
    budgetIncluded: true,
    status: ExpenseStatus.confirmed,
    entryType: ExpenseEntryType.purchase,
    relatedExpenseId: null,
    createdAt: occurredAt,
  );
}

SyncRecordMetadata _metadata(String id, DateTime updatedAt) =>
    SyncRecordMetadata(recordId: id, syncVersion: 1, updatedAt: updatedAt);

final class _CompletedStartupStateStore implements StartupStateStore {
  const _CompletedStartupStateStore();

  @override
  Future<bool> isOnboardingComplete() async => true;

  @override
  Future<void> markOnboardingComplete() async {}

  @override
  Future<void> resetOnboarding() async {}
}

final _previewDevices = <_PreviewDevice>[
  const _PreviewDevice(
    name: 'iphone-6.5',
    physicalSize: Size(1242, 2688),
    devicePixelRatio: 3,
  ),
  const _PreviewDevice(
    name: 'ipad-13',
    physicalSize: Size(2064, 2752),
    devicePixelRatio: 2,
  ),
];

final class _PreviewDevice {
  const _PreviewDevice({
    required this.name,
    required this.physicalSize,
    required this.devicePixelRatio,
  });

  final String name;
  final Size physicalSize;
  final double devicePixelRatio;
}
