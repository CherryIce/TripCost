import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/currencies/application/currency_directory_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/features/onboarding/presentation/quick_setup_page.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _expressionController = TextEditingController(text: '12800');
  Timer? _rateRefreshCooldownTimer;
  var _rateRefreshCoolingDown = false;
  var _setupPromptDismissed = false;

  @override
  void dispose() {
    _rateRefreshCooldownTimer?.cancel();
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
    final trips = ref.watch(tripsControllerProvider);
    final paymentMethods = ref.watch(paymentMethodsControllerProvider);
    final setupDataReady = trips.hasValue && paymentMethods.hasValue;
    final setupCompletedCount =
        1 +
        ((trips.value?.isNotEmpty ?? false) ? 1 : 0) +
        ((paymentMethods.value?.isNotEmpty ?? false) ? 1 : 0);
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
                  title: localizations.currencyLocal,
                  onSelected: ref
                      .read(converterControllerProvider.notifier)
                      .changeTransactionCurrency,
                ),
                onSelectHomeCurrency: () => _selectCurrency(
                  selected: state.homeCurrency,
                  title: localizations.currencyHome,
                  onSelected: ref
                      .read(converterControllerProvider.notifier)
                      .changeHomeCurrency,
                ),
                onSwap: ref
                    .read(converterControllerProvider.notifier)
                    .swapCurrencies,
                onAdjustRate: () => _showRateSheet(state),
                onRefreshRate: _refreshMarketRate,
                isRateRefreshCoolingDown: _rateRefreshCoolingDown,
              ),
              const SizedBox(height: AppSpacing.medium),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: CupertinoButton.filled(
                        key: const Key('compare-payment-button'),
                        onPressed: state.draft == null
                            ? null
                            : () => context.push(
                                AppRoutes.paymentComparison,
                                extra: state.draft,
                              ),
                        child: Text(
                          localizations.converterCompare,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: CupertinoButton(
                        key: const Key('dcc-button'),
                        color: CupertinoColors.secondarySystemFill.resolveFrom(
                          context,
                        ),
                        onPressed: state.draft == null
                            ? null
                            : () => context.push(
                                AppRoutes.dcc,
                                extra: state.draft,
                              ),
                        child: Text(
                          localizations.converterDcc,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (setupDataReady &&
                  setupCompletedCount < 3 &&
                  !_setupPromptDismissed) ...<Widget>[
                const SizedBox(height: AppSpacing.large),
                _QuickSetupPromptCard(
                  progress: localizations.onboardingSetupProgress(
                    setupCompletedCount,
                    3,
                  ),
                  onContinue: () => _openQuickSetup(state),
                  onDismiss: () => setState(() => _setupPromptDismissed = true),
                ),
              ],
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
    required String title,
    required Future<void> Function(Currency) onSelected,
  }) async {
    final result = await showCurrencyPickerPage(
      context: context,
      title: title,
      selected: selected,
    );
    if (result?.currency case final currency?) {
      if (!mounted) return;
      await onSelected(currency);
    }
  }

  Future<void> _openQuickSetup(ConverterState state) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      CupertinoPageRoute<void>(
        builder: (pageContext) => QuickSetupPage(
          initialCurrency: state.homeCurrency,
          onFinish: (currency) async {
            if (currency != state.homeCurrency) {
              await ref
                  .read(converterControllerProvider.notifier)
                  .changeHomeCurrency(currency);
            }
            if (pageContext.mounted) Navigator.of(pageContext).pop();
          },
        ),
      ),
    );
  }

  Future<void> _refreshMarketRate() async {
    if (_rateRefreshCoolingDown) return;
    setState(() => _rateRefreshCoolingDown = true);
    _rateRefreshCooldownTimer?.cancel();
    _rateRefreshCooldownTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _rateRefreshCoolingDown = false);
    });
    await ref.read(converterControllerProvider.notifier).refresh();
  }

  Future<void> _showRateSheet(ConverterState state) async {
    if (state.transactionCurrency == state.homeCurrency) return;
    final notifier = ref.read(converterControllerProvider.notifier);
    final result = await showCupertinoModalPopup<_RateSheetResult>(
      context: context,
      builder: (context) => _RateSelectionSheet(
        state: state,
        marketReference: notifier.loadMarketReference(),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    switch (result.action) {
      case _RateSheetAction.useMarket:
        await notifier.useMarketRate();
      case _RateSheetAction.useManual:
        await notifier.setManualRate(result.manualRate!);
    }
  }
}

enum _RateSheetAction { useMarket, useManual }

final class _RateSheetResult {
  const _RateSheetResult._(this.action, this.manualRate);

  const _RateSheetResult.useMarket() : this._(_RateSheetAction.useMarket, null);

  const _RateSheetResult.useManual(DecimalValue rate)
    : this._(_RateSheetAction.useManual, rate);

  final _RateSheetAction action;
  final DecimalValue? manualRate;
}

class _RateSelectionSheet extends StatefulWidget {
  const _RateSelectionSheet({
    required this.state,
    required this.marketReference,
  });

  final ConverterState state;
  final Future<RateSnapshotModel?> marketReference;

  @override
  State<_RateSelectionSheet> createState() => _RateSelectionSheetState();
}

class _RateSelectionSheetState extends State<_RateSelectionSheet> {
  late final TextEditingController _manualController;
  final FocusNode _manualFocusNode = FocusNode();
  late bool _manualSelected;

  @override
  void initState() {
    super.initState();
    final activeResolution = widget.state.rateResolution;
    final activeManual =
        activeResolution?.availability == RateAvailability.manual;
    _manualSelected = true;
    _manualController = TextEditingController(
      text: activeManual ? activeResolution!.snapshot!.rate.toString() : '',
    );
  }

  @override
  void dispose() {
    _manualController.dispose();
    _manualFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final surfaceColor = CupertinoColors.systemBackground.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Semantics(
          role: SemanticsRole.dialog,
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          child: Container(
            key: const Key('rate-selection-sheet'),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: FutureBuilder<RateSnapshotModel?>(
                future: widget.marketReference,
                builder: (context, snapshot) {
                  final marketRate = snapshot.data;
                  final manualRate = _manualRate;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey3.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Text(
                                  localizations.converterRateSheetTitle,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.state.transactionCurrency.code} '
                                  '→ ${widget.state.homeCurrency.code}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoButton(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.all(8),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  size: 20,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  semanticLabel: localizations.commonCancel,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _RateChoiceRow(
                          selected: !_manualSelected,
                          title: localizations.converterMarketReference,
                          value: marketRate == null
                              ? null
                              : _formatRateEquation(
                                  marketRate,
                                  fractionDigits: 6,
                                ),
                          detail: marketRate == null
                              ? localizations.converterMarketUnavailable
                              : localizations.converterRateSourceDetail(
                                  marketRate.sourceName,
                                  _formatRateTime(
                                    context,
                                    marketRate.fetchedAt,
                                  ),
                                ),
                          loading:
                              snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              marketRate == null,
                          onPressed: marketRate == null
                              ? null
                              : () => setState(() => _manualSelected = false),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(height: 0.5, color: separatorColor),
                        ),
                        _RateChoiceRow(
                          selected: _manualSelected,
                          title: localizations.converterManualReference,
                          onPressed: () {
                            setState(() => _manualSelected = true);
                            _manualFocusNode.requestFocus();
                          },
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          key: const Key('manual-rate-field'),
                          controller: _manualController,
                          focusNode: _manualFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          placeholder: marketRate == null
                              ? localizations.converterManualRateHint
                              : _formatRate(marketRate.rate, 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Text(
                              localizations.converterRateUnit(
                                widget.state.homeCurrency.code,
                                widget.state.transactionCurrency.code,
                              ),
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                          onTap: () => setState(() => _manualSelected = true),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (manualRate != null && marketRate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _comparisonMessage(
                              localizations,
                              manualRate,
                              marketRate.rate,
                            ),
                            key: const Key('manual-rate-comparison'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _OutlinedSheetButton(
                                key: const Key('use-market-rate'),
                                label: localizations.converterUseMarketRate,
                                onPressed: marketRate == null
                                    ? null
                                    : () => Navigator.of(
                                        context,
                                      ).pop(const _RateSheetResult.useMarket()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CupertinoButton.filled(
                                key: const Key('save-manual-rate'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 13,
                                ),
                                onPressed: manualRate == null
                                    ? null
                                    : () => Navigator.of(context).pop(
                                        _RateSheetResult.useManual(manualRate),
                                      ),
                                child: Text(
                                  localizations.converterSaveAndUse,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  DecimalValue? get _manualRate {
    try {
      final rate = DecimalValue.parse(_manualController.text.trim());
      return rate.compareTo(DecimalValue.zero) > 0 ? rate : null;
    } on FormatException {
      return null;
    }
  }
}

class _RateChoiceRow extends StatelessWidget {
  const _RateChoiceRow({
    required this.selected,
    required this.title,
    required this.onPressed,
    this.value,
    this.detail,
    this.loading = false,
  });

  final bool selected;
  final String title;
  final String? value;
  final String? detail;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              size: 22,
              color: selected
                  ? AppColors.primary.resolveFrom(context)
                  : CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: CupertinoActivityIndicator(),
            )
          else if (value != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8),
              child: Text(
                value!,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutlinedSheetButton extends StatelessWidget {
  const _OutlinedSheetButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? CupertinoColors.systemGrey3.resolveFrom(context)
        : AppColors.primary.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        onPressed: onPressed,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
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
    required this.onAdjustRate,
    required this.onRefreshRate,
    required this.isRateRefreshCoolingDown,
  });

  final TextEditingController expressionController;
  final ConverterState state;
  final ValueChanged<String> onExpressionChanged;
  final VoidCallback onSelectTransactionCurrency;
  final VoidCallback onSelectHomeCurrency;
  final VoidCallback onSwap;
  final VoidCallback onAdjustRate;
  final VoidCallback onRefreshRate;
  final bool isRateRefreshCoolingDown;

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
          Text(
            localizations.converterInputLabel,
            key: const Key('converter-input-label'),
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          const SizedBox(height: AppSpacing.small),
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
          const SizedBox(height: 4),
          if (state.rateResolution?.snapshot case final snapshot?)
            Text(
              _formatRateEquation(snapshot, fractionDigits: 6),
              key: const Key('converter-active-rate'),
              style: const TextStyle(fontSize: 14),
            ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          const SizedBox(height: 10),
          _ActiveRateSummary(
            state: state,
            onAdjustRate: onAdjustRate,
            onRefreshRate: onRefreshRate,
            isRefreshCoolingDown: isRateRefreshCoolingDown,
          ),
        ],
      ),
    );
  }
}

class _ActiveRateSummary extends StatelessWidget {
  const _ActiveRateSummary({
    required this.state,
    required this.onAdjustRate,
    required this.onRefreshRate,
    required this.isRefreshCoolingDown,
  });

  final ConverterState state;
  final VoidCallback onAdjustRate;
  final VoidCallback onRefreshRate;
  final bool isRefreshCoolingDown;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final resolution = state.rateResolution;
    final snapshot = resolution?.snapshot;
    final title = state.isResolvingRate
        ? localizations.converterRateLoading
        : switch (resolution?.availability) {
            RateAvailability.manual => localizations.converterManualReference,
            RateAvailability.liveMarket ||
            RateAvailability.cachedMarket ||
            RateAvailability.staleMarket ||
            RateAvailability.cardNetwork =>
              localizations.converterMarketReference,
            RateAvailability.identity => localizations.converterRateIdentity,
            _ => localizations.converterMarketUnavailable,
          };
    final detail = snapshot == null
        ? null
        : localizations.converterRateSourceDetail(
            resolution?.availability == RateAvailability.manual
                ? localizations.converterManualReference
                : snapshot.sourceName,
            _formatRateTime(context, snapshot.fetchedAt),
          );
    final canRefreshMarket = switch (resolution?.availability) {
      RateAvailability.manual || RateAvailability.identity => false,
      _ => true,
    };
    return Row(
      children: <Widget>[
        if (state.isResolvingRate)
          const CupertinoActivityIndicator()
        else
          Icon(
            snapshot == null
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.check_mark_circled_solid,
            size: 22,
            color: snapshot == null
                ? CupertinoColors.systemOrange
                : AppColors.primary.resolveFrom(context),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canRefreshMarket)
          CupertinoButton(
            key: const Key('refresh-market-rate'),
            minimumSize: Size.zero,
            padding: const EdgeInsets.all(8),
            onPressed: state.isResolvingRate || isRefreshCoolingDown
                ? null
                : onRefreshRate,
            child: Icon(
              CupertinoIcons.refresh,
              size: 20,
              semanticLabel: localizations.converterRefresh,
            ),
          ),
        if (resolution?.availability != RateAvailability.identity)
          CupertinoButton(
            key: const Key('adjust-rate'),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            onPressed: onAdjustRate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(localizations.converterAdjustRate),
                const SizedBox(width: 2),
                const Icon(CupertinoIcons.chevron_forward, size: 14),
              ],
            ),
          ),
      ],
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

String _formatRate(DecimalValue rate, int fractionDigits) {
  final fixed = rate.toFixed(fractionDigits);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatRateEquation(
  RateSnapshotModel snapshot, {
  required int fractionDigits,
}) {
  return '1 ${snapshot.baseCurrency.code} = '
      '${_formatRate(snapshot.rate, fractionDigits)} '
      '${snapshot.quoteCurrency.code}';
}

String _formatRateTime(BuildContext context, DateTime fetchedAt) {
  return DateFormat.Md(
    Localizations.localeOf(context).toLanguageTag(),
  ).add_Hm().format(fetchedAt.toLocal());
}

String _comparisonMessage(
  AppLocalizations localizations,
  DecimalValue manualRate,
  DecimalValue marketRate,
) {
  final difference =
      (manualRate.divide(marketRate) - DecimalValue.parse('1')) *
      DecimalValue.parse('100');
  final displayed = difference.abs().toFixed(2);
  if (displayed == '0.00') {
    return localizations.converterRateDifferenceSame;
  }
  return difference.isNegative
      ? localizations.converterRateDifferenceLower(displayed)
      : localizations.converterRateDifferenceHigher(displayed);
}

class _QuickSetupPromptCard extends StatelessWidget {
  const _QuickSetupPromptCard({
    required this.progress,
    required this.onContinue,
    required this.onDismiss,
  });

  final String progress;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.onboardingSetupTitle,
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
              ),
              CupertinoButton(
                key: const Key('quick-setup-prompt-dismiss'),
                padding: EdgeInsets.zero,
                onPressed: onDismiss,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  semanticLabel: l10n.onboardingSetupDismiss,
                ),
              ),
            ],
          ),
          Text(
            progress,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              key: const Key('quick-setup-prompt-continue'),
              color: CupertinoColors.secondarySystemFill.resolveFrom(context),
              onPressed: onContinue,
              child: Text(l10n.onboardingSetupContinue),
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
