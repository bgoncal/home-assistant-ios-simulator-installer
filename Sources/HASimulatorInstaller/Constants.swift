import Foundation

enum Constants {
    static let minimumIOSVersion = "16.4"
    static let minimumXcodeVersion = "14.3"

    static let updateRepository = "bgoncal/home-assistant-ios-simulator-installer"
    static let updateAssetName = "Home-Assistant-Test-Lab.zip"

    static let keychainService = "io.home-assistant.SimulatorInstaller"
    static let xcodeBundleIdentifier = "com.apple.dt.Xcode"
    static let xcodeAppStoreURL = URL(string: "macappstore://apps.apple.com/app/id497799835")!

    static var gitHubClientID: String? {
        let value = Bundle.main.object(forInfoDictionaryKey: "GitHubClientID") as? String
            ?? ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"]
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    static let defaultServerPort = 8123
    static let pyPIProjectURL = URL(string: "https://pypi.org/pypi/homeassistant/json")!

    static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HASimulatorInstaller", isDirectory: true)
    }

    static var iOSBuildsDirectory: URL {
        cacheDirectory.appendingPathComponent("iOS", isDirectory: true)
    }

    static var androidBuildsDirectory: URL {
        cacheDirectory.appendingPathComponent("Android", isDirectory: true)
    }

    static var managedAndroidSDKDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HASimulatorInstaller/Android SDK", isDirectory: true)
    }

    static let androidVirtualDeviceName = "Home_Assistant_Test"
    static let androidSystemImageAPI = 36
    static let androidEmulatorHostAddress = "10.0.2.2"

    static var toolsDirectory: URL {
        cacheDirectory.appendingPathComponent("Tools", isDirectory: true)
    }

    static var coreBuildsDirectory: URL {
        cacheDirectory.appendingPathComponent("Core", isDirectory: true)
    }

    static var frontendBuildsDirectory: URL {
        cacheDirectory.appendingPathComponent("Frontend", isDirectory: true)
    }

    static var serverDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HASimulatorInstaller/Server", isDirectory: true)
    }

    static var serverConfigDirectory: URL {
        serverDirectory.appendingPathComponent("config", isDirectory: true)
    }

    static var serverLogFile: URL {
        serverDirectory.appendingPathComponent("server.log")
    }

    static var serverPIDFile: URL {
        serverDirectory.appendingPathComponent("server.pid")
    }
}
