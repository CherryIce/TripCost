import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';

ExchangeRateRepository createFakeRateRepository({
  DateTime? now,
  String rate = '0.047840625',
  Map<String, Duration> delays = const <String, Duration>{},
  FakeRateRequestCounter? requestCounter,
}) {
  final clock = now ?? DateTime.utc(2026, 8, 17, 8);
  return ExchangeRateRepository(
    marketGateway: _FakeRateGateway(
      rate: rate,
      now: clock,
      delays: delays,
      requestCounter: requestCounter,
    ),
    snapshotRepository: MemoryRateSnapshotRepository(),
    clock: () => clock,
    idFactory: () => 'fake-rate',
  );
}

final class FakeRateRequestCounter {
  int count = 0;
}

final class MemoryRateSnapshotRepository implements RateSnapshotRepository {
  final List<RateSnapshotModel> values = <RateSnapshotModel>[];

  @override
  Future<RateSnapshotModel?> findById(String id) async {
    return values.where((value) => value.metadata.recordId == id).firstOrNull;
  }

  @override
  Future<RateSnapshotModel?> findLatest({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    RateSourceType? sourceType,
    DateTime? sourceAtOrBefore,
  }) async {
    return values.reversed.where((value) {
      return value.metadata.deletedAt == null &&
          value.baseCurrency.code == baseCurrencyCode &&
          value.quoteCurrency.code == quoteCurrencyCode &&
          (sourceType == null || value.sourceType == sourceType) &&
          (sourceAtOrBefore == null ||
              !value.sourceTimestamp.isAfter(sourceAtOrBefore));
    }).firstOrNull;
  }

  @override
  Future<void> save(RateSnapshotModel snapshot) async {
    values.removeWhere(
      (value) => value.metadata.recordId == snapshot.metadata.recordId,
    );
    values.add(snapshot);
  }

  @override
  Future<void> softDeleteForPairAndSource({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    required RateSourceType sourceType,
    required DateTime deletedAtUtc,
  }) async {
    values.removeWhere(
      (value) =>
          value.baseCurrency.code == baseCurrencyCode &&
          value.quoteCurrency.code == quoteCurrencyCode &&
          value.sourceType == sourceType,
    );
  }
}

final class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository([this.value]);

  UserSettingsModel? value;

  @override
  Future<UserSettingsModel?> load() async => value;

  @override
  Future<void> save(UserSettingsModel settings) async {
    value = settings;
  }
}

final class MemoryPaymentMethodRepository implements PaymentMethodRepository {
  MemoryPaymentMethodRepository([
    Iterable<PaymentMethodModel> initial = const <PaymentMethodModel>[],
  ]) : values = <PaymentMethodModel>[...initial];

  final List<PaymentMethodModel> values;

  @override
  Future<List<PaymentMethodModel>> listActive() async => List.unmodifiable(
    values.where((value) => value.metadata.deletedAt == null),
  );

  @override
  Future<void> save(PaymentMethodModel paymentMethod) async {
    values.removeWhere(
      (value) => value.metadata.recordId == paymentMethod.metadata.recordId,
    );
    values.add(paymentMethod);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    values.removeWhere((value) => value.metadata.recordId == id);
  }
}

final class MemoryTripRepository implements TripRepository {
  MemoryTripRepository([Iterable<TripModel> initial = const <TripModel>[]])
    : values = <TripModel>[...initial];

  final List<TripModel> values;

  @override
  Future<TripModel?> findById(String id) async =>
      values.where((value) => value.metadata.recordId == id).firstOrNull;

  @override
  Future<List<TripModel>> listActive() async => List<TripModel>.unmodifiable(
    values.where((value) => value.metadata.deletedAt == null),
  );

  @override
  Future<void> save(TripModel trip) async {
    values.removeWhere(
      (value) => value.metadata.recordId == trip.metadata.recordId,
    );
    values.add(trip);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    values.removeWhere((value) => value.metadata.recordId == id);
  }
}

final class MemoryExpenseRepository implements ExpenseRepository {
  MemoryExpenseRepository([
    Iterable<ExpenseModel> initial = const <ExpenseModel>[],
  ]) : values = <ExpenseModel>[...initial];

  final List<ExpenseModel> values;

  @override
  Future<ExpenseModel?> findById(String id) async =>
      values.where((value) => value.metadata.recordId == id).firstOrNull;

  @override
  Future<List<ExpenseModel>> listActive() async =>
      List<ExpenseModel>.unmodifiable(values);

  @override
  Future<List<ExpenseModel>> listForTrip(String tripId) async =>
      List<ExpenseModel>.unmodifiable(
        values.where((value) => value.tripId == tripId),
      );

  @override
  Future<void> save(ExpenseModel expense) async {
    values.removeWhere(
      (value) => value.metadata.recordId == expense.metadata.recordId,
    );
    values.insert(0, expense);
  }

  @override
  Future<void> saveWithCalibration(
    ExpenseModel expense,
    FeeCalibrationModel calibration,
  ) => save(expense);

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    values.removeWhere((value) => value.metadata.recordId == id);
  }
}

final class MemoryFeeCalibrationRepository implements FeeCalibrationRepository {
  final List<FeeCalibrationModel> values = <FeeCalibrationModel>[];

  @override
  Future<List<FeeCalibrationModel>> listForPaymentMethod(
    String paymentMethodId,
  ) async => List<FeeCalibrationModel>.unmodifiable(
    values.where((value) => value.paymentMethodId == paymentMethodId),
  );

  @override
  Future<void> save(FeeCalibrationModel calibration) async {
    values.removeWhere(
      (value) => value.metadata.recordId == calibration.metadata.recordId,
    );
    values.add(calibration);
  }
}

final class FakeNetworkStatusProvider implements NetworkStatusProvider {
  const FakeNetworkStatusProvider([
    this.connectionType = NetworkConnectionType.wifi,
  ]);

  final NetworkConnectionType connectionType;

  @override
  Future<NetworkConnectionType> current() async => connectionType;
}

final class _FakeRateGateway implements FrankfurterRatesGateway {
  _FakeRateGateway({
    required this.rate,
    required this.now,
    required this.delays,
    this.requestCounter,
  });

  final String rate;
  final DateTime now;
  final Map<String, Duration> delays;
  final FakeRateRequestCounter? requestCounter;

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async => const [];

  @override
  Future<FrankfurterRateDto> getRate({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    DateTime? date,
  }) async {
    requestCounter?.count += 1;
    final delay = delays['$baseCurrencyCode:$quoteCurrencyCode'];
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    final resolvedRate = switch ((baseCurrencyCode, quoteCurrencyCode)) {
      ('JPY', 'CNY') => rate,
      ('CNY', 'JPY') => DecimalValue.parse(
        '1',
      ).divide(DecimalValue.parse(rate)).toString(),
      _ => '1',
    };
    return FrankfurterRateDto(
      date: date ?? now,
      baseCurrencyCode: baseCurrencyCode,
      quoteCurrencyCode: quoteCurrencyCode,
      rate: DecimalValue.parse(resolvedRate),
    );
  }

  @override
  Future<List<FrankfurterRateDto>> getRates({
    required String baseCurrencyCode,
    required Iterable<String> quoteCurrencyCodes,
    DateTime? date,
  }) async {
    final values = <FrankfurterRateDto>[];
    for (final quote in quoteCurrencyCodes) {
      values.add(
        await getRate(
          baseCurrencyCode: baseCurrencyCode,
          quoteCurrencyCode: quote,
          date: date,
        ),
      );
    }
    return values;
  }
}
