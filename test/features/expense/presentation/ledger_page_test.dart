import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:trip_cost/features/expense/presentation/ledger_page.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';

void main() {
  test('receipt picker imports the image into private storage', () async {
    final root = await Directory.systemTemp.createTemp('receipt-editor-test-');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.png');
    await source.writeAsBytes(<int>[0, 1, 2, 3]);

    final reference = await importReceiptFromPhotoLibrary(
      picker: _ReceiptPicker(source.path),
      storage: ReceiptStorage(rootDirectory: () async => root),
    );

    expect(reference, startsWith('receipts/'));
    final imported = await Directory('${root.path}/receipts').list().toList();
    expect(imported, hasLength(1));
    expect(imported.single.path, isNot(source.path));
  });
}

final class _ReceiptPicker implements ScannerImagePicker {
  const _ReceiptPicker(this.path);

  final String path;

  @override
  Future<String?> pick(ScannerImageSource source) async => path;
}
