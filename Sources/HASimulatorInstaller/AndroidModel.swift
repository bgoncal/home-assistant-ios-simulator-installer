import AppKit
import Observation

@MainActor
@Observable
final class AndroidModel {
    var enabled = UserDefaults.standard.bool(forKey: Keys.enabled) {
        didSet { UserDefaults.standard.set(enabled, forKey: Keys.enabled) }
    }

    var flavor = AndroidFlavor(rawValue: UserDefaults.standard.string(forKey: Keys.flavor) ?? "") ?? .full {
        didSet { UserDefaults.standard.set(flavor.rawValue, forKey: Keys.flavor) }
    }

    var usePullRequest = false
    var pullRequestText = ""
    var startFresh = false
    var device: AndroidVirtualDevice?

    private(set) var sdk: AndroidSDK?
    private(set) var devices: [AndroidVirtualDevice] = []
    private(set) var isCheckingSetup = false
    var activity: Activity?
    var showsLicense = false
    var showsAddDevice = false

    var phase: InstallPhase = .idle {
        didSet {
            switch phase {
            case let .working(message, _):
                activityLog.add(message, for: .androidApp)
            case let .done(summary):
                activityLog.add("Running \(summary.replacingOccurrences(of: "\n", with: ", "))", for: .androidApp)
            case .idle:
                break
            }
        }
    }

    private(set) var errorMessage: String?
    private(set) var installedBuild: ResolvedBuild?
    private(set) var installedPackage: String?
    private(set) var serial: String?

    let activityLog: ActivityLog
    private var installedArtifactID: Int?
    private var setupTask: Task<Void, Never>?
    private var pendingRequest: DeviceRequest?

    init(activityLog: ActivityLog) {
        self.activityLog = activityLog
    }

    var isReady: Bool { sdk?.hasEmulator == true && !devices.isEmpty }
    var isRunning: Bool { installedPackage != nil && serial != nil }
    var hasTestDevice: Bool { devices.contains { $0.name == Constants.androidVirtualDeviceName } }
    var selectedSource: BuildSource? {
        guard usePullRequest else { return .latest }
        return BuildSource.pullRequestNumber(from: pullRequestText).map(BuildSource.pullRequest)
    }

    func canInstall(isSignedIn: Bool) -> Bool {
        isReady && device != nil && selectedSource != nil && isSignedIn
    }

    func status() -> ComponentStatus {
        guard enabled else { return .off }
        if case let .working(message, _) = phase { return .working(message) }
        if let errorMessage { return .failed(errorMessage) }
        if isRunning, let installedBuild { return .running(installedBuild.title) }
        return .ready
    }

    func refreshSetup() async {
        isCheckingSetup = true
        defer { isCheckingSetup = false }
        sdk = AndroidSDK.locate()
        guard let sdk, sdk.hasEmulator else {
            devices = []
            device = nil
            return
        }
        devices = (try? await AndroidEmulatorController(sdk: sdk).devices()) ?? []
        if device.map(devices.contains) != true {
            device = devices.first { $0.name == Constants.androidVirtualDeviceName } ?? devices.first
        }
    }

    func setUpEmulator() {
        request(DeviceRequest(name: Constants.androidVirtualDeviceName, profile: .standard, version: nil))
    }

    func addDevice(named name: String, profile: AndroidDeviceProfile, version: AndroidVersion) {
        request(DeviceRequest(name: Self.deviceName(from: name), profile: profile, version: version))
    }

    func isInstalled(_ version: AndroidVersion) -> Bool {
        sdk?.installedSystemImages.contains(version.systemImage) == true
    }

    func hasDevice(named name: String) -> Bool {
        let deviceName = Self.deviceName(from: name)
        return devices.contains { $0.name == deviceName }
    }

    func acceptLicenseAndSetUp() {
        showsLicense = false
        if let pendingRequest {
            startSetup(pendingRequest)
        }
        pendingRequest = nil
    }

    private func request(_ request: DeviceRequest) {
        if AndroidSDKInstaller.needsLicenseAcceptance(sdk) {
            pendingRequest = request
            showsLicense = true
        } else {
            startSetup(request)
        }
    }

    private static func deviceName(from name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        return String(name.trimmingCharacters(in: .whitespaces).unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }

    func cancelSetup() {
        setupTask?.cancel()
    }

    func download(token: String) async {
        guard let source = selectedSource else { return }
        errorMessage = nil
        do {
            let (build, package) = try await fetch(source, token: token)
            let name = "Home Assistant \(flavor.label) \(build.commit).apk"
            let destination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: package.apk, to: destination)
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: destination.path)
            phase = .idle
            activityLog.add("Saved \(name) to Downloads", for: .androidApp)
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch {
            fail(error)
        }
    }

    func install(token: String) async {
        guard let sdk, let device, let source = selectedSource else { return }
        errorMessage = nil
        let previousPhase = phase
        let controller = AndroidEmulatorController(sdk: sdk)

        do {
            let (build, package) = try await fetch(source, token: token)
            if !startFresh, isRunning, build.artifactID == installedArtifactID, installedPackage == package.packageName,
               let serial, try await controller.runningSerial(of: device) == serial {
                phase = previousPhase
                return
            }
            installedArtifactID = nil
            installedPackage = nil
            serial = nil

            phase = .working("Starting \(device.displayName)… The first start takes a minute.", progress: nil)
            let serial = try await controller.boot(device)

            if startFresh {
                phase = .working("Removing the old app…", progress: nil)
                try await controller.uninstall(package.packageName, from: serial)
            }

            phase = .working("Installing…", progress: nil)
            try await controller.install(package.apk, on: serial)

            phase = .working("Opening the app…", progress: nil)
            try await controller.launch(package.packageName, on: serial)

            self.serial = serial
            installedPackage = package.packageName
            installedArtifactID = build.artifactID
            installedBuild = build
            phase = .done("\(build.title) (\(flavor.label))\nCommit \(build.commit), built \(build.builtAt.formatted(.relative(presentation: .named)))")
        } catch {
            fail(error)
        }
    }

    func stopApp() async {
        guard let sdk, let serial, let installedPackage else { return }
        try? await AndroidEmulatorController(sdk: sdk).stop(installedPackage, on: serial)
        self.installedPackage = nil
        phase = .idle
        activityLog.add("Closed the app", for: .androidApp)
    }

    func removeApp() async {
        guard let sdk, let serial, let installedPackage else { return }
        try? await AndroidEmulatorController(sdk: sdk).uninstall(installedPackage, from: serial)
        self.installedPackage = nil
        installedArtifactID = nil
        phase = .idle
        activityLog.add("Removed the app from the emulator", for: .androidApp)
    }

    func connect(to port: Int) async {
        guard let sdk, let serial, let installedPackage else { return }
        let address = "http://\(Constants.androidEmulatorHostAddress):\(port)"
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        guard let invite = URL(string: "homeassistant://invite#url=\(encoded)") else { return }
        do {
            try await AndroidEmulatorController(sdk: sdk).open(invite, in: installedPackage, on: serial)
        } catch {
            fail(error)
        }
    }

    func takeScreenshot(to file: URL) async {
        guard let sdk, let serial else { return }
        do {
            try await AndroidEmulatorController(sdk: sdk).screenshot(of: serial, to: file)
            NSWorkspace.shared.activateFileViewerSelecting([file])
        } catch {
            fail(error)
        }
    }

    private func fetch(_ source: BuildSource, token: String) async throws -> (ResolvedBuild, AndroidPackage) {
        phase = .working("Finding the build…", progress: nil)
        let gitHub = GitHubClient(token: token, repository: .android)
        let build = try await gitHub.resolve(source)

        if let cached = APKCache.package(for: build.artifactID, flavor: flavor) {
            return (build, cached)
        }

        phase = .working("Downloading \(build.title)…", progress: 0)
        let zip = try await ArtifactDownloader.download(
            gitHub.downloadRequest(artifactID: build.artifactID),
            to: APKCache.zipLocation(for: build.artifactID),
            expectedSize: build.artifactSize
        ) { [weak self] progress in
            Task { @MainActor in
                guard let self, self.phase.isWorking else { return }
                self.phase = .working("Downloading \(build.title)…", progress: progress)
            }
        }
        phase = .working("Unpacking…", progress: nil)
        try await APKCache.extract(zip, artifactID: build.artifactID, title: "\(build.title) (\(build.commit))")
        guard let package = APKCache.package(for: build.artifactID, flavor: flavor) else {
            throw InstallerError("This build has no \(flavor.label.lowercased()) version of the app.")
        }
        return (build, package)
    }

    private func startSetup(_ request: DeviceRequest) {
        guard activity == nil else { return }
        errorMessage = nil
        let displayName = AndroidVirtualDevice(name: request.name).displayName
        activity = Activity(
            title: isReady ? "Adding \(displayName)" : "Setting up the Android emulator",
            detail: nil,
            progress: nil
        )
        setupTask = Task {
            do {
                let sdk = try await AndroidSDKInstaller.setUp(
                    sdk,
                    deviceName: request.name,
                    profile: request.profile,
                    version: request.version
                ) { [weak self] step, progress in
                    self?.activity?.detail = step
                    self?.activity?.progress = progress
                    self?.activityLog.add(step, for: .androidApp)
                }
                self.sdk = sdk
                await refreshSetup()
                device = devices.first { $0.name == request.name } ?? device
                activityLog.add("\(displayName) is ready", for: .androidApp)
            } catch is CancellationError {
            } catch {
                fail(error)
            }
            activity = nil
            setupTask = nil
        }
    }

    private func fail(_ error: Error) {
        phase = .idle
        if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
            activityLog.add("Stopped", for: .androidApp)
            return
        }
        errorMessage = error.localizedDescription
        activityLog.add(error.localizedDescription, for: .androidApp, isError: true)
    }

    private struct DeviceRequest {
        let name: String
        let profile: AndroidDeviceProfile
        let version: AndroidVersion?
    }

    private enum Keys {
        static let enabled = "androidEnabled"
        static let flavor = "androidFlavor"
    }
}
