import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/features/future_invest/infrastructure/future_invest_js_bridge.dart';

void main() {
  group('FutureInvestBridgeMessage', () {
    test('parses the JSON close contract used by H5 pages', () {
      final message = FutureInvestBridgeMessage.tryParse('''
        {
          "method": "close",
          "params": {"methodId": "cb_close_1", "count": 2}
        }
      ''');

      expect(message, isNotNull);
      expect(message!.requestsBack, isTrue);
      expect(message.methodId, 'cb_close_1');
      expect(message.historySteps, 2);
    });

    test('parses the WKWebView native map description', () {
      final message = FutureInvestBridgeMessage.tryParse(
        '{method: close, params: {methodId: cb_close_2, count: 3}}',
      );

      expect(message, isNotNull);
      expect(message!.requestsBack, isTrue);
      expect(message.methodId, 'cb_close_2');
      expect(message.historySteps, 3);
    });

    test('accepts common back aliases and clamps unsafe counts', () {
      final back = FutureInvestBridgeMessage.tryParse(
        '{"method":"back","params":{"count":0}}',
      );
      final pop = FutureInvestBridgeMessage.tryParse(
        '{"method":"pop","params":{"count":99}}',
      );

      expect(back?.requestsBack, isTrue);
      expect(back?.historySteps, 1);
      expect(pop?.requestsBack, isTrue);
      expect(pop?.historySteps, 20);
    });

    test('keeps unsupported bridge calls distinguishable', () {
      final message = FutureInvestBridgeMessage.tryParse(
        '{"method":"saveImage","params":{"methodId":"cb_save_1"}}',
      );

      expect(message, isNotNull);
      expect(message!.requestsBack, isFalse);
      expect(message.methodId, 'cb_save_1');
    });

    test('rejects malformed or unrelated messages', () {
      expect(FutureInvestBridgeMessage.tryParse(''), isNull);
      expect(FutureInvestBridgeMessage.tryParse('hello'), isNull);
      expect(
        FutureInvestBridgeMessage.tryParse('{params: {count: 2}}'),
        isNull,
      );
    });
  });
}
