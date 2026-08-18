import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/export/expense_export_service.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/money/money_formatter.dart';
import 'package:trip_cost/core/trips/domain/trip_budget.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/features/settings/application/settings_data_service.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final trips = ref.watch(tripsControllerProvider);
    final expenses = ref.watch(expensesControllerProvider).value ?? const [];
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.tripsTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.push(AppRoutes.tripCreate),
          child: Icon(
            CupertinoIcons.add,
            semanticLabel: localizations.tripCreate,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: trips.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: CupertinoButton(
              onPressed: () => ref.invalidate(tripsControllerProvider),
              child: Text(localizations.converterRefresh),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyTrips(
                onCreate: () => context.push(AppRoutes.tripCreate),
              );
            }
            final now = DateTime.now().toUtc();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: <Widget>[
                for (final section in TripListSection.values) ...<Widget>[
                  if (items.any(
                    (trip) => tripListSection(trip, now) == section,
                  ))
                    _SectionTitle(section: section),
                  for (final trip in items.where(
                    (trip) => tripListSection(trip, now) == section,
                  )) ...<Widget>[
                    _TripCard(
                      trip: trip,
                      summary: const TripBudgetCalculator().calculate(
                        trip: trip,
                        expenses: expenses,
                        now: now,
                      ),
                      onTap: () => context.push(
                        AppRoutes.tripDetail(trip.metadata.recordId),
                        extra: trip,
                      ),
                      onMore: () => _showActions(context, ref, trip),
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  const SizedBox(height: AppSpacing.medium),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    TripModel trip,
  ) async {
    final l10n = AppLocalizations.of(context);
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('edit'),
            child: Text(l10n.commonEdit),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('copy'),
            child: Text(l10n.tripCopy),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('export'),
            child: Text(l10n.tripExport),
          ),
          if (trip.status != TripStatus.archived)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop('archive'),
              child: Text(l10n.tripArchive),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop('delete'),
            child: Text(l10n.commonDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'edit':
        await context.push(
          AppRoutes.tripEdit(trip.metadata.recordId),
          extra: trip,
        );
      case 'copy':
        await ref.read(tripsControllerProvider.notifier).duplicate(trip);
      case 'export':
        await _exportTrip(context, ref, trip);
      case 'archive':
        await ref.read(tripsControllerProvider.notifier).archive(trip);
      case 'delete':
        final choice = await showCupertinoDialog<String>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.tripDeleteTitle),
            content: Text(l10n.tripDeleteMessage),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop('keep'),
                child: Text(l10n.tripDeleteKeepReceipts),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop('receipts'),
                child: Text(l10n.tripDeleteWithReceipts),
              ),
            ],
          ),
        );
        if (choice != null) {
          var receiptFailures = const <String>[];
          if (choice == 'receipts') {
            receiptFailures = await ref
                .read(expensesControllerProvider.notifier)
                .clearReceiptImagesForTrip(trip.metadata.recordId);
          }
          await ref
              .read(tripsControllerProvider.notifier)
              .delete(trip.metadata.recordId);
          if (receiptFailures.isNotEmpty && context.mounted) {
            await _showMessage(context, l10n.tripReceiptDeletePartial);
          }
        }
    }
  }

  Future<void> _exportTrip(
    BuildContext context,
    WidgetRef ref,
    TripModel trip,
  ) async {
    final l10n = AppLocalizations.of(context);
    final format = await showCupertinoModalPopup<ExpenseExportFormat>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(ExpenseExportFormat.csv),
            child: Text(l10n.exportCsv),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(ExpenseExportFormat.pdf),
            child: Text(l10n.exportPdf),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ),
    );
    if (format == null || !context.mounted) return;
    try {
      final service = ref.read(expenseExportServiceProvider);
      final locale = Localizations.localeOf(context).toLanguageTag();
      final file = format == ExpenseExportFormat.csv
          ? await service.createCsv(
              locale: locale,
              tripId: trip.metadata.recordId,
            )
          : await service.createPdf(
              locale: locale,
              tripId: trip.metadata.recordId,
            );
      await service.share(file);
    } on ExpenseExportException catch (error) {
      if (!context.mounted) return;
      final message = switch (error.code) {
        ExpenseExportException.empty => l10n.exportEmpty,
        ExpenseExportException.tooLarge => l10n.exportTooLarge,
        _ => l10n.exportFailed,
      };
      await _showMessage(context, message);
    } on Object {
      if (context.mounted) await _showMessage(context, l10n.exportFailed);
    }
  }

  Future<void> _showMessage(BuildContext context, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).commonDone),
          ),
        ],
      ),
    );
  }
}

class TripEditorPage extends ConsumerStatefulWidget {
  const TripEditorPage({this.initial, super.key});

  final TripModel? initial;

  @override
  ConsumerState<TripEditorPage> createState() => _TripEditorPageState();
}

class TripEditorLoaderPage extends ConsumerWidget {
  const TripEditorLoaderPage({required this.tripId, this.initial, super.key});

  final String tripId;
  final TripModel? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initial != null) return TripEditorPage(initial: initial);
    final trips = ref.watch(tripsControllerProvider);
    return trips.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        child: Center(child: Text(AppLocalizations.of(context).tripMissing)),
      ),
      data: (items) {
        final trip = items
            .where((item) => item.metadata.recordId == tripId)
            .firstOrNull;
        return trip == null
            ? CupertinoPageScaffold(
                child: Center(
                  child: Text(AppLocalizations.of(context).tripMissing),
                ),
              )
            : TripEditorPage(initial: trip);
      },
    );
  }
}

class _TripEditorPageState extends ConsumerState<TripEditorPage> {
  final _name = TextEditingController();
  final _destinations = TextEditingController();
  final _budget = TextEditingController();
  final _participants = TextEditingController(text: '1');
  late final String _recordId;
  late DateTime _startDate;
  late DateTime _endDate;
  Currency _homeCurrency = CurrencyCatalog().resolve('CNY');
  final Set<Currency> _localCurrencies = <Currency>{};
  String? _defaultPaymentMethodId;
  bool _offlinePack = false;
  bool _invalid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _recordId = initial?.metadata.recordId ?? const Uuid().v4();
    final today = localCalendarDate(DateTime.now());
    _startDate = initial?.startDate ?? today;
    _endDate = initial?.endDate ?? _startDate.add(const Duration(days: 6));
    if (initial != null) {
      _name.text = initial.name;
      _destinations.text = initial.destinationCodes.join(', ');
      _budget.text = initial.totalBudget?.amount.toString() ?? '';
      _participants.text = initial.participantCount.toString();
      _homeCurrency = initial.homeCurrency;
      _localCurrencies.addAll(initial.localCurrencies);
      _defaultPaymentMethodId = initial.defaultPaymentMethodId;
      _offlinePack = initial.offlinePackUpdatedAt != null;
    } else {
      _localCurrencies.add(CurrencyCatalog().resolve('JPY'));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _destinations.dispose();
    _budget.dispose();
    _participants.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final methods =
        ref.watch(paymentMethodsControllerProvider).value ?? const [];
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: widget.initial == null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isSaving ? null : _close,
                child: Text(l10n.commonCancel),
              )
            : null,
        middle: Text(widget.initial == null ? l10n.tripCreate : l10n.tripEdit),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator(radius: 8)
              : Text(l10n.commonSave),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _Field(label: l10n.tripName, controller: _name),
            _Field(
              label: l10n.tripDestinations,
              controller: _destinations,
              placeholder: l10n.tripDestinationsHint,
              onChanged: _recommendLocalCurrencies,
            ),
            _Choice(
              label: l10n.tripStartDate,
              value: _formatDate(_startDate, context),
              onPressed: () => _pickDate(true),
            ),
            _Choice(
              label: l10n.tripEndDate,
              value: _formatDate(_endDate, context),
              onPressed: () => _pickDate(false),
            ),
            _Choice(
              label: l10n.currencyHome,
              value: _homeCurrency.code,
              onPressed: _pickHomeCurrency,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(l10n.tripLocalCurrencies),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final currency in CurrencyCatalog.knownCurrencies)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => setState(() {
                      if (_localCurrencies.contains(currency)) {
                        if (_localCurrencies.length > 1) {
                          _localCurrencies.remove(currency);
                        }
                      } else {
                        _localCurrencies.add(currency);
                      }
                    }),
                    child: Text(
                      currency.code,
                      style: TextStyle(
                        fontWeight: _localCurrencies.contains(currency)
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
            _Field(
              label: l10n.tripBudget,
              controller: _budget,
              numeric: true,
              placeholder: l10n.tripBudgetOptional,
            ),
            _Field(
              label: l10n.tripParticipants,
              controller: _participants,
              numeric: true,
            ),
            _Choice(
              label: l10n.tripDefaultPayment,
              value:
                  methods
                      .where(
                        (item) =>
                            item.metadata.recordId == _defaultPaymentMethodId,
                      )
                      .firstOrNull
                      ?.name ??
                  l10n.commonNone,
              onPressed: () => _pickPaymentMethod(methods),
            ),
            CupertinoListTile(
              padding: EdgeInsets.zero,
              title: Text(l10n.tripOfflinePack),
              subtitle: Text(l10n.tripOfflinePackHint),
              trailing: CupertinoSwitch(
                value: _offlinePack,
                onChanged: (value) => setState(() => _offlinePack = value),
              ),
            ),
            if (_invalid)
              Text(
                l10n.tripInvalid,
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool start) async {
    var selected = start ? _startDate : _endDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 330,
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
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selected,
                  onDateTimeChanged: (value) => selected = DateTime.utc(
                    value.year,
                    value.month,
                    value.day,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() {
      if (start) {
        _startDate = selected;
        if (_endDate.isBefore(selected)) _endDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _pickHomeCurrency() async {
    final selected = await _choose<Currency>(<Currency, String>{
      for (final item in CurrencyCatalog.knownCurrencies)
        item: '${item.code} · ${item.name}',
    });
    if (selected != null) setState(() => _homeCurrency = selected);
  }

  void _recommendLocalCurrencies(String value) {
    final destinationCodes = value
        .split(',')
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final recommended = CurrencyCatalog.knownCurrencies.where(
      (currency) => currency.countryCodes.any(destinationCodes.contains),
    );
    if (recommended.isNotEmpty) {
      setState(() => _localCurrencies.addAll(recommended));
    }
  }

  Future<void> _pickPaymentMethod(List<PaymentMethodModel> methods) async {
    final selected = await _choose<String?>(<String?, String>{
      null: AppLocalizations.of(context).commonNone,
      for (final item in methods) item.metadata.recordId: item.name,
    });
    setState(() => _defaultPaymentMethodId = selected);
  }

  Future<T?> _choose<T>(Map<T, String> options) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          for (final option in options.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(option.key),
              child: Text(option.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _invalid = false;
    });
    try {
      final now = DateTime.now().toUtc();
      final budgetText = _budget.text.trim();
      final initial = widget.initial;
      final trip = TripModel(
        metadata: SyncRecordMetadata(
          recordId: _recordId,
          syncVersion: (initial?.metadata.syncVersion ?? 0) + 1,
          updatedAt: now,
        ),
        name: _name.text.trim(),
        destinationCodes: _destinations.text
            .split(',')
            .map((value) => value.trim().toUpperCase())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
        startDate: _startDate,
        endDate: _endDate,
        homeCurrency: _homeCurrency,
        localCurrencies: _localCurrencies.toList(growable: false),
        totalBudget: budgetText.isEmpty
            ? null
            : Money.parse(budgetText, _homeCurrency),
        participantCount: int.parse(_participants.text.trim()),
        defaultPaymentMethodId: _defaultPaymentMethodId,
        offlinePackUpdatedAt: _offlinePack
            ? initial?.offlinePackUpdatedAt
            : null,
        status: tripStatusForDates(
          startDate: _startDate,
          endDate: _endDate,
          now: now,
          archived: initial?.status == TripStatus.archived,
        ),
        createdAt: initial?.createdAt ?? now,
      );
      await ref.read(tripsControllerProvider.notifier).save(trip);
      if (_offlinePack) {
        try {
          final settings = await ref.read(settingsRepositoryProvider).load();
          await ref
              .read(offlineRatePackServiceProvider)
              .download(
                tripId: trip.metadata.recordId,
                homeCurrency: trip.homeCurrency,
                localCurrencies: trip.localCurrencies,
                wifiOnly: settings?.wifiOnlyRefresh ?? false,
              );
          ref.invalidate(tripsControllerProvider);
        } on Object {
          // A failed optional download must not roll back the local trip.
        }
      }
      if (mounted) _close();
    } on Object {
      if (mounted) {
        setState(() {
          _invalid = true;
          _isSaving = false;
        });
      }
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.trips);
    }
  }
}

class TripDashboardPage extends ConsumerWidget {
  const TripDashboardPage({required this.tripId, this.initial, super.key});

  final String tripId;
  final TripModel? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripsControllerProvider).value ?? const [];
    final trip =
        trips.where((item) => item.metadata.recordId == tripId).firstOrNull ??
        initial;
    final expenses = ref.watch(expensesControllerProvider).value ?? const [];
    final paymentMethods =
        ref.watch(paymentMethodsControllerProvider).value ?? const [];
    if (trip == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(l10n.tripsTitle)),
        child: Center(child: Text(l10n.tripMissing)),
      );
    }
    final summary = const TripBudgetCalculator().calculate(
      trip: trip,
      expenses: expenses,
      now: DateTime.now().toUtc(),
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = const MoneyFormatter();
    String money(Money? value) => value == null
        ? l10n.tripNoBudget
        : formatter.format(value, locale: locale, includeCode: true);
    final tripExpenses = expenses
        .where((item) => item.tripId == tripId)
        .take(5)
        .toList(growable: false);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(trip.name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.push(AppRoutes.tripEdit(tripId), extra: trip),
          child: Text(l10n.commonEdit),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.tripBudget,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _Metric(label: l10n.tripSpent, value: money(summary.spent)),
                  _Metric(
                    label: l10n.tripRemaining,
                    value: money(summary.remaining),
                  ),
                  _Metric(
                    label: l10n.tripDailyRemaining,
                    value: money(summary.remainingPerDay),
                  ),
                  _Metric(
                    label: l10n.tripDailyAverage,
                    value: money(summary.currentDailyAverage),
                  ),
                  _Metric(
                    label: l10n.tripDayProgress,
                    value: '${summary.elapsedDays}/${summary.totalDays}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: () =>
                        context.push(AppRoutes.expenseCreate, extra: trip),
                    child: Text(l10n.expenseManualAdd),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  onPressed: () => context.push(AppRoutes.scan),
                  child: Text(l10n.scanAction),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            if (summary.categoryTotals.isNotEmpty) ...<Widget>[
              Text(
                l10n.ledgerCategories,
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              for (final entry in summary.categoryTotals.entries)
                _Metric(
                  label: _tripCategoryLabel(l10n, entry.key),
                  value:
                      '${money(entry.value)} · '
                      '${_share(entry.value, summary.spent)}%',
                ),
              const SizedBox(height: AppSpacing.medium),
            ],
            if (summary.paymentMethodTotals.isNotEmpty) ...<Widget>[
              Text(
                l10n.tripPaymentBreakdown,
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              for (final entry in summary.paymentMethodTotals.entries)
                _Metric(
                  label:
                      paymentMethods
                          .where((item) => item.metadata.recordId == entry.key)
                          .firstOrNull
                          ?.name ??
                      l10n.commonNone,
                  value:
                      '${money(entry.value)} · '
                      '${_share(entry.value, summary.spent)}%',
                ),
              const SizedBox(height: AppSpacing.medium),
            ],
            Text(
              l10n.expenseRecent,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            if (tripExpenses.isEmpty)
              _Surface(child: Text(l10n.ledgerEmpty))
            else
              for (final expense in tripExpenses)
                CupertinoListTile(
                  padding: EdgeInsets.zero,
                  title: Text(expense.title),
                  subtitle: Text(
                    '${_tripCategoryLabel(l10n, expense.category)} · '
                    '${money(expense.transactionAmount)}',
                  ),
                  trailing: Text(
                    money(
                      expense.actualFinalAmount ?? expense.estimatedFinalAmount,
                    ),
                  ),
                  onTap: () => context.push(
                    AppRoutes.expenseDetail(expense.metadata.recordId),
                    extra: expense,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.summary,
    required this.onTap,
    required this.onMore,
  });

  final TripModel trip;
  final TripBudgetSummary summary;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = const MoneyFormatter();
    final spent = formatter.format(
      summary.spent,
      locale: locale,
      includeCode: true,
    );
    final budget = summary.totalBudget == null
        ? AppLocalizations.of(context).tripNoBudget
        : formatter.format(
            summary.totalBudget!,
            locale: locale,
            includeCode: true,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Surface(
        child: Row(
          children: <Widget>[
            const Icon(CupertinoIcons.airplane, size: 30),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_formatDate(trip.startDate, context)} – ${_formatDate(trip.endDate, context)}',
                  ),
                  Text(
                    '${trip.localCurrencies.map((item) => item.code).join(' / ')} · $spent / $budget',
                  ),
                  Text(
                    trip.offlinePackUpdatedAt == null
                        ? AppLocalizations.of(context).tripOfflineMissing
                        : AppLocalizations.of(context).tripOfflineReady,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onMore,
              child: const Icon(CupertinoIcons.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.section});
  final TripListSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (section) {
      TripListSection.active => l10n.tripActive,
      TripListSection.upcoming => l10n.tripUpcoming,
      TripListSection.history => l10n.tripHistory,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(CupertinoIcons.airplane, size: 44),
            const SizedBox(height: AppSpacing.medium),
            Text(l10n.tripsSubtitle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.medium),
            CupertinoButton.filled(
              onPressed: onCreate,
              child: Text(l10n.tripCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.numeric = false,
    this.placeholder,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final String? placeholder;
  final ValueChanged<String>? onChanged;

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
            placeholder: placeholder,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            padding: const EdgeInsets.all(12),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: child,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

String _formatDate(DateTime date, BuildContext context) {
  return DateFormat.yMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(date);
}

String _share(Money value, Money total) {
  if (total.amount.isZero) return '0.0';
  return (value.amount.divide(total.amount) * DecimalValue.parse('100'))
      .toFixed(1);
}

String _tripCategoryLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'food' => l10n.categoryFood,
      'transport' => l10n.categoryTransport,
      'shopping' => l10n.categoryShopping,
      'hotel' => l10n.categoryHotel,
      'tickets' => l10n.categoryTickets,
      _ => l10n.categoryOther,
    };
