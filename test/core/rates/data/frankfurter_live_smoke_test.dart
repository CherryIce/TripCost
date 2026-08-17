import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';

void main() {
  final enabled = Platform.environment['RUN_FRANKFURTER_SMOKE'] == '1';

  test(
    'live v2 service returns currencies, batch rates, and historical pair',
    () async {
      final client = FrankfurterApiClient(timeout: const Duration(seconds: 15));

      final currencies = await client.getCurrencies();
      final latest = await client.getRates(
        baseCurrencyCode: 'USD',
        quoteCurrencyCodes: <String>['CNY', 'JPY'],
      );
      final historical = await client.getRate(
        baseCurrencyCode: 'USD',
        quoteCurrencyCode: 'CNY',
        date: DateTime.utc(2026, 8, 16),
      );

      expect(currencies.any((item) => item.code == 'USD'), isTrue);
      expect(latest.map((item) => item.quoteCurrencyCode).toSet(), <String>{
        'CNY',
        'JPY',
      });
      expect(historical.date.isAfter(DateTime.utc(2026, 8, 16)), isFalse);
    },
    skip: enabled ? false : 'Set RUN_FRANKFURTER_SMOKE=1 for network evidence.',
  );
}
