import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';
import 'package:trip_cost/features/settings/application/sync_settings_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeControllerProvider);
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
            Text(
              localizations.syncTitle,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: AppSpacing.small),
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
            Text(
              localizations.paymentMethodsTitle,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () => context.push(AppRoutes.paymentMethods),
              child: Row(
                children: <Widget>[
                  const Icon(CupertinoIcons.creditcard),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(child: Text(localizations.paymentMethodsTitle)),
                  const Icon(CupertinoIcons.chevron_forward, size: 16),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              localizations.languageTitle,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: AppSpacing.small),
            _LanguageOption(
              label: localizations.systemLanguage,
              onPressed: ref
                  .read(localeControllerProvider.notifier)
                  .followSystem,
              selected: currentLocale == null,
            ),
            _LanguageOption(
              label: localizations.simplifiedChinese,
              onPressed: ref
                  .read(localeControllerProvider.notifier)
                  .useSimplifiedChinese,
              selected: currentLocale?.languageCode == 'zh',
            ),
            _LanguageOption(
              label: localizations.english,
              onPressed: ref.read(localeControllerProvider.notifier).useEnglish,
              selected: currentLocale?.languageCode == 'en',
            ),
          ],
        ),
      ),
    );
  }
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
