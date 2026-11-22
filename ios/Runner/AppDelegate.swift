import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupId = "group.com.example.ketion"
  private let shareChannelName = "com.example.ketion/share_target"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(name: shareChannelName, binaryMessenger: controller.binaryMessenger)

      shareChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else { return }
        if call.method == "getPendingShares" {
          result(self.readPendingShares())
        } else if call.method == "clearPendingShares" {
          self.clearPendingShares()
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func readPendingShares() -> [[String: Any]] {
    guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
      return []
    }
    let manifestURL = groupURL.appendingPathComponent("pending_shares.json")
    guard let data = try? Data(contentsOf: manifestURL),
          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
      return []
    }
    return json
  }

  private func clearPendingShares() {
    guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
      return
    }
    let manifestURL = groupURL.appendingPathComponent("pending_shares.json")
    try? FileManager.default.removeItem(at: manifestURL)
  }
}
