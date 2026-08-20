import 'package:trip_cost/core/domain/core_models.dart';

enum ScanPurpose { compare, record }

final class ScanPageArguments {
  const ScanPageArguments({
    this.initialPurpose = ScanPurpose.compare,
    this.trip,
  });

  final ScanPurpose initialPurpose;
  final TripModel? trip;
}
