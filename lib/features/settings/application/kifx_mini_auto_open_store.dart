import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KifxMiniAutoOpenStore {
  Future<bool> isEnabled();

  Future<void> enable();
}

final class SharedPreferencesKifxMiniAutoOpenStore
    implements KifxMiniAutoOpenStore {
  SharedPreferencesKifxMiniAutoOpenStore([
    Future<SharedPreferences> Function()? loadPreferences,
  ]) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const preferenceKey = 'kifx_mini_auto_open';

  final Future<SharedPreferences> Function() _loadPreferences;

  @override
  Future<bool> isEnabled() async {
    return (await _loadPreferences()).getBool(preferenceKey) ?? false;
  }

  @override
  Future<void> enable() async {
    await (await _loadPreferences()).setBool(preferenceKey, true);
  }
}

final kifxMiniAutoOpenStoreProvider = Provider<KifxMiniAutoOpenStore>((ref) {
  return SharedPreferencesKifxMiniAutoOpenStore();
});
