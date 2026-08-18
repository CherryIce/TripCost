import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let platformApis = PlatformApiStubs()
  private let visionOcrApi = VisionOcrService()
  private var documentExportService: DocumentExportService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    prepareLaunchSurface()
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return false
    }
    GeneratedPluginRegistrant.register(with: self)
    VisionOcrApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: visionOcrApi)
    CloudSyncApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: platformApis)
    SharedSnapshotApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: platformApis)
    WidgetControlApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: platformApis)
    documentExportService = DocumentExportService.register(
      binaryMessenger: controller.binaryMessenger,
      presentingViewController: controller
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func prepareLaunchSurface() {
    let launchBackground = UIColor(named: "LaunchBackground") ?? .systemGroupedBackground
    window?.backgroundColor = launchBackground

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    if controller.splashScreenView == nil {
      // UILaunchScreen covers system startup; keep the same surface visible until Flutter's first frame.
      let launchController = UIStoryboard(name: "LaunchScreen", bundle: nil)
        .instantiateInitialViewController()
      controller.splashScreenView = launchController?.view
    }
    // Do not force the Flutter view to load before the engine is ready.
    controller.viewIfLoaded?.backgroundColor = launchBackground
  }
}
