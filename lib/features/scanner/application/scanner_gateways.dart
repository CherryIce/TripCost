import 'package:image_picker/image_picker.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';

enum ScannerImageSource { camera, photoLibrary }

abstract interface class ScannerImagePicker {
  Future<String?> pick(ScannerImageSource source);
}

abstract interface class ScannerOcrGateway {
  Future<List<String>> supportedRecognitionLanguages();

  Future<OcrResult> recognizeImage(OcrRequest request);
}

final class DeviceScannerImagePicker implements ScannerImagePicker {
  DeviceScannerImagePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pick(ScannerImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source == ScannerImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      requestFullMetadata: false,
    );
    return image?.path;
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
