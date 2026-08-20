import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/features/payment_method/presentation/payment_methods_page.dart';
import 'package:trip_cost/features/trip/application/trips_controller.dart';
import 'package:trip_cost/features/trip/presentation/trips_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';

class QuickSetupPage extends ConsumerStatefulWidget {
  const QuickSetupPage({
    required this.initialCurrency,
    required this.onFinish,
    this.excludedCurrency,
    this.onBack,
    this.onCurrencyChanged,
    super.key,
  });

  final Currency initialCurrency;
  final Currency? excludedCurrency;
  final VoidCallback? onBack;
  final ValueChanged<Currency>? onCurrencyChanged;
  final Future<void> Function(Currency currency) onFinish;

  @override
  ConsumerState<QuickSetupPage> createState() => _QuickSetupPageState();
}

class _QuickSetupPageState extends ConsumerState<QuickSetupPage> {
  late Currency _selectedCurrency;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripsControllerProvider);
    final paymentMethods = ref.watch(paymentMethodsControllerProvider);
    final tripItems = trips.value ?? const <TripModel>[];
    final paymentItems = paymentMethods.value ?? const <PaymentMethodModel>[];
    final completedCount =
        1 + (tripItems.isEmpty ? 0 : 1) + (paymentItems.isEmpty ? 0 : 1);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.launchBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.onboardingSetupTitle),
        leading: widget.onBack == null
            ? null
            : CupertinoNavigationBarBackButton(onPressed: widget.onBack),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                key: const Key('quick-setup-list'),
                padding: const EdgeInsets.only(
                  top: AppSpacing.large,
                  bottom: AppSpacing.large,
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                    ),
                    child: Text(
                      l10n.onboardingSetupSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        fontSize: 17,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .resolveFrom(context)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          l10n.onboardingSetupProgress(completedCount, 3),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  CupertinoListSection.insetGrouped(
                    margin: const EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      AppSpacing.large,
                      AppSpacing.medium,
                      0,
                    ),
                    children: <Widget>[
                      CupertinoListTile(
                        key: const Key('quick-setup-currency'),
                        leading: const _SetupIcon(
                          icon: CupertinoIcons.money_dollar_circle,
                        ),
                        title: Text(l10n.currencyHome),
                        subtitle: Text(
                          l10n.onboardingSetupCurrencySelected(
                            _selectedCurrency.code,
                          ),
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                        ),
                        onTap: _chooseHomeCurrency,
                      ),
                      CupertinoListTile(
                        key: const Key('quick-setup-trip'),
                        leading: const _SetupIcon(
                          icon: CupertinoIcons.airplane,
                        ),
                        title: Text(l10n.tripsTab),
                        subtitle: Text(
                          _tripStatus(l10n, trips, tripItems),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                        ),
                        onTap: () => _openTrips(tripItems),
                      ),
                      CupertinoListTile(
                        key: const Key('quick-setup-payment'),
                        leading: const _SetupIcon(
                          icon: CupertinoIcons.creditcard,
                        ),
                        title: Text(l10n.paymentMethodsTitle),
                        subtitle: Text(
                          _paymentStatus(l10n, paymentMethods, paymentItems),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                        ),
                        onTap: () => _openPaymentMethods(paymentItems),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.launchBackground.resolveFrom(context),
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  AppSpacing.medium,
                  AppSpacing.large,
                  AppSpacing.medium,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    key: const Key('quick-setup-finish'),
                    onPressed: _isFinishing ? null : _finish,
                    child: _isFinishing
                        ? const CupertinoActivityIndicator(radius: 9)
                        : Text(l10n.onboardingSetupEnterHome),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tripStatus(
    AppLocalizations l10n,
    AsyncValue<List<TripModel>> state,
    List<TripModel> items,
  ) {
    if (state.isLoading && !state.hasValue) return '…';
    if (items.isEmpty) return l10n.onboardingSetupTripNotCreated;
    if (items.length == 1) return items.single.name;
    return l10n.onboardingSetupTripCount(items.length);
  }

  String _paymentStatus(
    AppLocalizations l10n,
    AsyncValue<List<PaymentMethodModel>> state,
    List<PaymentMethodModel> items,
  ) {
    if (state.isLoading && !state.hasValue) return '…';
    if (items.isEmpty) return l10n.onboardingSetupPaymentNotAdded;
    return l10n.onboardingSetupPaymentCount(items.length);
  }

  Future<void> _chooseHomeCurrency() async {
    final result = await showCurrencyPickerPage(
      context: context,
      title: AppLocalizations.of(context).currencyHome,
      selected: _selectedCurrency,
      excluded: widget.excludedCurrency,
    );
    if (result?.currency case final selected?) {
      if (!mounted) return;
      setState(() => _selectedCurrency = selected);
      widget.onCurrencyChanged?.call(selected);
    }
  }

  Future<void> _openTrips(List<TripModel> trips) async {
    if (trips.isEmpty) {
      await Navigator.of(context).push<void>(
        CupertinoPageRoute<void>(
          builder: (context) =>
              TripEditorPage(defaultHomeCurrency: _selectedCurrency),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(builder: (context) => const TripsPage()),
    );
  }

  Future<void> _openPaymentMethods(
    List<PaymentMethodModel> paymentMethods,
  ) async {
    if (paymentMethods.isNotEmpty) {
      await context.push<void>(AppRoutes.paymentMethods);
      return;
    }
    final result = await Navigator.of(context).push<PaymentMethodModel>(
      CupertinoPageRoute<PaymentMethodModel>(
        builder: (context) => const PaymentMethodEditorPage(),
      ),
    );
    if (result == null || !mounted) return;
    await ref.read(paymentMethodsControllerProvider.notifier).save(result);
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await widget.onFinish(_selectedCurrency);
    } on Object {
      if (mounted) setState(() => _isFinishing = false);
    }
  }
}

class _SetupIcon extends StatelessWidget {
  const _SetupIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary.resolveFrom(context).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}
