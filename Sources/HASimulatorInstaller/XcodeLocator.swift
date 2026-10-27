import AppKit

enum XcodeLocator {
    private static let selectionKey = "selectedXcodePath"

    static func installations() -> [XcodeInstallation] {
        let applications = URL(fileURLWithPath: "/Applications", isDirectory: true)
        let scanned = (try? FileManager.default.contentsOfDirectory(at: applications, includingPropertiesForKeys: nil)) ?? []
        let registered = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: Constants.xcodeBundleIdentifier)

        var seen = Set<String>()
        return (scanned + registered)
            .filter { $0.pathExtension == "app" }
            .map(\.standardizedFileURL)
            .filter { seen.insert($0.path).inserted }
            .compactMap(XcodeInstallation.init(url:))
            .sorted {
                $0.version.compare($1.version, options: .numeric) == .orderedDescending
            }
    }

    static func preferredSelection(in installations: [XcodeInstallation]) async -> XcodeInstallation? {
        if let saved = UserDefaults.standard.string(forKey: selectionKey),
           let match = installations.first(where: { $0.url.path == saved }) {
            return match
        }
        if let selected = await xcodeSelectPath(),
           let match = installations.first(where: { selected.hasPrefix($0.url.path) }) {
            return match
        }
        return installations.first { $0.url.path == "/Applications/Xcode.app" } ?? installations.first
    }

    static func remember(_ installation: XcodeInstallation) {
        UserDefaults.standard.set(installation.url.path, forKey: selectionKey)
    }

    private static func xcodeSelectPath() async -> String? {
        guard let result = try? await ProcessRunner.run("/usr/bin/xcode-select", ["-p"]), result.succeeded else {
            return nil
        }
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
