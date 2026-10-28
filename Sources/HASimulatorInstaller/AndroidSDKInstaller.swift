import Foundation

@MainActor
enum AndroidSDKInstaller {
    static let licenseURL = URL(string: "https://developer.android.com/studio/terms")!
    private static let repositoryURL = URL(string: "https://dl.google.com/android/repository/repository2-3.xml")!

    static func needsLicenseAcceptance(_ sdk: AndroidSDK?) -> Bool {
        !(sdk?.hasAcceptedLicense ?? false)
    }

    static func setUp(
        _ existing: AndroidSDK?,
        deviceName: String = Constants.androidVirtualDeviceName,
        profile: AndroidDeviceProfile = .standard,
        version: AndroidVersion? = nil,
        step: @escaping @Sendable @MainActor (String, Double?) -> Void
    ) async throws -> AndroidSDK {
        let sdk = existing ?? AndroidSDK(root: Constants.managedAndroidSDKDirectory)
        try FileManager.default.createDirectory(at: sdk.root, withIntermediateDirectories: true)

        step("Getting Java…", nil)
        let java = try await JavaRuntime.home()
        let environment = [
            "JAVA_HOME": java.path,
            "ANDROID_HOME": sdk.root.path,
            "ANDROID_SDK_ROOT": sdk.root.path,
        ]

        if !sdk.hasCommandLineTools {
            step("Downloading the Android command-line tools…", nil)
            try await installCommandLineTools(in: sdk)
        }

        if !sdk.hasAcceptedLicense {
            step("Accepting the Android SDK license…", nil)
            try require(
                await ProcessRunner.run(
                    "/bin/sh",
                    ["-c", "yes | \"$0\" --licenses --sdk_root=\"$1\"", sdk.sdkManager.path, sdk.root.path],
                    environment: environment
                ),
                "Couldn't accept the Android SDK license"
            )
        }

        let image = version?.systemImage ?? systemImage(in: sdk)
        var packages: [String] = []
        if !FileManager.default.isExecutableFile(atPath: sdk.adb.path) { packages.append("platform-tools") }
        if !FileManager.default.isExecutableFile(atPath: sdk.emulator.path) { packages.append("emulator") }
        if !sdk.installedSystemImages.contains(image) { packages.append(image) }
        if !packages.isEmpty {
            let message = packages == [image] ? "Downloading \(version?.name ?? "Android")… This is about 2 GB." : "Downloading the Android emulator… This is a few gigabytes."
            step(message, 0)
            try require(
                await ProcessRunner.run(
                    sdk.sdkManager.path,
                    ["--sdk_root=\(sdk.root.path)"] + packages,
                    environment: environment
                ) { output in
                    guard let percent = lastPercentage(in: output) else { return }
                    Task { @MainActor in step(message, percent) }
                },
                "Couldn't download the Android emulator"
            )
        }

        let devices = try await AndroidEmulatorController(sdk: sdk).devices()
        if !devices.contains(where: { $0.name == deviceName }) {
            step("Creating \(AndroidVirtualDevice(name: deviceName).displayName)…", nil)
            try require(
                await ProcessRunner.run(
                    "/bin/sh",
                    [
                        "-c", "echo no | \"$0\" create avd --name \"$1\" --package \"$2\" --device \"$3\"",
                        sdk.avdManager.path, deviceName, image, profile.id,
                    ],
                    environment: environment
                ),
                "Couldn't create the device"
            )
        }
        return sdk
    }

    private static func systemImage(in sdk: AndroidSDK) -> String {
        #if arch(arm64)
        let abi = "arm64-v8a"
        #else
        let abi = "x86_64"
        #endif
        let preferred = "system-images;android-\(Constants.androidSystemImageAPI);google_apis_playstore;\(abi)"
        if sdk.installedSystemImages.contains(preferred) {
            return preferred
        }
        return sdk.installedSystemImages
            .filter { $0.hasSuffix(";\(abi)") && $0.contains(";google_apis") }
            .max() ?? preferred
    }

    private static func installCommandLineTools(in sdk: AndroidSDK) async throws {
        let (data, _) = try await URLSession.shared.data(from: repositoryURL)
        let catalog = String(decoding: data, as: UTF8.self)
        let latest = catalog.matches(of: /commandlinetools-mac-(\d+)_latest\.zip/)
            .compactMap { Int($0.1) }
            .max()
        guard let latest,
              let url = URL(string: "https://dl.google.com/android/repository/commandlinetools-mac-\(latest)_latest.zip") else {
            throw InstallerError("Couldn't find the Android command-line tools to download.")
        }

        let (archive, response) = try await URLSession.shared.download(from: url)
        defer { try? FileManager.default.removeItem(at: archive) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw InstallerError("Couldn't download the Android command-line tools. Check your internet connection and try again.")
        }

        let toolsDirectory = sdk.root.appendingPathComponent("cmdline-tools", isDirectory: true)
        let unpacked = toolsDirectory.appendingPathComponent("unpacked-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: unpacked, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: unpacked) }
        try require(
            await ProcessRunner.run("/usr/bin/ditto", ["-x", "-k", archive.path, unpacked.path]),
            "Couldn't unpack the Android command-line tools"
        )
        let destination = toolsDirectory.appendingPathComponent("latest", isDirectory: true)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: unpacked.appendingPathComponent("cmdline-tools"), to: destination)
    }

    nonisolated private static func lastPercentage(in output: String) -> Double? {
        guard let match = output.matches(of: /(\d{1,3})%/).last, let value = Double(match.1) else { return nil }
        return min(value / 100, 1)
    }

    private static func require(_ result: ProcessResult, _ message: String) throws {
        guard result.succeeded else {
            throw InstallerError("\(message): \(result.lastErrorLine)")
        }
    }
}
