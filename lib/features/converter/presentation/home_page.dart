import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/currencies/application/currency_directory_controller.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/currency_picker_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _expressionController = TextEditingController(text: '12800');

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final converter = ref.watch(converterControllerProvider);
    ref.watch(currencyDirectoryProvider);
    final recentExpenses =
        (ref.watch(expensesControllerProvider).value ?? const [])
            .take(3)
            .toList();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.homeTitle),
      ),
      child: SafeArea(
        child: converter.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: CupertinoButton(
              onPressed: () => ref.invalidate(converterControllerProvider),
              child: Text(localizations.converterRefresh),
            ),
          ),
          data: (state) => ListView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: <Widget>[
              _ConversionCard(
                expressionController: _expressionController,
                state: state,
                onExpressionChanged: ref
                    .read(converterControllerProvider.notifier)
                    .updateExpression,
                onSelectTransactionCurrency: () => _selectCurrency(
                  selected: state.transactionCurrency,
                  excluded: state.homeCurrency,
                  favoriteCurrencies: state.favoriteCurrencies,
                  title: localizations.currencyLocal,
                  onSelected: ref
                      .read(converterControllerProvider.notifier)
                      .changeTransactionCurrency,
                ),
                onSelectHomeCurrency: () => _selectCurrency(
                  selected: state.homeCurrency,
                  excluded: state.transactionCurrency,
                  favoriteCurrencies: state.favoriteCurrencies,
                  title: localizations.currencyHome,
                  onSelected: ref
                      .read(converterControllerProvider.notifier)
                      .changeHomeCurrency,
                ),
                onSwap: ref
                    .read(converterControllerProvider.notifier)
                    .swapCurrencies,
                onToggleFavorite: () => ref
                    .read(converterControllerProvider.notifier)
                    .toggleFavorite(state.transactionCurrency),
              ),
              const SizedBox(height: AppSpacing.medium),
              _RateStatusCard(
                state: state,
                onManualRate: _showManualRateDialog,
                onRefresh: ref
                    .read(converterControllerProvider.notifier)
                    .refresh,
              ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: state.draft == null
                          ? null
                          : () => context.push(
                              AppRoutes.paymentComparison,
                              extra: state.draft,
                            ),
                      child: Text(localizations.converterCompare),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.secondarySystemFill.resolveFrom(
                        context,
                      ),
                      onPressed: state.draft == null
                          ? null
                          : () =>
                                context.push(AppRoutes.dcc, extra: state.draft),
                      child: Text(localizations.converterDcc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                localizations.converterRecentTitle,
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              const SizedBox(height: AppSpacing.small),
              if (recentExpenses.isEmpty)
                _Surface(
                  child: Text(
                    localizations.converterRecentEmpty,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                )
              else
                for (final expense in recentExpenses)
                  CupertinoListTile(
                    padding: EdgeInsets.zero,
                    title: Text(expense.title),
                    subtitle: Text(expense.category),
                    additionalInfo: Text(
                      const MoneyFormatter().format(
                        expense.actualFinalAmount ??
                            expense.estimatedFinalAmount,
                        locale: Localizations.localeOf(context).toLanguageTag(),
                        includeCode: true,
                      ),
                    ),
                    trailing: const Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                    ),
                    onTap: () => context.push(
                      AppRoutes.expenseDetail(expense.metadata.recordId),
                      extra: expense,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCurrency({
    required Currency selected,
    required Currency excluded,
    required List<Currency> favoriteCurrencies,
    required String title,
    required Future<void> Function(Currency) onSelected,
  }) async {
    final localizations = AppLocalizations.of(context);
    final currency = await showCupertinoModalPopup<Currency>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, modalRef, child) {
          final directory = modalRef.watch(currencyDirectoryProvider);
          final metadata = modalRef
              .read(currencyDirectoryRepositoryProvider)
              .metadata;
          return CurrencyPickerSheet(
            currencies: directory.currencies,
            selected: selected,
            excluded: excluded,
            favoriteCurrencies: favoriteCurrencies,
            title: title,
            cancelLabel: localizations.commonCancel,
            displayName: (item) => metadata.localizedName(
              item,
              Localizations.localeOf(context).languageCode,
            ),
            isRefreshing: directory.isRefreshing,
          );
        },
      ),
    );
    if (currency != null) {
      await onSelected(currency);
    }
  }

  Future<void> _showManualRateDialog() async {
    final controller = TextEditingController();
    final localizations = AppLocalizations.of(context);
    final value = await showCupertinoDialog<DecimalValue>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(localizations.converterManualRate),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.medium),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: localizations.converterManualRateHint,
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.commonCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              try {
                final rate = DecimalValue.parse(controller.text.trim());
                if (rate.compareTo(DecimalValue.zero) <= 0) {
                  return;
                }
                Navigator.of(context).pop(rate);
              } on FormatException {
                return;
              }
            },
            child: Text(localizations.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await ref.read(converterControllerProvider.notifier).setManualRate(value);
    }
  }
}

class _ConversionCard extends StatelessWidget {
  const _ConversionCard({
    required this.expressionController,
    required this.state,
    required this.onExpressionChanged,
    required this.onSelectTransactionCurrency,
    required this.onSelectHomeCurrency,
    required this.onSwap,
    required this.onToggleFavorite,
  });

  final TextEditingController expressionController;
  final ConverterState state;
  final ValueChanged<String> onExpressionChanged;
  final VoidCallback onSelectTransactionCurrency;
  final VoidCallback onSelectHomeCurrency;
  final VoidCallback onSwap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = const MoneyFormatter();
    final expressionMessage = state.expressionError != null
        ? localizations.converterInvalidExpression
        : state.evaluatedAmount != null &&
              state.evaluatedAmount!.compareTo(DecimalValue.zero) <= 0
        ? localizations.converterPositiveAmount
        : null;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _CurrencyButton(
                  label: localizations.currencyLocal,
                  currency: state.transactionCurrency,
                  onPressed: onSelectTransactionCurrency,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(AppSpacing.small),
                onPressed: onSwap,
                child: const Icon(CupertinoIcons.arrow_right_arrow_left),
              ),
              Expanded(
                child: _CurrencyButton(
                  label: localizations.currencyHome,
                  currency: state.homeCurrency,
                  onPressed: onSelectHomeCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  localizations.converterInputLabel,
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onToggleFavorite,
                child: Icon(
                  state.isFavorite(state.transactionCurrency)
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.star,
                  semanticLabel: state.isFavorite(state.transactionCurrency)
                      ? localizations.currencyUnfavorite
                      : localizations.currencyFavorite,
                ),
              ),
            ],
          ),
          CupertinoTextField(
            key: const Key('converter-expression'),
            controller: expressionController,
            placeholder: localizations.converterInputHint,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onChanged: onExpressionChanged,
            padding: const EdgeInsets.all(14),
          ),
          if (expressionMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.small),
            Text(
              expressionMessage,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          Text(
            localizations.converterResultLabel,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.convertedMoney == null
                ? '— ${state.homeCurrency.code}'
                : formatter.format(
                    state.convertedMoney!,
                    locale: locale,
                    includeCode: true,
                  ),
            key: const Key('converter-result'),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({
    required this.label,
    required this.currency,
    required this.onPressed,
  });

  final String label;
  final Currency currency;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      onPressed: onPressed,
      child: Column(
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            currency.code,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RateStatusCard extends StatelessWidget {
  const _RateStatusCard({
    required this.state,
    required this.onManualRate,
    required this.onRefresh,
  });

  final ConverterState state;
  final VoidCallback onManualRate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final resolution = state.rateResolution;
    final snapshot = resolution?.snapshot;
    final time = snapshot == null
        ? ''
        : DateFormat.yMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).add_Hm().format(snapshot.fetchedAt.toLocal());
    final message = state.isResolvingRate
        ? localizations.converterRateLoading
        : switch (resolution?.availability) {
            RateAvailability.liveMarket => localizations.converterRateLive(
              snapshot!.sourceName,
              time,
            ),
            RateAvailability.cachedMarket => localizations.converterRateCached(
              time,
              snapshot!.sourceName,
            ),
            RateAvailability.staleMarket => localizations.converterRateStale(
              time,
            ),
            RateAvailability.manual => localizations.converterRateManual,
            RateAvailability.cardNetwork => localizations.converterRateCard(
              snapshot!.sourceName,
              time,
            ),
            RateAvailability.identity => localizations.converterRateIdentity,
            _ => localizations.converterRateUnavailable,
          };
    return _Surface(
      child: Row(
        children: <Widget>[
          Icon(
            snapshot == null
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.clock,
            color: snapshot == null
                ? CupertinoColors.systemOrange
                : AppTheme.accent.resolveFrom(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(message)),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            onPressed: onRefresh,
            child: Icon(
              CupertinoIcons.refresh,
              semanticLabel: localizations.converterRefresh,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            onPressed: onManualRate,
            child: Icon(
              CupertinoIcons.pencil,
              semanticLabel: localizations.converterManualRate,
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: child,
      ),
    );
  }
}
