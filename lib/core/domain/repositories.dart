import 'package:trip_cost/core/domain/core_models.dart';

abstract interface class CacheRepositoryObserver {
  Stream<void> watchChanges();
}

abstract interface class RateSnapshotRepository {
  Future<void> save(RateSnapshotModel snapshot);

  Future<RateSnapshotModel?> findById(String id);

  Future<RateSnapshotModel?> findLatest({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    RateSourceType? sourceType,
    DateTime? sourceAtOrBefore,
  });

  Future<void> softDeleteForPairAndSource({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    required RateSourceType sourceType,
    required DateTime deletedAtUtc,
  });
}

abstract interface class PaymentMethodRepository {
  Future<void> save(PaymentMethodModel paymentMethod);

  Future<List<PaymentMethodModel>> listActive();

  Future<void> softDelete(String id, DateTime deletedAtUtc);
}

abstract interface class TripRepository {
  Future<void> save(TripModel trip);

  Future<List<TripModel>> listActive();

  Future<TripModel?> findById(String id);

  Future<void> softDelete(String id, DateTime deletedAtUtc);
}

abstract interface class ExpenseRepository {
  Future<void> save(ExpenseModel expense);

  Future<List<ExpenseModel>> listActive();

  Future<ExpenseModel?> findById(String id);

  Future<List<ExpenseModel>> listForTrip(String tripId);

  Future<void> saveWithCalibration(
    ExpenseModel expense,
    FeeCalibrationModel calibration,
  );

  Future<void> softDelete(String id, DateTime deletedAtUtc);
}

abstract interface class FeeCalibrationRepository {
  Future<void> save(FeeCalibrationModel calibration);

  Future<List<FeeCalibrationModel>> listForPaymentMethod(
    String paymentMethodId,
  );
}

abstract interface class SettingsRepository {
  Future<UserSettingsModel?> load();

  Future<void> save(UserSettingsModel settings);
}
