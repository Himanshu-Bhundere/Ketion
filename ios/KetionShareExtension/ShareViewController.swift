import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private let appGroupId = "group.com.example.ketion"
    private var activityIndicator: UIActivityIndicatorView!

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
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] (tempUrl, error) in
                        defer { group.leave() }
                        guard let self = self, let url = tempUrl else { return }
                        if let itemMap = self.copyFileToAppGroup(url: url) {
                            extractedItems.append(itemMap)
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (tempUrl, error) in
                        defer { group.leave() }
                        guard let self = self, let url = tempUrl else { return }
                        if let itemMap = self.copyFileToAppGroup(url: url) {
                            extractedItems.append(itemMap)
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] (data, error) in
                        defer { group.leave() }
                        guard let self = self, let url = data as? URL else { return }
                        if let itemMap = self.copyFileToAppGroup(url: url) {
                            extractedItems.append(itemMap)
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { [weak self] (tempUrl, error) in
                        defer { group.leave() }
                        guard let self = self, let url = tempUrl else { return }
                        if let itemMap = self.copyFileToAppGroup(url: url) {
                            extractedItems.append(itemMap)
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (data, error) in
                        defer { group.leave() }
                        if let url = data as? URL {
                            extractedItems.append([
                                "type": "link",
                                "name": url.absoluteString,
                                "url": url.absoluteString
                            ])
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                        defer { group.leave() }
                        if let text = data as? String {
                            let isUrl = text.hasPrefix("http://") || text.hasPrefix("https://")
                            extractedItems.append([
                                "type": isUrl ? "link" : "text",
                                "name": isUrl ? text : "Shared Text",
                                "url": isUrl ? text : nil as Any?,
                                "text": isUrl ? nil as Any? : text
                            ])
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.savePendingShares(extractedItems)
            self.completeExtension()
        }
    }

    private func copyFileToAppGroup(url: URL) -> [String: Any]? {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let sharedDir = groupURL.appendingPathComponent("shared_incoming", isDirectory: true)
        try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true, attributes: nil)

        let fileName = url.lastPathComponent
        let destURL = sharedDir.appendingPathComponent("\(Int(Date().timeIntervalSince1970))_\(fileName)")

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
                "mimeType": url.mimeType(),
                "size": fileSize
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
    func mimeType() -> String {
        if let uti = UTType(filenameExtension: pathExtension) {
            return uti.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
}
