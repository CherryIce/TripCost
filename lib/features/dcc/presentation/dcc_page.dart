import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/dcc/domain/dcc_calculator.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class DccPage extends ConsumerStatefulWidget {
  const DccPage({required this.draft, super.key});

  final ConversionDraft? draft;

  @override
  ConsumerState<DccPage> createState() => _DccPageState();
}

class _DccPageState extends ConsumerState<DccPage> {
  late final TextEditingController _localAmount;
  final _merchantQuote = TextEditingController();
  String? _paymentMethodId;

  @override
  void initState() {
    super.initState();
    _localAmount = TextEditingController(
      text: widget.draft?.transactionAmount.amount.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _localAmount.dispose();
    _merchantQuote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final methods = ref.watch(paymentMethodsControllerProvider);
    final quoteCurrency = widget.draft?.rateResolution.snapshot?.quoteCurrency;
    final methodList = (methods.value ?? const <PaymentMethodModel>[])
        .where(
          (method) =>
              method.billingCurrency == quoteCurrency &&
              method.supportedTransactionTypes.contains(
                TransactionType.purchase,
              ),
        )
        .toList(growable: false);
    final selectedMethod = methodList
        .where((method) => method.metadata.recordId == _paymentMethodId)
        .firstOrNull;
    final calculation = _calculate(selectedMethod);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.dccTitle),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _DccField(
              label:
                  '${localizations.dccLocalAmount} '
                  '(${widget.draft?.transactionAmount.currency.code ?? '—'})',
              controller: _localAmount,
              onChanged: (_) => setState(() {}),
            ),
            _DccField(
              label:
                  '${localizations.dccMerchantQuote} '
                  '(${widget.draft?.rateResolution.snapshot?.quoteCurrency.code ?? '—'})',
              controller: _merchantQuote,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.medium),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: methodList.isEmpty
                  ? null
                  : () => _choosePaymentMethod(methodList),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(localizations.dccOptionalPayment)),
                  Text(
                    selectedMethod?.name ?? localizations.dccNoPayment,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_forward, size: 16),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            if (calculation.error != null)
              Text(
                _errorMessage(localizations, calculation.error!),
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
            if (calculation.assessment != null)
              _DccResultCard(assessment: calculation.assessment!),
          ],
        ),
      ),
    );
  }

  ({DccAssessment? assessment, DccErrorCode? error}) _calculate(
    PaymentMethodModel? method,
  ) {
    final draft = widget.draft;
    if (draft == null || _merchantQuote.text.trim().isEmpty) {
      return (assessment: null, error: null);
    }
    try {
      DecimalValue localValue;
      try {
        localValue = DecimalValue.parse(_localAmount.text.trim());
      } on FormatException {
        return (assessment: null, error: DccErrorCode.nonPositiveLocalAmount);
      }
      DecimalValue quoteValue;
      try {
        quoteValue = DecimalValue.parse(_merchantQuote.text.trim());
      } on FormatException {
        return (assessment: null, error: DccErrorCode.nonPositiveMerchantQuote);
      }
      final snapshot = draft.rateResolution.snapshot;
      return (
        assessment: const DccCalculator().calculate(
          localAmount: Money(
            amount: localValue,
            currency: draft.transactionAmount.currency,
          ),
          merchantHomeQuote: Money(
            amount: quoteValue,
            currency: snapshot!.quoteCurrency,
          ),
          referenceRate: snapshot,
          paymentRule: method?.freezeRules(),
        ),
        error: null,
      );
    } on DccCalculationException catch (error) {
      return (assessment: null, error: error.code);
    }
  }

  Future<void> _choosePaymentMethod(List<PaymentMethodModel> methods) async {
    final localizations = AppLocalizations.of(context);
    final selected = await showCupertinoModalPopup<String?>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(localizations.dccNoPayment),
          ),
          for (final method in methods)
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.of(context).pop(method.metadata.recordId),
              child: Text(method.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.commonCancel),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _paymentMethodId = selected.isEmpty ? null : selected);
    }
  }
}

class _DccField extends StatelessWidget {
  const _DccField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(14),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DccResultCard extends StatelessWidget {
  const _DccResultCard({required this.assessment});

  final DccAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = const MoneyFormatter();
    String money(Money value) =>
        formatter.format(value, locale: locale, includeCode: true);
    final percentage = assessment.extraPercent * DecimalValue.parse('100');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          children: <Widget>[
            _ResultRow(
              label: localizations.dccImpliedRate,
              value: assessment.merchantImpliedRate.toFixed(8),
            ),
            _ResultRow(
              label: localizations.dccReferenceRate,
              value: assessment.referenceRate.toFixed(8),
            ),
            _ResultRow(
              label: localizations.dccReferenceAmount,
              value: money(assessment.referenceAmount),
            ),
            _ResultRow(
              label: localizations.dccExtraAmount,
              value: money(assessment.extraAmount),
              emphasized: true,
            ),
            _ResultRow(
              label: localizations.dccExtraPercent,
              value: '${percentage.toFixed(2)}%',
              emphasized: true,
            ),
            if (assessment.localCurrencyPaymentEstimate != null)
              _ResultRow(
                label: localizations.dccLocalPaymentEstimate,
                value: money(
                  assessment.localCurrencyPaymentEstimate!.estimatedCost,
                ),
              ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              percentage.isNegative || percentage.isZero
                  ? localizations.dccGuidanceLower
                  : localizations.dccGuidanceHigher(percentage.toFixed(2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

String _errorMessage(AppLocalizations l10n, DccErrorCode code) =>
    switch (code) {
      DccErrorCode.nonPositiveLocalAmount => l10n.dccInvalidLocal,
      DccErrorCode.nonPositiveMerchantQuote => l10n.dccInvalidQuote,
      DccErrorCode.sameCurrency => l10n.dccSameCurrency,
      DccErrorCode.missingRate ||
      DccErrorCode.currencyMismatch => l10n.dccMissingRate,
    };
