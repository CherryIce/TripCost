import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/app/app_surface_controller.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/destinations/country_directory.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase.open();
  final initialLanguageMode = await _loadInitialLanguageMode(database);
  final initialAppSurfaceMode = await _loadInitialAppSurfaceMode();
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(database.close);
          return database;
        }),
        initialAppLanguageModeProvider.overrideWithValue(initialLanguageMode),
        initialAppSurfaceModeProvider.overrideWithValue(initialAppSurfaceMode),
        localDataChangeCoordinatorProvider.overrideWith(
          (ref) => ref.watch(productionLocalDataChangeCoordinatorProvider),
        ),
      ],
      child: const _ProductionAppBootstrap(),
    ),
  );
}

Future<AppSurfaceMode> _loadInitialAppSurfaceMode() async {
  try {
    return await SharedPreferencesAppSurfaceStore().load();
  } on Object {
    return AppSurfaceMode.roamSum;
  }
}

Future<AppLanguageMode> _loadInitialLanguageMode(AppDatabase database) async {
  try {
    final settings = await DriftSettingsRepository(database).load();
    return settings?.languageMode ?? AppLanguageMode.system;
  } on Object {
    return AppLanguageMode.system;
  }
}

final class _ProductionAppBootstrap extends ConsumerStatefulWidget {
  const _ProductionAppBootstrap();

  @override
  ConsumerState<_ProductionAppBootstrap> createState() =>
      _ProductionAppBootstrapState();
}

final class _ProductionAppBootstrapState
    extends ConsumerState<_ProductionAppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(Future<void>(CountryDirectory.prewarm));
      if (mounted) {
        unawaited(ref.read(localDataChangeCoordinatorProvider).notify());
      }
    });
  }

  @override
  Widget build(BuildContext context) => const TripCostApp();
}
