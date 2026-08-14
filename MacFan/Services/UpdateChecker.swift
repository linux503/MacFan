import AppKit
import Foundation
import Observation

struct AppVersionInfo: Sendable {
    var latestVersion: String
    var releaseNotes: String?
    var releaseURL: URL?
    var websiteURL: URL
}

enum UpdateCheckResult: Sendable {
    case upToDate(current: String)
    case available(current: String, info: AppVersionInfo)
    case failed(String)
}

@MainActor
@Observable
final class UpdateChecker {
    var isChecking = false
    var lastResult: UpdateCheckResult?
    var alertPresented = false
    var alertTitle = ""
    var alertMessage = ""
    var availableReleaseURL: URL?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func openWebsite() {
        NSWorkspace.shared.open(AppLinks.website)
    }

    func openGitHub() {
        NSWorkspace.shared.open(AppLinks.github)
    }

    func openReleaseOrWebsite() {
        if let availableReleaseURL {
            NSWorkspace.shared.open(availableReleaseURL)
        } else {
            openWebsite()
        }
    }

    func checkForUpdates(l10n: LocalizationStore) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        do {
            let info = try await fetchLatest()
            let current = currentVersion
            if isNewer(info.latestVersion, than: current) {
                lastResult = .available(current: current, info: info)
                availableReleaseURL = info.releaseURL ?? AppLinks.website
                alertTitle = l10n.t("alert.updateTitle")
                alertMessage = String(format: l10n.t("update.available"), info.latestVersion, current)
                if let notes = info.releaseNotes, !notes.isEmpty {
                    alertMessage += "\n\n" + notes
                }
            } else {
                lastResult = .upToDate(current: current)
                availableReleaseURL = nil
                alertTitle = l10n.t("alert.updateTitle")
                alertMessage = String(format: l10n.t("update.latest"), current)
            }
        } catch {
            lastResult = .failed(error.localizedDescription)
            availableReleaseURL = AppLinks.website
            alertTitle = l10n.t("alert.updateTitle")
            alertMessage = l10n.t("update.failed")
        }
        alertPresented = true
    }

    private func fetchLatest() async throws -> AppVersionInfo {
        if let pages = try? await fetchFromPages() {
            return pages
        }
        return try await fetchFromGitHub()
    }

    private func fetchFromPages() async throws -> AppVersionInfo {
        var request = URLRequest(url: AppLinks.versionManifest)
        request.timeoutInterval = 12
        request.setValue("MacFan/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let version = (json["version"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !version.isEmpty else { throw URLError(.cannotParseResponse) }
        let notes = json["notes"] as? String
        let release = (json["release_url"] as? String).flatMap(URL.init(string:))
        let site = (json["website"] as? String).flatMap(URL.init(string:)) ?? AppLinks.website
        return AppVersionInfo(latestVersion: version, releaseNotes: notes, releaseURL: release, websiteURL: site)
    }

    private func fetchFromGitHub() async throws -> AppVersionInfo {
        var request = URLRequest(url: AppLinks.githubLatestRelease)
        request.timeoutInterval = 12
        request.setValue("MacFan/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        var tag = (json["tag_name"] as? String) ?? ""
        if tag.lowercased().hasPrefix("v") { tag = String(tag.dropFirst()) }
        guard !tag.isEmpty else { throw URLError(.cannotParseResponse) }
        let notes = json["body"] as? String
        let html = (json["html_url"] as? String).flatMap(URL.init(string:))
        return AppVersionInfo(latestVersion: tag, releaseNotes: notes, releaseURL: html, websiteURL: AppLinks.website)
    }

    /// Semver-ish compare: "1.2.0" > "1.1.9"
    private func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 }
        let b = current.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 }
        let count = max(a.count, b.count)
        for i in 0..<count {
            let lhs = i < a.count ? a[i] : 0
            let rhs = i < b.count ? b[i] : 0
            if lhs != rhs { return lhs > rhs }
        }
        return false
    }
}
