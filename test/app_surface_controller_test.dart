import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app_surface_controller.dart';

void main() {
  test('starts from the mode loaded before app startup', () {
    final container = ProviderContainer(
      overrides: [
        initialAppSurfaceModeProvider.overrideWithValue(
          AppSurfaceMode.futureInvest,
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appSurfaceControllerProvider),
      AppSurfaceMode.futureInvest,
    );
  });

  test('persists a surface change before publishing it', () async {
    final store = _MemoryAppSurfaceStore();
    final container = ProviderContainer(
      overrides: [appSurfaceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container
        .read(appSurfaceControllerProvider.notifier)
        .setMode(AppSurfaceMode.futureInvest);

    expect(store.value, AppSurfaceMode.futureInvest);
    expect(
      container.read(appSurfaceControllerProvider),
      AppSurfaceMode.futureInvest,
    );
  });

  test('keeps the current surface when persistence fails', () async {
    final container = ProviderContainer(
      overrides: [
        appSurfaceStoreProvider.overrideWithValue(
          _MemoryAppSurfaceStore(shouldFail: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(appSurfaceControllerProvider.notifier)
          .setMode(AppSurfaceMode.futureInvest),
      throwsStateError,
    );
    expect(
      container.read(appSurfaceControllerProvider),
      AppSurfaceMode.roamSum,
    );
  });
}

final class _MemoryAppSurfaceStore implements AppSurfaceStore {
  _MemoryAppSurfaceStore({this.shouldFail = false});

  final bool shouldFail;
  AppSurfaceMode value = AppSurfaceMode.roamSum;

  @override
  Future<AppSurfaceMode> load() async => value;

  @override
  Future<void> save(AppSurfaceMode mode) async {
    if (shouldFail) throw StateError('save failed');
    value = mode;
  }
}
