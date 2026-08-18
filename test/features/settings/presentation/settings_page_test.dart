import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/features/settings/presentation/settings_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

import '../../../helpers/isolated_test_database.dart';
import '../../../helpers/m4_fakes.dart';

void main() {
  testWidgets('currency setting actions share the same trailing alignment', (
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

    final favoritesChevronX = trailingChevronX('JPY, USD, EUR');
    expect(trailingChevronX('CNY'), closeTo(favoritesChevronX, 0.1));
    expect(trailingChevronX('每 6 小时'), closeTo(favoritesChevronX, 0.1));
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

    expect(find.text('Currency and rates'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Default home currency')),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.text('Export expenses as CSV'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.bySemanticsLabel('Export expenses as CSV'), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('favorite currency sheet insets rows and scrollable safe area', (
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

    final favoriteCurrencies = find.text('Favorite currencies');
    await tester.ensureVisible(favoriteCurrencies);
    await tester.tap(favoriteCurrencies);
    await tester.pumpAndSettle();

    final sheet = find.byType(CupertinoPopupSurface);
    final sheetList = find.descendant(
      of: sheet,
      matching: find.byType(ListView),
    );
    final list = tester.widget<ListView>(sheetList);
    expect(list.padding, const EdgeInsets.fromLTRB(16, 0, 16, 50));
  });
}
