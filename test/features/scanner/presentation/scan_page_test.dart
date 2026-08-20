import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/core/platform/system_permissions.dart';
import 'package:trip_cost/features/scanner/application/scan_flow.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';
import 'package:trip_cost/features/scanner/presentation/scan_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'record mode explains OCR bookkeeping and keeps manual fallback',
    (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(
        _testApp(
          arguments: const ScanPageArguments(
            initialPurpose: ScanPurpose.record,
          ),
          picker: _FakeImagePicker('/tmp/fixture.png'),
          gateway: _FakeOcrGateway(const <OcrCandidate>[]),
        ),
      );

      expect(find.byKey(const Key('scan-purpose-control')), findsOneWidget);
      expect(
        find.text('Scan a receipt or bill to prefill an expense.'),
        findsOneWidget,
      );
      expect(find.text('Add an expense manually'), findsOneWidget);
      expect(find.text('Continue without scanning'), findsOneWidget);
      expect(find.text('Compare payment methods'), findsNothing);
    },
  );

  testWidgets('before-scan state exposes all entry paths and bottom sheet', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      _testApp(
        picker: _FakeImagePicker('/tmp/fixture.png'),
        gateway: _FakeOcrGateway(const <OcrCandidate>[]),
      ),
    );

    expect(find.byKey(const Key('scan-intro-artwork')), findsOneWidget);
    expect(find.text('Scan a photo'), findsOneWidget);
    expect(find.text('Choose from Photos'), findsOneWidget);
    expect(find.text('Enter an amount manually'), findsOneWidget);
    expect(find.text('Continue even without an image'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('scan-manual-entry')),
      120,
    );
    await tester.tap(find.byKey(const Key('scan-manual-entry')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('scan-candidate-editor-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('scan-editor-handle')), findsOneWidget);
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Type the listed price directly'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);

    final currencyRowRect = tester.getRect(
      find.byKey(const Key('scan-edit-currency')),
    );
    final currencyValue = tester.widget<Text>(
      find.byKey(const Key('scan-edit-currency-value')),
    );
    final currencyValueRect = tester.getRect(
      find.byKey(const Key('scan-edit-currency-value')),
    );
    final currencyChevronRect = tester.getRect(
      find.byKey(const Key('scan-edit-currency-chevron')),
    );
    expect(currencyValue.textAlign, TextAlign.end);
    expect(currencyRowRect.right - currencyChevronRect.right, closeTo(14, 1));
    expect(currencyChevronRect.left - currencyValueRect.right, closeTo(8, 1));

    final sheet = tester.widget<Container>(
      find.byKey(const Key('scan-candidate-editor-sheet')),
    );
    final decoration = sheet.decoration! as BoxDecoration;
    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
  });

  testWidgets('photo OCR shows low-confidence candidate and editable total', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      _testApp(
        picker: _FakeImagePicker('/tmp/fixture.png'),
        gateway: _FakeOcrGateway(<OcrCandidate>[
          _candidate('TOTAL USD 12,50', confidence: 0.4),
        ]),
      ),
    );

    await tester.tap(find.byKey(const Key('scan-photo-library')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('1 price detected'), 200);

    expect(find.text('1 price detected'), findsOneWidget);
    expect(find.text('Low confidence · review this value'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Selected total · USD 12.5'),
      200,
    );
    expect(find.text('Selected total · USD 12.5'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('scan-continue')),
      100,
    );
    expect(
      tester
          .widget<CupertinoButton>(find.byKey(const Key('scan-continue')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('multiple prices can be selected and added together', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      _testApp(
        picker: _FakeImagePicker('/tmp/menu.png'),
        gateway: _FakeOcrGateway(<OcrCandidate>[
          _candidate(r'$12.50'),
          _candidate(r'$3.25'),
        ]),
      ),
    );

    await tester.tap(find.byKey(const Key('scan-camera')));
    await tester.pumpAndSettle();
    expect(find.text('Selected total · USD 15.75'), findsNothing);

    for (var index = 0; index < 2; index++) {
      final toggle = find.byKey(Key('scan-toggle-$index'));
      await tester.scrollUntilVisible(toggle, 220);
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      find.text('Selected total · USD 15.75'),
      150,
    );
    expect(find.text('Selected total · USD 15.75'), findsOneWidget);
  });

  testWidgets('permission denial keeps manual fallback available', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final permissions = _FakePermissionGateway();
    await tester.pumpWidget(
      _testApp(
        picker: _DeniedImagePicker(),
        gateway: _FakeOcrGateway(const <OcrCandidate>[]),
        permissionGateway: permissions,
      ),
    );

    await tester.tap(find.byKey(const Key('scan-camera')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('system-permission-alert')), findsOneWidget);
    expect(find.text('Camera access is unavailable'), findsOneWidget);
    await tester.tap(find.byKey(const Key('system-permission-open-settings')));
    await tester.pumpAndSettle();

    expect(permissions.openSettingsCalls, 1);
    expect(find.textContaining('Access was not granted'), findsOneWidget);
    expect(find.byKey(const Key('scan-manual-entry')), findsOneWidget);
  });

  testWidgets('no OCR candidates can fall back to a manual amount', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      _testApp(
        picker: _FakeImagePicker('/tmp/blank.png'),
        gateway: _FakeOcrGateway(const <OcrCandidate>[]),
      ),
    );
    await tester.tap(find.byKey(const Key('scan-photo-library')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('No prices were found'),
      200,
    );
    expect(find.textContaining('No prices were found'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('scan-manual-entry')),
      100,
    );
    await tester.tap(find.byKey(const Key('scan-manual-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('scan-edit-amount')), '1,280');
    await tester.tap(find.byKey(const Key('scan-edit-currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-common-option-USD')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-save-editor')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Selected total · USD 1280'),
      100,
    );
    expect(find.text('Selected total · USD 1280'), findsOneWidget);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _testApp({
  ScanPageArguments arguments = const ScanPageArguments(),
  required ScannerImagePicker picker,
  required ScannerOcrGateway gateway,
  SystemPermissionGateway? permissionGateway,
}) => ProviderScope(
  child: CupertinoApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ScanPage(
      arguments: arguments,
      imagePicker: picker,
      ocrGateway: gateway,
      permissionGateway: permissionGateway,
    ),
  ),
);

OcrCandidate _candidate(String text, {double confidence = 0.95}) =>
    OcrCandidate(
      text: text,
      confidence: confidence,
      x: 0.1,
      y: 0.2,
      width: 0.5,
      height: 0.1,
    );

final class _FakeImagePicker implements ScannerImagePicker {
  const _FakeImagePicker(this.path);

  final String path;

  @override
  Future<String?> pick(ScannerImageSource source) async => path;
}

final class _DeniedImagePicker implements ScannerImagePicker {
  @override
  Future<String?> pick(ScannerImageSource source) =>
      Future<String?>.error(PlatformException(code: 'camera_access_denied'));
}

final class _FakePermissionGateway implements SystemPermissionGateway {
  var openSettingsCalls = 0;

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<SystemPermissionStatus> request(SystemPermission permission) async =>
      SystemPermissionStatus.denied;

  @override
  Future<SystemPermissionStatus> status(SystemPermission permission) async =>
      SystemPermissionStatus.denied;
}

final class _FakeOcrGateway implements ScannerOcrGateway {
  const _FakeOcrGateway(this.candidates);

  final List<OcrCandidate> candidates;

  @override
  Future<OcrResult> recognizeImage(OcrRequest request) async =>
      OcrResult(candidates: candidates, contractVersion: 1);

  @override
  Future<List<String>> supportedRecognitionLanguages() async => const <String>[
    'en-US',
    'zh-Hans',
  ];
}
