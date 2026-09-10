import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/features/settings/application/kifx_mini_auto_open_store.dart';
import 'package:trip_cost/features/settings/presentation/settings_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

import '../../../helpers/isolated_test_database.dart';
import '../../../helpers/m4_fakes.dart';

void main() {
  testWidgets('secondary categories cover the persistent bottom navigation', (
    tester,
  ) async {
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: CupertinoApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Column(
            children: <Widget>[
              Expanded(
                child: Navigator(
                  onGenerateRoute: (_) => CupertinoPageRoute<void>(
                    builder: (_) => const SettingsPage(),
                  ),
                ),
              ),
              const Text('persistent-bottom-navigation'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('persistent-bottom-navigation'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-category-currency-rates')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('currency-rates-settings-list')),
      findsOneWidget,
    );
    expect(find.text('persistent-bottom-navigation'), findsNothing);
  });

  testWidgets('currency details move to a secondary page and stay aligned', (
    tester,
  ) async {
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: CupertinoApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('货币与汇率'), findsOneWidget);
    expect(find.text('默认本位币'), findsNothing);
    expect(find.text('仅在 Wi-Fi 下刷新汇率'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-category-currency-rates')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('currency-rates-settings-list')),
      findsOneWidget,
    );
    expect(find.text('默认本位币'), findsOneWidget);
    expect(find.text('仅在 Wi-Fi 下刷新汇率'), findsOneWidget);

    double trailingChevronX(String value) {
      final button = find.ancestor(
        of: find.text(value),
        matching: find.byType(CupertinoButton),
      );
      final chevron = find.descendant(
        of: button,
        matching: find.byIcon(CupertinoIcons.chevron_forward),
      );
      return tester.getCenter(chevron).dx;
    }

    final defaultCurrencyChevronX = trailingChevronX('CNY');
    expect(trailingChevronX('每 6 小时'), closeTo(defaultCurrencyChevronX, 0.1));
  });

  testWidgets('settings remain navigable at large text with button semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: CupertinoApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-category-data')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byKey(const Key('settings-category-list')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Data, backup, and export')),
      findsWidgets,
    );
    expect(find.text('Export expenses as CSV'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-category-data')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('data-settings-list')), findsOneWidget);
    expect(find.bySemanticsLabel('Export expenses as CSV'), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('favorite setting is removed and default uses shared picker', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.padding = const FakeViewPadding(bottom: 102);
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: CupertinoApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favorite currencies'), findsNothing);
    await tester.tap(find.byKey(const Key('settings-category-currency-rates')));
    await tester.pumpAndSettle();

    final defaultCurrency = find.text('Default home currency');
    await tester.ensureVisible(defaultCurrency);
    await tester.tap(defaultCurrency);
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoPopupSurface), findsNothing);
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    expect(find.text('Common trading currencies'), findsOneWidget);
    expect(find.text('All trading currencies'), findsOneWidget);
    expect(find.byKey(const Key('currency-option-CNY')), findsOneWidget);
    final list = tester.widget<ListView>(
      find.byKey(const Key('currency-directory-list')),
    );
    final padding = (list.padding! as EdgeInsetsDirectional).resolve(
      TextDirection.ltr,
    );
    expect(padding.bottom, 50);
    expect(padding.right, 28);
  });

  testWidgets('settings opens KIFX with the TripCost host configuration', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('stmini_flutter/methods');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final autoOpenStore = _MemoryKifxMiniAutoOpenStore();
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          kifxMiniAutoOpenStoreProvider.overrideWithValue(autoOpenStore),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: CupertinoApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('settings-category-kifx-mini'));
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.text('KIFX小程序'), findsOneWidget);
    expect(calls.map((call) => call.method), <String>[
      'initialize',
      'openMini',
    ]);
    expect(calls.first.arguments, <String, Object?>{
      'bridgeContext': <String, Object?>{'packageName': 'com.tripcost.lite'},
    });
    final openArguments = calls.last.arguments! as Map<Object?, Object?>;
    final link = Uri.parse(openArguments['link']! as String);
    expect(link.scheme, 'mini');
    expect(link.host, 'kifx');
    expect(
      link.queryParameters['downloadUrl'],
      'https://site.761242.com/maple/v1/static/'
      '20260908_018ee521a82c8c4edb72c8d9f2a2b18157.zip',
    );
    expect(link.queryParameters['currentVersion'], '2.0.0');
    expect(link.queryParameters['minSupportVersion'], '2.0.0');
    expect(link.queryParameters['miniName'], 'KIFX');
    expect(link.queryParameters['miniNameEn'], 'KIFX');
    expect(autoOpenStore.enabled, isTrue);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('settings recognizes a five-second three-finger long press', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('stmini_flutter/methods');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final autoOpenStore = _MemoryKifxMiniAutoOpenStore();
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          kifxMiniAutoOpenStoreProvider.overrideWithValue(autoOpenStore),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: CupertinoApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('settings-category-kifx-mini'));
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    final entryBounds = tester.getRect(entry);
    final first = await tester.startGesture(
      Offset(entryBounds.left + 40, entryBounds.center.dy),
      pointer: 1,
    );
    final second = await tester.startGesture(
      Offset(entryBounds.left + 120, entryBounds.center.dy),
      pointer: 2,
    );
    final third = await tester.startGesture(
      Offset(entryBounds.left + 200, entryBounds.center.dy),
      pointer: 3,
    );

    await tester.pump(const Duration(milliseconds: 4999));
    expect(calls, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(calls.map((call) => call.method), <String>[
      'initialize',
      'openMini',
    ]);

    await tester.pump(const Duration(seconds: 5));
    expect(calls, hasLength(2));

    await first.up();
    await second.up();
    await third.up();
    await tester.pump();
    expect(calls, hasLength(2));
    expect(autoOpenStore.enabled, isTrue);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a failed KIFX launch does not enable automatic opening', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('stmini_flutter/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final autoOpenStore = _MemoryKifxMiniAutoOpenStore();
    final database = createIsolatedTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          kifxMiniAutoOpenStoreProvider.overrideWithValue(autoOpenStore),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: CupertinoApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('settings-category-kifx-mini'));
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(autoOpenStore.enabled, isFalse);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

final class _MemoryKifxMiniAutoOpenStore implements KifxMiniAutoOpenStore {
  bool enabled = false;

  @override
  Future<void> enable() async {
    enabled = true;
  }

  @override
  Future<bool> isEnabled() async => enabled;
}
