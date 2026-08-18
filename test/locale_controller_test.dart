import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/features/settings/application/general_settings_controller.dart';

import 'helpers/m4_fakes.dart';

void main() {
  test('switches between system, Chinese, and English', () {
    final container = ProviderContainer(
      overrides: [
        systemLocaleProvider.overrideWithValue(const Locale('en', 'GB')),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), isNull);
    container.read(localeControllerProvider.notifier).useSimplifiedChinese();
    expect(container.read(localeControllerProvider), const Locale('zh', 'GB'));
    container.read(localeControllerProvider.notifier).useEnglish();
    expect(container.read(localeControllerProvider), const Locale('en', 'GB'));
    container.read(localeControllerProvider.notifier).followSystem();
    expect(container.read(localeControllerProvider), isNull);
  });

  test('starts with the language mode persisted before app startup', () {
    final chinese = ProviderContainer(
      overrides: [
        systemLocaleProvider.overrideWithValue(const Locale('en', 'JP')),
        initialAppLanguageModeProvider.overrideWithValue(
          AppLanguageMode.simplifiedChinese,
        ),
      ],
    );
    final english = ProviderContainer(
      overrides: [
        systemLocaleProvider.overrideWithValue(const Locale('en', 'GB')),
        initialAppLanguageModeProvider.overrideWithValue(
          AppLanguageMode.english,
        ),
      ],
    );
    addTearDown(chinese.dispose);
    addTearDown(english.dispose);

    expect(chinese.read(localeControllerProvider), const Locale('zh', 'JP'));
    expect(english.read(localeControllerProvider), const Locale('en', 'GB'));
  });

  test('maps Chinese system locales to Chinese and all others to English', () {
    expect(
      resolveSupportedAppLocale(const Locale('zh', 'CN')),
      const Locale('zh', 'CN'),
    );
    expect(
      resolveSupportedAppLocale(const Locale('zh', 'TW')),
      const Locale('zh', 'TW'),
    );
    expect(
      resolveSupportedAppLocale(const Locale('en', 'US')),
      const Locale('en', 'US'),
    );
    expect(
      resolveSupportedAppLocale(const Locale('fr', 'FR')),
      const Locale('en', 'FR'),
    );
    expect(resolveSupportedAppLocale(null), const Locale('en'));
  });

  test(
    'settings selection persists the mode and updates runtime locale',
    () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [
          systemLocaleProvider.overrideWithValue(const Locale('en', 'GB')),
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(generalSettingsControllerProvider.future);

      await container
          .read(generalSettingsControllerProvider.notifier)
          .setLanguage(AppLanguageMode.simplifiedChinese);

      expect(repository.value?.languageMode, AppLanguageMode.simplifiedChinese);
      expect(
        container.read(localeControllerProvider),
        const Locale('zh', 'GB'),
      );

      await container
          .read(generalSettingsControllerProvider.notifier)
          .setLanguage(AppLanguageMode.system);

      expect(repository.value?.languageMode, AppLanguageMode.system);
      expect(container.read(localeControllerProvider), isNull);
    },
  );
}
