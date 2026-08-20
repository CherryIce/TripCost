import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';
import 'package:trip_cost/features/onboarding/application/default_currency_recommender.dart';
import 'package:trip_cost/features/onboarding/presentation/quick_setup_page.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _pageCount = 3;

  final _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;
  bool _showQuickSetup = false;
  Currency? _selectedCurrency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedCurrency ??= const DefaultCurrencyRecommender().recommend(
      ref.read(systemLocaleProvider),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showQuickSetup) {
      return QuickSetupPage(
        key: const Key('onboarding-quick-setup'),
        initialCurrency: _selectedCurrency!,
        onBack: () => setState(() => _showQuickSetup = false),
        onCurrencyChanged: (currency) => _selectedCurrency = currency,
        onFinish: (currency) {
          _selectedCurrency = currency;
          return _finish();
        },
      );
    }
    final localizations = AppLocalizations.of(context);
    final pages = <_OnboardingContent>[
      _OnboardingContent(
        asset: 'assets/onboarding/scan_price.png',
        title: localizations.onboardingScanTitle,
        subtitle: localizations.onboardingScanSubtitle,
      ),
      _OnboardingContent(
        asset: 'assets/onboarding/compare_payments.png',
        title: localizations.onboardingCompareTitle,
        subtitle: localizations.onboardingCompareSubtitle,
      ),
      _OnboardingContent(
        asset: 'assets/onboarding/track_budget.png',
        title: localizations.onboardingBudgetTitle,
        subtitle: localizations.onboardingBudgetSubtitle,
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.launchBackground,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CupertinoButton(
                onPressed: _isFinishing ? null : () => _finish(),
                child: Text(localizations.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _OnboardingSlide(content: pages[index]),
              ),
            ),
            _PageIndicator(currentPage: _currentPage, pageCount: _pageCount),
            const SizedBox(height: AppSpacing.large),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isFinishing ? null : _advance,
                  child: Text(
                    _currentPage == _pageCount - 1
                        ? localizations.onboardingSetupStart
                        : localizations.onboardingNext,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
          ],
        ),
      ),
    );
  }

  Future<void> _advance() async {
    if (_currentPage == _pageCount - 1) {
      setState(() => _showQuickSetup = true);
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final previous = await repository.load();
      final now = DateTime.now().toUtc();
      final selected = _selectedCurrency!;
      await repository.save(
        UserSettingsModel(
          metadata: SyncRecordMetadata(
            recordId: DriftSettingsRepository.settingsRecordId,
            syncVersion: (previous?.metadata.syncVersion ?? 0) + 1,
            updatedAt: now,
          ),
          defaultCurrency: selected,
          lastTransactionCurrency:
              previous?.lastTransactionCurrency ??
              fallbackTransactionCurrency(),
          // Kept only to preserve compatibility with existing settings rows.
          favoriteCurrencies:
              previous?.favoriteCurrencies ?? const <Currency>[],
          languageMode: previous?.languageMode ?? AppLanguageMode.system,
          refreshInterval:
              previous?.refreshInterval ?? const Duration(hours: 6),
          wifiOnlyRefresh: previous?.wifiOnlyRefresh ?? false,
          syncEnabled: previous?.syncEnabled ?? false,
        ),
      );
    } on Object {
      // Default settings are best-effort; onboarding completion remains separate.
    }
    try {
      await ref.read(startupStateStoreProvider).markOnboardingComplete();
    } on Object {
      // Local storage failure must not block entering the app.
    }
    if (!mounted) return;
    GoRouter.of(context).go(AppRoutes.home);
  }
}

class _OnboardingContent {
  const _OnboardingContent({
    required this.asset,
    required this.subtitle,
    required this.title,
  });

  final String asset;
  final String subtitle;
  final String title;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content});

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final imageHeight = textScale > 1.2 ? 220.0 : 300.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Image.asset(
              content.asset,
              height: imageHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            content.subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 17,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (index) {
        final isCurrent = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isCurrent
                ? AppColors.primary.resolveFrom(context)
                : CupertinoColors.systemGrey4.resolveFrom(context),
          ),
        );
      }),
    );
  }
}
