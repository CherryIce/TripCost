import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/config/app_environment.dart';
import 'package:trip_cost/core/currencies/data/currency_directory_repository.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/expenses/data/drift_expense_repository.dart';
import 'package:trip_cost/core/payments/data/drift_payment_method_repository.dart';
import 'package:trip_cost/core/rates/application/offline_rate_pack_service.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/data/connectivity_network_status_provider.dart';
import 'package:trip_cost/core/rates/data/drift_rate_snapshot_repository.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';
import 'package:trip_cost/core/sync/application/local_data_change_coordinator.dart';
import 'package:trip_cost/core/sync/application/sync_orchestrator.dart';
import 'package:trip_cost/core/sync/data/drift_sync_store.dart';
import 'package:trip_cost/core/sync/data/platform_cloud_sync_gateway.dart';
import 'package:trip_cost/core/trips/data/drift_trip_repository.dart';
import 'package:trip_cost/core/widget/widget_snapshot_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final rateGatewayProvider = Provider<FrankfurterRatesGateway>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final base = environment.apiBaseUrl.toString().replaceFirst(
    RegExp(r'/$'),
    '',
  );
  final uri = base.endsWith('/v2')
      ? Uri.parse('$base/')
      : Uri.parse('$base/v2/');
  return FrankfurterApiClient(baseUri: uri);
});

final currencyDirectoryRepositoryProvider =
    Provider<CurrencyDirectoryRepository>((ref) {
      return CurrencyDirectoryRepository(
        database: ref.watch(appDatabaseProvider),
        gateway: ref.watch(rateGatewayProvider),
      );
    });

final rateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ExchangeRateRepository(
    marketGateway: ref.watch(rateGatewayProvider),
    snapshotRepository: DriftRateSnapshotRepository(database),
  );
});

final networkStatusProvider = Provider<NetworkStatusProvider>((ref) {
  return ConnectivityNetworkStatusProvider();
});

final rateRefreshSchedulerProvider = Provider<RateRefreshScheduler>((ref) {
  return RateRefreshScheduler(
    rateRepository: ref.watch(rateRepositoryProvider),
    networkStatusProvider: ref.watch(networkStatusProvider),
  );
});

final offlineRatePackServiceProvider = Provider<OfflineRatePackService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return OfflineRatePackService(
    refreshScheduler: ref.watch(rateRefreshSchedulerProvider),
    rateRepository: ref.watch(rateRepositoryProvider),
    statusStore: DriftOfflinePackStatusStore(database),
  );
});

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((
  ref,
) {
  return DriftPaymentMethodRepository(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(appDatabaseProvider));
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return DriftTripRepository(ref.watch(appDatabaseProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return DriftExpenseRepository(ref.watch(appDatabaseProvider));
});

final feeCalibrationRepositoryProvider = Provider<FeeCalibrationRepository>((
  ref,
) {
  return DriftFeeCalibrationRepository(ref.watch(appDatabaseProvider));
});

final syncStoreProvider = Provider<DriftSyncStore>((ref) {
  return DriftSyncStore(ref.watch(appDatabaseProvider));
});

final cloudSyncGatewayProvider = Provider<PlatformCloudSyncGateway>((ref) {
  return PlatformCloudSyncGateway();
});

final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(
    gateway: ref.watch(cloudSyncGatewayProvider),
    store: ref.watch(syncStoreProvider),
  );
});

final widgetSnapshotServiceProvider = Provider<WidgetSnapshotService>((ref) {
  return WidgetSnapshotService(ref.watch(appDatabaseProvider));
});

final productionLocalDataChangeCoordinatorProvider =
    Provider<LocalDataChangeCoordinator>((ref) {
      return LocalDataChangeCoordinator(
        settingsRepository: ref.watch(settingsRepositoryProvider),
        syncOrchestrator: ref.watch(syncOrchestratorProvider),
        widgetSnapshotService: ref.watch(widgetSnapshotServiceProvider),
      );
    });

final localDataChangeCoordinatorProvider = Provider<LocalDataChangeNotifier>(
  (ref) => const NoopLocalDataChangeNotifier(),
);
