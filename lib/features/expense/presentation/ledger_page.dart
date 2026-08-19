import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/expenses/domain/expense_calibration.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/core/platform/system_permissions.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';
import 'package:trip_cost/shared/widgets/system_permission_alert.dart';
import 'package:uuid/uuid.dart';

enum LedgerViewMode { timeline, calendar, category }

class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  LedgerViewMode _mode = LedgerViewMode.timeline;
  LedgerFilter _filter = const LedgerFilter();

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
            _filter.isEmpty
                ? CupertinoIcons.slider_horizontal_3
                : CupertinoIcons.slider_horizontal_below_rectangle,
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
            final items = all.where(_filter.matches).toList(growable: false);
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  child: CupertinoSlidingSegmentedControl<LedgerViewMode>(
                    groupValue: _mode,
                    children: <LedgerViewMode, Widget>{
                      LedgerViewMode.timeline: Text(l10n.ledgerTimeline),
                      LedgerViewMode.calendar: Text(l10n.ledgerCalendar),
                      LedgerViewMode.category: Text(l10n.ledgerCategories),
                    },
                    onValueChanged: (value) {
                      if (value != null) setState(() => _mode = value);
                    },
                  ),
                ),
                if (!_filter.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(l10n.ledgerFilteredCount(items.length)),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              setState(() => _filter = const LedgerFilter()),
                          child: Text(l10n.ledgerClearFilters),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(l10n.ledgerEmpty))
                      : switch (_mode) {
                          LedgerViewMode.timeline => _Timeline(items: items),
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

  Future<void> _editFilters(
    List<TripModel> trips,
    List<PaymentMethodModel> methods,
  ) async {
    final result = await Navigator.of(context).push<LedgerFilter>(
      CupertinoPageRoute<LedgerFilter>(
        builder: (context) => LedgerFilterPage(
          initial: _filter,
          trips: trips,
          paymentMethods: methods,
        ),
      ),
    );
    if (result != null) setState(() => _filter = result);
  }
}

final class LedgerFilter {
  const LedgerFilter({
    this.tripId,
    this.category,
    this.currencyCode,
    this.paymentMethodId,
    this.status,
    this.from,
    this.to,
    this.minimumAmount,
    this.maximumAmount,
  });

  final String? tripId;
  final String? category;
  final String? currencyCode;
  final String? paymentMethodId;
  final ExpenseStatus? status;
  final DateTime? from;
  final DateTime? to;
  final DecimalValue? minimumAmount;
  final DecimalValue? maximumAmount;

  bool get isEmpty =>
      tripId == null &&
      category == null &&
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
        (category == null || expense.category == category) &&
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

int ledgerRecentDaySelection(LedgerFilter filter) {
  final from = filter.from;
  final to = filter.to;
  if (from == null || to == null) return 0;
  final hours = to.difference(from).inHours;
  return (hours / Duration.hoursPerDay).round();
}

class LedgerFilterPage extends StatefulWidget {
  const LedgerFilterPage({
    required this.initial,
    required this.trips,
    required this.paymentMethods,
    super.key,
  });

  final LedgerFilter initial;
  final List<TripModel> trips;
  final List<PaymentMethodModel> paymentMethods;

  @override
  State<LedgerFilterPage> createState() => _LedgerFilterPageState();
}

class _LedgerFilterPageState extends State<LedgerFilterPage> {
  late String? _tripId = widget.initial.tripId;
  late String? _category = widget.initial.category;
  late String? _currency = widget.initial.currencyCode;
  late String? _payment = widget.initial.paymentMethodId;
  late ExpenseStatus? _status = widget.initial.status;
  late int _dateRange = ledgerRecentDaySelection(widget.initial);
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.ledgerFilters),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _done,
          child: Text(l10n.commonDone),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _FilterChoice(
              label: l10n.expenseTrip,
              value: _tripName(),
              onPressed: _chooseTrip,
            ),
            _FilterChoice(
              label: l10n.expenseCategory,
              value: _category == null
                  ? l10n.commonAll
                  : _categoryLabel(l10n, _category!),
              onPressed: _chooseCategory,
            ),
            _FilterChoice(
              label: l10n.currencyLocal,
              value: _currency ?? l10n.commonAll,
              onPressed: _chooseCurrency,
            ),
            _FilterChoice(
              label: l10n.expensePaymentMethod,
              value: _paymentName(),
              onPressed: _choosePayment,
            ),
            _FilterChoice(
              label: l10n.expenseStatus,
              value: _status == null
                  ? l10n.commonAll
                  : _status == ExpenseStatus.confirmed
                  ? l10n.expenseConfirmed
                  : l10n.commonEstimated,
              onPressed: _chooseStatus,
            ),
            _FilterChoice(
              label: l10n.expenseDate,
              value: _dateRange == 0
                  ? l10n.commonAll
                  : l10n.ledgerRecentDays(_dateRange),
              onPressed: _chooseDateRange,
            ),
            _Input(
              label: l10n.ledgerMinimumAmount,
              controller: _minimum,
              numeric: true,
            ),
            _Input(
              label: l10n.ledgerMaximumAmount,
              controller: _maximum,
              numeric: true,
            ),
            if (_invalid)
              Text(
                l10n.ledgerInvalidFilters,
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
          ],
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
  String _paymentName() =>
      widget.paymentMethods
          .where((item) => item.metadata.recordId == _payment)
          .firstOrNull
          ?.name ??
      AppLocalizations.of(context).commonAll;

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
    final value = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonAll,
      for (final item in widget.trips) item.metadata.recordId: item.name,
    });
    if (mounted) setState(() => _tripId = value);
  }

  Future<void> _chooseCategory() async {
    final value = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonAll,
      for (final item in _categories)
        item: _categoryLabel(AppLocalizations.of(context), item),
    });
    if (mounted) setState(() => _category = value);
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
    final value = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonAll,
      for (final item in widget.paymentMethods)
        item.metadata.recordId: item.name,
    });
    if (mounted) setState(() => _payment = value);
  }

  Future<void> _chooseStatus() async {
    final value = await _choose<ExpenseStatus?>(<ExpenseStatus?, String>{
      null: AppLocalizations.of(context).commonAll,
      ExpenseStatus.estimated: AppLocalizations.of(context).commonEstimated,
      ExpenseStatus.confirmed: AppLocalizations.of(context).expenseConfirmed,
    });
    if (mounted) setState(() => _status = value);
  }

  Future<void> _chooseDateRange() async {
    final value = await _choose<int>(<int, String>{
      0: AppLocalizations.of(context).commonAll,
      7: AppLocalizations.of(context).ledgerRecentDays(7),
      30: AppLocalizations.of(context).ledgerRecentDays(30),
    });
    if (value != null && mounted) setState(() => _dateRange = value);
  }

  void _done() {
    try {
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
      Navigator.of(context).pop(
        LedgerFilter(
          tripId: _tripId,
          category: _category,
          currencyCode: _currency,
          paymentMethodId: _payment,
          status: _status,
          from: _dateRange == 0
              ? null
              : now.subtract(Duration(days: _dateRange)),
          to: _dateRange == 0 ? null : now,
          minimumAmount: minimum,
          maximumAmount: maximum,
        ),
      );
    } on FormatException {
      setState(() => _invalid = true);
    }
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
  final _tax = TextEditingController(text: '0');
  final _tip = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _participants = TextEditingController(text: '1');
  final _notes = TextEditingController();
  final _receiptPath = TextEditingController();
  Currency _transactionCurrency = CurrencyCatalog().resolve('JPY');
  Currency _homeCurrency = CurrencyCatalog().resolve('CNY');
  String _category = 'shopping';
  String? _tripId;
  String? _paymentMethodId;
  DateTime _occurredAt = DateTime.now().toUtc();
  bool _budgetIncluded = true;
  bool _invalid = false;
  bool _updatingEstimatedAmount = false;
  bool _isLoadingCurrencyDefaults = false;
  late String _estimatedBaseAmount;

  ExpenseDraftSeed? get _seed => widget.arguments?.seed;

  @override
  void initState() {
    super.initState();
    final seed = _seed;
    final trip = widget.arguments?.trip;
    if (seed != null) {
      _transactionAmount.text = seed.transactionAmount.amount.toString();
      _referenceAmount.text = seed.breakdown.referenceAmount.amount.toString();
      _estimatedAmount.text = seed.breakdown.estimatedCost.amount.toString();
      _transactionCurrency = seed.transactionAmount.currency;
      _homeCurrency = seed.breakdown.estimatedCost.currency;
      _paymentMethodId = seed.breakdown.paymentRule.paymentMethodId;
      _receiptPath.text = seed.receiptLocalPath ?? '';
    }
    if (trip != null) {
      _tripId = trip.metadata.recordId;
      _homeCurrency = trip.homeCurrency;
      _transactionCurrency = trip.localCurrencies.first;
      _participants.text = trip.participantCount.toString();
      _paymentMethodId ??= trip.defaultPaymentMethodId;
    }
    if (seed == null && trip == null) {
      _isLoadingCurrencyDefaults = true;
      unawaited(_loadCurrencyDefaults());
    }
    _estimatedBaseAmount = _estimatedAmount.text;
    _estimatedAmount.addListener(_captureEstimatedBaseAmount);
    for (final controller in <TextEditingController>[_tax, _tip, _discount]) {
      controller.addListener(_recalculateEstimatedAmount);
    }
  }

  @override
  void dispose() {
    _estimatedAmount.removeListener(_captureEstimatedBaseAmount);
    for (final controller in <TextEditingController>[_tax, _tip, _discount]) {
      controller.removeListener(_recalculateEstimatedAmount);
    }
    for (final controller in <TextEditingController>[
      _title,
      _transactionAmount,
      _referenceAmount,
      _estimatedAmount,
      _tax,
      _tip,
      _discount,
      _participants,
      _notes,
      _receiptPath,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripsControllerProvider).value ?? const [];
    final methods =
        ref.watch(paymentMethodsControllerProvider).value ?? const [];
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.expenseManualAdd),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoadingCurrencyDefaults
              ? null
              : () => _save(trips, methods),
          child: Text(l10n.commonSave),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoadingCurrencyDefaults
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: AppInsets.secondaryPageScrollPadding(context),
                children: <Widget>[
                  _Input(label: l10n.expenseTitle, controller: _title),
                  _FilterChoice(
                    label: l10n.expenseTrip,
                    value:
                        trips
                            .where((item) => item.metadata.recordId == _tripId)
                            .firstOrNull
                            ?.name ??
                        l10n.commonNone,
                    onPressed: () => _chooseTrip(trips),
                  ),
                  _FilterChoice(
                    label: l10n.expenseCategory,
                    value: _categoryLabel(l10n, _category),
                    onPressed: _chooseCategory,
                  ),
                  _FilterChoice(
                    key: const Key('expense-transaction-currency'),
                    label: l10n.currencyLocal,
                    value: _transactionCurrency.code,
                    onPressed: () => _chooseCurrency(true),
                  ),
                  _Input(
                    label: l10n.expenseTransactionAmount,
                    controller: _transactionAmount,
                    numeric: true,
                  ),
                  _FilterChoice(
                    key: const Key('expense-home-currency'),
                    label: l10n.currencyHome,
                    value: _homeCurrency.code,
                    onPressed: _tripId == null
                        ? () => _chooseCurrency(false)
                        : () {},
                  ),
                  _Input(
                    label: l10n.expenseReferenceAmount,
                    controller: _referenceAmount,
                    numeric: true,
                  ),
                  _Input(
                    label: l10n.expenseEstimatedAmount,
                    controller: _estimatedAmount,
                    numeric: true,
                  ),
                  _FilterChoice(
                    label: l10n.expensePaymentMethod,
                    value:
                        methods
                            .where(
                              (item) =>
                                  item.metadata.recordId == _paymentMethodId,
                            )
                            .firstOrNull
                            ?.name ??
                        l10n.commonNone,
                    onPressed: () => _choosePayment(methods),
                  ),
                  _Input(
                    label: l10n.expenseTax,
                    controller: _tax,
                    numeric: true,
                  ),
                  _Input(
                    label: l10n.expenseTip,
                    controller: _tip,
                    numeric: true,
                  ),
                  _Input(
                    label: l10n.expenseDiscount,
                    controller: _discount,
                    numeric: true,
                  ),
                  _Input(
                    label: l10n.tripParticipants,
                    controller: _participants,
                    numeric: true,
                  ),
                  _FilterChoice(
                    label: l10n.expenseDate,
                    value: DateFormat.yMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).add_Hm().format(_occurredAt.toLocal()),
                    onPressed: _pickDate,
                  ),
                  _FilterChoice(
                    key: const Key('expense-receipt-picker'),
                    label: l10n.expenseReceiptPath,
                    value: _receiptPath.text.isEmpty
                        ? l10n.commonNone
                        : _receiptPath.text,
                    onPressed: _chooseReceiptImage,
                  ),
                  _Input(
                    label: l10n.expenseNotes,
                    controller: _notes,
                    maxLines: 3,
                  ),
                  CupertinoListTile(
                    padding: EdgeInsets.zero,
                    title: Text(l10n.expenseBudgetIncluded),
                    trailing: CupertinoSwitch(
                      value: _budgetIncluded,
                      onChanged: (value) =>
                          setState(() => _budgetIncluded = value),
                    ),
                  ),
                  if (_invalid)
                    Text(
                      l10n.expenseInvalid,
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadCurrencyDefaults() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).load();
      if (!mounted) return;
      setState(() {
        if (settings != null) {
          _transactionCurrency = settings.lastTransactionCurrency;
          _homeCurrency = settings.defaultCurrency;
        }
        _isLoadingCurrencyDefaults = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _isLoadingCurrencyDefaults = false);
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
  Future<void> _chooseTrip(List<TripModel> trips) async {
    final selected = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonNone,
      for (final item in trips) item.metadata.recordId: item.name,
    });
    if (!mounted) return;
    final trip = trips
        .where((item) => item.metadata.recordId == selected)
        .firstOrNull;
    setState(() {
      _tripId = selected;
      if (trip != null) {
        _homeCurrency = trip.homeCurrency;
        if (!trip.localCurrencies.contains(_transactionCurrency)) {
          _transactionCurrency = trip.localCurrencies.first;
        }
        _participants.text = trip.participantCount.toString();
        _paymentMethodId = trip.defaultPaymentMethodId;
      }
    });
  }

  Future<void> _chooseCategory() async {
    final selected = await _choose<String>(<String, String>{
      for (final item in _categories)
        item: _categoryLabel(AppLocalizations.of(context), item),
    });
    if (selected != null && mounted) setState(() => _category = selected);
  }

  Future<void> _choosePayment(List<PaymentMethodModel> methods) async {
    final selected = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonNone,
      for (final item in methods)
        if (item.billingCurrency == _homeCurrency)
          item.metadata.recordId: item.name,
    });
    if (mounted) setState(() => _paymentMethodId = selected);
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
      });
    }
  }

  Future<void> _pickDate() async {
    var selected = _occurredAt.toLocal();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 340,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).commonDone),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: selected,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => _occurredAt = selected.toUtc());
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
      if (mounted) setState(() => _receiptPath.text = relativePath);
    } on SystemPermissionUnavailable catch (error) {
      if (!mounted) return;
      await showSystemPermissionUnavailableAlert(
        context: context,
        error: error,
        gateway: _permissionGateway,
      );
    } on Object {
      if (mounted) setState(() => _invalid = true);
    }
  }

  void _captureEstimatedBaseAmount() {
    if (!_updatingEstimatedAmount) {
      _estimatedBaseAmount = _estimatedAmount.text;
    }
  }

  void _recalculateEstimatedAmount() {
    try {
      final finalAmount = calculateEstimatedFinalAmount(
        baseAmount: Money.parse(_estimatedBaseAmount, _homeCurrency),
        taxAmount: Money.parse(_tax.text.trim(), _homeCurrency),
        tipAmount: Money.parse(_tip.text.trim(), _homeCurrency),
        discountAmount: Money.parse(_discount.text.trim(), _homeCurrency),
      );
      _updatingEstimatedAmount = true;
      _estimatedAmount.text = finalAmount.amount.toString();
      _estimatedAmount.selection = TextSelection.collapsed(
        offset: _estimatedAmount.text.length,
      );
    } on FormatException {
      // Partial numeric input is allowed while the user is editing.
    } finally {
      _updatingEstimatedAmount = false;
    }
  }

  Future<void> _save(
    List<TripModel> trips,
    List<PaymentMethodModel> methods,
  ) async {
    try {
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
      if (transaction.amount.compareTo(DecimalValue.zero) <= 0 ||
          reference.amount.compareTo(DecimalValue.zero) <= 0 ||
          estimated.amount.compareTo(DecimalValue.zero) <= 0) {
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
          : RateSnapshotModel(
              metadata: SyncRecordMetadata(
                recordId: const Uuid().v4(),
                syncVersion: 1,
                updatedAt: now,
              ),
              baseCurrency: _transactionCurrency,
              quoteCurrency: _homeCurrency,
              rate: rate,
              sourceType: RateSourceType.manual,
              sourceName: 'manual',
              sourceTimestamp: _occurredAt,
              fetchedAt: now,
              isCached: true,
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
        actualFinalAmount: null,
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
        status: ExpenseStatus.estimated,
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
      await ref.read(expensesControllerProvider.notifier).save(expense);
      ref.invalidate(tripsControllerProvider);
      if (mounted) context.pop();
    } on Object {
      setState(() => _invalid = true);
    }
  }
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
    final expense =
        (ref.watch(expensesControllerProvider).value ?? const [])
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
    final calibration = expense.paymentMethodId == null
        ? null
        : ref.watch(calibrationSummaryProvider(expense.paymentMethodId!));
    final remainingRefund = ref
        .read(expensesControllerProvider.notifier)
        .remainingRefundAmount(expense);
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
            const SizedBox(height: AppSpacing.large),
            CupertinoButton.filled(
              onPressed: expense.entryType == ExpenseEntryType.purchase
                  ? () => _recordActual(context, ref, expense)
                  : null,
              child: Text(l10n.expenseRecordActual),
            ),
            CupertinoButton(
              onPressed:
                  expense.entryType == ExpenseEntryType.purchase &&
                      remainingRefund.compareTo(DecimalValue.zero) > 0
                  ? () => _adjust(context, ref, expense)
                  : null,
              child: Text(l10n.expenseAdjust),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordActual(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) async {
    final controller = TextEditingController(
      text:
          expense.actualFinalAmount?.amount.toString() ??
          expense.estimatedFinalAmount.amount.toString(),
    );
    final amount = await _amountDialog(
      context,
      title: AppLocalizations.of(context).expenseRecordActual,
      controller: controller,
    );
    controller.dispose();
    if (amount != null) {
      await ref
          .read(expensesControllerProvider.notifier)
          .recordActual(
            expense,
            Money(amount: amount, currency: expense.referenceAmount.currency),
          );
    }
  }

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) async {
    final l10n = AppLocalizations.of(context);
    final expensesController = ref.read(expensesControllerProvider.notifier);
    final hasRefund =
        expensesController
            .remainingRefundAmount(expense)
            .compareTo(originalRefundableAmount(expense)) <
        0;
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          if (!hasRefund)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop('void'),
              child: Text(l10n.expenseVoid),
            ),
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
    if (action == 'void') {
      await ref.read(expensesControllerProvider.notifier).voidExpense(expense);
    } else if (action == 'refund') {
      await ref
          .read(expensesControllerProvider.notifier)
          .createRefund(
            original: expense,
            homeAmount:
                expense.actualFinalAmount ?? expense.estimatedFinalAmount,
            partial: false,
          );
    } else if (action == 'partial' && context.mounted) {
      final controller = TextEditingController();
      final amount = await _amountDialog(
        context,
        title: l10n.expensePartialRefund,
        controller: controller,
      );
      controller.dispose();
      if (amount != null) {
        try {
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
        } on FormatException {
          if (context.mounted) {
            await showCupertinoDialog<void>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                content: Text(l10n.expenseRefundInvalid),
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
      }
    }
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});
  final List<ExpenseModel> items;
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(AppSpacing.medium),
    itemCount: items.length,
    itemBuilder: (context, index) => _ExpenseTile(expense: items[index]),
  );
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
  const _ExpenseTile({required this.expense});
  final ExpenseModel expense;
  @override
  Widget build(BuildContext context) {
    final formatter = const MoneyFormatter();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = expense.actualFinalAmount ?? expense.estimatedFinalAmount;
    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(_entryIcon(expense.entryType)),
      title: Text(expense.title),
      subtitle: Text(
        '${_categoryLabel(AppLocalizations.of(context), expense.category)} · ${DateFormat.MMMd(locale).format(expense.occurredAt.toLocal())}',
      ),
      additionalInfo: Text(
        formatter.format(amount, locale: locale, includeCode: true),
      ),
      trailing: const Icon(CupertinoIcons.chevron_forward, size: 14),
      onTap: () => context.push(
        AppRoutes.expenseDetail(expense.metadata.recordId),
        extra: expense,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.controller,
    this.numeric = false,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          padding: const EdgeInsets.all(12),
        ),
      ],
    ),
  );
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final String value;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 10),
    onPressed: onPressed,
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const Icon(CupertinoIcons.chevron_forward, size: 14),
      ],
    ),
  );
}

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
            : l10n.commonEstimated,
      ExpenseEntryType.refund => l10n.expenseRefund,
      ExpenseEntryType.partialRefund => l10n.expensePartialRefund,
      ExpenseEntryType.voided => l10n.expenseVoid,
    };
String _rateSourceName(AppLocalizations l10n, String value) =>
    value == 'manual' ? l10n.expenseManualRateSource : value;
String _paymentRuleName(AppLocalizations l10n, String value) =>
    value == 'manual' ? l10n.expenseManualPaymentRule : value;
IconData _entryIcon(ExpenseEntryType type) => switch (type) {
  ExpenseEntryType.purchase => CupertinoIcons.cart,
  ExpenseEntryType.refund ||
  ExpenseEntryType.partialRefund => CupertinoIcons.arrow_uturn_left,
  ExpenseEntryType.voided => CupertinoIcons.clear_circled,
};
