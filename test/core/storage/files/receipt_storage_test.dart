import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';

void main() {
  late Directory root;
  late ReceiptStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('m2-receipts-');
    storage = ReceiptStorage(rootDirectory: () async => root);
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'imports into a private relative reference and detects missing files',
    () async {
      final source = File('${root.path}/source.png');
      await source.writeAsBytes(<int>[1, 2, 3, 4]);

      final reference = await storage.importImage(source);
      expect(reference, startsWith('receipts/'));
      expect(reference, isNot(contains(root.path)));
      expect(
        (await storage.resolve(reference)).status,
        ReceiptLookupStatus.available,
      );

      await storage.delete(reference);
      expect(
        (await storage.resolve(reference)).status,
        ReceiptLookupStatus.missing,
      );
    },
  );

  test('rejects path traversal and unsupported files', () async {
    expect(
      (await storage.resolve('../outside.png')).status,
      ReceiptLookupStatus.invalidReference,
    );
    final text = File('${root.path}/receipt.txt');
    await text.writeAsString('not an image');
    await expectLater(
      storage.importImage(text),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'clears managed images without removing unrelated private files',
    () async {
      final source = File('${root.path}/source.jpg');
      final unrelated = File('${root.path}/unrelated.dat');
      await source.writeAsBytes(<int>[1]);
      await unrelated.writeAsBytes(<int>[2]);
      await storage.importImage(source);

      final report = await storage.clearAll();

      expect(report.succeeded, isTrue);
      expect(report.deletedFiles, 1);
      expect(await unrelated.exists(), isTrue);
    },
  );
}
