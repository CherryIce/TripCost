import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/expenses/domain/expense_adjustment.dart';
import 'package:trip_cost/core/expenses/domain/expense_calibration.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/core/payments/domain/payment_cost_engine.dart';
import 'package:trip_cost/core/platform/system_permissions.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/app_keyboard_actions.dart';
import 'package:trip_cost/shared/widgets/app_toast.dart';
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';
import 'package:trip_cost/shared/widgets/precise_date_time_picker_sheet.dart';
import 'package:trip_cost/shared/widgets/system_permission_alert.dart';
import 'package:uuid/uuid.dart';

enum LedgerViewMode { timeline, calendar, category }

enum LedgerPeriod { thisMonth, lastMonth, all }

enum LedgerDateRange { all, recent7Days, recent30Days, custom }

class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  LedgerViewMode _mode = LedgerViewMode.timeline;
  LedgerPeriod _period = LedgerPeriod.thisMonth;
  LedgerFilter _filter = const LedgerFilter();
  List<ExpenseModel>? _cachedExpenses;
  LedgerPeriod? _cachedPeriod;
  LedgerFilter? _cachedFilter;
  int? _cachedMonth;
  _LedgerDerivedData? _cachedDerivedData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expenses = ref.watch(expensesControllerProvider);
    final trips = ref.watch(tripsControllerProvider).value ?? const [];
    final methods =
        ref.watch(paymentMethodsControllerProvider).value ?? const [];
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.ledgerTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _editFilters(trips, methods),
          child: Icon(
            CupertinoIcons.slider_horizontal_3,
            semanticLabel: l10n.ledgerFilters,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.push(AppRoutes.expenseCreate),
          child: Icon(CupertinoIcons.add, semanticLabel: l10n.expenseManualAdd),
        ),
      ),
      child: SafeArea(
        child: expenses.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: CupertinoButton(
              onPressed: () => ref.invalidate(expensesControllerProvider),
              child: Text(l10n.converterRefresh),
            ),
          ),
          data: (all) {
            final derived = _derivedDataFor(all);
            final items = derived.items;
            return Column(
              children: <Widget>[
                _LedgerOverview(
                  items: items,
                  currency: derived.summaryCurrency,
                  period: _period,
                  mode: _mode,
                  onChoosePeriod: _choosePeriod,
                  onModeChanged: (value) => setState(() => _mode = value),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(l10n.ledgerEmpty))
                      : switch (_mode) {
                          LedgerViewMode.timeline => _Timeline(
                            entries: derived.timelineEntries,
                            trips: trips,
                          ),
                          LedgerViewMode.calendar => _Calendar(items: items),
                          LedgerViewMode.category => _Categories(items: items),
                        },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _LedgerDerivedData _derivedDataFor(List<ExpenseModel> all) {
    final now = DateTime.now();
    final month = now.year * 12 + now.month;
    final cached = _cachedDerivedData;
    if (cached != null &&
        identical(_cachedExpenses, all) &&
        _cachedPeriod == _period &&
        identical(_cachedFilter, _filter) &&
        _cachedMonth == month) {
      return cached;
    }

    final periodItems = all
        .where((expense) => ledgerPeriodMatches(_period, expense, now))
        .toList(growable: false);
    final sortedItems = periodItems.where(_filter.matches).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final items = List<ExpenseModel>.unmodifiable(sortedItems);
    final derived = _LedgerDerivedData(
      items: items,
      summaryCurrency:
          items.firstOrNull?.referenceAmount.currency ??
          periodItems.firstOrNull?.referenceAmount.currency ??
          all.firstOrNull?.referenceAmount.currency ??
          CurrencyCatalog().resolve('CNY'),
      timelineEntries: _buildTimelineEntries(items),
    );
    _cachedExpenses = all;
    _cachedPeriod = _period;
    _cachedFilter = _filter;
    _cachedMonth = month;
    _cachedDerivedData = derived;
    return derived;
  }

  Future<void> _choosePeriod() async {
    final l10n = AppLocalizations.of(context);
    final value = await showCupertinoModalPopup<LedgerPeriod>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          for (final entry in <LedgerPeriod, String>{
            LedgerPeriod.thisMonth: l10n.ledgerThisMonth,
            LedgerPeriod.lastMonth: l10n.ledgerLastMonth,
            LedgerPeriod.all: l10n.ledgerAllTime,
          }.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(entry.key),
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ),
    );
    if (value != null && mounted) setState(() => _period = value);
  }

  Future<void> _editFilters(
    List<TripModel> trips,
    List<PaymentMethodModel> methods,
  ) async {
    final all = ref.read(expensesControllerProvider).value ?? const [];
    final visibleExpenses = all
        .where(
          (expense) => ledgerPeriodMatches(_period, expense, DateTime.now()),
        )
        .toList(growable: false);
    final result = await showCupertinoModalPopup<LedgerFilter>(
      context: context,
      builder: (context) => LedgerFilterSheet(
        initial: _filter,
        trips: trips,
        paymentMethods: methods,
        expenses: visibleExpenses,
      ),
    );
    if (result != null) setState(() => _filter = result);
  }
}

bool ledgerPeriodMatches(
  LedgerPeriod period,
  ExpenseModel expense,
  DateTime now,
) {
  if (period == LedgerPeriod.all) return true;
  final local = expense.occurredAt.toLocal();
  final anchor = now.toLocal();
  if (period == LedgerPeriod.thisMonth) {
    return local.year == anchor.year && local.month == anchor.month;
  }
  final previous = DateTime(anchor.year, anchor.month - 1);
  return local.year == previous.year && local.month == previous.month;
}

class _LedgerOverview extends StatelessWidget {
  const _LedgerOverview({
    required this.items,
    required this.currency,
    required this.period,
    required this.mode,
    required this.onChoosePeriod,
    required this.onModeChanged,
  });

  final List<ExpenseModel> items;
  final Currency currency;
  final LedgerPeriod period;
  final LedgerViewMode mode;
  final VoidCallback onChoosePeriod;
  final ValueChanged<LedgerViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = const MoneyFormatter();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final summaryItems = items
        .where(
          (item) =>
              item.entryType != ExpenseEntryType.voided &&
              item.referenceAmount.currency == currency,
        )
        .toList(growable: false);
    var total = DecimalValue.zero;
    for (final item in summaryItems) {
      total =
          total + (item.actualFinalAmount ?? item.estimatedFinalAmount).amount;
    }
    final categories = _ledgerCategoryShares(summaryItems, currency);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CupertinoButton(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                color: CupertinoColors.secondarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(9),
                onPressed: onChoosePeriod,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _periodLabel(l10n, period),
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 13,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _spendingLabel(l10n, period),
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatter.format(
                Money(amount: total, currency: currency),
                locale: locale,
              ),
              key: const Key('ledger-summary-total'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.ledgerSummaryCount(summaryItems.length, currency.code),
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 14,
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  for (var index = 0; index < categories.length; index++) ...[
                    if (index > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: categories[index].percent.clamp(1, 100),
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: categories[index].color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final category in categories)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${_categoryLabel(l10n, category.category)} '
                            '${category.percent}%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(
                              Money(
                                amount: category.amount,
                                currency: currency,
                              ),
                              locale: locale,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<LedgerViewMode>(
                groupValue: mode,
                children: <LedgerViewMode, Widget>{
                  LedgerViewMode.timeline: Text(l10n.ledgerTimeline),
                  LedgerViewMode.calendar: Text(l10n.ledgerCalendar),
                  LedgerViewMode.category: Text(l10n.ledgerCategories),
                },
                onValueChanged: (value) {
                  if (value != null) onModeChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LedgerCategoryShare {
  const _LedgerCategoryShare({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String category;
  final DecimalValue amount;
  final int percent;
  final Color color;
}

List<_LedgerCategoryShare> _ledgerCategoryShares(
  Iterable<ExpenseModel> items,
  Currency currency,
) {
  final totals = <String, DecimalValue>{};
  for (final item in items) {
    final amount = item.actualFinalAmount ?? item.estimatedFinalAmount;
    if (amount.currency != currency) continue;
    totals.update(
      item.category,
      (value) => value + amount.amount,
      ifAbsent: () => amount.amount,
    );
  }
  final sorted =
      totals.entries
          .where((entry) => entry.value.compareTo(DecimalValue.zero) > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  var total = DecimalValue.zero;
  for (final entry in sorted) {
    total = total + entry.value;
  }
  if (total.isZero) return const <_LedgerCategoryShare>[];
  const colors = <Color>[
    Color(0xFFF5A800),
    AppColors.primary,
    Color(0xFF8155EA),
  ];
  return <_LedgerCategoryShare>[
    for (var index = 0; index < sorted.take(3).length; index++)
      _LedgerCategoryShare(
        category: sorted[index].key,
        amount: sorted[index].value,
        percent: int.parse(
          (sorted[index].value.divide(total) * DecimalValue.parse('100'))
              .toFixed(0),
        ),
        color: colors[index],
      ),
  ];
}

String _periodLabel(AppLocalizations l10n, LedgerPeriod period) =>
    switch (period) {
      LedgerPeriod.thisMonth => l10n.ledgerThisMonth,
      LedgerPeriod.lastMonth => l10n.ledgerLastMonth,
      LedgerPeriod.all => l10n.ledgerAllTime,
    };

String _spendingLabel(AppLocalizations l10n, LedgerPeriod period) =>
    switch (period) {
      LedgerPeriod.thisMonth => l10n.ledgerThisMonthSpending,
      LedgerPeriod.lastMonth => l10n.ledgerLastMonthSpending,
      LedgerPeriod.all => l10n.ledgerTotalSpending,
    };

final class LedgerFilter {
  const LedgerFilter({
    this.tripId,
    this.categories = const <String>{},
    this.currencyCode,
    this.paymentMethodId,
    this.status,
    this.dateRange = LedgerDateRange.all,
    this.from,
    this.to,
    this.minimumAmount,
    this.maximumAmount,
  });

  final String? tripId;
  final Set<String> categories;
  final String? currencyCode;
  final String? paymentMethodId;
  final ExpenseStatus? status;
  final LedgerDateRange dateRange;
  final DateTime? from;
  final DateTime? to;
  final DecimalValue? minimumAmount;
  final DecimalValue? maximumAmount;

  bool get isEmpty =>
      tripId == null &&
      categories.isEmpty &&
      currencyCode == null &&
      paymentMethodId == null &&
      status == null &&
      from == null &&
      to == null &&
      minimumAmount == null &&
      maximumAmount == null;

  bool matches(ExpenseModel expense) {
    final amount = (expense.actualFinalAmount ?? expense.estimatedFinalAmount)
        .amount
        .abs();
    return (tripId == null || expense.tripId == tripId) &&
        (categories.isEmpty || categories.contains(expense.category)) &&
        (currencyCode == null ||
            expense.transactionAmount.currency.code == currencyCode) &&
        (paymentMethodId == null ||
            expense.paymentMethodId == paymentMethodId) &&
        (status == null || expense.status == status) &&
        (from == null || !expense.occurredAt.isBefore(from!)) &&
        (to == null || !expense.occurredAt.isAfter(to!)) &&
        (minimumAmount == null || amount.compareTo(minimumAmount!) >= 0) &&
        (maximumAmount == null || amount.compareTo(maximumAmount!) <= 0);
  }
}

class LedgerFilterSheet extends StatefulWidget {
  const LedgerFilterSheet({
    required this.initial,
    required this.trips,
    required this.paymentMethods,
    required this.expenses,
    super.key,
  });

  final LedgerFilter initial;
  final List<TripModel> trips;
  final List<PaymentMethodModel> paymentMethods;
  final List<ExpenseModel> expenses;

  @override
  State<LedgerFilterSheet> createState() => _LedgerFilterSheetState();
}

class _LedgerFilterSheetState extends State<LedgerFilterSheet> {
  late String? _tripId = widget.initial.tripId;
  late Set<String> _categories = <String>{...widget.initial.categories};
  late String? _currency = widget.initial.currencyCode;
  late String? _payment = widget.initial.paymentMethodId;
  late ExpenseStatus? _status = widget.initial.status;
  late LedgerDateRange _dateRange = widget.initial.dateRange;
  late DateTime? _customFrom = widget.initial.from;
  late DateTime? _customTo = widget.initial.to;
  late final _minimum = TextEditingController(
    text: widget.initial.minimumAmount?.toString() ?? '',
  );
  late final _maximum = TextEditingController(
    text: widget.initial.maximumAmount?.toString() ?? '',
  );
  bool _invalid = false;

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          key: const Key('ledger-filter-sheet'),
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3.resolveFrom(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Text(
                        l10n.ledgerFilters,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          onPressed: _clear,
                          child: Text(l10n.ledgerClearFilters),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 20,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SheetChoiceGroup(
                          children: <Widget>[
                            _SheetFilterRow(
                              key: const Key('ledger-filter-trip-row'),
                              icon: CupertinoIcons.briefcase,
                              label: l10n.expenseTrip,
                              value: _tripName(),
                              onPressed: _chooseTrip,
                            ),
                            _SheetFilterRow(
                              key: const Key('ledger-filter-category-row'),
                              icon: CupertinoIcons.tag,
                              label: l10n.expenseCategory,
                              value: _categoryNames(),
                              onPressed: _chooseCategories,
                            ),
                            _SheetFilterRow(
                              key: const Key('ledger-filter-currency-row'),
                              icon: _currencyFilterIcon(_currency),
                              label: l10n.currencyLocal,
                              value: _currency ?? l10n.commonAll,
                              onPressed: _chooseCurrency,
                            ),
                            _SheetFilterRow(
                              icon: CupertinoIcons.creditcard,
                              label: l10n.expensePaymentMethod,
                              value: _paymentName(),
                              onPressed: _choosePayment,
                            ),
                            _SheetFilterRow(
                              icon: CupertinoIcons.check_mark_circled,
                              label: l10n.expenseStatus,
                              value: _statusName(),
                              onPressed: _chooseStatus,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.expenseDate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child:
                              CupertinoSlidingSegmentedControl<LedgerDateRange>(
                                groupValue: _dateRange,
                                backgroundColor: CupertinoColors.systemGrey6,
                                thumbColor: AppColors.primary,
                                children: <LedgerDateRange, Widget>{
                                  LedgerDateRange.all: _dateRangeLabel(
                                    LedgerDateRange.all,
                                    l10n.commonAll,
                                  ),
                                  LedgerDateRange.recent7Days: _dateRangeLabel(
                                    LedgerDateRange.recent7Days,
                                    l10n.ledgerRecentDaysShort(7),
                                  ),
                                  LedgerDateRange.recent30Days: _dateRangeLabel(
                                    LedgerDateRange.recent30Days,
                                    l10n.ledgerRecentDaysShort(30),
                                  ),
                                  LedgerDateRange.custom: _dateRangeLabel(
                                    LedgerDateRange.custom,
                                    l10n.ledgerCustomDate,
                                  ),
                                },
                                onValueChanged: (value) {
                                  if (value == null) return;
                                  if (value == LedgerDateRange.custom) {
                                    _chooseCustomDateRange();
                                  } else {
                                    setState(() => _dateRange = value);
                                  }
                                },
                              ),
                        ),
                        if (_dateRange == LedgerDateRange.custom &&
                            _customFrom != null &&
                            _customTo != null) ...[
                          const SizedBox(height: 8),
                          _customDateRangeSummary(l10n),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: _CompactAmountField(
                                label: l10n.ledgerMinimumAmount,
                                controller: _minimum,
                                onChanged: _amountChanged,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(12, 40, 12, 0),
                              child: Text('–'),
                            ),
                            Expanded(
                              child: _CompactAmountField(
                                label: l10n.ledgerMaximumAmount,
                                controller: _maximum,
                                onChanged: _amountChanged,
                              ),
                            ),
                          ],
                        ),
                        if (_invalid) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.ledgerInvalidFilters,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      key: const Key('apply-ledger-filters'),
                      onPressed: _done,
                      child: Text(l10n.ledgerViewRecords(_matchingCount)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tripName() =>
      widget.trips
          .where((item) => item.metadata.recordId == _tripId)
          .firstOrNull
          ?.name ??
      AppLocalizations.of(context).commonAll;
  String _categoryNames() => _categories.isEmpty
      ? AppLocalizations.of(context).commonAll
      : _categories
            .map((item) => _categoryLabel(AppLocalizations.of(context), item))
            .join(AppLocalizations.of(context).ledgerSelectionSeparator);
  String _paymentName() =>
      widget.paymentMethods
          .where((item) => item.metadata.recordId == _payment)
          .firstOrNull
          ?.name ??
      AppLocalizations.of(context).commonAll;
  String _statusName() => _status == null
      ? AppLocalizations.of(context).commonAll
      : _status == ExpenseStatus.confirmed
      ? AppLocalizations.of(context).expenseConfirmed
      : AppLocalizations.of(context).expensePending;

  Widget _dateRangeLabel(LedgerDateRange value, String label) => Text(
    label,
    style: TextStyle(
      color: _dateRange == value
          ? CupertinoColors.white
          : CupertinoColors.label.resolveFrom(context),
    ),
  );

  Widget _customDateRangeSummary(AppLocalizations l10n) {
    final range = _customDateRangeText();
    return Semantics(
      button: true,
      label: '${l10n.ledgerCustomDate}: $range',
      hint: l10n.commonEdit,
      excludeSemantics: true,
      child: CupertinoButton(
        key: const Key('ledger-custom-date-summary'),
        minimumSize: const Size(double.infinity, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: CupertinoColors.secondarySystemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        onPressed: _chooseCustomDateRange,
        child: Row(
          children: <Widget>[
            Icon(
              CupertinoIcons.calendar,
              size: 19,
              color: AppColors.primary.resolveFrom(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                range,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  String _customDateRangeText() {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat.yMd(locale);
    return '${formatter.format(_customFrom!.toLocal())} – '
        '${formatter.format(_customTo!.toLocal())}';
  }

  int get _matchingCount {
    try {
      final filter = _buildFilter();
      return widget.expenses.where(filter.matches).length;
    } on FormatException {
      return 0;
    }
  }

  Future<T?> _choose<T>(Map<T, String> values) => showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      actions: <Widget>[
        for (final entry in values.entries)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(entry.key),
            child: Text(entry.value),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context).commonCancel),
      ),
    ),
  );

  Future<void> _chooseTrip() async {
    const all = '__all__';
    final value = await _choose<String>(<String, String>{
      all: AppLocalizations.of(context).commonAll,
      for (final item in widget.trips) item.metadata.recordId: item.name,
    });
    if (value != null && mounted) {
      setState(() => _tripId = value == all ? null : value);
    }
  }

  Future<void> _chooseCategories() async {
    final value = await showCupertinoModalPopup<Set<String>>(
      context: context,
      builder: (context) => _CategorySelectionSheet(selected: _categories),
    );
    if (value != null && mounted) setState(() => _categories = value);
  }

  Future<void> _chooseCurrency() async {
    final selected = _currency == null
        ? null
        : CurrencyCatalog().resolve(_currency!);
    final result = await showCurrencyPickerPage(
      context: context,
      title: AppLocalizations.of(context).currencyLocal,
      selected: selected,
      allLabel: AppLocalizations.of(context).commonAll,
    );
    if (result != null && mounted) {
      setState(() => _currency = result.currency?.code);
    }
  }

  Future<void> _choosePayment() async {
    const all = '__all__';
    final value = await _choose<String>(<String, String>{
      all: AppLocalizations.of(context).commonAll,
      for (final item in widget.paymentMethods)
        item.metadata.recordId: item.name,
    });
    if (value != null && mounted) {
      setState(() => _payment = value == all ? null : value);
    }
  }

  Future<void> _chooseStatus() async {
    final value = await _choose<int>(<int, String>{
      -1: AppLocalizations.of(context).commonAll,
      0: AppLocalizations.of(context).expensePending,
      1: AppLocalizations.of(context).expenseConfirmed,
    });
    if (value != null && mounted) {
      setState(() {
        _status = switch (value) {
          0 => ExpenseStatus.estimated,
          1 => ExpenseStatus.confirmed,
          _ => null,
        };
      });
    }
  }

  Future<void> _chooseCustomDateRange() async {
    final now = DateTime.now();
    final storedFrom = _customFrom?.toLocal() ?? now;
    final initialFrom = storedFrom.isAfter(now) ? now : storedFrom;
    final storedTo = _customTo?.toLocal() ?? now;
    final cappedTo = storedTo.isAfter(now) ? now : storedTo;
    final initialTo = cappedTo.isBefore(initialFrom) ? initialFrom : cappedTo;
    final range = await showCupertinoModalPopup<_LedgerDateRangeSelection>(
      context: context,
      builder: (context) => _LedgerDateRangePickerSheet(
        initialFrom: initialFrom,
        initialTo: initialTo,
        maximum: now,
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _customFrom = DateTime(
        range.from.year,
        range.from.month,
        range.from.day,
      ).toUtc();
      _customTo = DateTime(
        range.to.year,
        range.to.month,
        range.to.day,
        23,
        59,
        59,
        999,
      ).toUtc();
      _dateRange = LedgerDateRange.custom;
    });
  }

  void _done() {
    try {
      Navigator.of(context).pop(_buildFilter());
    } on FormatException {
      setState(() => _invalid = true);
    }
  }

  LedgerFilter _buildFilter() {
    final now = DateTime.now().toUtc();
    final minimum = _parseOptional(_minimum.text);
    final maximum = _parseOptional(_maximum.text);
    if (minimum?.isNegative == true ||
        maximum?.isNegative == true ||
        (minimum != null &&
            maximum != null &&
            minimum.compareTo(maximum) > 0)) {
      throw const FormatException('Invalid amount range.');
    }
    return LedgerFilter(
      tripId: _tripId,
      categories: Set<String>.unmodifiable(_categories),
      currencyCode: _currency,
      paymentMethodId: _payment,
      status: _status,
      dateRange: _dateRange,
      from: switch (_dateRange) {
        LedgerDateRange.all => null,
        LedgerDateRange.recent7Days => now.subtract(const Duration(days: 7)),
        LedgerDateRange.recent30Days => now.subtract(const Duration(days: 30)),
        LedgerDateRange.custom => _customFrom,
      },
      to: switch (_dateRange) {
        LedgerDateRange.all => null,
        LedgerDateRange.recent7Days || LedgerDateRange.recent30Days => now,
        LedgerDateRange.custom => _customTo,
      },
      minimumAmount: minimum,
      maximumAmount: maximum,
    );
  }

  void _clear() {
    setState(() {
      _tripId = null;
      _categories = <String>{};
      _currency = null;
      _payment = null;
      _status = null;
      _dateRange = LedgerDateRange.all;
      _customFrom = null;
      _customTo = null;
      _minimum.clear();
      _maximum.clear();
      _invalid = false;
    });
  }

  void _amountChanged(String _) {
    setState(() => _invalid = false);
  }
}

class _LedgerDateRangeSelection {
  const _LedgerDateRangeSelection({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

class _LedgerDateRangePickerSheet extends StatefulWidget {
  const _LedgerDateRangePickerSheet({
    required this.initialFrom,
    required this.initialTo,
    required this.maximum,
  });

  final DateTime initialFrom;
  final DateTime initialTo;
  final DateTime maximum;

  @override
  State<_LedgerDateRangePickerSheet> createState() =>
      _LedgerDateRangePickerSheetState();
}

class _LedgerDateRangePickerSheetState
    extends State<_LedgerDateRangePickerSheet> {
  late DateTime _from = _dateOnly(widget.initialFrom);
  late DateTime _to = _dateOnly(widget.initialTo);
  bool _editingEnd = false;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateLabel(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMd(locale).format(value);
  }

  void _select(DateTime value) {
    final selected = _dateOnly(value);
    setState(() {
      if (_editingEnd) {
        _to = selected.isBefore(_from) ? _from : selected;
      } else {
        _from = selected;
        if (_to.isBefore(_from)) _to = _from;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final preferredSheetHeight = (screenHeight * 0.55)
        .clamp(430.0, 470.0)
        .toDouble();
    final sheetHeight = preferredSheetHeight > screenHeight
        ? screenHeight
        : preferredSheetHeight;
    final background = CupertinoColors.systemBackground.resolveFrom(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          key: const Key('ledger-date-picker-sheet'),
          width: double.infinity,
          height: sheetHeight,
          color: background,
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3.resolveFrom(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 100),
                        child: Text(
                          l10n.ledgerDateRangePickerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CupertinoButton(
                          key: const Key('ledger-date-picker-cancel'),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 16),
                          child: CupertinoButton.filled(
                            key: const Key('ledger-date-picker-done'),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => Navigator.of(context).pop(
                              _LedgerDateRangeSelection(from: _from, to: _to),
                            ),
                            child: Text(
                              l10n.commonDone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _LedgerRangeDateField(
                          key: const Key('ledger-date-range-start-field'),
                          label: l10n.ledgerStartDate,
                          value: _dateLabel(context, _from),
                          active: !_editingEnd,
                          onPressed: () => setState(() => _editingEnd = false),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '–',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _LedgerRangeDateField(
                          key: const Key('ledger-date-range-end-field'),
                          label: l10n.ledgerEndDate,
                          value: _dateLabel(context, _to),
                          active: _editingEnd,
                          onPressed: () => setState(() => _editingEnd = true),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        SizedBox.expand(
                          key: const Key('ledger-date-picker-wheel'),
                          child: CupertinoDatePicker(
                            key: ValueKey<bool>(_editingEnd),
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: _editingEnd ? _to : _from,
                            minimumDate: _editingEnd ? _from : null,
                            maximumDate: widget.maximum,
                            backgroundColor: background,
                            itemExtent: 44,
                            selectionOverlayBuilder:
                                (
                                  context, {
                                  required selectedIndex,
                                  required columnCount,
                                }) => null,
                            onDateTimeChanged: _select,
                          ),
                        ),
                        IgnorePointer(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              key: const Key(
                                'ledger-date-picker-selection-band',
                              ),
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerRangeDateField extends StatelessWidget {
  const _LedgerRangeDateField({
    required this.label,
    required this.value,
    required this.active,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String value;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 56),
      onPressed: onPressed,
      child: Semantics(
        selected: active,
        child: Container(
          width: double.infinity,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? primary : const Color(0x00000000),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetChoiceGroup extends StatelessWidget {
  const _SheetChoiceGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: separator, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 48),
                child: Container(height: 0.5, color: separator),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _SheetFilterRow extends StatelessWidget {
  const _SheetFilterRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    minimumSize: Size.zero,
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: SizedBox(
      height: 48,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox.square(
              dimension: 20,
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: AppColors.primary.resolveFrom(context),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompactAmountField extends StatelessWidget {
  const _CompactAmountField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      CupertinoTextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: label,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        onChanged: onChanged,
      ),
    ],
  );
}

class _CategorySelectionSheet extends StatefulWidget {
  const _CategorySelectionSheet({required this.selected});

  final Set<String> selected;

  @override
  State<_CategorySelectionSheet> createState() =>
      _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<_CategorySelectionSheet> {
  late final Set<String> _selected = <String>{...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3.resolveFrom(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Text(
                        l10n.expenseCategory,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(Set<String>.unmodifiable(_selected)),
                          child: Text(l10n.commonDone),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final category in _categories)
                  CupertinoButton(
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => setState(() {
                      if (!_selected.add(category)) _selected.remove(category);
                    }),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _categoryLabel(l10n, category),
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        ),
                        if (_selected.contains(category))
                          const Icon(CupertinoIcons.check_mark, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpenseEditorPage extends ConsumerStatefulWidget {
  const ExpenseEditorPage({
    this.arguments,
    this.receiptImagePicker,
    this.permissionGateway,
    super.key,
  });
  final ExpenseEditorArguments? arguments;
  final ScannerImagePicker? receiptImagePicker;
  final SystemPermissionGateway? permissionGateway;

  @override
  ConsumerState<ExpenseEditorPage> createState() => _ExpenseEditorPageState();
}

class _ExpenseEditorPageState extends ConsumerState<ExpenseEditorPage> {
  late final SystemPermissionGateway _permissionGateway =
      widget.permissionGateway ?? const MethodChannelSystemPermissionGateway();
  final _title = TextEditingController();
  final _transactionAmount = TextEditingController();
  final _referenceAmount = TextEditingController();
  final _estimatedAmount = TextEditingController();
  final _actualAmount = TextEditingController();
  final _tax = TextEditingController(text: '0');
  final _tip = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _participants = TextEditingController(text: '1');
  final _notes = TextEditingController();
  final _receiptPath = TextEditingController();
  final _titleFocus = FocusNode();
  final _transactionFocus = FocusNode();
  final _actualFocus = FocusNode();
  final _taxFocus = FocusNode();
  final _tipFocus = FocusNode();
  final _discountFocus = FocusNode();
  final _participantsFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _editorScrollController = ScrollController();
  final _notesGroupKey = GlobalKey();
  Currency _transactionCurrency = CurrencyCatalog().resolve('USD');
  Currency _homeCurrency = CurrencyCatalog().resolve('CNY');
  String _category = 'shopping';
  String? _tripId;
  String? _paymentMethodId;
  ExpenseStatus _status = ExpenseStatus.estimated;
  DateTime _occurredAt = DateTime.now().toUtc();
  bool _budgetIncluded = true;
  bool _isLoadingCurrencyDefaults = false;
  bool _appliedInitialPaymentStatus = false;
  bool _isCalculating = false;
  bool _calculationUnavailable = false;
  bool _detailsExpanded = false;
  bool _isSaving = false;
  bool _isResolvingReceipt = false;
  int _calculationGeneration = 0;
  int _receiptGeneration = 0;
  bool _notesVisibilityScheduled = false;
  Timer? _calculationDebounce;
  RateSnapshotModel? _activeRateSnapshot;
  File? _receiptFile;
  String _lastAutomaticActual = '';
  List<PaymentMethodModel> _availableMethods = const <PaymentMethodModel>[];

  ExpenseDraftSeed? get _seed => widget.arguments?.seed;
  ReceiptExpensePrefill? get _receiptPrefill =>
      widget.arguments?.receiptPrefill;

  List<FocusNode> get _focusOrder => <FocusNode>[
    _titleFocus,
    _transactionFocus,
    if (_status == ExpenseStatus.confirmed) _actualFocus,
    if (_detailsExpanded) ...<FocusNode>[
      _taxFocus,
      _tipFocus,
      _discountFocus,
      _participantsFocus,
    ],
    _notesFocus,
  ];

  @override
  void initState() {
    super.initState();
    final seed = _seed;
    final receiptPrefill = _receiptPrefill;
    final trip = widget.arguments?.trip;
    if (seed != null) {
      _transactionAmount.text = seed.transactionAmount.amount.toString();
      _referenceAmount.text = seed.breakdown.referenceAmount.amount.toString();
      _estimatedAmount.text = seed.breakdown.estimatedCost.amount.toString();
      _transactionCurrency = seed.transactionAmount.currency;
      _homeCurrency = seed.breakdown.estimatedCost.currency;
      _paymentMethodId = seed.breakdown.paymentRule.paymentMethodId;
      _receiptPath.text = seed.receiptLocalPath ?? '';
      _activeRateSnapshot = seed.rateSnapshot;
    }
    if (receiptPrefill != null) {
      _title.text = receiptPrefill.title ?? '';
      if (receiptPrefill.transactionAmount case final amount?) {
        _transactionAmount.text = amount.amount.toString();
        _transactionCurrency = amount.currency;
      }
      _occurredAt = receiptPrefill.occurredAt ?? _occurredAt;
      _receiptPath.text = receiptPrefill.receiptLocalPath ?? '';
    }
    if (trip != null) {
      _tripId = trip.metadata.recordId;
      _homeCurrency = trip.homeCurrency;
      if (receiptPrefill?.transactionAmount == null) {
        _transactionCurrency = trip.localCurrencies.first;
      }
      _participants.text = trip.participantCount.toString();
      _paymentMethodId ??= trip.defaultPaymentMethodId;
    }
    if (seed == null && trip == null) {
      _isLoadingCurrencyDefaults = true;
      unawaited(
        _loadCurrencyDefaults(
          preserveTransactionCurrency:
              receiptPrefill?.transactionAmount != null,
        ),
      );
    }
    for (final controller in <TextEditingController>[
      _transactionAmount,
      _tax,
      _tip,
      _discount,
    ]) {
      controller.addListener(_scheduleRecalculation);
    }
    _notesFocus.addListener(_scheduleNotesVisibility);
    if (_receiptPath.text.isNotEmpty) {
      unawaited(_resolveReceiptPreview(_receiptPath.text));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleRecalculation(immediate: true);
    });
  }

  @override
  void dispose() {
    _calculationDebounce?.cancel();
    _notesFocus.removeListener(_scheduleNotesVisibility);
    for (final controller in <TextEditingController>[
      _transactionAmount,
      _tax,
      _tip,
      _discount,
    ]) {
      controller.removeListener(_scheduleRecalculation);
    }
    for (final controller in <TextEditingController>[
      _title,
      _transactionAmount,
      _referenceAmount,
      _estimatedAmount,
      _actualAmount,
      _tax,
      _tip,
      _discount,
      _participants,
      _notes,
      _receiptPath,
    ]) {
      controller.dispose();
    }
    for (final node in <FocusNode>[
      _titleFocus,
      _transactionFocus,
      _actualFocus,
      _taxFocus,
      _tipFocus,
      _discountFocus,
      _participantsFocus,
      _notesFocus,
    ]) {
      node.dispose();
    }
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripsControllerProvider).value ?? const [];
    final methodsState = ref.watch(paymentMethodsControllerProvider);
    final methods = methodsState.value ?? const [];
    _availableMethods = methods;
    if (!_appliedInitialPaymentStatus && methodsState.hasValue) {
      _appliedInitialPaymentStatus = true;
      final selectedMethod = methods
          .where((item) => item.metadata.recordId == _paymentMethodId)
          .firstOrNull;
      if (selectedMethod?.type == PaymentMethodType.cash) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _applyPaymentStatusDefault(selectedMethod));
          _scheduleRecalculation(immediate: true);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scheduleRecalculation(immediate: true);
        });
      }
    }
    final selectedTrip = trips
        .where((item) => item.metadata.recordId == _tripId)
        .firstOrNull;
    final selectedMethod = methods
        .where((item) => item.metadata.recordId == _paymentMethodId)
        .firstOrNull;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    if (keyboardVisible && _notesFocus.hasFocus) {
      _scheduleNotesVisibility();
    }
    final bottomPadding =
        AppInsets.scrollableBottomPadding(context) +
        (keyboardVisible
            ? keyboardInset + AppKeyboardAccessoryBar.height + 12
            : 0);
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.expenseManualAdd),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoadingCurrencyDefaults || _isSaving
              ? null
              : () => _save(methods),
          child: _isSaving
              ? const CupertinoActivityIndicator(radius: 9)
              : Text(l10n.commonSave),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoadingCurrencyDefaults
            ? const Center(child: CupertinoActivityIndicator())
            : Stack(
                children: <Widget>[
                  ListView(
                    key: const Key('expense-editor-list'),
                    controller: _editorScrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      AppSpacing.medium,
                      AppSpacing.medium,
                      bottomPadding,
                    ),
                    children: <Widget>[
                      if (_receiptPrefill case final prefill?) ...<Widget>[
                        _OcrPrefillBanner(
                          message: l10n.expenseOcrPrefillBanner(
                            prefill.filledFieldCount,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _ExpenseEditorSection(
                        key: const Key('expense-editor-basics-section'),
                        label: l10n.expenseEditorBasics,
                        children: <Widget>[
                          _ExpenseEditorTextRow(
                            fieldKey: const Key('expense-title-field'),
                            label: l10n.expenseTitle,
                            placeholder: l10n.expenseTitlePlaceholder,
                            controller: _title,
                            focusNode: _titleFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                _transactionFocus.requestFocus(),
                            confirmationLabel:
                                _receiptPrefill?.titleNeedsConfirmation == true
                                ? l10n.expenseOcrNeedsConfirmation
                                : null,
                          ),
                          _ExpenseEditorActionRow(
                            rowKey: const Key('expense-trip-category-row'),
                            label: l10n.expenseEditorTripCategory,
                            value:
                                '${selectedTrip?.name ?? l10n.commonNone} · '
                                '${_categoryLabel(l10n, _category)}',
                            onPressed: () =>
                                _chooseTripOrCategory(trips, methods),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ExpenseEditorSection(
                        key: const Key('expense-editor-amount-section'),
                        label: l10n.expenseEditorAmount,
                        footer: Text(
                          _calculationUnavailable
                              ? l10n.converterRateUnavailable
                              : l10n.expenseEditorLiveHint,
                          style: TextStyle(
                            color: _calculationUnavailable
                                ? CupertinoColors.systemRed.resolveFrom(context)
                                : CupertinoColors.secondaryLabel.resolveFrom(
                                    context,
                                  ),
                            fontSize: 13,
                          ),
                        ),
                        children: <Widget>[
                          _ExpenseAmountInputRow(
                            fieldKey: const Key(
                              'expense-transaction-amount-field',
                            ),
                            currencyKey: const Key(
                              'expense-transaction-currency',
                            ),
                            label: l10n.expenseTransactionAmount,
                            placeholder:
                                l10n.expenseTransactionAmountPlaceholder,
                            controller: _transactionAmount,
                            focusNode: _transactionFocus,
                            currencyCode: _transactionCurrency.code,
                            onChooseCurrency: () => _chooseCurrency(true),
                            onSubmitted: (_) => _moveFocus(forward: true),
                          ),
                          _ExpenseEditorActionRow(
                            rowKey: const Key('expense-date-row'),
                            label: l10n.expenseDate,
                            value: DateFormat.yMd(
                              Localizations.localeOf(context).toLanguageTag(),
                            ).add_Hms().format(_occurredAt.toLocal()),
                            onPressed: _pickDate,
                          ),
                          _ExpenseMoneyResultRow(
                            rowKey: const Key('expense-home-currency'),
                            label: l10n.expenseReferenceAmount,
                            value: _formattedAmount(_referenceAmount.text),
                            loading: _isCalculating,
                          ),
                          _ExpenseMoneyResultRow(
                            rowKey: const Key('expense-estimated-amount-field'),
                            label: l10n.expenseEstimatedAmount,
                            value: _formattedAmount(_estimatedAmount.text),
                            emphasized: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ExpenseEditorSection(
                        key: const Key('expense-editor-payment-section'),
                        label: l10n.expenseEditorPaymentStatus,
                        children: <Widget>[
                          _ExpenseEditorActionRow(
                            label: l10n.expensePaymentMethod,
                            value: selectedMethod?.name ?? l10n.commonNone,
                            onPressed: () => _choosePayment(methods),
                          ),
                          _ExpenseStatusRow(
                            value: _status,
                            pendingLabel: l10n.expensePending,
                            confirmedLabel: l10n.expenseConfirmed,
                            onChanged: _changeStatus,
                          ),
                          if (_status == ExpenseStatus.confirmed)
                            _ExpenseEditorTextRow(
                              fieldKey: const Key(
                                'expense-actual-amount-field',
                              ),
                              label: l10n.expenseActualAmount,
                              controller: _actualAmount,
                              focusNode: _actualFocus,
                              numeric: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _moveFocus(forward: true),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ExpenseEditorGroup(
                        key: const Key('expense-editor-adjustments-group'),
                        children: <Widget>[
                          _ExpenseEditorActionRow(
                            label: l10n.expenseEditorAdjustments,
                            value: _adjustmentSummary(l10n),
                            expanded: _detailsExpanded,
                            onPressed: () => setState(
                              () => _detailsExpanded = !_detailsExpanded,
                            ),
                          ),
                          if (_detailsExpanded) ...<Widget>[
                            _ExpenseEditorTextRow(
                              fieldKey: const Key('expense-tax-field'),
                              label: l10n.expenseTax,
                              controller: _tax,
                              focusNode: _taxFocus,
                              numeric: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _tipFocus.requestFocus(),
                            ),
                            _ExpenseEditorTextRow(
                              fieldKey: const Key('expense-tip-field'),
                              label: l10n.expenseTip,
                              controller: _tip,
                              focusNode: _tipFocus,
                              numeric: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _discountFocus.requestFocus(),
                            ),
                            _ExpenseEditorTextRow(
                              fieldKey: const Key('expense-discount-field'),
                              label: l10n.expenseDiscount,
                              controller: _discount,
                              focusNode: _discountFocus,
                              numeric: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _participantsFocus.requestFocus(),
                            ),
                            _ExpenseEditorTextRow(
                              fieldKey: const Key('expense-participants-field'),
                              label: l10n.tripParticipants,
                              controller: _participants,
                              focusNode: _participantsFocus,
                              numeric: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _notesFocus.requestFocus(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildReceiptSection(l10n),
                      const SizedBox(height: 14),
                      _ExpenseEditorGroup(
                        key: _notesGroupKey,
                        children: <Widget>[
                          _ExpenseEditorTextRow(
                            fieldKey: const Key('expense-notes-field'),
                            label: l10n.expenseNotes,
                            controller: _notes,
                            focusNode: _notesFocus,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _dismissKeyboard(),
                          ),
                          _ExpenseBudgetRow(
                            label: l10n.expenseBudgetIncluded,
                            value: _budgetIncluded,
                            onChanged: (value) =>
                                setState(() => _budgetIncluded = value),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (keyboardVisible)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: keyboardInset,
                      child: AppKeyboardAccessoryBar(
                        key: const Key('expense-keyboard-accessory'),
                        onPrevious: _canMoveFocus(forward: false)
                            ? () => _moveFocus(forward: false)
                            : null,
                        onNext: _canMoveFocus(forward: true)
                            ? () => _moveFocus(forward: true)
                            : null,
                        onDone: _dismissKeyboard,
                        doneLabel: l10n.commonDone,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _scheduleNotesVisibility() {
    if (_notesVisibilityScheduled || !_notesFocus.hasFocus) return;
    _notesVisibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notesVisibilityScheduled = false;
      if (!mounted || !_notesFocus.hasFocus) return;
      if (MediaQuery.viewInsetsOf(context).bottom <= 0) return;
      final notesContext = _notesGroupKey.currentContext;
      if (notesContext == null) return;
      final notesBox = notesContext.findRenderObject();
      if (notesBox is! RenderBox || !_editorScrollController.hasClients) {
        return;
      }
      final availableBottom =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom -
          AppKeyboardAccessoryBar.height -
          12;
      final notesBottom = notesBox
          .localToGlobal(Offset(0, notesBox.size.height))
          .dy;
      final overlap = notesBottom - availableBottom;
      if (overlap <= 0) return;
      final position = _editorScrollController.position;
      final target = (position.pixels + overlap)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      unawaited(
        _editorScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  Widget _buildReceiptSection(AppLocalizations l10n) {
    return Column(
      key: const Key('expense-receipt-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.expenseReceiptSection,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 15,
                ),
              ),
            ),
            if (_receiptFile != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _chooseReceiptImage,
                child: Text(l10n.expenseReceiptReplace),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isResolvingReceipt)
          const SizedBox(
            height: 136,
            child: Center(child: CupertinoActivityIndicator()),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_receiptFile case final file?) ...<Widget>[
                Expanded(
                  child: _ExpenseReceiptThumbnail(
                    file: file,
                    removeLabel: l10n.expenseReceiptRemove,
                    onRemove: _removeReceipt,
                  ),
                ),
                const SizedBox(width: 12),
                _ExpenseReceiptAddTile(
                  key: const Key('expense-receipt-picker'),
                  label: l10n.expenseReceiptAdd,
                  compact: true,
                  onPressed: _chooseReceiptImage,
                ),
              ] else
                Expanded(
                  child: _ExpenseReceiptAddTile(
                    key: const Key('expense-receipt-picker'),
                    label: l10n.expenseReceiptAdd,
                    compact: false,
                    onPressed: _chooseReceiptImage,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _loadCurrencyDefaults({
    bool preserveTransactionCurrency = false,
  }) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).load();
      if (!mounted) return;
      setState(() {
        if (settings != null) {
          if (!preserveTransactionCurrency) {
            _transactionCurrency = settings.lastTransactionCurrency;
          }
          _homeCurrency = settings.defaultCurrency;
        }
        _isLoadingCurrencyDefaults = false;
      });
      _activeRateSnapshot = null;
      _scheduleRecalculation(immediate: true);
    } on Object {
      if (!mounted) return;
      setState(() => _isLoadingCurrencyDefaults = false);
      _scheduleRecalculation(immediate: true);
    }
  }

  Future<T?> _choose<T>(Map<T, String> values) => showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      actions: <Widget>[
        for (final entry in values.entries)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(entry.key),
            child: Text(entry.value),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context).commonCancel),
      ),
    ),
  );
  Future<void> _chooseTripOrCategory(
    List<TripModel> trips,
    List<PaymentMethodModel> methods,
  ) async {
    _dismissKeyboard();
    final selection = await showCupertinoModalPopup<_ExpenseContextSelection>(
      context: context,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.42),
      builder: (context) => _ExpenseContextPickerSheet(
        trips: trips,
        initialTripId: _tripId,
        initialCategory: _category,
      ),
    );
    if (!mounted || selection == null) return;

    final tripChanged = selection.tripId != _tripId;
    final trip = trips
        .where((item) => item.metadata.recordId == selection.tripId)
        .firstOrNull;
    setState(() {
      _category = selection.category;
      if (!tripChanged) return;

      _tripId = selection.tripId;
      if (trip != null) {
        _homeCurrency = trip.homeCurrency;
        if (!trip.localCurrencies.contains(_transactionCurrency)) {
          _transactionCurrency = trip.localCurrencies.first;
        }
        _participants.text = trip.participantCount.toString();
        final selectedMethod = methods
            .where(
              (item) =>
                  item.metadata.recordId == trip.defaultPaymentMethodId &&
                  item.billingCurrency == trip.homeCurrency,
            )
            .firstOrNull;
        _paymentMethodId = selectedMethod?.metadata.recordId;
        _applyPaymentStatusDefault(selectedMethod);
      }
      _activeRateSnapshot = null;
    });
    if (tripChanged) _scheduleRecalculation(immediate: true);
  }

  Future<void> _choosePayment(List<PaymentMethodModel> methods) async {
    final selected = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonNone,
      for (final item in methods)
        if (item.billingCurrency == _homeCurrency)
          item.metadata.recordId: item.name,
    });
    if (!mounted) return;
    final method = methods
        .where((item) => item.metadata.recordId == selected)
        .firstOrNull;
    setState(() {
      _paymentMethodId = selected;
      _applyPaymentStatusDefault(method);
    });
    _scheduleRecalculation(immediate: true);
  }

  void _applyPaymentStatusDefault(PaymentMethodModel? method) {
    if (method?.type != PaymentMethodType.cash) return;
    _status = ExpenseStatus.confirmed;
    if (_actualAmount.text.trim().isEmpty) {
      _actualAmount.text = _estimatedAmount.text.trim();
      _lastAutomaticActual = _actualAmount.text;
    }
  }

  Future<void> _chooseCurrency(bool transaction) async {
    final current = transaction ? _transactionCurrency : _homeCurrency;
    final result = await showCurrencyPickerPage(
      context: context,
      title: transaction
          ? AppLocalizations.of(context).currencyLocal
          : AppLocalizations.of(context).currencyHome,
      selected: current,
    );
    if (result?.currency case final selected?) {
      if (!mounted) return;
      setState(() {
        if (transaction) {
          _transactionCurrency = selected;
        } else {
          _homeCurrency = selected;
          _paymentMethodId = null;
        }
        _activeRateSnapshot = null;
      });
      _scheduleRecalculation(immediate: true);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showPreciseDateTimePickerSheet(
      context: context,
      initial: _occurredAt.toLocal(),
      title: AppLocalizations.of(context).expenseDate,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _occurredAt = selected.toUtc();
      _activeRateSnapshot = null;
    });
    _scheduleRecalculation(immediate: true);
  }

  Future<void> _chooseReceiptImage() async {
    try {
      final relativePath = await importReceiptFromPhotoLibrary(
        picker:
            widget.receiptImagePicker ??
            DeviceScannerImagePicker(permissionGateway: _permissionGateway),
        storage: ref.read(receiptStorageProvider),
      );
      if (relativePath == null) return;
      if (!mounted) return;
      _receiptPath.text = relativePath;
      await _resolveReceiptPreview(relativePath);
    } on SystemPermissionUnavailable catch (error) {
      if (!mounted) return;
      await showSystemPermissionUnavailableAlert(
        context: context,
        error: error,
        gateway: _permissionGateway,
      );
    } on Object {
      if (mounted) {
        _showValidationToast(AppLocalizations.of(context).expenseInvalid);
      }
    }
  }

  Future<void> _resolveReceiptPreview(String reference) async {
    final generation = ++_receiptGeneration;
    if (mounted) setState(() => _isResolvingReceipt = true);
    final lookup = await ref.read(receiptStorageProvider).resolve(reference);
    if (!mounted || generation != _receiptGeneration) return;
    setState(() {
      _receiptFile = lookup.file;
      _isResolvingReceipt = false;
    });
  }

  Future<void> _removeReceipt() async {
    final reference = _receiptPath.text;
    ++_receiptGeneration;
    setState(() {
      _receiptPath.clear();
      _receiptFile = null;
      _isResolvingReceipt = false;
    });
    if (reference.isNotEmpty) {
      try {
        await ref.read(receiptStorageProvider).delete(reference);
      } on Object {
        // The record is already detached; cleanup can be retried by data reset.
      }
    }
  }

  void _scheduleRecalculation({bool immediate = false}) {
    _calculationDebounce?.cancel();
    if (!mounted) return;
    if (immediate) {
      unawaited(_recalculateCosts());
      return;
    }
    _calculationDebounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_recalculateCosts()),
    );
  }

  Future<void> _recalculateCosts() async {
    final generation = ++_calculationGeneration;
    try {
      final transaction = Money.parse(
        _transactionAmount.text.trim(),
        _transactionCurrency,
      );
      if (transaction.amount.compareTo(DecimalValue.zero) <= 0) {
        throw const FormatException('Amount must be positive.');
      }
      if (mounted) {
        setState(() {
          _isCalculating = true;
          _calculationUnavailable = false;
        });
      }
      var snapshot = _activeRateSnapshot;
      if (snapshot == null ||
          snapshot.baseCurrency != _transactionCurrency ||
          snapshot.quoteCurrency != _homeCurrency) {
        final resolution = await ref
            .read(rateRepositoryProvider)
            .resolveRate(
              baseCurrency: _transactionCurrency,
              quoteCurrency: _homeCurrency,
              date: _occurredAt,
            );
        snapshot = resolution.snapshot;
      }
      if (!mounted || generation != _calculationGeneration) return;
      if (snapshot == null) {
        setState(() {
          _isCalculating = false;
          _calculationUnavailable = true;
          _referenceAmount.clear();
          _estimatedAmount.clear();
        });
        return;
      }
      _activeRateSnapshot = snapshot;
      final selectedMethod = _availableMethods
          .where(
            (item) =>
                item.metadata.recordId == _paymentMethodId &&
                item.billingCurrency == _homeCurrency,
          )
          .firstOrNull;
      final breakdown = const PaymentCostEngine().calculate(
        transactionAmount: transaction,
        rateSnapshot: snapshot,
        paymentRule:
            selectedMethod?.freezeRules() ?? _manualRule(_homeCurrency),
      );
      final finalAmount = calculateEstimatedFinalAmount(
        baseAmount: breakdown.estimatedCost,
        taxAmount: Money.parse(_tax.text.trim(), _homeCurrency),
        tipAmount: Money.parse(_tip.text.trim(), _homeCurrency),
        discountAmount: Money.parse(_discount.text.trim(), _homeCurrency),
      );
      final previousAutomaticActual = _lastAutomaticActual;
      _referenceAmount.text = breakdown.referenceAmount.amount.toString();
      _estimatedAmount.text = finalAmount.amount.toString();
      if (_status == ExpenseStatus.confirmed &&
          (_actualAmount.text.trim().isEmpty ||
              _actualAmount.text == previousAutomaticActual)) {
        _actualAmount.text = _estimatedAmount.text;
        _lastAutomaticActual = _actualAmount.text;
      }
      setState(() {
        _isCalculating = false;
        _calculationUnavailable = false;
      });
    } on FormatException {
      if (!mounted || generation != _calculationGeneration) return;
      setState(() {
        _isCalculating = false;
        _calculationUnavailable = false;
        _referenceAmount.clear();
        _estimatedAmount.clear();
      });
    } on Object {
      if (!mounted || generation != _calculationGeneration) return;
      setState(() {
        _isCalculating = false;
        _calculationUnavailable = true;
      });
    }
  }

  Future<void> _save(List<PaymentMethodModel> methods) async {
    if (_isSaving) return;
    _dismissKeyboard();
    if (_title.text.trim().isEmpty || _transactionAmount.text.trim().isEmpty) {
      _showValidationToast(AppLocalizations.of(context).expenseMissingRequired);
      return;
    }
    _calculationDebounce?.cancel();
    setState(() => _isSaving = true);
    try {
      await _recalculateCosts();
      if (!mounted) return;
      final now = DateTime.now().toUtc();
      final transaction = Money.parse(
        _transactionAmount.text.trim(),
        _transactionCurrency,
      );
      final reference = Money.parse(
        _referenceAmount.text.trim(),
        _homeCurrency,
      );
      final estimated = Money.parse(
        _estimatedAmount.text.trim(),
        _homeCurrency,
      );
      final actual = _status == ExpenseStatus.confirmed
          ? Money.parse(_actualAmount.text.trim(), _homeCurrency)
          : null;
      if (transaction.amount.compareTo(DecimalValue.zero) <= 0 ||
          reference.amount.compareTo(DecimalValue.zero) <= 0 ||
          estimated.amount.compareTo(DecimalValue.zero) <= 0 ||
          (actual != null && actual.amount.compareTo(DecimalValue.zero) <= 0)) {
        throw const FormatException('Amounts must be positive.');
      }
      final selectedMethod = methods
          .where((item) => item.metadata.recordId == _paymentMethodId)
          .firstOrNull;
      final rate = reference.amount.divide(transaction.amount);
      final seedSnapshot = _seed?.rateSnapshot;
      final rateSnapshot =
          (seedSnapshot != null &&
              canReuseSeedRateSnapshot(
                seed: _seed!,
                transactionAmount: transaction,
                referenceAmount: reference,
              ))
          ? seedSnapshot
          : _copyRateSnapshotForExpense(
              source: _activeRateSnapshot,
              fallbackRate: rate,
              now: now,
            );
      final seedRule = _seed?.breakdown.paymentRule;
      final reuseSeedRule =
          seedRule != null &&
          canReuseSeedPaymentRule(
            seed: _seed!,
            paymentMethodId: _paymentMethodId,
            billingCurrencyCode: _homeCurrency.code,
          );
      final paymentRule = reuseSeedRule
          ? seedRule
          : selectedMethod?.freezeRules() ?? _manualRule(_homeCurrency);
      final expense = ExpenseModel(
        metadata: SyncRecordMetadata(
          recordId: const Uuid().v4(),
          syncVersion: 1,
          updatedAt: now,
        ),
        tripId: _tripId,
        title: _title.text.trim(),
        category: _category,
        transactionAmount: transaction,
        referenceAmount: reference,
        estimatedFinalAmount: estimated,
        actualFinalAmount: actual,
        paymentMethodId:
            selectedMethod?.metadata.recordId ??
            (reuseSeedRule ? _paymentMethodId : null),
        paymentRuleSnapshot: paymentRule,
        rateSnapshot: rateSnapshot,
        taxAmount: Money.parse(_tax.text.trim(), _homeCurrency),
        tipAmount: Money.parse(_tip.text.trim(), _homeCurrency),
        discountAmount: Money.parse(_discount.text.trim(), _homeCurrency),
        participantCount: int.parse(_participants.text.trim()),
        occurredAt: _occurredAt,
        receiptLocalPath: _emptyToNull(_receiptPath.text),
        notes: _emptyToNull(_notes.text),
        budgetIncluded: _budgetIncluded,
        status: _status,
        createdAt: now,
      );
      final duplicate = ref
          .read(expensesControllerProvider.notifier)
          .possibleDuplicate(expense);
      if (duplicate != null && mounted) {
        final proceed = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(AppLocalizations.of(context).expenseDuplicateTitle),
            content: Text(AppLocalizations.of(context).expenseDuplicateMessage),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).commonCancel),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context).expenseSaveAnyway),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
      final controller = ref.read(expensesControllerProvider.notifier);
      if (expense.actualFinalAmount == null) {
        await controller.save(expense);
      } else {
        await controller.saveConfirmed(expense);
      }
      ref.invalidate(tripsControllerProvider);
      if (mounted) context.pop(true);
    } on Object {
      if (mounted) {
        _showValidationToast(AppLocalizations.of(context).expenseInvalid);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  RateSnapshotModel _copyRateSnapshotForExpense({
    required RateSnapshotModel? source,
    required DecimalValue fallbackRate,
    required DateTime now,
  }) {
    return RateSnapshotModel(
      metadata: SyncRecordMetadata(
        recordId: const Uuid().v4(),
        syncVersion: 1,
        updatedAt: now,
      ),
      baseCurrency: _transactionCurrency,
      quoteCurrency: _homeCurrency,
      rate: source?.rate ?? fallbackRate,
      sourceType: source?.sourceType ?? RateSourceType.manual,
      sourceName: source?.sourceName ?? 'manual',
      sourceTimestamp: source?.sourceTimestamp ?? _occurredAt,
      fetchedAt: source?.fetchedAt ?? now,
      isCached: source?.isCached ?? true,
    );
  }

  void _changeStatus(ExpenseStatus value) {
    setState(() {
      _status = value;
      if (value == ExpenseStatus.confirmed &&
          _actualAmount.text.trim().isEmpty) {
        _actualAmount.text = _estimatedAmount.text.trim();
        _lastAutomaticActual = _actualAmount.text;
      }
    });
  }

  String _formattedAmount(String source) {
    if (source.trim().isEmpty) return '${_homeCurrency.code} —';
    try {
      final money = Money.parse(source.trim(), _homeCurrency);
      final formatted = const MoneyFormatter().format(
        money,
        locale: Localizations.localeOf(context).toLanguageTag(),
        includeSymbol: false,
      );
      return '${_homeCurrency.code} $formatted';
    } on FormatException {
      return '${_homeCurrency.code} —';
    }
  }

  String _adjustmentSummary(AppLocalizations l10n) {
    String shortLabel(String value) =>
        value.split('（').first.split(' in ').first;
    return '${shortLabel(l10n.expenseTax)} ${_tax.text} · '
        '${shortLabel(l10n.expenseTip)} ${_tip.text} · '
        '${shortLabel(l10n.expenseDiscount)} ${_discount.text} · '
        '${_participants.text} ${l10n.tripParticipants}';
  }

  void _showValidationToast(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    AppToast.show(
      context,
      message,
      key: const Key('expense-validation-toast'),
      style: AppToastStyle.error,
    );
  }

  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  bool _canMoveFocus({required bool forward}) {
    final nodes = _focusOrder.where((node) => node.context != null).toList();
    final current = nodes.indexWhere((node) => node.hasFocus);
    if (current < 0) return false;
    return forward ? current < nodes.length - 1 : current > 0;
  }

  void _moveFocus({required bool forward}) {
    final nodes = _focusOrder.where((node) => node.context != null).toList();
    final current = nodes.indexWhere((node) => node.hasFocus);
    if (current < 0) return;
    final target = forward ? current + 1 : current - 1;
    if (target < 0 || target >= nodes.length) return;
    nodes[target].requestFocus();
  }
}

enum _ExpenseContextField { trip, category }

class _ExpenseContextSelection {
  const _ExpenseContextSelection({
    required this.tripId,
    required this.category,
  });

  final String? tripId;
  final String category;
}

class _ExpenseContextPickerSheet extends StatefulWidget {
  const _ExpenseContextPickerSheet({
    required this.trips,
    required this.initialTripId,
    required this.initialCategory,
  });

  final List<TripModel> trips;
  final String? initialTripId;
  final String initialCategory;

  @override
  State<_ExpenseContextPickerSheet> createState() =>
      _ExpenseContextPickerSheetState();
}

class _ExpenseContextPickerSheetState
    extends State<_ExpenseContextPickerSheet> {
  _ExpenseContextField _activeField = _ExpenseContextField.category;
  late String? _tripId;
  late String _category = widget.initialCategory;

  @override
  void initState() {
    super.initState();
    _tripId =
        widget.trips.any(
          (trip) => trip.metadata.recordId == widget.initialTripId,
        )
        ? widget.initialTripId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final preferredSheetHeight = (mediaQuery.size.height * 0.57)
        .clamp(480.0, 560.0)
        .toDouble();
    final availableSheetHeight =
        mediaQuery.size.height - mediaQuery.padding.top;
    final sheetHeight = preferredSheetHeight
        .clamp(0.0, availableSheetHeight)
        .toDouble();
    final selectedTrip = widget.trips
        .where((trip) => trip.metadata.recordId == _tripId)
        .firstOrNull;
    final tripLabel = selectedTrip?.name ?? l10n.commonNone;
    final categoryLabel = _categoryLabel(l10n, _category);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        key: const Key('expense-context-picker-sheet'),
        height: sheetHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemFill.resolveFrom(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 75,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            l10n.expenseEditorTripCategory,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$tripLabel · $categoryLabel',
                            key: const Key('expense-context-picker-summary'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      PositionedDirectional(
                        end: 14,
                        top: 15,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: CupertinoButton(
                            key: const Key('expense-context-picker-close'),
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: CupertinoColors.secondarySystemFill
                                    .resolveFrom(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 18,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: 118,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemBackground
                                .resolveFrom(context),
                          ),
                          child: Column(
                            children: <Widget>[
                              _ExpenseContextFieldButton(
                                buttonKey: const Key(
                                  'expense-context-picker-trip-tab',
                                ),
                                label: l10n.expenseTrip,
                                value: tripLabel,
                                selected:
                                    _activeField == _ExpenseContextField.trip,
                                onPressed: () => setState(
                                  () =>
                                      _activeField = _ExpenseContextField.trip,
                                ),
                              ),
                              _ExpenseContextFieldButton(
                                buttonKey: const Key(
                                  'expense-context-picker-category-tab',
                                ),
                                label: l10n.expenseCategory,
                                value: categoryLabel,
                                selected:
                                    _activeField ==
                                    _ExpenseContextField.category,
                                onPressed: () => setState(
                                  () => _activeField =
                                      _ExpenseContextField.category,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      Expanded(
                        child: _activeField == _ExpenseContextField.trip
                            ? ListView(
                                key: const Key(
                                  'expense-context-picker-trip-list',
                                ),
                                padding: EdgeInsets.zero,
                                children: <Widget>[
                                  _ExpenseContextOptionRow(
                                    rowKey: const Key(
                                      'expense-context-picker-trip-none',
                                    ),
                                    label: l10n.commonNone,
                                    selected: _tripId == null,
                                    onPressed: () =>
                                        setState(() => _tripId = null),
                                  ),
                                  for (final trip in widget.trips)
                                    _ExpenseContextOptionRow(
                                      rowKey: Key(
                                        'expense-context-picker-trip-${trip.metadata.recordId}',
                                      ),
                                      label: trip.name,
                                      selected:
                                          _tripId == trip.metadata.recordId,
                                      onPressed: () => setState(
                                        () => _tripId = trip.metadata.recordId,
                                      ),
                                    ),
                                ],
                              )
                            : ListView(
                                key: const Key(
                                  'expense-context-picker-category-list',
                                ),
                                padding: EdgeInsets.zero,
                                children: <Widget>[
                                  for (final category in _categories)
                                    _ExpenseContextOptionRow(
                                      rowKey: Key(
                                        'expense-context-picker-category-$category',
                                      ),
                                      label: _categoryLabel(l10n, category),
                                      icon: _contextPickerCategoryIcon(
                                        category,
                                      ),
                                      iconColor: _categoryColor(category),
                                      selected: _category == category,
                                      onPressed: () =>
                                          setState(() => _category = category),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + mediaQuery.padding.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CupertinoButton(
                      key: const Key('expense-context-picker-done'),
                      padding: EdgeInsets.zero,
                      color: AppColors.primary.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.of(context).pop(
                        _ExpenseContextSelection(
                          tripId: _tripId,
                          category: _category,
                        ),
                      ),
                      child: Text(
                        l10n.commonDone,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseContextFieldButton extends StatelessWidget {
  const _ExpenseContextFieldButton({
    required this.buttonKey,
    required this.label,
    required this.value,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    final labelColor = selected
        ? primary
        : CupertinoColors.label.resolveFrom(context);
    final valueColor = selected
        ? primary
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoButton(
      key: buttonKey,
      minimumSize: const Size.fromHeight(76),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 76,
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.1) : null,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Stack(
          children: <Widget>[
            if (selected)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: valueColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseContextOptionRow extends StatelessWidget {
  const _ExpenseContextOptionRow({
    required this.rowKey,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    this.iconColor,
  });

  final Key rowKey;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    return CupertinoButton(
      key: rowKey,
      minimumSize: const Size.fromHeight(50),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            if (icon case final iconData?) ...<Widget>[
              SizedBox(
                width: 30,
                child: Icon(iconData, size: 23, color: iconColor),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? primary
                      : CupertinoColors.label.resolveFrom(context),
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              Icon(CupertinoIcons.check_mark, size: 20, color: primary),
          ],
        ),
      ),
    );
  }
}

class _OcrPrefillBanner extends StatelessWidget {
  const _OcrPrefillBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('expense-ocr-prefill-banner'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          CupertinoIcons.doc_text_viewfinder,
          color: AppColors.primary,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExpenseEditorSection extends StatelessWidget {
  const _ExpenseEditorSection({
    required this.label,
    required this.children,
    this.footer,
    super.key,
  });

  final String label;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, bottom: 8),
        child: Text(
          label,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 15,
          ),
        ),
      ),
      _ExpenseEditorGroup(children: children),
      if (footer != null)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: footer,
        ),
    ],
  );
}

class _ExpenseEditorGroup extends StatelessWidget {
  const _ExpenseEditorGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border.all(color: separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            for (var index = 0; index < children.length; index++) ...<Widget>[
              if (index > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: SizedBox(
                    height: 0.5,
                    child: ColoredBox(color: separator),
                  ),
                ),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseEditorActionRow extends StatelessWidget {
  const _ExpenseEditorActionRow({
    this.rowKey,
    required this.label,
    required this.value,
    required this.onPressed,
    this.expanded = false,
  });

  final Key? rowKey;
  final String label;
  final String value;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: rowKey,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    minimumSize: const Size.fromHeight(48),
    onPressed: onPressed,
    child: Row(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Icon(
          expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_forward,
          size: 15,
          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
        ),
      ],
    ),
  );
}

class _ExpenseEditorTextRow extends StatelessWidget {
  const _ExpenseEditorTextRow({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.textInputAction,
    required this.onSubmitted,
    this.numeric = false,
    this.maxLines = 1,
    this.placeholder,
    this.confirmationLabel,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;
  final bool numeric;
  final int maxLines;
  final String? placeholder;
  final String? confirmationLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 7 : 0),
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Stack(
            children: <Widget>[
              CupertinoTextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                maxLines: maxLines,
                minLines: maxLines,
                placeholder: placeholder,
                textAlign: maxLines > 1 ? TextAlign.start : TextAlign.end,
                keyboardType: numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                padding: EdgeInsets.fromLTRB(
                  10,
                  8,
                  10,
                  confirmationLabel == null ? 8 : 24,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              if (confirmationLabel case final confirmation?)
                PositionedDirectional(
                  end: 10,
                  bottom: 5,
                  child: IgnorePointer(
                    child: Text(
                      confirmation,
                      style: TextStyle(
                        color: CupertinoColors.systemOrange.resolveFrom(
                          context,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExpenseAmountInputRow extends StatelessWidget {
  const _ExpenseAmountInputRow({
    required this.fieldKey,
    required this.currencyKey,
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    required this.currencyCode,
    required this.onChooseCurrency,
    required this.onSubmitted,
  });

  final Key fieldKey;
  final Key currencyKey;
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String currencyCode;
  final VoidCallback onChooseCurrency;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
    child: Row(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            placeholder: placeholder,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onSubmitted: onSubmitted,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        CupertinoButton(
          key: currencyKey,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          minimumSize: Size.zero,
          onPressed: onChooseCurrency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(currencyCode, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.chevron_down, size: 14),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExpenseMoneyResultRow extends StatelessWidget {
  const _ExpenseMoneyResultRow({
    required this.rowKey,
    required this.label,
    required this.value,
    this.loading = false,
    this.emphasized = false,
  });

  final Key rowKey;
  final String label;
  final String value;
  final bool loading;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    key: rowKey,
    constraints: const BoxConstraints(minHeight: 48),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        if (loading)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 10),
            child: CupertinoActivityIndicator(radius: 8),
          ),
        Text(
          value,
          style: TextStyle(
            color: emphasized
                ? AppColors.primary
                : CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 16,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

class _ExpenseStatusRow extends StatelessWidget {
  const _ExpenseStatusRow({
    required this.value,
    required this.pendingLabel,
    required this.confirmedLabel,
    required this.onChanged,
  });

  final ExpenseStatus value;
  final String pendingLabel;
  final String confirmedLabel;
  final ValueChanged<ExpenseStatus> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Row(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(
            AppLocalizations.of(context).expenseAmountStatus,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: CupertinoSlidingSegmentedControl<ExpenseStatus>(
            key: const Key('expense-amount-status'),
            groupValue: value,
            children: <ExpenseStatus, Widget>{
              ExpenseStatus.estimated: Text(pendingLabel),
              ExpenseStatus.confirmed: Text(confirmedLabel),
            },
            onValueChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ],
    ),
  );
}

class _ExpenseReceiptThumbnail extends StatelessWidget {
  const _ExpenseReceiptThumbnail({
    required this.file,
    required this.removeLabel,
    required this.onRemove,
  });

  final File file;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('expense-receipt-thumbnail'),
    height: 136,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: CupertinoColors.secondarySystemFill.resolveFrom(context),
              child: const Center(child: Icon(CupertinoIcons.photo, size: 36)),
            ),
          ),
        ),
        PositionedDirectional(
          top: 7,
          end: 7,
          child: Semantics(
            button: true,
            label: removeLabel,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(30),
              color: const Color(0xBFFFFFFF),
              borderRadius: BorderRadius.circular(15),
              onPressed: onRemove,
              child: const Icon(
                CupertinoIcons.xmark,
                color: CupertinoColors.black,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExpenseReceiptAddTile extends StatelessWidget {
  const _ExpenseReceiptAddTile({
    required this.label,
    required this.compact,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? 104 : null,
    height: 136,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(CupertinoIcons.camera, size: 30),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ExpenseBudgetRow extends StatelessWidget {
  const _ExpenseBudgetRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

Future<String?> importReceiptFromPhotoLibrary({
  required ScannerImagePicker picker,
  required ReceiptStorage storage,
}) async {
  final sourcePath = await picker.pick(ScannerImageSource.photoLibrary);
  return sourcePath == null ? null : storage.importImage(File(sourcePath));
}

class ExpenseDetailPage extends ConsumerWidget {
  const ExpenseDetailPage({required this.expenseId, this.initial, super.key});
  final String expenseId;
  final ExpenseModel? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allExpenses =
        ref.watch(expensesControllerProvider).value ?? const <ExpenseModel>[];
    final expense =
        allExpenses
            .where((item) => item.metadata.recordId == expenseId)
            .firstOrNull ??
        initial;
    if (expense == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(l10n.ledgerTitle)),
        child: Center(child: Text(l10n.expenseMissing)),
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = const MoneyFormatter();
    String money(Money value) =>
        formatter.format(value, locale: locale, includeCode: true);
    final actual = expense.actualFinalAmount;
    final difference = actual == null
        ? null
        : const ExpenseCalibrationCalculator().difference(
            estimatedAmount: expense.estimatedFinalAmount,
            actualFinalAmount: actual,
          );
    final differencePercent = actual == null
        ? null
        : const ExpenseCalibrationCalculator().differencePercent(
            estimatedAmount: expense.estimatedFinalAmount,
            actualFinalAmount: actual,
          );
    final calibration =
        expense.entryType != ExpenseEntryType.purchase ||
            expense.paymentMethodId == null
        ? null
        : ref.watch(calibrationSummaryProvider(expense.paymentMethodId!));
    final relatedOriginal = expense.relatedExpenseId == null
        ? null
        : allExpenses
              .where(
                (item) =>
                    item.metadata.recordId == expense.relatedExpenseId &&
                    item.entryType == ExpenseEntryType.purchase,
              )
              .firstOrNull;
    final adjustmentSummary = expense.entryType == ExpenseEntryType.purchase
        ? ExpenseAdjustmentSummary.from(
            original: expense,
            expenses: allExpenses,
          )
        : null;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(expense.title)),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _DetailRow(
              label: l10n.expenseTransactionAmount,
              value: money(expense.transactionAmount),
            ),
            _DetailRow(
              label: l10n.expenseReferenceAmount,
              value: money(expense.referenceAmount),
            ),
            _DetailRow(
              label: l10n.expenseEstimatedAmount,
              value: money(expense.estimatedFinalAmount),
            ),
            _DetailRow(
              label: l10n.expenseActualAmount,
              value: actual == null ? l10n.commonNone : money(actual),
            ),
            if (difference != null)
              _DetailRow(
                label: l10n.expenseDifference,
                value:
                    '${money(difference)} · ${differencePercent!.toFixed(2)}%',
              ),
            _DetailRow(
              label: l10n.expenseRateSnapshot,
              value:
                  '${expense.rateSnapshot.rate} · ${_rateSourceName(l10n, expense.rateSnapshot.sourceName)}',
            ),
            _DetailRow(
              label: l10n.expensePaymentSnapshot,
              value: _paymentRuleName(l10n, expense.paymentRuleSnapshot.name),
            ),
            _DetailRow(
              label: l10n.expenseStatus,
              value: _entryLabel(l10n, expense),
            ),
            if (adjustmentSummary?.hasRefunds ?? false) ...<Widget>[
              _DetailRow(
                label: l10n.expenseRefundStatus,
                value: _refundStateLabel(l10n, adjustmentSummary!.refundState),
              ),
              _DetailRow(
                label: l10n.expenseRefundedTotal,
                value: money(
                  Money(
                    amount: -adjustmentSummary.refundedAmount,
                    currency: expense.referenceAmount.currency,
                  ),
                ),
              ),
              if (adjustmentSummary.netAmount != null)
                _DetailRow(
                  label: l10n.expenseNetAmount,
                  value: money(
                    Money(
                      amount: adjustmentSummary.netAmount!,
                      currency: expense.referenceAmount.currency,
                    ),
                  ),
                ),
            ],
            if (relatedOriginal != null)
              _DetailRow(
                label: l10n.expenseRelatedOriginal,
                value: relatedOriginal.title,
              ),
            if (expense.metadata.syncState == SyncState.conflict)
              Text(
                l10n.expenseActualConflict,
                style: const TextStyle(color: CupertinoColors.systemOrange),
              ),
            if (calibration != null)
              calibration.when(
                loading: () => const CupertinoActivityIndicator(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (summary) => Text(
                  summary.count == 0
                      ? l10n.calibrationNone
                      : summary.canSuggestRuleUpdate
                      ? l10n.calibrationRangeReady(
                          summary.count,
                          summary.minimumMarkupPercent!.toFixed(2),
                          summary.maximumMarkupPercent!.toFixed(2),
                        )
                      : l10n.calibrationRange(
                          summary.count,
                          summary.minimumMarkupPercent!.toFixed(2),
                          summary.maximumMarkupPercent!.toFixed(2),
                        ),
                ),
              ),
            if (adjustmentSummary?.refunds.isNotEmpty ?? false) ...<Widget>[
              const SizedBox(height: AppSpacing.medium),
              Text(
                l10n.expenseRefundRecords,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              for (final refund in adjustmentSummary!.refunds)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onPressed: () => context.push(
                    AppRoutes.expenseDetail(refund.metadata.recordId),
                    extra: refund,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(_entryLabel(l10n, refund))),
                      Text(
                        money(
                          refund.actualFinalAmount ??
                              refund.estimatedFinalAmount,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(CupertinoIcons.chevron_forward, size: 16),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.large),
            if (adjustmentSummary?.canRecordActual ?? false)
              CupertinoButton.filled(
                onPressed: () => _recordActual(
                  context,
                  ref,
                  expense,
                  correction: false,
                  hasRefunds: false,
                ),
                child: Text(l10n.expenseRecordActual),
              )
            else if (adjustmentSummary?.canEditActual ?? false)
              CupertinoButton(
                onPressed: () => _recordActual(
                  context,
                  ref,
                  expense,
                  correction: true,
                  hasRefunds: false,
                ),
                child: Text(l10n.expenseEditActual),
              ),
            if (adjustmentSummary?.canCorrectActual ?? false)
              CupertinoButton(
                onPressed: () => _recordActual(
                  context,
                  ref,
                  expense,
                  correction: true,
                  hasRefunds: true,
                ),
                child: Text(l10n.expenseCorrectOriginal),
              ),
            if (adjustmentSummary?.canRefund ?? false)
              CupertinoButton(
                onPressed: () => _recordRefund(context, ref, expense),
                child: Text(
                  adjustmentSummary!.hasRefunds
                      ? l10n.expenseContinueRefund
                      : l10n.expenseRecordRefund,
                ),
              ),
            if (adjustmentSummary?.canVoid ?? false)
              CupertinoButton(
                onPressed: () => _voidExpense(context, ref, expense),
                child: Text(
                  l10n.expenseVoidAction,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
              ),
            if ((expense.entryType == ExpenseEntryType.refund ||
                    expense.entryType == ExpenseEntryType.partialRefund) &&
                relatedOriginal != null) ...<Widget>[
              CupertinoButton(
                onPressed: () =>
                    _correctRefund(context, ref, expense, relatedOriginal),
                child: Text(l10n.expenseCorrectRefund),
              ),
              CupertinoButton(
                onPressed: () => context.push(
                  AppRoutes.expenseDetail(relatedOriginal.metadata.recordId),
                  extra: relatedOriginal,
                ),
                child: Text(l10n.expenseViewOriginal),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _recordActual(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense, {
    required bool correction,
    required bool hasRefunds,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (hasRefunds) {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.expenseCorrectOriginal),
          content: Text(l10n.expenseCorrectionWarning),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final controller = TextEditingController(
      text:
          expense.actualFinalAmount?.amount.toString() ??
          expense.estimatedFinalAmount.amount.toString(),
    );
    final amount = await _amountDialog(
      context,
      title: correction
          ? hasRefunds
                ? l10n.expenseCorrectOriginal
                : l10n.expenseEditActual
          : l10n.expenseRecordActual,
      controller: controller,
    );
    controller.dispose();
    if (amount != null) {
      try {
        await ref
            .read(expensesControllerProvider.notifier)
            .recordActual(
              expense,
              Money(amount: amount, currency: expense.referenceAmount.currency),
            );
      } on FormatException {
        if (context.mounted) await _showAdjustmentError(context);
      }
    }
  }

  Future<void> _recordRefund(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) async {
    final l10n = AppLocalizations.of(context);
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('refund'),
            child: Text(l10n.expenseRefund),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('partial'),
            child: Text(l10n.expensePartialRefund),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    try {
      if (action == 'refund') {
        await ref
            .read(expensesControllerProvider.notifier)
            .createRefund(
              original: expense,
              homeAmount: expense.actualFinalAmount!,
              partial: false,
            );
        return;
      }
      final controller = TextEditingController();
      final amount = await _amountDialog(
        context,
        title: l10n.expensePartialRefund,
        controller: controller,
      );
      controller.dispose();
      if (amount != null) {
        await ref
            .read(expensesControllerProvider.notifier)
            .createRefund(
              original: expense,
              homeAmount: Money(
                amount: amount,
                currency: expense.referenceAmount.currency,
              ),
              partial: true,
            );
      }
    } on FormatException {
      if (context.mounted) await _showAdjustmentError(context);
    }
  }

  Future<void> _voidExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.expenseVoidAction),
        content: Text(l10n.expenseVoidConfirm),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.expenseVoidAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(expensesControllerProvider.notifier).voidExpense(expense);
    } on FormatException {
      if (context.mounted) await _showAdjustmentError(context);
    }
  }

  Future<void> _correctRefund(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel refund,
    ExpenseModel original,
  ) async {
    final controller = TextEditingController(
      text: (refund.actualFinalAmount ?? refund.estimatedFinalAmount).amount
          .abs()
          .toString(),
    );
    final amount = await _amountDialog(
      context,
      title: AppLocalizations.of(context).expenseCorrectRefund,
      controller: controller,
    );
    controller.dispose();
    if (amount == null) return;
    try {
      await ref
          .read(expensesControllerProvider.notifier)
          .correctRefund(
            refund: refund,
            homeAmount: Money(
              amount: amount,
              currency: original.referenceAmount.currency,
            ),
          );
    } on FormatException {
      if (context.mounted) await _showAdjustmentError(context);
    }
  }

  Future<void> _showAdjustmentError(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(l10n.expenseAdjustmentInvalid),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonDone),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries, required this.trips});
  final List<_TimelineEntry> entries;
  final List<TripModel> trips;

  @override
  Widget build(BuildContext context) {
    final tripNames = <String, String>{
      for (final trip in trips) trip.metadata.recordId: trip.name,
    };
    return ListView.builder(
      key: const Key('ledger-timeline-list'),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return switch (entries[index]) {
          _TimelineDayEntry(:final day, :final items) => _TimelineDayHeader(
            day: day,
            items: items,
          ),
          _TimelineExpenseEntry(:final expense) => _ExpenseTile(
            expense: expense,
            tripName: expense.tripId == null ? null : tripNames[expense.tripId],
          ),
        };
      },
    );
  }
}

final class _LedgerDerivedData {
  const _LedgerDerivedData({
    required this.items,
    required this.summaryCurrency,
    required this.timelineEntries,
  });

  final List<ExpenseModel> items;
  final Currency summaryCurrency;
  final List<_TimelineEntry> timelineEntries;
}

sealed class _TimelineEntry {
  const _TimelineEntry();
}

final class _TimelineDayEntry extends _TimelineEntry {
  const _TimelineDayEntry({required this.day, required this.items});

  final DateTime day;
  final List<ExpenseModel> items;
}

final class _TimelineExpenseEntry extends _TimelineEntry {
  const _TimelineExpenseEntry(this.expense);

  final ExpenseModel expense;
}

List<_TimelineEntry> _buildTimelineEntries(List<ExpenseModel> items) {
  final groups = <DateTime, List<ExpenseModel>>{};
  for (final item in items) {
    final local = item.occurredAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    groups.putIfAbsent(day, () => <ExpenseModel>[]).add(item);
  }
  return List<_TimelineEntry>.unmodifiable(<_TimelineEntry>[
    for (final group in groups.entries) ...<_TimelineEntry>[
      _TimelineDayEntry(
        day: group.key,
        items: List<ExpenseModel>.unmodifiable(group.value),
      ),
      for (final item in group.value) _TimelineExpenseEntry(item),
    ],
  ]);
}

class _TimelineDayHeader extends StatelessWidget {
  const _TimelineDayHeader({required this.day, required this.items});

  final DateTime day;
  final List<ExpenseModel> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = DateFormat.MMMd(locale).format(day);
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final amounts = <String, Money>{};
    for (final item in items) {
      if (item.entryType == ExpenseEntryType.voided) continue;
      final amount = item.actualFinalAmount ?? item.estimatedFinalAmount;
      amounts.update(
        amount.currency.code,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }
    final total = amounts.length == 1
        ? const MoneyFormatter().format(amounts.values.single, locale: locale)
        : l10n.ledgerDayCount(items.length);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 9),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              isToday ? l10n.ledgerToday(formattedDate) : formattedDate,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            total,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.items});
  final List<ExpenseModel> items;
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<ExpenseModel>>{};
    for (final item in items) {
      final key = DateFormat.yMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(item.occurredAt.toLocal());
      groups.putIfAbsent(key, () => <ExpenseModel>[]).add(item);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: <Widget>[
        for (final group in groups.entries) ...<Widget>[
          Text(group.key, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final item in group.value) _ExpenseTile(expense: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.items});
  final List<ExpenseModel> items;
  @override
  Widget build(BuildContext context) {
    final totals = ledgerCategoryTotals(items);
    final formatter = const MoneyFormatter();
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: <Widget>[
        for (final entry in totals.entries)
          CupertinoListTile(
            title: Text(
              '${_categoryLabel(AppLocalizations.of(context), entry.key.split('|').first)} · '
              '${entry.value.currency.code}',
            ),
            trailing: Text(
              formatter.format(entry.value, locale: locale, includeCode: true),
            ),
          ),
      ],
    );
  }
}

Map<String, Money> ledgerCategoryTotals(Iterable<ExpenseModel> items) {
  final totals = <String, Money>{};
  for (final item in items) {
    if (!item.budgetIncluded || item.entryType == ExpenseEntryType.voided) {
      continue;
    }
    final amount = item.actualFinalAmount ?? item.estimatedFinalAmount;
    final key = '${item.category}|${amount.currency.code}';
    totals.update(key, (value) => value + amount, ifAbsent: () => amount);
  }
  return Map<String, Money>.unmodifiable(totals);
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, this.tripName});
  final ExpenseModel expense;
  final String? tripName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = const MoneyFormatter();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = expense.actualFinalAmount ?? expense.estimatedFinalAmount;
    final isRefund =
        expense.entryType == ExpenseEntryType.refund ||
        expense.entryType == ExpenseEntryType.partialRefund;
    final isVoided = expense.entryType == ExpenseEntryType.voided;
    final categoryColor = _categoryColor(expense.category);
    final subtitleParts = <String>[
      if (tripName != null) tripName!,
      _categoryLabel(l10n, expense.category),
      formatter.format(
        expense.transactionAmount,
        locale: locale,
        includeSymbol: false,
        includeCode: true,
      ),
    ];
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: () => context.push(
        AppRoutes.expenseDetail(expense.metadata.recordId),
        extra: expense,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRefund
                    ? const Color(0xFFE8F7E8)
                    : categoryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRefund
                    ? CupertinoIcons.arrow_counterclockwise
                    : _categoryIcon(expense.category),
                size: 21,
                color: isRefund ? CupertinoColors.systemGreen : categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isVoided
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : CupertinoColors.label.resolveFrom(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: isVoided
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatter.format(amount, locale: locale),
                  style: TextStyle(
                    color: isRefund
                        ? CupertinoColors.systemGreen.resolveFrom(context)
                        : isVoided
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : CupertinoColors.label.resolveFrom(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _entryLabel(l10n, expense),
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(String category) => switch (category) {
  'food' => const Color(0xFFF0A400),
  'transport' => const Color(0xFF23A9A1),
  'shopping' => AppColors.primary,
  'hotel' => const Color(0xFF8155EA),
  'tickets' => const Color(0xFFDA5A78),
  _ => const Color(0xFF7B8794),
};

IconData _categoryIcon(String category) => switch (category) {
  'food' => Icons.restaurant_rounded,
  'transport' => CupertinoIcons.car_detailed,
  'shopping' => CupertinoIcons.bag,
  'hotel' => Icons.bed_rounded,
  'tickets' => CupertinoIcons.ticket,
  _ => CupertinoIcons.ellipsis_circle,
};

IconData _contextPickerCategoryIcon(String category) =>
    category == 'transport' ? CupertinoIcons.bus : _categoryIcon(category);

IconData _currencyFilterIcon(String? currencyCode) => switch (currencyCode) {
  'CNY' || 'JPY' => CupertinoIcons.money_yen_circle,
  'EUR' => CupertinoIcons.money_euro_circle,
  'GBP' => CupertinoIcons.money_pound_circle,
  _ => CupertinoIcons.money_dollar_circle,
};

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Future<DecimalValue?> _amountDialog(
  BuildContext context, {
  required String title,
  required TextEditingController controller,
}) => showCupertinoDialog<DecimalValue>(
  context: context,
  builder: (context) => CupertinoAlertDialog(
    title: Text(title),
    content: Padding(
      padding: const EdgeInsets.only(top: 10),
      child: CupertinoTextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ),
    actions: <Widget>[
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context).commonCancel),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: () {
          try {
            final value = DecimalValue.parse(controller.text.trim());
            if (value.compareTo(DecimalValue.zero) > 0) {
              Navigator.of(context).pop(value);
            }
          } on FormatException {
            return;
          }
        },
        child: Text(AppLocalizations.of(context).commonSave),
      ),
    ],
  ),
);

PaymentRuleSnapshot _manualRule(Currency home) => PaymentRuleSnapshot(
  paymentMethodId: '',
  name: 'manual',
  type: PaymentMethodType.custom,
  network: PaymentNetwork.unknown,
  billingCurrencyCode: home.code,
  foreignFeePercent: DecimalValue.zero,
  crossBorderFeePercent: DecimalValue.zero,
  rateMarkupPercent: DecimalValue.zero,
  fixedFee: DecimalValue.zero,
  cashbackPercent: DecimalValue.zero,
  minimumFee: null,
  maximumFee: null,
  cashExchangeRate: null,
  supportedTransactionTypes: const <TransactionType>{TransactionType.purchase},
);

DecimalValue? _parseOptional(String value) {
  final text = value.trim();
  return text.isEmpty ? null : DecimalValue.parse(text);
}

String? _emptyToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

const List<String> _categories = <String>[
  'food',
  'transport',
  'shopping',
  'hotel',
  'tickets',
  'other',
];
String _categoryLabel(AppLocalizations l10n, String value) => switch (value) {
  'food' => l10n.categoryFood,
  'transport' => l10n.categoryTransport,
  'shopping' => l10n.categoryShopping,
  'hotel' => l10n.categoryHotel,
  'tickets' => l10n.categoryTickets,
  _ => l10n.categoryOther,
};
String _entryLabel(AppLocalizations l10n, ExpenseModel expense) =>
    switch (expense.entryType) {
      ExpenseEntryType.purchase =>
        expense.status == ExpenseStatus.confirmed
            ? l10n.expenseConfirmed
            : l10n.expensePending,
      ExpenseEntryType.refund => l10n.expenseRefund,
      ExpenseEntryType.partialRefund => l10n.expensePartialRefund,
      ExpenseEntryType.voided => l10n.expenseVoid,
    };
String _refundStateLabel(AppLocalizations l10n, ExpenseRefundState state) =>
    switch (state) {
      ExpenseRefundState.none => l10n.expenseRefundNone,
      ExpenseRefundState.partial => l10n.expenseRefundPartialStatus,
      ExpenseRefundState.full => l10n.expenseRefundFullStatus,
      ExpenseRefundState.invalid => l10n.expenseRefundInvalidStatus,
    };
String _rateSourceName(AppLocalizations l10n, String value) =>
    value == 'manual' ? l10n.expenseManualRateSource : value;
String _paymentRuleName(AppLocalizations l10n, String value) =>
    value == 'manual' ? l10n.expenseManualPaymentRule : value;
