import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';

final paymentMethodsControllerProvider =
    AsyncNotifierProvider<PaymentMethodsController, List<PaymentMethodModel>>(
      PaymentMethodsController.new,
    );

final class PaymentMethodsController
    extends AsyncNotifier<List<PaymentMethodModel>> {
  @override
  Future<List<PaymentMethodModel>> build() {
    return ref.watch(paymentMethodRepositoryProvider).listActive();
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
}
