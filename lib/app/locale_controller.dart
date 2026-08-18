import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void followSystem() => state = null;

  void useEnglish() => state = const Locale('en');

  void useSimplifiedChinese() => state = const Locale('zh');

  void setMode(AppLanguageMode mode) {
    state = switch (mode) {
      AppLanguageMode.system => null,
      AppLanguageMode.simplifiedChinese => const Locale('zh'),
      AppLanguageMode.english => const Locale('en'),
    };
  }
}
