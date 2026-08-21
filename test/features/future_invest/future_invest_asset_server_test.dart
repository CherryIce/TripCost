import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/features/future_invest/infrastructure/future_invest_asset_server.dart';

void main() {
  test(
    'serves the embedded ESM entry only from the verified asset manifest',
    () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      final server = FutureInvestAssetServer(
        assetBundle: _MemoryAssetBundle(<String, String>{
          'assets/future_invest_h5/asset-manifest.json': jsonEncode({
            'files': [
              {'path': 'index.html'},
              {'path': 'static/js/entry.js'},
            ],
          }),
          'assets/future_invest_h5/index.html': '''
            <div id="app"></div>
            <script type="module" src="./static/js/entry.js"></script>
          ''',
          'assets/future_invest_h5/static/js/entry.js':
              'document.querySelector("#app").textContent = "ready";',
        }),
      );
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await server.close();
        HttpOverrides.global = previousHttpOverrides;
      });

      final entry = await server.start();
      expect(entry.scheme, 'http');
      expect(entry.host, InternetAddress.loopbackIPv4.address);

      final entryResponse = await _get(client, entry);
      expect(entryResponse.statusCode, HttpStatus.ok);
      expect(entryResponse.contentType, startsWith('text/html'));
      expect(entryResponse.body, contains('<div id="app"></div>'));

      final entryScript = RegExp(
        r'<script type="module" src="([^"]+\.js)"',
      ).firstMatch(entryResponse.body)?.group(1);
      expect(entryScript, isNotNull);

      final scriptResponse = await _get(client, entry.resolve(entryScript!));
      expect(scriptResponse.statusCode, HttpStatus.ok);
      expect(scriptResponse.contentType, startsWith('text/javascript'));
      expect(scriptResponse.body, isNotEmpty);

      final missingResponse = await _get(
        client,
        entry.resolve('static/js/not-in-asset-manifest.js'),
      );
      expect(missingResponse.statusCode, HttpStatus.notFound);

      await server.close();
      expect(server.start, throwsStateError);
    },
  );
}

Future<_ResponseSnapshot> _get(HttpClient client, Uri uri) async {
  final response = await (await client.getUrl(uri)).close();
  return _ResponseSnapshot(
    statusCode: response.statusCode,
    contentType: response.headers.contentType?.toString(),
    body: await utf8.decoder.bind(response).join(),
  );
}

final class _ResponseSnapshot {
  const _ResponseSnapshot({
    required this.statusCode,
    required this.contentType,
    required this.body,
  });

  final int statusCode;
  final String? contentType;
  final String body;
}

final class _MemoryAssetBundle extends AssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw StateError('Missing test asset: $key');
    final bytes = Uint8List.fromList(utf8.encode(value));
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }
}
