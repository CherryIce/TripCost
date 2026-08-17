import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';

enum PaymentTemplateId {
  noForeignFeeCard,
  onePercentCard,
  onePointFivePercentCard,
  twoPercentCard,
  unionPayCnyCard,
  cashExchange,
  custom,
}

final class PaymentMethodTemplate {
  const PaymentMethodTemplate({
    required this.id,
    required this.type,
    required this.network,
    required this.foreignFeePercent,
    required this.crossBorderFeePercent,
    required this.rateMarkupPercent,
  });

  final PaymentTemplateId id;
  final PaymentMethodType type;
  final PaymentNetwork network;
  final DecimalValue foreignFeePercent;
  final DecimalValue crossBorderFeePercent;
  final DecimalValue rateMarkupPercent;
}

abstract final class PaymentMethodTemplates {
  static final List<PaymentMethodTemplate> values =
      List<PaymentMethodTemplate>.unmodifiable(<PaymentMethodTemplate>[
        PaymentMethodTemplate(
          id: PaymentTemplateId.noForeignFeeCard,
          type: PaymentMethodType.creditCard,
          network: PaymentNetwork.unknown,
          foreignFeePercent: DecimalValue.zero,
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
        PaymentMethodTemplate(
          id: PaymentTemplateId.onePercentCard,
          type: PaymentMethodType.creditCard,
          network: PaymentNetwork.unknown,
          foreignFeePercent: DecimalValue.parse('1'),
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
        PaymentMethodTemplate(
          id: PaymentTemplateId.onePointFivePercentCard,
          type: PaymentMethodType.creditCard,
          network: PaymentNetwork.unknown,
          foreignFeePercent: DecimalValue.parse('1.5'),
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
        PaymentMethodTemplate(
          id: PaymentTemplateId.twoPercentCard,
          type: PaymentMethodType.creditCard,
          network: PaymentNetwork.unknown,
          foreignFeePercent: DecimalValue.parse('2'),
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
        PaymentMethodTemplate(
          id: PaymentTemplateId.unionPayCnyCard,
          type: PaymentMethodType.creditCard,
          network: PaymentNetwork.unionpay,
          foreignFeePercent: DecimalValue.zero,
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
        PaymentMethodTemplate(
          id: PaymentTemplateId.cashExchange,
          type: PaymentMethodType.cash,
          network: PaymentNetwork.unknown,
          foreignFeePercent: DecimalValue.zero,
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
        PaymentMethodTemplate(
          id: PaymentTemplateId.custom,
          type: PaymentMethodType.custom,
          network: PaymentNetwork.unknown,
          foreignFeePercent: DecimalValue.zero,
          crossBorderFeePercent: DecimalValue.zero,
          rateMarkupPercent: DecimalValue.zero,
        ),
      ]);
}
