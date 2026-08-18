import 'package:flutter/services.dart';

enum SystemPermission { camera, photoLibrary }

enum SystemPermissionStatus {
  notDetermined,
  granted,
  limited,
  denied,
  restricted,
  unavailable;

  bool get isAvailable =>
      this == SystemPermissionStatus.granted ||
      this == SystemPermissionStatus.limited;
}

abstract interface class SystemPermissionGateway {
  Future<SystemPermissionStatus> status(SystemPermission permission);

  Future<SystemPermissionStatus> request(SystemPermission permission);

  Future<bool> openSettings();
}

final class MethodChannelSystemPermissionGateway
    implements SystemPermissionGateway {
  const MethodChannelSystemPermissionGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('trip_cost/permissions');

  final MethodChannel _channel;

  @override
  Future<SystemPermissionStatus> status(SystemPermission permission) async {
    final value = await _channel.invokeMethod<String>(
      'status',
      <String, String>{'permission': permission.name},
    );
    return _decodeStatus(value);
  }

  @override
  Future<SystemPermissionStatus> request(SystemPermission permission) async {
    final value = await _channel.invokeMethod<String>(
      'request',
      <String, String>{'permission': permission.name},
    );
    return _decodeStatus(value);
  }

  @override
  Future<bool> openSettings() async =>
      await _channel.invokeMethod<bool>('openSettings') ?? false;

  SystemPermissionStatus _decodeStatus(String? value) => switch (value) {
    'notDetermined' => SystemPermissionStatus.notDetermined,
    'granted' => SystemPermissionStatus.granted,
    'limited' => SystemPermissionStatus.limited,
    'denied' => SystemPermissionStatus.denied,
    'restricted' => SystemPermissionStatus.restricted,
    _ => SystemPermissionStatus.unavailable,
  };
}

final class SystemPermissionGuard {
  const SystemPermissionGuard(this._gateway);

  final SystemPermissionGateway _gateway;

  Future<void> ensureAvailable(SystemPermission permission) async {
    var current = await _gateway.status(permission);
    if (current == SystemPermissionStatus.notDetermined) {
      current = await _gateway.request(permission);
    }
    if (!current.isAvailable) {
      throw SystemPermissionUnavailable(permission, current);
    }
  }
}

final class SystemPermissionUnavailable implements Exception {
  const SystemPermissionUnavailable(this.permission, this.status);

  final SystemPermission permission;
  final SystemPermissionStatus status;
}
