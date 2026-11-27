import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let appGroupId = "group.com.example.ketion"
    private var activityIndicator: UIActivityIndicatorView!
    private let syncQueue = DispatchQueue(label: "com.example.ketion.share_sync")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)

        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        processIncomingShare()
    }

    private func processIncomingShare() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeExtension()
            return
        }

        let group = DispatchGroup()
        var extractedItems: [[String: Any]] = []

        for item in items {
            let attachments = item.attachments ?? []
            var itemHandledAttachment = false

            for provider in attachments {
                itemHandledAttachment = true

                // 1. Video & Movie types (Apple Photos videos, QuickTime, MP4, etc.)
                if isVideoProvider(provider) {
                    group.enter()
                    let typeId = preferredTypeIdentifier(for: provider, matching: [.movie, .video, .audiovisualContent])
                        ?? UTType.movie.identifier
                    loadFileOrData(provider: provider, typeId: typeId, fallbackExtension: "mov") { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 2. Image types (Photos, Screenshots, Live Photos, third-party apps)
                else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    let typeId = preferredTypeIdentifier(for: provider, matching: [.image])
                        ?? UTType.image.identifier
                    loadImage(provider: provider, typeId: typeId) { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 3. Explicit File URLs (Files app, third-party document providers)
                else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    group.enter()
                    loadFileOrData(provider: provider, typeId: UTType.fileURL.identifier, fallbackExtension: nil) { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 4. PDF documents
                else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    group.enter()
                    loadFileOrData(provider: provider, typeId: UTType.pdf.identifier, fallbackExtension: "pdf") { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 5. Audio files (Voice Memos, Music, audio messages)
                else if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                    group.enter()
                    let typeId = preferredTypeIdentifier(for: provider, matching: [.audio])
                        ?? UTType.audio.identifier
                    loadFileOrData(provider: provider, typeId: typeId, fallbackExtension: "m4a") { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 6. Web URLs (Safari, Chrome, YouTube, Instagram, etc.)
                else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    loadURL(provider: provider) { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 7. Plain text / Rich text / HTML
                else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ||
                        provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    group.enter()
                    let typeId = provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                        ? UTType.plainText.identifier
                        : UTType.text.identifier
                    loadText(provider: provider, typeId: typeId) { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
                // 8. Any other generic file, data, or content type
                else if let fallbackTypeId = provider.registeredTypeIdentifiers.first {
                    group.enter()
                    let ext = UTType(fallbackTypeId)?.preferredFilenameExtension
                    loadFileOrData(provider: provider, typeId: fallbackTypeId, fallbackExtension: ext) { itemMap in
                        if let itemMap = itemMap {
                            self.syncQueue.sync { extractedItems.append(itemMap) }
                        }
                        group.leave()
                    }
                }
            }

            if !itemHandledAttachment,
               let text = item.attributedContentText?.string.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                syncQueue.sync {
                    extractedItems.append(makeTextOrLinkItem(text))
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.savePendingShares(extractedItems)
            self.completeExtension()
        }
    }

    private func isVideoProvider(_ provider: NSItemProvider) -> Bool {
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
           provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) ||
           provider.hasItemConformingToTypeIdentifier("com.apple.quicktime-movie") ||
           provider.hasItemConformingToTypeIdentifier("public.mpeg-4") {
            return true
        }
        // Only treat audiovisualContent as video when it is not purely audio.
        if provider.hasItemConformingToTypeIdentifier(UTType.audiovisualContent.identifier) &&
           !provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            return true
        }
        return false
    }

    private func preferredTypeIdentifier(for provider: NSItemProvider, matching targets: [UTType]) -> String? {
        return provider.registeredTypeIdentifiers.first { identifier in
            guard let type = UTType(identifier) else { return false }
            return targets.contains { type.conforms(to: $0) }
        }
    }

    private func loadFileOrData(
        provider: NSItemProvider,
        typeId: String,
        fallbackExtension: String?,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        provider.loadFileRepresentation(forTypeIdentifier: typeId) { [weak self] temporaryURL, _ in
            guard let self = self else {
                completion(nil)
                return
            }

            if let temporaryURL = temporaryURL,
               let itemMap = self.copyFileToAppGroup(url: temporaryURL, typeId: typeId) {
                completion(itemMap)
                return
            }

            // Fallback 1: loadItem (URL, Data, or String)
            provider.loadItem(forTypeIdentifier: typeId, options: nil) { [weak self] data, _ in
                guard let self = self else {
                    completion(nil)
                    return
                }

                if let url = data as? URL {
                    if url.isFileURL {
                        completion(self.copyFileToAppGroup(url: url, typeId: typeId))
                    } else if let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                        completion([
                            "type": "link",
                            "name": url.absoluteString,
                            "url": url.absoluteString
                        ])
                    } else {
                        completion(self.copyFileToAppGroup(url: url, typeId: typeId))
                    }
                    return
                }

                if let rawData = data as? Data {
                    if let parsedUrl = URL(dataRepresentation: rawData, relativeTo: nil),
                       parsedUrl.isFileURL {
                        completion(self.copyFileToAppGroup(url: parsedUrl, typeId: typeId))
                        return
                    }
                    completion(self.writeDataToAppGroup(rawData, typeId: typeId, fallbackExtension: fallbackExtension))
                    return
                }

                if let text = data as? String {
                    completion(self.makeTextOrLinkItem(text))
                    return
                }

                // Fallback 2: loadDataRepresentation
                provider.loadDataRepresentation(forTypeIdentifier: typeId) { [weak self] rawData, _ in
                    guard let self = self, let rawData = rawData else {
                        completion(nil)
                        return
                    }
                    completion(self.writeDataToAppGroup(rawData, typeId: typeId, fallbackExtension: fallbackExtension))
                }
            }
        }
    }

    private func loadImage(
        provider: NSItemProvider,
        typeId: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        provider.loadFileRepresentation(forTypeIdentifier: typeId) { [weak self] tempUrl, _ in
            guard let self = self else {
                completion(nil)
                return
            }
            if let url = tempUrl, let itemMap = self.copyFileToAppGroup(url: url, typeId: typeId) {
                completion(itemMap)
                return
            }

            provider.loadItem(forTypeIdentifier: typeId, options: nil) { [weak self] data, _ in
                guard let self = self else {
                    completion(nil)
                    return
                }
                if let url = data as? URL {
                    completion(self.copyFileToAppGroup(url: url, typeId: typeId))
                } else if let image = data as? UIImage,
                          let imageData = image.jpegData(compressionQuality: 0.95) ?? image.pngData() {
                    let ext = image.jpegData(compressionQuality: 0.95) != nil ? "jpg" : "png"
                    completion(self.writeDataToAppGroup(imageData, typeId: typeId, fallbackExtension: ext))
                } else if let rawData = data as? Data {
                    completion(self.writeDataToAppGroup(rawData, typeId: typeId, fallbackExtension: "jpg"))
                } else {
                    completion(nil)
                }
            }
        }
    }

    private func loadURL(
        provider: NSItemProvider,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
            guard let self = self else {
                completion(nil)
                return
            }

            if let url = data as? URL {
                if url.isFileURL {
                    completion(self.copyFileToAppGroup(url: url, typeId: UTType.fileURL.identifier))
                } else {
                    completion([
                        "type": "link",
                        "name": url.absoluteString,
                        "url": url.absoluteString
                    ])
                }
                return
            }

            if let rawData = data as? Data {
                if let parsedUrl = URL(dataRepresentation: rawData, relativeTo: nil) {
                    if parsedUrl.isFileURL {
                        completion(self.copyFileToAppGroup(url: parsedUrl, typeId: UTType.fileURL.identifier))
                    } else {
                        completion([
                            "type": "link",
                            "name": parsedUrl.absoluteString,
                            "url": parsedUrl.absoluteString
                        ])
                    }
                    return
                }
                if let str = String(data: rawData, encoding: .utf8) {
                    completion(self.makeTextOrLinkItem(str))
                    return
                }
            }

            if let text = data as? String {
                completion(self.makeTextOrLinkItem(text))
                return
            }

            completion(nil)
        }
    }

    private func loadText(
        provider: NSItemProvider,
        typeId: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        provider.loadItem(forTypeIdentifier: typeId, options: nil) { [weak self] data, _ in
            guard let self = self else {
                completion(nil)
                return
            }
            if let text = data as? String {
                completion(self.makeTextOrLinkItem(text))
            } else if let attributed = data as? NSAttributedString {
                completion(self.makeTextOrLinkItem(attributed.string))
            } else if let rawData = data as? Data,
                      let text = String(data: rawData, encoding: .utf8) {
                completion(self.makeTextOrLinkItem(text))
            } else if let url = data as? URL {
                if url.isFileURL {
                    completion(self.copyFileToAppGroup(url: url, typeId: typeId))
                } else {
                    completion([
                        "type": "link",
                        "name": url.absoluteString,
                        "url": url.absoluteString
                    ])
                }
            } else {
                completion(nil)
            }
        }
    }

    private func makeTextOrLinkItem(_ rawText: String) -> [String: Any] {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isUrl = (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")) &&
            !trimmed.contains(where: { $0.isWhitespace })
        if isUrl {
            return [
                "type": "link",
                "name": trimmed,
                "url": trimmed
            ]
        }
        return [
            "type": "text",
            "name": "Shared Text",
            "text": rawText
        ]
    }

    private func copyFileToAppGroup(url: URL, typeId: String? = nil) -> [String: Any]? {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let sharedDir = groupURL.appendingPathComponent("shared_incoming", isDirectory: true)
        try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true, attributes: nil)

        var fileName = url.lastPathComponent
        if fileName.isEmpty || fileName == "/" {
            let ext = typeId.flatMap { UTType($0)?.preferredFilenameExtension } ?? "bin"
            fileName = "shared_file.\(ext)"
        }
        let uniquePrefix = "\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8))"
        let destURL = sharedDir.appendingPathComponent("\(uniquePrefix)_\(fileName)")

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: url, to: destURL)

            let attributes = try? FileManager.default.attributesOfItem(atPath: destURL.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0

            return [
                "type": "file",
                "name": fileName,
                "localPath": destURL.path,
                "mimeType": destURL.mimeType(fallbackTypeId: typeId),
                "size": fileSize
            ]
        } catch {
            return nil
        }
    }

    private func writeDataToAppGroup(_ data: Data, typeId: String, fallbackExtension: String?) -> [String: Any]? {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let sharedDir = groupURL.appendingPathComponent("shared_incoming", isDirectory: true)
        try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true, attributes: nil)

        let ext = UTType(typeId)?.preferredFilenameExtension ?? fallbackExtension ?? "bin"
        let fileName = "shared_item.\(ext)"
        let uniquePrefix = "\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8))"
        let destURL = sharedDir.appendingPathComponent("\(uniquePrefix)_\(fileName)")

        do {
            try data.write(to: destURL, options: .atomic)
            return [
                "type": "file",
                "name": fileName,
                "localPath": destURL.path,
                "mimeType": destURL.mimeType(fallbackTypeId: typeId),
                "size": Int64(data.count)
            ]
        } catch {
            return nil
        }
    }

    private func savePendingShares(_ items: [[String: Any]]) {
        guard !items.isEmpty,
              let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return
        }

        let manifestURL = groupURL.appendingPathComponent("pending_shares.json")
        var existingList: [[String: Any]] = []

        if let data = try? Data(contentsOf: manifestURL),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
            existingList = json
        }

        existingList.append(contentsOf: items)

        if let updatedData = try? JSONSerialization.data(withJSONObject: existingList, options: .prettyPrinted) {
            try? updatedData.write(to: manifestURL)
        }
    }

    private func completeExtension() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

extension URL {
    func mimeType(fallbackTypeId: String? = nil) -> String {
        if !pathExtension.isEmpty,
           let uti = UTType(filenameExtension: pathExtension),
           let preferred = uti.preferredMIMEType {
            return preferred
        }
        if let typeId = fallbackTypeId,
           let uti = UTType(typeId),
           let preferred = uti.preferredMIMEType {
            return preferred
        }
        return "application/octet-stream"
    }
}
