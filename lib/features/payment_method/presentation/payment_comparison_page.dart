import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class PaymentComparisonPage extends ConsumerWidget {
  const PaymentComparisonPage({required this.draft, super.key});

  final ConversionDraft? draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final methods = ref.watch(paymentMethodsControllerProvider);
    final configuredMethods = methods.asData?.value;
    final methodAction = configuredMethods == null
        ? null
        : configuredMethods.isEmpty
        ? localizations.commonAdd
        : localizations.commonManage;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.paymentComparisonTitle),
        trailing: methodAction == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.push(AppRoutes.paymentMethods),
                child: Text(methodAction),
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: draft == null
            ? Center(child: Text(localizations.paymentComparisonMissing))
            : methods.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (error, stack) => Center(
                  child: CupertinoButton(
                    onPressed: () =>
                        ref.invalidate(paymentMethodsControllerProvider),
                    child: Text(localizations.converterRefresh),
                  ),
                ),
                data: (paymentMethods) {
                  final billingCurrency =
                      draft!.rateResolution.snapshot!.quoteCurrency.code;
                  final items = const PaymentCostEngine().compare(
                    transactionAmount: draft!.transactionAmount,
                    rateSnapshot: draft!.rateResolution.snapshot!,
                    paymentRules: paymentMethods.map(
                      (method) => method.freezeRules(),
                    ),
                  );
                  return ListView(
                    padding: AppInsets.secondaryPageScrollPadding(context),
                    children: <Widget>[
                      if (items.length < 2)
                        _Notice(
                          text: paymentMethods.isEmpty
                              ? localizations.paymentComparisonNeedTwo
                              : items.isEmpty
                              ? localizations.paymentComparisonNoApplicable(
                                  billingCurrency,
                                )
                              : localizations.paymentComparisonOnlyOne(
                                  billingCurrency,
                                ),
                          action: paymentMethods.isEmpty
                              ? localizations.commonAdd
                              : localizations.commonManage,
                          onPressed: () =>
                              context.push(AppRoutes.paymentMethods),
                        ),
                      Text(
                        localizations.paymentEstimateDisclaimer,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.large),
                          child: Text(
                            paymentMethods.isEmpty
                                ? localizations.paymentMethodsEmpty
                                : localizations
                                      .paymentComparisonConfiguredButUnavailable,
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        for (var index = 0; index < items.length; index++) ...[
                          _ComparisonCard(
                            item: items[index],
                            recommended: index == 0,
                            onSave: () => context.push(
                              AppRoutes.expenseCreate,
                              extra: ExpenseEditorArguments(
                                seed: ExpenseDraftSeed(
                                  transactionAmount: draft!.transactionAmount,
                                  rateSnapshot: draft!.rateResolution.snapshot!,
                                  breakdown: items[index].breakdown,
                                  receiptLocalPath: draft!.receiptLocalPath,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                        ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.item,
    required this.recommended,
    required this.onSave,
  });

  final PaymentComparisonItem item;
  final bool recommended;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final breakdown = item.breakdown;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = const MoneyFormatter();
    String money(Money value) =>
        formatter.format(value, locale: locale, includeCode: true);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
        border: recommended
            ? Border.all(color: CupertinoColors.activeGreen, width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    breakdown.paymentRule.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (recommended)
                  Text(
                    localizations.paymentRecommended,
                    style: const TextStyle(
                      color: CupertinoColors.activeGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    localizations.paymentDifference(
                      money(item.differenceFromLowest),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _BreakdownRow(
              label: localizations.paymentBaseAmount,
              value: money(breakdown.baseAmount),
            ),
            _BreakdownRow(
              label: localizations.paymentRateMarkupAmount,
              value: money(breakdown.rateMarkupAmount),
            ),
            _BreakdownRow(
              label: localizations.paymentForeignFeeAmount,
              value: money(breakdown.foreignFee),
            ),
            _BreakdownRow(
              label: localizations.paymentCrossBorderFeeAmount,
              value: money(breakdown.crossBorderFee),
            ),
            _BreakdownRow(
              label: localizations.paymentVariableFee,
              value: money(breakdown.variableFeeAfterLimits),
            ),
            _BreakdownRow(
              label: localizations.paymentFixedFeeAmount,
              value: money(breakdown.fixedFee),
            ),
            _BreakdownRow(
              label: localizations.paymentCashbackAmount,
              value: '-${money(breakdown.cashback)}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
              child: Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            _BreakdownRow(
              label:
                  '${localizations.commonEstimated} · '
                  '${localizations.paymentEstimatedTotal}',
              value: money(breakdown.estimatedCost),
              emphasized: true,
            ),
            if (breakdown.usesActualCashRate)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.small),
                child: Text(
                  localizations.paymentCashRateUsed,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: AppSpacing.small),
            CupertinoButton.filled(
              onPressed: onSave,
              child: Text(localizations.expenseSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
      fontSize: emphasized ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(text)),
          CupertinoButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}
