enum DecimalRounding {
  halfEven,
  halfUp,
  towardZero,
  awayFromZero,
  floor,
  ceiling,
}

/// An exact base-10 value represented as `coefficient * 10^-scale`.
///
/// This type intentionally rejects exponent notation and never converts through
/// [double], so values persisted by the accounting domain remain exact.
final class DecimalValue implements Comparable<DecimalValue> {
  factory DecimalValue(BigInt coefficient, int scale) {
    if (scale < 0 || scale > maxScale) {
      throw RangeError.range(scale, 0, maxScale, 'scale');
    }
    if (coefficient == BigInt.zero) {
      return DecimalValue._(BigInt.zero, 0);
    }

    var normalizedCoefficient = coefficient;
    var normalizedScale = scale;
    while (normalizedScale > 0 &&
        normalizedCoefficient.remainder(BigInt.from(10)) == BigInt.zero) {
      normalizedCoefficient ~/= BigInt.from(10);
      normalizedScale -= 1;
    }
    return DecimalValue._(normalizedCoefficient, normalizedScale);
  }

  DecimalValue._(this.coefficient, this.scale);

  factory DecimalValue.parse(String source) {
    if (!_canonicalPattern.hasMatch(source)) {
      throw const FormatException('Expected a canonical decimal value.');
    }

    var text = source;
    var negative = false;
    if (text.startsWith('-') || text.startsWith('+')) {
      negative = text.startsWith('-');
      text = text.substring(1);
    }
    final parts = text.split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > maxScale) {
      throw const FormatException('Decimal scale exceeds the supported limit.');
    }
    final digits = '${parts[0]}$fraction';
    var coefficient = BigInt.parse(digits);
    if (negative) {
      coefficient = -coefficient;
    }
    return DecimalValue(coefficient, fraction.length);
  }

  static final DecimalValue zero = DecimalValue(BigInt.zero, 0);
  static const int maxScale = 30;
  static final RegExp _canonicalPattern = RegExp(r'^[+-]?\d+(?:\.\d+)?$');

  final BigInt coefficient;
  final int scale;

  bool get isNegative => coefficient.isNegative;
  bool get isZero => coefficient == BigInt.zero;

  DecimalValue abs() => isNegative ? -this : this;

  DecimalValue operator -() => DecimalValue(-coefficient, scale);

  DecimalValue operator +(DecimalValue other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    return DecimalValue(
      coefficient * _pow10(commonScale - scale) +
          other.coefficient * _pow10(commonScale - other.scale),
      commonScale,
    );
  }

  DecimalValue operator -(DecimalValue other) => this + (-other);

  DecimalValue operator *(DecimalValue other) {
    final resultScale = scale + other.scale;
    final resultCoefficient = coefficient * other.coefficient;
    if (resultScale > maxScale) {
      return DecimalValue(
        _divideAndRound(
          resultCoefficient,
          _pow10(resultScale - maxScale),
          DecimalRounding.halfEven,
        ),
        maxScale,
      );
    }
    return DecimalValue(resultCoefficient, resultScale);
  }

  DecimalValue divide(
    DecimalValue divisor, {
    int precision = 18,
    DecimalRounding rounding = DecimalRounding.halfEven,
  }) {
    if (divisor.isZero) {
      throw const DecimalDivisionByZeroException();
    }
    if (precision < 0 || precision > maxScale) {
      throw RangeError.range(precision, 0, maxScale, 'precision');
    }

    final exponent = precision + divisor.scale - scale;
    final numerator = exponent >= 0
        ? coefficient * _pow10(exponent)
        : coefficient;
    final denominator = exponent >= 0
        ? divisor.coefficient
        : divisor.coefficient * _pow10(-exponent);
    final quotient = _divideAndRound(numerator, denominator, rounding);
    return DecimalValue(quotient, precision);
  }

  DecimalValue round(
    int targetScale, {
    DecimalRounding rounding = DecimalRounding.halfEven,
  }) {
    if (targetScale < 0 || targetScale > maxScale) {
      throw RangeError.range(targetScale, 0, maxScale, 'targetScale');
    }
    if (targetScale >= scale) {
      return this;
    }
    final divisor = _pow10(scale - targetScale);
    return DecimalValue(
      _divideAndRound(coefficient, divisor, rounding),
      targetScale,
    );
  }

  String toFixed(
    int fractionDigits, {
    DecimalRounding rounding = DecimalRounding.halfEven,
  }) {
    if (fractionDigits < 0 || fractionDigits > maxScale) {
      throw RangeError.range(fractionDigits, 0, maxScale, 'fractionDigits');
    }
    final rounded = round(fractionDigits, rounding: rounding);
    final negative = rounded.isNegative;
    final displayCoefficient =
        rounded.coefficient.abs() * _pow10(fractionDigits - rounded.scale);
    var digits = displayCoefficient.toString();
    if (fractionDigits == 0) {
      return '${negative ? '-' : ''}$digits';
    }
    digits = digits.padLeft(fractionDigits + 1, '0');
    final split = digits.length - fractionDigits;
    return '${negative ? '-' : ''}${digits.substring(0, split)}.'
        '${digits.substring(split)}';
  }

  @override
  int compareTo(DecimalValue other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    return (coefficient * _pow10(commonScale - scale)).compareTo(
      other.coefficient * _pow10(commonScale - other.scale),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DecimalValue &&
        coefficient == other.coefficient &&
        scale == other.scale;
  }

  @override
  int get hashCode => Object.hash(coefficient, scale);

  @override
  String toString() {
    final negative = isNegative;
    var digits = coefficient.abs().toString();
    if (scale == 0) {
      return '${negative ? '-' : ''}$digits';
    }
    digits = digits.padLeft(scale + 1, '0');
    final split = digits.length - scale;
    return '${negative ? '-' : ''}${digits.substring(0, split)}.'
        '${digits.substring(split)}';
  }

  static BigInt _divideAndRound(
    BigInt numerator,
    BigInt denominator,
    DecimalRounding rounding,
  ) {
    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator).abs();
    if (remainder == BigInt.zero) {
      return quotient;
    }

    final sign = numerator.isNegative == denominator.isNegative
        ? BigInt.one
        : -BigInt.one;
    final denominatorAbs = denominator.abs();
    final increment = switch (rounding) {
      DecimalRounding.towardZero => false,
      DecimalRounding.awayFromZero => true,
      DecimalRounding.floor => sign.isNegative,
      DecimalRounding.ceiling => !sign.isNegative,
      DecimalRounding.halfUp => remainder * BigInt.two >= denominatorAbs,
      DecimalRounding.halfEven =>
        remainder * BigInt.two > denominatorAbs ||
            (remainder * BigInt.two == denominatorAbs && quotient.isOdd),
    };
    return increment ? quotient + sign : quotient;
  }

  static BigInt _pow10(int exponent) => BigInt.from(10).pow(exponent);
}

final class DecimalDivisionByZeroException implements Exception {
  const DecimalDivisionByZeroException();

  @override
  String toString() => 'DecimalDivisionByZeroException';
}
