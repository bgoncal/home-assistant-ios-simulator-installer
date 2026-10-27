import AppKit
import CryptoKit
import Observation

@MainActor
@Observable
final class Updater {
    var state: UpdateState = .idle

    static var currentVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    func check(userInitiated: Bool) async {
        guard let currentVersion = Self.currentVersion else {
            if userInitiated {
                state = .failed("Updates only work in the built app, not when running from source.", nil)
            }
            return
        }
        if case .installing = state { return }

        state = .checking
        do {
            let update = try await latestRelease()
            if update.version.compare(currentVersion, options: .numeric) == .orderedDescending {
                state = .available(update)
            } else {
                state = userInitiated ? .upToDate : .idle
            }
        } catch {
            state = userInitiated ? .failed("Couldn't check for updates: \(error.localizedDescription)", nil) : .idle
        }
    }

    func dismiss() {
        state = .idle
    }

    func openReleasePage(_ update: AppUpdate) {
        NSWorkspace.shared.open(update.pageURL)
    }

    func install(_ update: AppUpdate) async {
        state = .installing(update)
        do {
            let currentApp = Bundle.main.bundleURL
            guard currentApp.pathExtension == "app" else {
                throw InstallerError("Updates only work in the built app, not when running from source.")
            }

            let workDirectory = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: currentApp,
                create: true
            )
            defer { try? FileManager.default.removeItem(at: workDirectory) }

            let (download, response) = try await URLSession.shared.download(from: update.downloadURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw InstallerError("The update couldn't be downloaded.")
            }
            let zip = workDirectory.appendingPathComponent(Constants.updateAssetName)
            try FileManager.default.moveItem(at: download, to: zip)

            if let expected = update.sha256 {
                let actual = SHA256.hash(data: try Data(contentsOf: zip)).map { String(format: "%02x", $0) }.joined()
                guard actual == expected.lowercased() else {
                    throw InstallerError("The downloaded update is damaged. Try again.")
                }
            }

            let extracted = workDirectory.appendingPathComponent("extracted", isDirectory: true)
            let unzip = try await ProcessRunner.run("/usr/bin/ditto", ["-x", "-k", zip.path, extracted.path])
            guard unzip.succeeded,
                  let newApp = try FileManager.default.contentsOfDirectory(at: extracted, includingPropertiesForKeys: nil)
                  .first(where: { $0.pathExtension == "app" }),
                  let newBundle = Bundle(url: newApp),
                  newBundle.bundleIdentifier == Bundle.main.bundleIdentifier,
                  newBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == update.version
            else {
                throw InstallerError("The downloaded update isn't a valid copy of this app.")
            }
            _ = try? await ProcessRunner.run("/usr/bin/xattr", ["-dr", "com.apple.quarantine", newApp.path])

            do {
                _ = try FileManager.default.replaceItemAt(currentApp, withItemAt: newApp)
            } catch {
                throw InstallerError(
                    "The app couldn't replace itself in \(currentApp.deletingLastPathComponent().path). Download the update from its release page instead."
                )
            }

            try relaunch(currentApp)
        } catch {
            state = .failed(error.localizedDescription, update)
        }
    }

    private func relaunch(_ app: URL) throws {
        let script = "while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.2; done; open \"$0\""
        _ = try ProcessRunner.start("/bin/sh", ["-c", script, app.path])
        NSApp.terminate(nil)
    }

    private func latestRelease() async throws -> AppUpdate {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(Constants.updateRepository)/releases/latest")!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("HASimulatorInstaller", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw InstallerError("GitHub didn't return the latest release.")
        }

        let release = try JSONDecoder().decode(Release.self, from: data)
        guard let asset = release.assets.first(where: { $0.name == Constants.updateAssetName }) else {
            throw InstallerError("The latest release has no app to download.")
        }
        return AppUpdate(
            version: release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV")),
            notes: release.body ?? "",
            downloadURL: asset.browserDownloadURL,
            sha256: asset.digest.flatMap { $0.hasPrefix("sha256:") ? String($0.dropFirst(7)) : nil },
            pageURL: release.htmlURL
        )
    }

    private struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browserDownloadURL: URL
            let digest: String?

            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadURL = "browser_download_url"
                case digest
            }
        }

        let tagName: String
        let body: String?
        let htmlURL: URL
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case body
            case htmlURL = "html_url"
            case assets
        }
    }
}
