import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';

final paymentMethodsControllerProvider =
    AsyncNotifierProvider<PaymentMethodsController, List<PaymentMethodModel>>(
      PaymentMethodsController.new,
    );

final class PaymentMethodsController
    extends AsyncNotifier<List<PaymentMethodModel>> {
  StreamSubscription<void>? _cacheSubscription;

  @override
  Future<List<PaymentMethodModel>> build() {
    final repository = ref.watch(paymentMethodRepositoryProvider);
    _observe(repository);
    return repository.listActive();
  }

  Future<void> save(PaymentMethodModel method) async {
    await ref.read(paymentMethodRepositoryProvider).save(method);
    state = AsyncData(
      await ref.read(paymentMethodRepositoryProvider).listActive(),
    );
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  Future<void> delete(String id) async {
    await ref
        .read(paymentMethodRepositoryProvider)
        .softDelete(id, DateTime.now().toUtc());
    state = AsyncData(
      await ref.read(paymentMethodRepositoryProvider).listActive(),
    );
    await ref.read(localDataChangeCoordinatorProvider).notify();
  }

  void _observe(PaymentMethodRepository repository) {
    unawaited(_cacheSubscription?.cancel());
    _cacheSubscription = repository is CacheRepositoryObserver
        ? (repository as CacheRepositoryObserver).watchChanges().listen((_) {
            if (ref.mounted) unawaited(_reload());
          })
        : null;
    ref.onDispose(() => _cacheSubscription?.cancel());
  }

  Future<void> _reload() async {
    final cached = await ref.read(paymentMethodRepositoryProvider).listActive();
    if (ref.mounted) state = AsyncData(cached);
  }
}
