import 'package:trip_cost/core/money/decimal_value.dart';

enum ExpressionErrorCode {
  empty,
  tooLong,
  invalidToken,
  unexpectedToken,
  nestingTooDeep,
  tooComplex,
  divisionByZero,
}

final class ExpressionException implements Exception {
  const ExpressionException(this.code, this.position, this.message);

  final ExpressionErrorCode code;
  final int position;
  final String message;

  @override
  String toString() => 'ExpressionException($code at $position: $message)';
}

final class DecimalExpressionParser {
  const DecimalExpressionParser({
    this.maxLength = 128,
    this.maxNesting = 16,
    this.maxOperations = 128,
    this.divisionPrecision = 18,
  });

  final int maxLength;
  final int maxNesting;
  final int maxOperations;
  final int divisionPrecision;

  DecimalValue evaluate(String source) {
    if (source.trim().isEmpty) {
      throw const ExpressionException(
        ExpressionErrorCode.empty,
        0,
        'Expression is empty.',
      );
    }
    if (source.length > maxLength) {
      throw ExpressionException(
        ExpressionErrorCode.tooLong,
        maxLength,
        'Expression exceeds $maxLength characters.',
      );
    }

    final state = _ParserState(
      source,
      maxNesting: maxNesting,
      maxOperations: maxOperations,
      divisionPrecision: divisionPrecision,
    );
    final value = state.parseExpression(0);
    state.skipWhitespace();
    if (!state.isAtEnd) {
      throw ExpressionException(
        ExpressionErrorCode.unexpectedToken,
        state.position,
        'Unexpected token.',
      );
    }
    return value;
  }
}

final class _ParserState {
  _ParserState(
    this.source, {
    required this.maxNesting,
    required this.maxOperations,
    required this.divisionPrecision,
  });

  final String source;
  final int maxNesting;
  final int maxOperations;
  final int divisionPrecision;
  var position = 0;
  var _operationCount = 0;

  bool get isAtEnd => position >= source.length;

  DecimalValue parseExpression(int depth) {
    var value = parseTerm(depth);
    while (true) {
      skipWhitespace();
      if (_consume('+')) {
        _countOperation();
        value += parseTerm(depth);
      } else if (_consume('-')) {
        _countOperation();
        value -= parseTerm(depth);
      } else {
        return value;
      }
    }
  }

  DecimalValue parseTerm(int depth) {
    var value = parseUnary(depth);
    while (true) {
      skipWhitespace();
      if (_consume('*')) {
        _countOperation();
        value *= parseUnary(depth);
      } else if (_consume('/')) {
        _countOperation();
        final divisorPosition = position;
        final divisor = parseUnary(depth);
        if (divisor.isZero) {
          throw ExpressionException(
            ExpressionErrorCode.divisionByZero,
            divisorPosition,
            'Division by zero is not allowed.',
          );
        }
        value = value.divide(divisor, precision: divisionPrecision);
      } else {
        return value;
      }
    }
  }

  DecimalValue parseUnary(int depth) {
    skipWhitespace();
    if (_consume('-')) {
      _countOperation();
      return -parseUnary(depth);
    }
    if (_consume('+')) {
      _countOperation();
      return parseUnary(depth);
    }
    return parsePrimary(depth);
  }

  DecimalValue parsePrimary(int depth) {
    skipWhitespace();
    if (_consume('(')) {
      if (depth >= maxNesting) {
        throw ExpressionException(
          ExpressionErrorCode.nestingTooDeep,
          position - 1,
          'Expression nesting exceeds $maxNesting levels.',
        );
      }
      final value = parseExpression(depth + 1);
      skipWhitespace();
      if (!_consume(')')) {
        throw ExpressionException(
          ExpressionErrorCode.unexpectedToken,
          position,
          'Expected a closing parenthesis.',
        );
      }
      return value;
    }
    return _parseNumber();
  }

  DecimalValue _parseNumber() {
    skipWhitespace();
    final start = position;
    var hasDigit = false;
    while (!isAtEnd && _isDigit(source.codeUnitAt(position))) {
      hasDigit = true;
      position += 1;
    }
    if (!isAtEnd && source[position] == '.') {
      position += 1;
      while (!isAtEnd && _isDigit(source.codeUnitAt(position))) {
        hasDigit = true;
        position += 1;
      }
    }
    if (!hasDigit) {
      throw ExpressionException(
        ExpressionErrorCode.invalidToken,
        start,
        'Expected a decimal number.',
      );
    }

    var token = source.substring(start, position);
    if (token.startsWith('.')) {
      token = '0$token';
    }
    if (token.endsWith('.')) {
      token = '${token}0';
    }
    try {
      return DecimalValue.parse(token);
    } on FormatException {
      throw ExpressionException(
        ExpressionErrorCode.invalidToken,
        start,
        'Invalid decimal number.',
      );
    }
  }

  void skipWhitespace() {
    while (!isAtEnd) {
      final code = source.codeUnitAt(position);
      if (code != 0x20 && code != 0x09 && code != 0x0A && code != 0x0D) {
        return;
      }
      position += 1;
    }
  }

  bool _consume(String token) {
    if (!isAtEnd && source[position] == token) {
      position += 1;
      return true;
    }
    return false;
  }

  void _countOperation() {
    _operationCount += 1;
    if (_operationCount > maxOperations) {
      throw ExpressionException(
        ExpressionErrorCode.tooComplex,
        position,
        'Expression exceeds $maxOperations operations.',
      );
    }
  }

  bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;
}
