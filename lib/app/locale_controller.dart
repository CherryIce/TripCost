import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';

final initialAppLanguageModeProvider = Provider<AppLanguageMode>((ref) {
  return AppLanguageMode.system;
});

final systemLocaleProvider = Provider<Locale>((ref) {
  return PlatformDispatcher.instance.locale;
});

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => _localeForMode(
    ref.watch(initialAppLanguageModeProvider),
    ref.watch(systemLocaleProvider),
  );

  void followSystem() => state = null;

  void useEnglish() => state = _localeForLanguage('en');

  void useSimplifiedChinese() => state = _localeForLanguage('zh');

  void setMode(AppLanguageMode mode) =>
      state = _localeForMode(mode, ref.read(systemLocaleProvider));

  Locale _localeForLanguage(String languageCode) {
    final system = ref.read(systemLocaleProvider);
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: system.languageCode == languageCode
          ? system.scriptCode
          : null,
      countryCode: system.countryCode,
    );
  }

  static Locale? _localeForMode(AppLanguageMode mode, Locale systemLocale) =>
      switch (mode) {
        AppLanguageMode.system => null,
        AppLanguageMode.simplifiedChinese => Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: systemLocale.languageCode == 'zh'
              ? systemLocale.scriptCode
              : null,
          countryCode: systemLocale.countryCode,
        ),
        AppLanguageMode.english => Locale.fromSubtags(
          languageCode: 'en',
          scriptCode: systemLocale.languageCode == 'en'
              ? systemLocale.scriptCode
              : null,
          countryCode: systemLocale.countryCode,
        ),
      };
}

Locale resolveSupportedAppLocale(Locale? preferredLocale) {
  final preferred = preferredLocale ?? const Locale('en');
  final languageCode = preferred.languageCode.toLowerCase() == 'zh'
      ? 'zh'
      : 'en';
  return Locale.fromSubtags(
    languageCode: languageCode,
    scriptCode: languageCode == preferred.languageCode.toLowerCase()
        ? preferred.scriptCode
        : null,
    countryCode: preferred.countryCode,
  );
}
