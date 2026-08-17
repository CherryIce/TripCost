import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'maps currencies from the v2 array without a hardcoded allowlist',
    () async {
      final transport = FixtureTransport(<String, String>{
        '/v2/currencies': await _fixture('currencies.json'),
      });
      final client = FrankfurterApiClient(
        transport: transport,
        baseUri: Uri.parse('https://example.test/v2/'),
      );

      final currencies = await client.getCurrencies();

      expect(currencies.map((item) => item.code), <String>['EUR', 'USD']);
      expect(currencies.last.toDomain().numericCode, '840');
      expect(transport.requests.single.query, isEmpty);
    },
  );

  test(
    'uses v2 batch query and preserves the provider observation date',
    () async {
      final transport = FixtureTransport(<String, String>{
        '/v2/rates': await _fixture('rates.json'),
      });
      final client = FrankfurterApiClient(
        transport: transport,
        baseUri: Uri.parse('https://example.test/v2/'),
      );

      final rates = await client.getRates(
        baseCurrencyCode: 'eur',
        quoteCurrencyCodes: <String>['JPY', 'CNY', 'JPY'],
      );

      expect(transport.requests.single.queryParameters, <String, String>{
        'base': 'EUR',
        'quotes': 'CNY,JPY',
      });
      expect(rates.first.date, DateTime.utc(2026, 8, 14));
      expect(rates.first.rate.toString(), '8.3214');
    },
  );

  test('uses the single-pair historical route and date query', () async {
    final transport = FixtureTransport(<String, String>{
      '/v2/rate/USD/CNY': await _fixture('rate_historical.json'),
    });
    final client = FrankfurterApiClient(
      transport: transport,
      baseUri: Uri.parse('https://example.test/v2/'),
    );

    final rate = await client.getRate(
      baseCurrencyCode: 'USD',
      quoteCurrencyCode: 'CNY',
      date: DateTime.utc(2026, 8, 16),
    );

    expect(transport.requests.single.path, '/v2/rate/USD/CNY');
    expect(transport.requests.single.queryParameters['date'], '2026-08-16');
    expect(rate.date, DateTime.utc(2026, 8, 14));
  });

  test('deduplicates identical in-flight requests', () async {
    final completer = Completer<FrankfurterHttpResponse>();
    final transport = DeferredTransport(completer.future);
    final client = FrankfurterApiClient(
      transport: transport,
      baseUri: Uri.parse('https://example.test/v2/'),
    );

    final first = client.getRate(
      baseCurrencyCode: 'USD',
      quoteCurrencyCode: 'CNY',
    );
    final second = client.getRate(
      baseCurrencyCode: 'USD',
      quoteCurrencyCode: 'CNY',
    );
    completer.complete(
      FrankfurterHttpResponse(
        statusCode: 200,
        body: await _fixture('rate_historical.json'),
      ),
    );

    await Future.wait(<Future<Object>>[first, second]);
    expect(transport.callCount, 1);
  });

  test(
    'maps HTTP errors without logging query values or response bodies',
    () async {
      final logs = <String>[];
      final transport = StaticTransport(
        const FrankfurterHttpResponse(
          statusCode: HttpStatus.serviceUnavailable,
          body: '{"message":"secret diagnostic"}',
        ),
      );
      final client = FrankfurterApiClient(
        transport: transport,
        baseUri: Uri.parse('https://example.test/v2/'),
        log: logs.add,
      );

      await expectLater(
        client.getRates(
          baseCurrencyCode: 'USD',
          quoteCurrencyCodes: <String>['CNY'],
        ),
        throwsA(
          isA<FrankfurterApiException>().having(
            (error) => error.code,
            'code',
            FrankfurterErrorCode.unavailable,
          ),
        ),
      );
      expect(logs.single, isNot(contains('quotes=')));
      expect(logs.single, isNot(contains('secret diagnostic')));
    },
  );
}

Future<String> _fixture(String name) {
  return File('test/fixtures/frankfurter/v2/$name').readAsString();
}

final class FixtureTransport implements FrankfurterHttpTransport {
  FixtureTransport(this.fixtures);

  final Map<String, String> fixtures;
  final List<Uri> requests = <Uri>[];

  @override
  Future<FrankfurterHttpResponse> get(
    Uri uri, {
    required Duration timeout,
  }) async {
    requests.add(uri);
    final body = fixtures[uri.path];
    if (body == null) {
      return const FrankfurterHttpResponse(statusCode: 404, body: '{}');
    }
    return FrankfurterHttpResponse(statusCode: 200, body: body);
  }
}

final class DeferredTransport implements FrankfurterHttpTransport {
  DeferredTransport(this.response);

  final Future<FrankfurterHttpResponse> response;
  int callCount = 0;

  @override
  Future<FrankfurterHttpResponse> get(Uri uri, {required Duration timeout}) {
    callCount += 1;
    return response;
  }
}

final class StaticTransport implements FrankfurterHttpTransport {
  StaticTransport(this.response);

  final FrankfurterHttpResponse response;

  @override
  Future<FrankfurterHttpResponse> get(
    Uri uri, {
    required Duration timeout,
  }) async => response;
}
