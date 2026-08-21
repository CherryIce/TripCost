import 'dart:convert';

final class FutureInvestBridgeMessage {
  const FutureInvestBridgeMessage({
    required this.method,
    required this.historySteps,
    this.methodId,
  });

  static const Set<String> backMethods = <String>{'back', 'close', 'pop'};

  final String method;
  final String? methodId;
  final int historySteps;

  bool get requestsBack => backMethods.contains(method.toLowerCase());

  static FutureInvestBridgeMessage? tryParse(String rawMessage) {
    final trimmed = rawMessage.trim();
    if (trimmed.isEmpty) return null;

    final decoded = _tryDecode(trimmed);
    if (decoded is Map<Object?, Object?>) {
      final method = decoded['method']?.toString().trim();
      if (method == null || method.isEmpty) return null;

      final params = decoded['params'];
      final paramsMap = params is Map<Object?, Object?> ? params : null;
      return FutureInvestBridgeMessage(
        method: method,
        methodId: paramsMap?['methodId']?.toString(),
        historySteps: _parseHistorySteps(paramsMap?['count']),
      );
    }
    if (decoded is String) return _fromPlainMethod(decoded);

    // WKWebView forwards JavaScript objects as a native map. webview_flutter
    // exposes that map through `toString()`, for example:
    // {method: close, params: {methodId: cb_close_1, count: 2}}
    final method = _mapDescriptionValue(trimmed, 'method');
    if (method == null || method.isEmpty) return _fromPlainMethod(trimmed);
    return FutureInvestBridgeMessage(
      method: method,
      methodId: _mapDescriptionValue(trimmed, 'methodId'),
      historySteps: _parseHistorySteps(_mapDescriptionValue(trimmed, 'count')),
    );
  }

  static Object? _tryDecode(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static FutureInvestBridgeMessage? _fromPlainMethod(String value) {
    final method = value.trim().toLowerCase();
    if (!backMethods.contains(method)) return null;
    return FutureInvestBridgeMessage(method: method, historySteps: 1);
  }

  static String? _mapDescriptionValue(String source, String key) {
    final match = RegExp(
      '(?:^|[,{]\\s*)${RegExp.escape(key)}\\s*:\\s*([^,}]+)',
      caseSensitive: false,
    ).firstMatch(source);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll(RegExp(r'''^["']|["']$'''), '');
  }

  static int _parseHistorySteps(Object? value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 1) return 1;
    return parsed.clamp(1, 20);
  }
}
