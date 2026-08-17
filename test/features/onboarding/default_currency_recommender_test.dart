import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/features/onboarding/application/default_currency_recommender.dart';

void main() {
  const recommender = DefaultCurrencyRecommender();

  test('prefers system region and falls back by language', () {
    expect(recommender.recommend(const Locale('en', 'JP')).code, 'JPY');
    expect(recommender.recommend(const Locale('zh')).code, 'CNY');
    expect(recommender.recommend(const Locale('en')).code, 'USD');
  });
}
