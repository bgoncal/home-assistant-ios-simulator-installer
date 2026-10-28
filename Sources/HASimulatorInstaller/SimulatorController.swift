import Foundation

struct SimulatorController: Sendable {
    let developerDirectory: URL

    func checkLicense() async throws {
        let result = try await simctl(["list", "runtimes"])
        if !result.succeeded, (result.error + result.output).localizedCaseInsensitiveContains("license") {
            throw InstallerError("Open this Xcode once and agree to its license, then come back here.")
        }
    }

    func inventory() async throws -> (runtimes: [SimulatorRuntime], devices: [SimulatorDevice]) {
        let runtimes = try await decode(["list", "runtimes", "available", "-j"], as: RuntimeList.self).runtimes
            .filter { $0.identifier.contains("SimRuntime.iOS") && $0.isAvailable != false }
            .filter { $0.version.compare(Constants.minimumIOSVersion, options: .numeric) != .orderedAscending }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
            .map { runtime in
                SimulatorRuntime(
                    identifier: runtime.identifier,
                    name: runtime.name,
                    version: runtime.version,
                    build: runtime.buildversion,
                    deviceTypes: (runtime.supportedDeviceTypes ?? [])
                        .filter { $0.productFamily == "iPhone" || $0.productFamily == "iPad" }
                        .map { SimulatorDeviceType(identifier: $0.identifier, name: $0.name) }
                )
            }
        let devices = try await decode(["list", "devices", "available", "-j"], as: DeviceList.self).devices
            .flatMap { runtimeID, devices in
                devices.map {
                    SimulatorDevice(udid: $0.udid, name: $0.name, runtimeID: runtimeID, isBooted: $0.state == "Booted")
                }
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return (runtimes, devices)
    }

    func download(_ release: RuntimeRelease, progress: @escaping @Sendable (Double) -> Void) async throws {
        let xcodebuild = developerDirectory.appendingPathComponent("usr/bin/xcodebuild").path
        let result = try await ProcessRunner.run(
            xcodebuild,
            ["-downloadPlatform", "iOS", "-buildVersion", release.downloadVersion],
            environment: ["DEVELOPER_DIR": developerDirectory.path]
        ) { output in
            if let percentage = Self.lastPercentage(in: output) {
                progress(percentage / 100)
            }
        }
        guard result.succeeded else {
            throw InstallerError("Downloading \(release.displayName) failed: \(result.lastErrorLine)")
        }
    }

    func createDevice(_ type: SimulatorDeviceType, runtime: SimulatorRuntime, name: String? = nil) async throws -> SimulatorDevice {
        let name = name ?? type.name
        let result = try await simctl(["create", name, type.identifier, runtime.identifier])
        try require(result, "Couldn't create \(name)")
        return SimulatorDevice(
            udid: result.output.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name,
            runtimeID: runtime.identifier,
            isBooted: false
        )
    }

    func boot(_ device: SimulatorDevice) async throws {
        let result = try await simctl(["boot", device.udid])
        if !result.succeeded, !result.error.contains("current state: Booted") {
            throw InstallerError("Couldn't start \(device.name): \(result.lastErrorLine)")
        }
        if let simulatorApp {
            _ = try await ProcessRunner.run("/usr/bin/open", [
                "-a", simulatorApp.path,
                "--args", "-CurrentDeviceUDID", device.udid,
            ])
        }
        try await require(simctl(["bootstatus", device.udid, "-b"]), "\(device.name) didn't finish starting up")
    }

    func missingFrameworks(in app: URL) async throws -> [String] {
        let embedded = Set(
            ((try? FileManager.default.contentsOfDirectory(
                at: app.appendingPathComponent("Frameworks", isDirectory: true),
                includingPropertiesForKeys: nil
            )) ?? []).map(\.lastPathComponent)
        )

        var linked = Set<String>()
        for binary in machOCandidates(in: app) {
            let result = try await ProcessRunner.run(
                "/usr/bin/xcrun",
                ["otool", "-L", binary.path],
                environment: ["DEVELOPER_DIR": developerDirectory.path]
            )
            for match in result.output.matches(of: /@rpath\/([^\/\s]+\.framework)\//) {
                linked.insert(String(match.output.1))
            }
        }
        return linked.subtracting(embedded).sorted()
    }

    func uninstall(bundleID: String, from device: SimulatorDevice) async throws {
        _ = try await simctl(["uninstall", device.udid, bundleID])
    }

    func install(_ app: URL, on device: SimulatorDevice) async throws {
        try await require(simctl(["install", device.udid, app.path]), "Installing the app failed")
    }

    func launch(bundleID: String, on device: SimulatorDevice) async throws {
        try await require(simctl(["launch", device.udid, bundleID]), "Opening the app failed")
    }

    func open(_ url: URL, on device: SimulatorDevice) async throws {
        try await require(simctl(["openurl", device.udid, url.absoluteString]), "Opening the link in the app failed")
    }

    func terminate(bundleID: String, on device: SimulatorDevice) async throws {
        let result = try await simctl(["terminate", device.udid, bundleID])
        if !result.succeeded, !result.lastErrorLine.localizedCaseInsensitiveContains("found nothing to terminate") {
            throw InstallerError("Stopping the app failed: \(result.lastErrorLine)")
        }
    }

    func screenshot(of device: SimulatorDevice, to file: URL) async throws {
        try await require(
            simctl(["io", device.udid, "screenshot", file.path]),
            "Taking the screenshot failed"
        )
    }

    func startRecording(of device: SimulatorDevice, to file: URL) throws -> Process {
        try ProcessRunner.start(
            "/usr/bin/xcrun",
            ["simctl", "io", device.udid, "recordVideo", "--codec=h264", "--force", file.path],
            environment: ["DEVELOPER_DIR": developerDirectory.path]
        )
    }

    private func machOCandidates(in app: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: app,
            includingPropertiesForKeys: [.isRegularFileKey, .isExecutableKey]
        ) else { return [] }

        var candidates: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension == "xctest" {
                enumerator.skipDescendants()
                continue
            }
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isExecutableKey])
            if values?.isRegularFile == true, values?.isExecutable == true || url.pathExtension == "dylib" {
                candidates.append(url)
            }
        }
        return candidates
    }

    private var simulatorApp: URL? {
        [
            developerDirectory.appendingPathComponent("Applications/Simulator.app"),
            developerDirectory.deletingLastPathComponent().appendingPathComponent("Applications/DeviceHub.app"),
        ].first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func lastPercentage(in output: String) -> Double? {
        output.matches(of: /(\d{1,3}(?:\.\d+)?)\s?%/).last.flatMap { Double($0.output.1) }
    }

    private func simctl(_ arguments: [String]) async throws -> ProcessResult {
        try await ProcessRunner.run(
            "/usr/bin/xcrun",
            ["simctl"] + arguments,
            environment: ["DEVELOPER_DIR": developerDirectory.path]
        )
    }

    private func require(_ result: ProcessResult, _ message: String) throws {
        guard result.succeeded else {
            throw InstallerError("\(message): \(result.lastErrorLine)")
        }
    }

    private func decode<T: Decodable>(_ arguments: [String], as type: T.Type) async throws -> T {
        let result = try await simctl(arguments)
        guard result.succeeded else {
            throw InstallerError("Couldn't read the list of simulators: \(result.lastErrorLine)")
        }
        return try JSONDecoder().decode(T.self, from: Data(result.output.utf8))
    }

    private struct RuntimeList: Decodable {
        struct Runtime: Decodable {
            struct DeviceType: Decodable {
                let identifier: String
                let name: String
                let productFamily: String?
            }

            let identifier: String
            let name: String
            let version: String
            let buildversion: String
            let isAvailable: Bool?
            let supportedDeviceTypes: [DeviceType]?
        }

        let runtimes: [Runtime]
    }

    private struct DeviceList: Decodable {
        struct Device: Decodable {
            let udid: String
            let name: String
            let state: String
        }

        let devices: [String: [Device]]
    }
}
