import Flutter
import UIKit
import UniformTypeIdentifiers

class SceneDelegate: FlutterSceneDelegate {
  private static let shareChannelName = "com.example.ketion/share_target"
  private static var pendingShares: [[String: Any]] = []
  private static var shareMethodChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    setupShareChannelIfNeeded()

    if !connectionOptions.urlContexts.isEmpty {
      handleIncomingUrls(connectionOptions.urlContexts)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    setupShareChannelIfNeeded()
    handleIncomingUrls(URLContexts)
  }

  private func setupShareChannelIfNeeded() {
    guard Self.shareMethodChannel == nil else { return }
    guard let controller = window?.rootViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(name: Self.shareChannelName, binaryMessenger: controller.binaryMessenger)
    Self.shareMethodChannel = channel

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getPendingShares" {
        let shares = Self.pendingShares
        Self.pendingShares.removeAll()
        result(shares)
      } else if call.method == "clearPendingShares" {
        Self.pendingShares.removeAll()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleIncomingUrls(_ urlContexts: Set<UIOpenURLContext>) {
    var receivedItems: [[String: Any]] = []

    for context in urlContexts {
      let url = context.url
      if url.isFileURL {
        if let item = processIncomingFileUrl(url) {
          receivedItems.append(item)
        }
      } else if let scheme = url.scheme, scheme == "http" || scheme == "https" {
        receivedItems.append([
          "type": "link",
          "name": url.absoluteString,
          "url": url.absoluteString,
        ])
      }
    }

    guard !receivedItems.isEmpty else { return }

    if let channel = Self.shareMethodChannel {
      channel.invokeMethod("onShareReceived", arguments: receivedItems)
    } else {
      Self.pendingShares.append(contentsOf: receivedItems)
    }
  }

  private func processIncomingFileUrl(_ url: URL) -> [String: Any]? {
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let fileName = url.lastPathComponent
    let fileExtension = url.pathExtension.lowercased()

    var mimeType = "application/octet-stream"
    if #available(iOS 14.0, *) {
      if let utType = UTType(filenameExtension: fileExtension),
         let preferredMime = utType.preferredMIMEType {
        mimeType = preferredMime
      }
    } else {
      if ["jpg", "jpeg", "png", "gif", "webp"].contains(fileExtension) {
        mimeType = "image/\(fileExtension == "jpg" ? "jpeg" : fileExtension)"
      } else if ["mp4", "mov", "m4v"].contains(fileExtension) {
        mimeType = "video/\(fileExtension)"
      } else if ["mp3", "m4a", "wav", "aac"].contains(fileExtension) {
        mimeType = "audio/\(fileExtension)"
      } else if fileExtension == "pdf" {
        mimeType = "application/pdf"
      }
    }

    let fileManager = FileManager.default
    guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      return nil
    }

    let incomingDir = cacheDir.appendingPathComponent("shared_incoming")
    try? fileManager.createDirectory(at: incomingDir, withIntermediateDirectories: true)

    let destinationUrl = incomingDir.appendingPathComponent("\(Int(Date().timeIntervalSince1970))_\(fileName)")
    try? fileManager.removeItem(at: destinationUrl)

    do {
      try fileManager.copyItem(at: url, to: destinationUrl)
      let attributes = try fileManager.attributesOfItem(atPath: destinationUrl.path)
      let fileSize = attributes[.size] as? Int64 ?? 0

      return [
        "type": "file",
        "name": fileName,
        "localPath": destinationUrl.path,
        "mimeType": mimeType,
        "size": fileSize
      ]
    } catch {
      return [
        "type": "file",
        "name": fileName,
        "localPath": url.path,
        "mimeType": mimeType,
        "size": 0
      ]
    }
  }
}
