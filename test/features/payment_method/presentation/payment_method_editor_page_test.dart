import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/features/payment_method/presentation/payment_methods_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

void main() {
  testWidgets('keeps the generated name in sync when switching templates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaymentMethodEditorPage(),
      ),
    );
    await tester.pumpAndSettle();

    await _selectTemplate(
      tester,
      currentLabel: '完全自定义',
      selectedLabel: '无外币手续费卡',
    );
    _expectNameAndForeignFee(tester, '无外币手续费卡', '0');

    await _selectTemplate(
      tester,
      currentLabel: '无外币手续费卡',
      selectedLabel: '1% 手续费卡',
    );
    _expectNameAndForeignFee(tester, '1% 手续费卡', '1');

    await _selectTemplate(
      tester,
      currentLabel: '1% 手续费卡',
      selectedLabel: '无外币手续费卡',
    );
    _expectNameAndForeignFee(tester, '无外币手续费卡', '0');
  });
}

Future<void> _selectTemplate(
  WidgetTester tester, {
  required String currentLabel,
  required String selectedLabel,
}) async {
  await tester.tap(find.widgetWithText(CupertinoButton, currentLabel));
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(CupertinoActionSheetAction, selectedLabel),
  );
  await tester.pumpAndSettle();
}

void _expectNameAndForeignFee(
  WidgetTester tester,
  String expectedName,
  String expectedForeignFee,
) {
  final fields = tester
      .widgetList<CupertinoTextField>(find.byType(CupertinoTextField))
      .toList();
  expect(fields[0].controller!.text, expectedName);
  expect(fields[1].controller!.text, expectedForeignFee);
}
