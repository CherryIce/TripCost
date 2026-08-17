import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/data/connectivity_network_status_provider.dart';

void main() {
  test('prefers wifi when multiple transports are active', () {
    expect(
      networkConnectionTypeFor(<ConnectivityResult>[
        ConnectivityResult.mobile,
        ConnectivityResult.wifi,
      ]),
      NetworkConnectionType.wifi,
    );
  });

  test('maps mobile, none, and other transports for refresh policy', () {
    expect(
      networkConnectionTypeFor(<ConnectivityResult>[ConnectivityResult.mobile]),
      NetworkConnectionType.cellular,
    );
    expect(
      networkConnectionTypeFor(<ConnectivityResult>[ConnectivityResult.none]),
      NetworkConnectionType.offline,
    );
    expect(
      networkConnectionTypeFor(<ConnectivityResult>[
        ConnectivityResult.ethernet,
      ]),
      NetworkConnectionType.other,
    );
  });
}
