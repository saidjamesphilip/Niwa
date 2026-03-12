import Foundation
import AppKit

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var downloadURL: String?
    @Published var isChecking = false

    private let currentVersion: String
    private let releasesURL = "https://api.github.com/repos/saidjamesphilip/Niwa/releases/latest"

    init() {
        self.currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    func checkForUpdates() async {
        isChecking = true
        defer { isChecking = false }

        guard let url = URL(string: releasesURL) else { return }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else { return }

            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            latestVersion = remoteVersion
            downloadURL = htmlURL
            updateAvailable = isNewer(remote: remoteVersion, current: currentVersion)
        } catch {
            // Silently fail — the app is offline-first
        }
    }

    private func isNewer(remote: String, current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(remoteParts.count, currentParts.count) {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }

    func openDownloadPage() {
        guard let urlString = downloadURL, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
