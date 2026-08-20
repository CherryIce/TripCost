import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/features/payment_method/presentation/payment_methods_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

void main() {
  testWidgets('groups the editor into compact payment sections', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(_localizedEditor());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('payment-editor-template-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('payment-editor-basics-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('payment-editor-fees-section')),
      findsOneWidget,
    );

    final nameField = tester.widget<CupertinoTextField>(
      find.byKey(const Key('payment-name-field')),
    );
    expect(nameField.textAlign, TextAlign.end);
  });

  testWidgets('keeps the generated name in sync when switching templates', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedEditor());
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

  testWidgets('shows invalid form feedback in the root overlay', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(_localizedEditor());
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pump(const Duration(milliseconds: 200));

    final toast = find.byKey(const Key('payment-validation-toast'));
    final template = find.byKey(const Key('payment-editor-template-section'));
    expect(toast, findsOneWidget);
    expect(
      find.ancestor(of: toast, matching: find.byType(ListView)),
      findsNothing,
    );
    expect(tester.getRect(toast).top, lessThan(tester.getRect(template).top));
    expect(find.text('请检查名称、非负费率和手续费上下限。'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });
}

Widget _localizedEditor() => const CupertinoApp(
  locale: Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: PaymentMethodEditorPage(),
);

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
