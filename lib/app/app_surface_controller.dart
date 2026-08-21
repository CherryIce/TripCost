import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSurfaceMode { roamSum, futureInvest }

abstract interface class AppSurfaceStore {
  Future<AppSurfaceMode> load();

  Future<void> save(AppSurfaceMode mode);
}

final class SharedPreferencesAppSurfaceStore implements AppSurfaceStore {
  SharedPreferencesAppSurfaceStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const preferenceKey = 'app.surface_mode.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSurfaceMode> load() async {
    final stored = await _preferences.getString(preferenceKey);
    return AppSurfaceMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppSurfaceMode.roamSum,
    );
  }

  @override
  Future<void> save(AppSurfaceMode mode) {
    return _preferences.setString(preferenceKey, mode.name);
  }
}

final appSurfaceStoreProvider = Provider<AppSurfaceStore>((ref) {
  return SharedPreferencesAppSurfaceStore();
});

final initialAppSurfaceModeProvider = Provider<AppSurfaceMode>((ref) {
  return AppSurfaceMode.roamSum;
});

final appSurfaceControllerProvider =
    NotifierProvider<AppSurfaceController, AppSurfaceMode>(
      AppSurfaceController.new,
    );

final class AppSurfaceController extends Notifier<AppSurfaceMode> {
  @override
  AppSurfaceMode build() => ref.watch(initialAppSurfaceModeProvider);

  Future<void> setMode(AppSurfaceMode mode) async {
    if (mode == state) return;
    await ref.read(appSurfaceStoreProvider).save(mode);
    state = mode;
  }
}
