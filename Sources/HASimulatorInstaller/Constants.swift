import Foundation

enum Constants {
    static let repositoryOwner = "home-assistant"
    static let repositoryName = "iOS"
    static let workflowFile = "ci.yml"
    static let mainBranch = "main"
    static let artifactName = "ios-simulator"
    static let minimumIOSVersion = "16.4"
    static let minimumXcodeVersion = "14.3"

    static let updateRepository = "bgoncal/home-assistant-ios-simulator-installer"
    static let updateAssetName = "Home-Assistant-iOS-Simulator-Installer.zip"

    static let keychainService = "io.home-assistant.SimulatorInstaller"
    static let xcodeBundleIdentifier = "com.apple.dt.Xcode"
    static let xcodeAppStoreURL = URL(string: "macappstore://apps.apple.com/app/id497799835")!

    static var gitHubClientID: String? {
        let value = Bundle.main.object(forInfoDictionaryKey: "GitHubClientID") as? String
            ?? ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"]
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HASimulatorInstaller", isDirectory: true)
    }
}
