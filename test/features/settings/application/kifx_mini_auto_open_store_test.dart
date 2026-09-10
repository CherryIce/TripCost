import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_cost/features/settings/application/kifx_mini_auto_open_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('successful enable persists automatic KIFX opening', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPreferencesKifxMiniAutoOpenStore();

    expect(await store.isEnabled(), isFalse);

    await store.enable();

    expect(await SharedPreferencesKifxMiniAutoOpenStore().isEnabled(), isTrue);
  });
}
