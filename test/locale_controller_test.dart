import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/locale_controller.dart';

void main() {
  test('switches between system, Chinese, and English', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), isNull);
    container.read(localeControllerProvider.notifier).useSimplifiedChinese();
    expect(container.read(localeControllerProvider), const Locale('zh'));
    container.read(localeControllerProvider.notifier).useEnglish();
    expect(container.read(localeControllerProvider), const Locale('en'));
    container.read(localeControllerProvider.notifier).followSystem();
    expect(container.read(localeControllerProvider), isNull);
  });
}
