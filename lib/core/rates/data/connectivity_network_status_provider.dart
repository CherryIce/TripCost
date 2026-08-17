import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';

final class ConnectivityNetworkStatusProvider implements NetworkStatusProvider {
  ConnectivityNetworkStatusProvider({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<NetworkConnectionType> current() async {
    return networkConnectionTypeFor(await _connectivity.checkConnectivity());
  }
}

NetworkConnectionType networkConnectionTypeFor(
  Iterable<ConnectivityResult> results,
) {
  final values = results.toSet();
  if (values.contains(ConnectivityResult.wifi)) {
    return NetworkConnectionType.wifi;
  }
  if (values.contains(ConnectivityResult.mobile)) {
    return NetworkConnectionType.cellular;
  }
  if (values.isEmpty ||
      (values.length == 1 && values.contains(ConnectivityResult.none))) {
    return NetworkConnectionType.offline;
  }
  return NetworkConnectionType.other;
}
