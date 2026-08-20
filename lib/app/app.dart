import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/app/router/app_router.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/app_keyboard_actions.dart';

class TripCostApp extends ConsumerWidget {
  const TripCostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (preferred, _) =>
          resolveSupportedAppLocale(preferred),
      theme: AppTheme.cupertino,
      builder: (context, child) =>
          AppKeyboardDismissRegion(child: _SyncCompletionBanner(child: child!)),
    );
  }
}

final class _SyncCompletionBanner extends ConsumerStatefulWidget {
  const _SyncCompletionBanner({required this.child});

  final Widget child;

  @override
  ConsumerState<_SyncCompletionBanner> createState() =>
      _SyncCompletionBannerState();
}

final class _SyncCompletionBannerState
    extends ConsumerState<_SyncCompletionBanner> {
  Timer? _dismissTimer;
  bool _visible = false;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncCompletionProvider, (previous, next) {
      if (!next.hasValue) return;
      _dismissTimer?.cancel();
      setState(() => _visible = true);
      _dismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _visible = false);
      });
    });
    return Stack(
      textDirection: Directionality.of(context),
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + 8,
          start: 16,
          end: 16,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _visible ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    AppLocalizations.of(context).syncCompletedNotice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
