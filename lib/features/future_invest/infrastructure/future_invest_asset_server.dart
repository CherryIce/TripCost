import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class FutureInvestAssetServer {
  FutureInvestAssetServer({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  static const _assetRoot = 'assets/future_invest_h5';
  static const _manifestAsset = '$_assetRoot/asset-manifest.json';

  final AssetBundle _assetBundle;
  HttpServer? _server;
  Future<Uri>? _startFuture;
  Set<String> _allowedPaths = const <String>{};
  bool _closed = false;

  Future<Uri> start() {
    if (_closed) {
      throw StateError('Future Invest asset server is already closed.');
    }
    final server = _server;
    if (server != null) return Future<Uri>.value(_entryUri(server));
    return _startFuture ??= _start();
  }

  Future<void> close() async {
    _closed = true;
    final pendingStart = _startFuture;
    if (pendingStart != null) {
      try {
        await pendingStart;
      } on Object {
        // A failed start has no server to close.
      }
    }
    final server = _server;
    _server = null;
    _startFuture = null;
    if (server != null) await server.close(force: true);
  }

  Future<Uri> _start() async {
    try {
      _allowedPaths = await _loadAllowedPaths();
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: false,
      );
      _server = server;
      server.listen((request) => unawaited(_serve(request)));
      return _entryUri(server);
    } finally {
      _startFuture = null;
    }
  }

  Future<Set<String>> _loadAllowedPaths() async {
    final manifest = jsonDecode(await _assetBundle.loadString(_manifestAsset));
    if (manifest is! Map<String, dynamic>) {
      throw const FormatException('Invalid Future Invest asset manifest.');
    }
    final files = manifest['files'];
    if (files is! List<dynamic>) {
      throw const FormatException('Future Invest manifest has no file list.');
    }

    return <String>{
      'asset-manifest.json',
      for (final file in files)
        if (file is Map<String, dynamic> && file['path'] is String)
          file['path'] as String,
    };
  }

  Future<void> _serve(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        return;
      }

      final relativePath = request.uri.pathSegments.isEmpty
          ? 'index.html'
          : request.uri.pathSegments.join('/');
      if (!_allowedPaths.contains(relativePath)) {
        response.statusCode = HttpStatus.notFound;
        return;
      }

      final data = await _assetBundle.load('$_assetRoot/$relativePath');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      response.headers
        ..contentType = _contentType(relativePath)
        ..contentLength = bytes.length
        ..set('X-Content-Type-Options', 'nosniff')
        ..set(
          HttpHeaders.cacheControlHeader,
          _isMutableEntry(relativePath)
              ? 'no-store'
              : 'public, max-age=31536000, immutable',
        );
      if (request.method == 'GET') response.add(bytes);
    } on FlutterError {
      response.statusCode = HttpStatus.notFound;
    } on Object {
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  }

  Uri _entryUri(HttpServer server) => Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: server.port,
    path: '/index.html',
  );

  bool _isMutableEntry(String relativePath) =>
      relativePath == 'index.html' ||
      relativePath == 'asset-manifest.json' ||
      relativePath == 'version.json';

  ContentType _contentType(String relativePath) {
    if (relativePath.endsWith('.html')) {
      return ContentType.html;
    }
    if (relativePath.endsWith('.js')) {
      return ContentType('text', 'javascript', charset: 'utf-8');
    }
    if (relativePath.endsWith('.css')) {
      return ContentType('text', 'css', charset: 'utf-8');
    }
    if (relativePath.endsWith('.json')) {
      return ContentType.json;
    }
    if (relativePath.endsWith('.svg')) {
      return ContentType('image', 'svg+xml');
    }
    if (relativePath.endsWith('.png')) {
      return ContentType('image', 'png');
    }
    if (relativePath.endsWith('.gif')) {
      return ContentType('image', 'gif');
    }
    if (relativePath.endsWith('.webp')) {
      return ContentType('image', 'webp');
    }
    return ContentType.binary;
  }
}
