import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/app/router/app_router.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

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
      theme: AppTheme.cupertino,
    );
  }
}
