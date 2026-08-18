import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/trips/domain/trip_budget.dart';
import 'package:uuid/uuid.dart';

final tripsControllerProvider =
    AsyncNotifierProvider<TripsController, List<TripModel>>(
      TripsController.new,
    );

final class TripsController extends AsyncNotifier<List<TripModel>> {
  StreamSubscription<void>? _cacheSubscription;

  @override
  Future<List<TripModel>> build() {
    final repository = ref.watch(tripRepositoryProvider);
    _observe(repository);
    return repository.listActive();
  }

  Future<void> save(TripModel trip) async {
    await ref.read(tripRepositoryProvider).save(trip);
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> archive(TripModel trip) async {
    final now = DateTime.now().toUtc();
    await save(_copyTrip(trip, now: now, status: TripStatus.archived));
  }

  Future<void> duplicate(TripModel trip) async {
    final now = DateTime.now().toUtc();
    final duration = trip.endDate.difference(trip.startDate);
    final start = localCalendarDate(now);
    final end = start.add(duration);
    await save(
      TripModel(
        metadata: SyncRecordMetadata(
          recordId: const Uuid().v4(),
          syncVersion: 1,
          updatedAt: now,
        ),
        name: trip.name,
        destinationCodes: trip.destinationCodes,
        startDate: start,
        endDate: end,
        homeCurrency: trip.homeCurrency,
        localCurrencies: trip.localCurrencies,
        totalBudget: trip.totalBudget,
        participantCount: trip.participantCount,
        defaultPaymentMethodId: trip.defaultPaymentMethodId,
        status: tripStatusForDates(startDate: start, endDate: end, now: now),
        createdAt: now,
      ),
    );
  }

  Future<void> delete(String id) async {
    await ref
        .read(tripRepositoryProvider)
        .softDelete(id, DateTime.now().toUtc());
    await _reload();
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> _reload() async {
    final cached = await ref.read(tripRepositoryProvider).listActive();
    if (ref.mounted) state = AsyncData(cached);
  }

  void _observe(TripRepository repository) {
    unawaited(_cacheSubscription?.cancel());
    _cacheSubscription = repository is CacheRepositoryObserver
        ? (repository as CacheRepositoryObserver).watchChanges().listen((_) {
            if (ref.mounted) unawaited(_reload());
          })
        : null;
    ref.onDispose(() => _cacheSubscription?.cancel());
  }
}

TripModel _copyTrip(
  TripModel trip, {
  required DateTime now,
  TripStatus? status,
}) {
  return TripModel(
    metadata: SyncRecordMetadata(
      recordId: trip.metadata.recordId,
      syncVersion: trip.metadata.syncVersion + 1,
      updatedAt: now,
    ),
    name: trip.name,
    destinationCodes: trip.destinationCodes,
    startDate: trip.startDate,
    endDate: trip.endDate,
    homeCurrency: trip.homeCurrency,
    localCurrencies: trip.localCurrencies,
    totalBudget: trip.totalBudget,
    participantCount: trip.participantCount,
    defaultPaymentMethodId: trip.defaultPaymentMethodId,
    offlinePackUpdatedAt: trip.offlinePackUpdatedAt,
    status: status ?? trip.status,
    createdAt: trip.createdAt,
  );
}
