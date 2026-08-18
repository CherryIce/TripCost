import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/export/expense_export_service.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/features/settings/application/general_settings_controller.dart';
import 'package:trip_cost/features/settings/application/settings_data_service.dart';
import 'package:trip_cost/features/settings/application/sync_settings_controller.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _operationInProgress = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final settingsState = ref.watch(generalSettingsControllerProvider);
    final syncState = ref.watch(syncSettingsControllerProvider);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.settingsTitle),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          children: <Widget>[
            Text(
              localizations.settingsSubtitle,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionTitle(localizations.paymentMethodsTitle),
            _SettingsButton(
              icon: CupertinoIcons.creditcard,
              label: localizations.paymentMethodsTitle,
              onPressed: () => context.push(AppRoutes.paymentMethods),
            ),
            const SizedBox(height: AppSpacing.large),
            settingsState.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (_, _) => Text(localizations.settingsLoadFailed),
              data: (settings) => _GeneralSettingsSection(
                settings: settings,
                onDefaultCurrency: () => _chooseDefaultCurrency(settings),
                onFavorites: () => _chooseFavorites(settings),
                onRefreshInterval: () => _chooseRefreshInterval(settings),
                onWifiOnly: _setWifiOnlyRefresh,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionTitle(localizations.syncTitle),
            syncState.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (_, _) => Text(localizations.syncStatusFailed),
              data: (value) => _SyncSettingsSection(
                value: value,
                onToggle: ref
                    .read(syncSettingsControllerProvider.notifier)
                    .setEnabled,
                onSyncNow: ref
                    .read(syncSettingsControllerProvider.notifier)
                    .synchronizeNow,
                onResolve: (conflict, useRemote) => ref
                    .read(syncSettingsControllerProvider.notifier)
                    .resolveConflict(conflict, useRemoteValue: useRemote),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionTitle(localizations.languageTitle),
            const SizedBox(height: AppSpacing.small),
            _LanguageOption(
              label: localizations.systemLanguage,
              onPressed: () => _setLanguage(AppLanguageMode.system),
              selected:
                  settingsState.value?.languageMode == AppLanguageMode.system,
            ),
            _LanguageOption(
              label: localizations.simplifiedChinese,
              onPressed: () => _setLanguage(AppLanguageMode.simplifiedChinese),
              selected:
                  settingsState.value?.languageMode ==
                  AppLanguageMode.simplifiedChinese,
            ),
            _LanguageOption(
              label: localizations.english,
              onPressed: () => _setLanguage(AppLanguageMode.english),
              selected:
                  settingsState.value?.languageMode == AppLanguageMode.english,
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionTitle(localizations.dataTitle),
            _SettingsButton(
              icon: CupertinoIcons.table,
              label: localizations.exportCsv,
              onPressed: _operationInProgress
                  ? null
                  : () => _export(ExpenseExportFormat.csv),
            ),
            _SettingsButton(
              icon: CupertinoIcons.doc_richtext,
              label: localizations.exportPdf,
              onPressed: _operationInProgress
                  ? null
                  : () => _export(ExpenseExportFormat.pdf),
            ),
            _SettingsButton(
              icon: CupertinoIcons.archivebox,
              label: localizations.backupCreate,
              onPressed: _operationInProgress ? null : _createBackup,
            ),
            _SettingsButton(
              icon: CupertinoIcons.arrow_down_doc,
              label: localizations.backupRestore,
              onPressed: _operationInProgress ? null : _restoreBackup,
            ),
            _SettingsButton(
              icon: CupertinoIcons.photo_on_rectangle,
              label: localizations.clearReceiptImages,
              onPressed: _operationInProgress ? null : _clearReceiptImages,
            ),
            _SettingsButton(
              icon: CupertinoIcons.delete,
              label: localizations.clearAllData,
              destructive: true,
              onPressed: _operationInProgress ? null : _clearAllData,
            ),
            if (_operationInProgress)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.small),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            const SizedBox(height: AppSpacing.large),
            _SectionTitle(localizations.privacyTitle),
            _SettingsButton(
              icon: CupertinoIcons.hand_raised,
              label: localizations.privacyPolicyTitle,
              onPressed: () => _showLongText(
                localizations.privacyPolicyTitle,
                localizations.privacyPolicyBody,
              ),
            ),
            _SettingsButton(
              icon: CupertinoIcons.info_circle,
              label: localizations.disclaimerTitle,
              onPressed: () => _showLongText(
                localizations.disclaimerTitle,
                localizations.disclaimerBody,
              ),
            ),
            _SettingsButton(
              icon: CupertinoIcons.lock_shield,
              label: localizations.permissionsTitle,
              onPressed: () => _showLongText(
                localizations.permissionsTitle,
                localizations.permissionsBody,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDefaultCurrency(UserSettingsModel settings) async {
    final selected = await showCupertinoModalPopup<Currency>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context).defaultCurrency),
        actions: <Widget>[
          for (final currency in CurrencyCatalog.knownCurrencies)
            CupertinoActionSheetAction(
              isDefaultAction: currency == settings.defaultCurrency,
              onPressed: () => Navigator.of(context).pop(currency),
              child: Text('${currency.code} · ${currency.name}'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
      ),
    );
    if (selected != null) {
      await ref
          .read(generalSettingsControllerProvider.notifier)
          .setDefaultCurrency(selected);
      ref.invalidate(converterControllerProvider);
    }
  }

  Future<void> _chooseFavorites(UserSettingsModel settings) async {
    final selected = settings.favoriteCurrencies.toSet();
    final result = await showCupertinoModalPopup<List<Currency>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CupertinoPopupSurface(
          child: SafeArea(
            top: false,
            bottom: false,
            child: SizedBox(
              height: 480 + MediaQuery.paddingOf(context).bottom,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).favoriteCurrencies,
                            style: CupertinoTheme.of(
                              context,
                            ).textTheme.navTitleTextStyle,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(selected.toList(growable: false)),
                          child: Text(AppLocalizations.of(context).commonDone),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.medium,
                        0,
                        AppSpacing.medium,
                        AppInsets.scrollableBottomPadding(context),
                      ),
                      children: <Widget>[
                        for (final currency in CurrencyCatalog.knownCurrencies)
                          _SwitchRow(
                            label: '${currency.code} · ${currency.name}',
                            value: selected.contains(currency),
                            onChanged: (value) => setModalState(() {
                              if (value) {
                                selected.add(currency);
                              } else {
                                selected.remove(currency);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      await ref
          .read(generalSettingsControllerProvider.notifier)
          .setFavoriteCurrencies(result);
      ref.invalidate(converterControllerProvider);
    }
  }

  Future<void> _chooseRefreshInterval(UserSettingsModel settings) async {
    const values = <Duration>[
      Duration(hours: 1),
      Duration(hours: 6),
      Duration(hours: 24),
    ];
    final selected = await showCupertinoModalPopup<Duration>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return CupertinoActionSheet(
          title: Text(l10n.refreshInterval),
          actions: <Widget>[
            for (final value in values)
              CupertinoActionSheetAction(
                isDefaultAction: settings.refreshInterval == value,
                onPressed: () => Navigator.of(context).pop(value),
                child: Text(l10n.refreshEveryHours(value.inHours)),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
        );
      },
    );
    if (selected != null) {
      await ref
          .read(generalSettingsControllerProvider.notifier)
          .setRefreshInterval(selected);
      ref.invalidate(converterControllerProvider);
    }
  }

  Future<void> _setWifiOnlyRefresh(bool value) async {
    await ref
        .read(generalSettingsControllerProvider.notifier)
        .setWifiOnlyRefresh(value);
    ref.invalidate(converterControllerProvider);
  }

  Future<void> _setLanguage(AppLanguageMode mode) async {
    await ref
        .read(generalSettingsControllerProvider.notifier)
        .setLanguage(mode);
  }

  Future<void> _export(ExpenseExportFormat format) async {
    final l10n = AppLocalizations.of(context);
    await _runOperation(() async {
      final service = ref.read(expenseExportServiceProvider);
      final locale = Localizations.localeOf(context).toLanguageTag();
      final file = format == ExpenseExportFormat.csv
          ? await service.createCsv(locale: locale)
          : await service.createPdf(locale: locale);
      await service.share(file);
    }, failure: l10n.exportFailed);
  }

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context);
    await _runOperation(() async {
      final service = ref.read(settingsDataServiceProvider);
      final backup = await service.createBackup();
      await service.shareBackup(backup);
    }, failure: l10n.backupFailed);
  }

  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.backupRestoreTitle, l10n.backupRestoreMessage)) {
      return;
    }
    await _runOperation(() async {
      final restored = await ref
          .read(settingsDataServiceProvider)
          .pickAndRestoreBackup();
      if (!restored || !mounted) return;
      _invalidateDataControllers();
      try {
        await ref.read(widgetSnapshotServiceProvider).refresh();
      } on Object {
        // Restored local data remains valid when Widget sharing is unavailable.
      }
      await _showNotice(l10n.backupRestored);
    }, failure: l10n.backupRestoreFailed);
  }

  Future<void> _clearReceiptImages() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
      l10n.clearReceiptImagesTitle,
      l10n.clearReceiptImagesMessage,
      destructive: true,
    )) {
      return;
    }
    await _runOperation(() async {
      final report = await ref
          .read(settingsDataServiceProvider)
          .clearReceiptImages();
      if (!report.succeeded) throw StateError('receipt-clear-failed');
      if (mounted) await _showNotice(l10n.clearReceiptImagesDone);
    }, failure: l10n.clearDataFailed);
  }

  Future<void> _clearAllData() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
      l10n.clearAllDataTitle,
      l10n.clearAllDataMessage,
      destructive: true,
    )) {
      return;
    }
    final service = ref.read(settingsDataServiceProvider);
    final confirmation = service.requestFullReset();
    if (!await _confirm(
      l10n.clearAllDataAgainTitle,
      l10n.clearAllDataAgainMessage,
      destructive: true,
    )) {
      return;
    }
    await _runOperation(() async {
      await service.clearAllData(confirmation);
      if (mounted) {
        context.go(AppRoutes.onboarding);
        await Future<void>.delayed(Duration.zero);
        _invalidateDataControllers();
      }
    }, failure: l10n.clearDataFailed);
  }

  void _invalidateDataControllers() {
    ref.invalidate(generalSettingsControllerProvider);
    ref.invalidate(syncSettingsControllerProvider);
    ref.invalidate(converterControllerProvider);
    ref.invalidate(paymentMethodsControllerProvider);
    ref.invalidate(tripsControllerProvider);
    ref.invalidate(expensesControllerProvider);
  }

  Future<void> _runOperation(
    Future<void> Function() operation, {
    required String failure,
  }) async {
    setState(() => _operationInProgress = true);
    try {
      await operation();
    } on ExpenseExportException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await _showNotice(switch (error.code) {
        ExpenseExportException.empty => l10n.exportEmpty,
        ExpenseExportException.tooLarge => l10n.exportTooLarge,
        _ => failure,
      });
    } on Object {
      if (mounted) await _showNotice(failure);
    } finally {
      if (mounted) setState(() => _operationInProgress = false);
    }
  }

  Future<bool> _confirm(
    String title,
    String message, {
    bool destructive = false,
  }) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).commonContinue),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showNotice(String message) => showCupertinoDialog<void>(
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

  Future<void> _showLongText(String title, String body) =>
      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoPopupSurface(
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: CupertinoTheme.of(
                              context,
                            ).textTheme.navTitleTextStyle,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(context).commonDone),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.medium,
                        0,
                        AppSpacing.medium,
                        AppSpacing.large,
                      ),
                      child: Text(body),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _GeneralSettingsSection extends StatelessWidget {
  const _GeneralSettingsSection({
    required this.settings,
    required this.onDefaultCurrency,
    required this.onFavorites,
    required this.onRefreshInterval,
    required this.onWifiOnly,
  });

  final UserSettingsModel settings;
  final VoidCallback onDefaultCurrency;
  final VoidCallback onFavorites;
  final VoidCallback onRefreshInterval;
  final ValueChanged<bool> onWifiOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(l10n.rateSettingsTitle),
        _SettingsButton(
          icon: CupertinoIcons.money_dollar_circle,
          label: l10n.defaultCurrency,
          value: settings.defaultCurrency.code,
          onPressed: onDefaultCurrency,
        ),
        _SettingsButton(
          icon: CupertinoIcons.star,
          label: l10n.favoriteCurrencies,
          value: settings.favoriteCurrencies.isEmpty
              ? l10n.noneSelected
              : settings.favoriteCurrencies
                    .map((currency) => currency.code)
                    .join(', '),
          onPressed: onFavorites,
        ),
        _SettingsButton(
          icon: CupertinoIcons.refresh,
          label: l10n.refreshInterval,
          value: l10n.refreshEveryHours(settings.refreshInterval.inHours),
          onPressed: onRefreshInterval,
        ),
        _SwitchRow(
          label: l10n.wifiOnlyRefresh,
          value: settings.wifiOnlyRefresh,
          onChanged: onWifiOnly,
        ),
        _SettingsRow(
          icon: CupertinoIcons.number,
          label: l10n.decimalDisplayRule,
          value: l10n.decimalDisplayCurrencyDefault,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.small),
    child: Text(
      label,
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
    ),
  );
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: value == null ? label : '$label, $value',
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: onPressed,
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: destructive
                ? CupertinoColors.systemRed.resolveFrom(context)
                : null,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              label,
              style: destructive
                  ? TextStyle(
                      color: CupertinoColors.systemRed.resolveFrom(context),
                    )
                  : null,
            ),
          ),
          if (value != null)
            Expanded(
              child: Text(
                value!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.small),
          const Icon(CupertinoIcons.chevron_forward, size: 16),
        ],
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: <Widget>[
        Icon(icon),
        const SizedBox(width: AppSpacing.small),
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

class _SyncSettingsSection extends StatelessWidget {
  const _SyncSettingsSection({
    required this.value,
    required this.onToggle,
    required this.onSyncNow,
    required this.onResolve,
  });

  final SyncSettingsState value;
  final ValueChanged<bool> onToggle;
  final Future<void> Function() onSyncNow;
  final Future<void> Function(SyncConflictModel, bool) onResolve;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final runtime = value.runtime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(localizations.syncEnable)),
            CupertinoSwitch(value: value.enabled, onChanged: onToggle),
          ],
        ),
        Text(
          _statusLabel(localizations, runtime),
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        if (runtime.lastSuccessAt != null)
          Text(
            localizations.syncLastSuccess(
              runtime.lastSuccessAt!.toLocal().toString().substring(0, 16),
            ),
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        if (runtime.lastErrorCode != null)
          Text(localizations.syncFailureReason(runtime.lastErrorCode!)),
        if (value.enabled)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: onSyncNow,
            child: Text(localizations.syncNow),
          ),
        for (final conflict in value.conflicts)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.small),
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange
                  .resolveFrom(context)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(localizations.syncActualConflict),
                Text(
                  localizations.syncConflictValues(
                    conflict.localValue ?? '—',
                    conflict.remoteValue ?? '—',
                  ),
                ),
                Row(
                  children: <Widget>[
                    CupertinoButton(
                      padding: const EdgeInsets.only(right: 12),
                      onPressed: () => onResolve(conflict, false),
                      child: Text(localizations.syncKeepLocal),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => onResolve(conflict, true),
                      child: Text(localizations.syncUseCloud),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _statusLabel(
    AppLocalizations localizations,
    SyncRuntimeStatus runtime,
  ) {
    if (!value.enabled) return localizations.syncStatusDisabled;
    if (runtime.accountState == SyncAccountState.noAccount) {
      return localizations.syncStatusNoAccount;
    }
    if (runtime.accountState == SyncAccountState.restricted) {
      return localizations.syncStatusRestricted;
    }
    return switch (runtime.phase) {
      SyncPhase.pushing || SyncPhase.pulling => localizations.syncStatusWorking,
      SyncPhase.succeeded => localizations.syncStatusSucceeded,
      SyncPhase.waitingRetry => localizations.syncStatusWaiting,
      SyncPhase.failed => localizations.syncStatusFailed,
      _ => localizations.syncStatusIdle,
    };
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.onPressed,
    required this.selected,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          if (selected) const Icon(CupertinoIcons.check_mark),
        ],
      ),
    );
  }
}
