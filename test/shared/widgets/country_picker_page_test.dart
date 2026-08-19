import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/country_picker_page.dart';

void main() {
  testWidgets('searches multiple countries and returns ISO2 codes', (
    tester,
  ) async {
    List<String>? selection;
    await _pumpPickerHost(
      tester,
      onOpen: (context) async {
        selection = await showCountryMultiPickerPage(
          context: context,
          title: '国家或地区',
          doneLabel: '完成',
          selectedCodes: const <String>[],
          minimumSelection: 1,
        );
      },
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search-field')), '日本');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-JP')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search-field')), '韩国');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-KR')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, '完成'));
    await tester.pumpAndSettle();

    expect(selection, <String>['JP', 'KR']);
  });

  testWidgets('keeps an unrecognized saved code visible until it is replaced', (
    tester,
  ) async {
    List<String>? selection;
    await _pumpPickerHost(
      tester,
      onOpen: (context) async {
        selection = await showCountryMultiPickerPage(
          context: context,
          title: '国家或地区',
          doneLabel: '完成',
          selectedCodes: const <String>['JAPAN'],
          minimumSelection: 1,
        );
      },
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('country-option-unknown-JAPAN')),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('country-search-field')), '日本');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-JP')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search-field')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-unknown-JAPAN')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, '完成'));
    await tester.pumpAndSettle();

    expect(selection, <String>['JP']);
  });
}

Future<void> _pumpPickerHost(
  WidgetTester tester, {
  required Future<void> Function(BuildContext) onOpen,
}) {
  return tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => CupertinoPageScaffold(
          child: Center(
            child: CupertinoButton(
              onPressed: () => onOpen(context),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    ),
  );
}
