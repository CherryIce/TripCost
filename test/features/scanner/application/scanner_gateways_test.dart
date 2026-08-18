import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trip_cost/core/platform/system_permissions.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';

void main() {
  test('checks the matching permission before every picker call', () async {
    final permissions = _FakePermissionGateway(SystemPermissionStatus.granted);
    final imagePicker = _FakeImagePicker();
    final picker = DeviceScannerImagePicker(
      imagePicker: imagePicker,
      permissionGateway: permissions,
    );

    await picker.pick(ScannerImageSource.camera);
    await picker.pick(ScannerImageSource.photoLibrary);

    expect(permissions.checked, <SystemPermission>[
      SystemPermission.camera,
      SystemPermission.photoLibrary,
    ]);
    expect(imagePicker.sources, <ImageSource>[
      ImageSource.camera,
      ImageSource.gallery,
    ]);
  });

  test('requests a not-determined permission before opening picker', () async {
    final permissions = _FakePermissionGateway(
      SystemPermissionStatus.notDetermined,
      requestedStatus: SystemPermissionStatus.limited,
    );
    final imagePicker = _FakeImagePicker();
    final picker = DeviceScannerImagePicker(
      imagePicker: imagePicker,
      permissionGateway: permissions,
    );

    await picker.pick(ScannerImageSource.photoLibrary);

    expect(permissions.requested, <SystemPermission>[
      SystemPermission.photoLibrary,
    ]);
    expect(imagePicker.sources, <ImageSource>[ImageSource.gallery]);
  });

  test('does not open picker when permission is unavailable', () async {
    final permissions = _FakePermissionGateway(SystemPermissionStatus.denied);
    final imagePicker = _FakeImagePicker();
    final picker = DeviceScannerImagePicker(
      imagePicker: imagePicker,
      permissionGateway: permissions,
    );

    await expectLater(
      picker.pick(ScannerImageSource.photoLibrary),
      throwsA(
        isA<SystemPermissionUnavailable>()
            .having(
              (error) => error.permission,
              'permission',
              SystemPermission.photoLibrary,
            )
            .having(
              (error) => error.status,
              'status',
              SystemPermissionStatus.denied,
            ),
      ),
    );
    expect(imagePicker.sources, isEmpty);
  });
}

final class _FakePermissionGateway implements SystemPermissionGateway {
  _FakePermissionGateway(this.current, {this.requestedStatus});

  SystemPermissionStatus current;
  final SystemPermissionStatus? requestedStatus;
  final List<SystemPermission> checked = <SystemPermission>[];
  final List<SystemPermission> requested = <SystemPermission>[];

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<SystemPermissionStatus> request(SystemPermission permission) async {
    requested.add(permission);
    current = requestedStatus ?? current;
    return current;
  }

  @override
  Future<SystemPermissionStatus> status(SystemPermission permission) async {
    checked.add(permission);
    return current;
  }
}

final class _FakeImagePicker extends ImagePicker {
  final List<ImageSource> sources = <ImageSource>[];

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    sources.add(source);
    return XFile('/tmp/permission-test.png');
  }
}
