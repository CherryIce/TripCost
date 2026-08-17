import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/money/expression_parser.dart';

void main() {
  const parser = DecimalExpressionParser();

  test('evaluates the product specification example', () {
    expect(parser.evaluate('1200 * 3 + 500').toString(), '4100');
  });

  test('supports precedence, parentheses and unary minus', () {
    expect(parser.evaluate('-(2 + 3) * 4 / 2').toString(), '-10');
    expect(parser.evaluate('.5 + +.25').toString(), '0.75');
  });

  test('reports division by zero as a typed validation error', () {
    expect(
      () => parser.evaluate('1 / (2 - 2)'),
      throwsA(
        isA<ExpressionException>().having(
          (error) => error.code,
          'code',
          ExpressionErrorCode.divisionByZero,
        ),
      ),
    );
  });

  test('rejects arbitrary code and non-decimal numeric forms', () {
    for (final expression in <String>['pow(2, 3)', '1e10', '0xFF', '1;2']) {
      expect(
        () => parser.evaluate(expression),
        throwsA(isA<ExpressionException>()),
        reason: expression,
      );
    }
  });

  test('enforces length, nesting and operation limits', () {
    const constrained = DecimalExpressionParser(
      maxLength: 20,
      maxNesting: 2,
      maxOperations: 2,
    );

    expect(
      () => constrained.evaluate('123456789012345678901'),
      throwsA(
        isA<ExpressionException>().having(
          (error) => error.code,
          'code',
          ExpressionErrorCode.tooLong,
        ),
      ),
    );
    expect(
      () => constrained.evaluate('(((1)))'),
      throwsA(
        isA<ExpressionException>().having(
          (error) => error.code,
          'code',
          ExpressionErrorCode.nestingTooDeep,
        ),
      ),
    );
    expect(
      () => constrained.evaluate('1 + 2 + 3 + 4'),
      throwsA(
        isA<ExpressionException>().having(
          (error) => error.code,
          'code',
          ExpressionErrorCode.tooComplex,
        ),
      ),
    );
  });
}
