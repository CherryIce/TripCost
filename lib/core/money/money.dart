import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';

final class Money implements Comparable<Money> {
  const Money({required this.amount, required this.currency});

  factory Money.parse(String canonicalAmount, Currency currency) {
    return Money(
      amount: DecimalValue.parse(canonicalAmount),
      currency: currency,
    );
  }

  final DecimalValue amount;
  final Currency currency;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(amount: amount - other.amount, currency: currency);
  }

  Money multiply(DecimalValue multiplier) {
    return Money(amount: amount * multiplier, currency: currency);
  }

  Money divide(
    DecimalValue divisor, {
    int precision = 18,
    DecimalRounding rounding = DecimalRounding.halfEven,
  }) {
    return Money(
      amount: amount.divide(divisor, precision: precision, rounding: rounding),
      currency: currency,
    );
  }

  Money rounded({DecimalRounding rounding = DecimalRounding.halfEven}) {
    return Money(
      amount: amount.round(currency.minorUnits, rounding: rounding),
      currency: currency,
    );
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return amount.compareTo(other.amount);
  }

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchException(currency.code, other.currency.code);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        amount == other.amount &&
        currency == other.currency;
  }

  @override
  int get hashCode => Object.hash(amount, currency);
}

final class CurrencyMismatchException implements Exception {
  const CurrencyMismatchException(this.left, this.right);

  final String left;
  final String right;

  @override
  String toString() => 'CurrencyMismatchException($left, $right)';
}
