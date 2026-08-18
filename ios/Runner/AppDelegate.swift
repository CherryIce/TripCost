import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private let platformApis = PlatformApiStubs()
  private let visionOcrApi = VisionOcrService()
  private var documentExportService: DocumentExportService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    guard let registrar = registry.registrar(forPlugin: "TripCostPlatformServices") else {
      return
    }
    let messenger = registrar.messenger()
    VisionOcrApiSetup.setUp(binaryMessenger: messenger, api: visionOcrApi)
    CloudSyncApiSetup.setUp(binaryMessenger: messenger, api: platformApis)
    SharedSnapshotApiSetup.setUp(binaryMessenger: messenger, api: platformApis)
    WidgetControlApiSetup.setUp(binaryMessenger: messenger, api: platformApis)
    documentExportService = DocumentExportService.register(
      binaryMessenger: messenger,
      presentingViewController: { [weak self] in self?.activeViewController() }
    )
  }

  private func activeViewController() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
    var current = root
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }
}
