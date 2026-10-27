import Foundation

struct XcodeInstallation: Identifiable, Hashable, Sendable {
    let url: URL
    let version: String
    let build: String

    var id: String { url.path }
    var developerDirectory: URL { url.appendingPathComponent("Contents/Developer", isDirectory: true) }
    var displayName: String { "Xcode \(version) (\(build))" }

    init?(url: URL) {
        guard let info = Bundle(url: url)?.infoDictionary,
              info["CFBundleIdentifier"] as? String == Constants.xcodeBundleIdentifier,
              let version = info["CFBundleShortVersionString"] as? String else { return nil }
        let versionPlist = NSDictionary(contentsOf: url.appendingPathComponent("Contents/version.plist"))
        self.url = url
        self.version = version
        build = versionPlist?["ProductBuildVersion"] as? String ?? "?"
    }
}
