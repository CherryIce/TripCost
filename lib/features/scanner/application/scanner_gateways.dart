import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/core/platform/system_permissions.dart';

enum ScannerImageSource { camera, photoLibrary }

abstract interface class ScannerImagePicker {
  Future<String?> pick(ScannerImageSource source);
}

abstract interface class ScannerOcrGateway {
  Future<List<String>> supportedRecognitionLanguages();

  Future<OcrResult> recognizeImage(OcrRequest request);
}

final class DeviceScannerImagePicker implements ScannerImagePicker {
  DeviceScannerImagePicker({
    ImagePicker? imagePicker,
    SystemPermissionGateway? permissionGateway,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _permissionGuard = SystemPermissionGuard(
         permissionGateway ?? const MethodChannelSystemPermissionGateway(),
       );

  final ImagePicker _imagePicker;
  final SystemPermissionGuard _permissionGuard;

  @override
  Future<String?> pick(ScannerImageSource source) async {
    final permission = source == ScannerImageSource.camera
        ? SystemPermission.camera
        : SystemPermission.photoLibrary;
    await _permissionGuard.ensureAvailable(permission);
    try {
      final image = await _imagePicker.pickImage(
        source: source == ScannerImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        requestFullMetadata: false,
      );
      return image?.path;
    } on PlatformException catch (error) {
      final status = switch (error.code) {
        'camera_access_restricted' ||
        'photo_access_restricted' => SystemPermissionStatus.restricted,
        'camera_access_denied' ||
        'photo_access_denied' => SystemPermissionStatus.denied,
        _ => null,
      };
      if (status != null) {
        throw SystemPermissionUnavailable(permission, status);
      }
      rethrow;
    }
  }
}

final class PigeonScannerOcrGateway implements ScannerOcrGateway {
  PigeonScannerOcrGateway({VisionOcrApi? api}) : _api = api ?? VisionOcrApi();

  final VisionOcrApi _api;

  @override
  Future<OcrResult> recognizeImage(OcrRequest request) =>
      _api.recognizeImage(request);

  @override
  Future<List<String>> supportedRecognitionLanguages() =>
      _api.supportedRecognitionLanguages();
}
