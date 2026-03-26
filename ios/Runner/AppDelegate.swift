import Flutter
import UIKit

private let icloudChannelName = "fr.tual.nousnous/icloud"

private func registerICloudChannel(_ messenger: FlutterBinaryMessenger) {
  let channel = FlutterMethodChannel(name: icloudChannelName, binaryMessenger: messenger)
  channel.setMethodCallHandler { call, result in
    switch call.method {
    case "isUbiquityAvailable":
      let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
      result(url != nil)

    case "backupExists":
      guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
        result(false)
        return
      }
      let path = container.appendingPathComponent("Documents").appendingPathComponent("easynounou_backup.zip").path
      result(FileManager.default.fileExists(atPath: path))

    case "backupModifiedMillis":
      guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
        result(nil)
        return
      }
      let url = container.appendingPathComponent("Documents").appendingPathComponent("easynounou_backup.zip")
      guard FileManager.default.fileExists(atPath: url.path) else {
        result(nil)
        return
      }
      do {
        let rv = try url.resourceValues(forKeys: [.contentModificationDateKey])
        if let d = rv.contentModificationDate {
          result(Int(d.timeIntervalSince1970 * 1000))
        } else {
          result(nil)
        }
      } catch {
        result(nil)
      }

    case "copyToICloud":
      guard let args = call.arguments as? [String: Any],
            let localPath = args["localPath"] as? String,
            let destName = args["destName"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
        return
      }
      guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
        result(FlutterError(code: "NO_ICLOUD", message: "Conteneur iCloud indisponible", details: nil))
        return
      }
      let docsURL = container.appendingPathComponent("Documents")
      do {
        try FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
        let destURL = docsURL.appendingPathComponent(destName)
        if FileManager.default.fileExists(atPath: destURL.path) {
          try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.copyItem(at: URL(fileURLWithPath: localPath), to: destURL)
        result(true)
      } catch {
        result(FlutterError(code: "COPY_FAIL", message: error.localizedDescription, details: nil))
      }

    case "copyFromICloud":
      guard let args = call.arguments as? [String: Any],
            let destLocalPath = args["destLocalPath"] as? String,
            let sourceName = args["sourceName"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
        return
      }
      guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
        result(FlutterError(code: "NO_ICLOUD", message: nil, details: nil))
        return
      }
      let srcURL = container.appendingPathComponent("Documents").appendingPathComponent(sourceName)
      guard FileManager.default.fileExists(atPath: srcURL.path) else {
        result(FlutterError(code: "NO_FILE", message: "Sauvegarde absente", details: nil))
        return
      }
      let destURL = URL(fileURLWithPath: destLocalPath)
      do {
        if FileManager.default.fileExists(atPath: destURL.path) {
          try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.copyItem(at: srcURL, to: destURL)
        result(true)
      } catch {
        result(FlutterError(code: "COPY_FAIL", message: error.localizedDescription, details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerICloudChannel(engineBridge.applicationRegistrar.messenger())
  }
}
