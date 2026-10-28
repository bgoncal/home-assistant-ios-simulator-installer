import AppKit
import Observation

@MainActor
@Observable
final class InstallerModel {
    let activityLog: ActivityLog
    let server: ServerModel
    let recentRuns = RecentRuns()

    var iOSEnabled = UserDefaults.standard.object(forKey: "iOSEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(iOSEnabled, forKey: "iOSEnabled") }
    }

    var xcodes: [XcodeInstallation] = []
    var selectedXcode: XcodeInstallation?
    var isCheckingSetup = false
    var licenseMessage: String?
    var runtimes: [SimulatorRuntime] = []
    var devices: [SimulatorDevice] = []
    var selectedRuntimeID: String?
    var deviceChoice: DeviceChoice?

    var xcodeReleases: [XcodeRelease] = []
    var runtimeReleases: [RuntimeRelease] = []
    var catalogError: String?
    var showsXcodeVersions = false
    var showsRuntimeVersions = false
    var showsBetas = false
    var activity: Activity?

    var username: String?
    var credentialSource: CredentialSource?
    var gitHubCLIAccounts: [String] = []
    var deviceCode: DeviceCode?
    var showsTokenEntry = false
    var tokenEntryError: String?

    var usePullRequest = false
    var pullRequestText = ""
    var startFresh = false

    var phase: InstallPhase = .idle {
        didSet {
            switch phase {
            case let .working(message, _):
                activityLog.add(message, for: .iOSApp)
            case let .done(summary):
                activityLog.add("Running \(summary.replacingOccurrences(of: "\n", with: ", "))", for: .iOSApp)
            case .idle:
                break
            }
        }
    }

    var errorMessage: String?
    private(set) var appErrorMessage: String?
    private(set) var installedBuild: ResolvedBuild?
    var installedDevice: SimulatorDevice?
    var runningBundleID: String?
    var appURLScheme: String?
    var recordingFile: URL?

    private var token: String?
    private var installedArtifactID: Int?
    private var signInTask: Task<Void, Never>?
    private var activityTask: Task<Void, Never>?
    private var recordingProcess: Process?
    private var installTask: Task<Void, Never>?

    init() {
        let activityLog = ActivityLog()
        self.activityLog = activityLog
        server = ServerModel(activityLog: activityLog)
    }

    func status(of component: Component) -> ComponentStatus {
        guard component == .iOSApp else { return server.status(of: component) }
        guard iOSEnabled else { return .off }
        if case let .working(message, _) = phase { return .working(message) }
        if let appErrorMessage { return .failed(appErrorMessage) }
        if runningBundleID != nil, let installedBuild { return .running(installedBuild.title) }
        return .ready
    }

    func removeAppFromSimulator() async {
        guard let simulator, let installedDevice, let runningBundleID else { return }
        do {
            try await simulator.uninstall(bundleID: runningBundleID, from: installedDevice)
            self.runningBundleID = nil
            installedArtifactID = nil
            phase = .idle
            activityLog.add("Removed the app from \(installedDevice.name)", for: .iOSApp)
        } catch {
            appErrorMessage = error.localizedDescription
        }
    }

    var hasXcode: Bool { selectedXcode != nil }
    var hasSimulators: Bool { !runtimes.isEmpty }
    var isSignedIn: Bool { token != nil }
    var isReady: Bool { hasXcode && licenseMessage == nil && hasSimulators && isSignedIn }
    var isRecording: Bool { recordingProcess != nil }
    var canSignInWithGitHub: Bool { Constants.gitHubClientID != nil }
    var isBusy: Bool { phase.isWorking || server.phase.isWorking }
    var canStop: Bool { isBusy || runningBundleID != nil || server.isRunning }
    var canConnectAppToServer: Bool { installedDevice != nil && appURLScheme != nil && server.running != nil }

    var selectedRuntime: SimulatorRuntime? {
        runtimes.first { $0.identifier == selectedRuntimeID }
    }

    var deviceChoices: [DeviceChoice] {
        guard let selectedRuntime else { return [] }
        let existing = devices.filter { $0.runtimeID == selectedRuntime.identifier }
        return existing.isEmpty
            ? selectedRuntime.deviceTypes.map(DeviceChoice.new)
            : existing.map(DeviceChoice.existing)
    }

    var visibleXcodeReleases: [XcodeRelease] {
        xcodeReleases.filter {
            ($0.isFinal || showsBetas)
                && $0.version.compare(Constants.minimumXcodeVersion, options: .numeric) != .orderedAscending
        }
    }

    var visibleRuntimeReleases: [RuntimeRelease] {
        runtimeReleases.filter { $0.isFinal || showsBetas }
    }

    var selectedSource: BuildSource? {
        guard usePullRequest else { return .latest }
        return BuildSource.pullRequestNumber(from: pullRequestText).map(BuildSource.pullRequest)
    }

    var canInstallApp: Bool {
        isReady && selectedSource != nil && deviceChoice != nil
    }

    var canRun: Bool {
        guard !isBusy, iOSEnabled || server.isActive else { return false }
        if iOSEnabled, !canInstallApp { return false }
        if server.isActive, !server.canStart(isSignedIn: isSignedIn) { return false }
        return true
    }

    private var simulator: SimulatorController? {
        selectedXcode.map { SimulatorController(developerDirectory: $0.developerDirectory) }
    }

    func runtimeLabel(_ runtime: SimulatorRuntime) -> String {
        let isAmbiguous = runtimes.filter { $0.version == runtime.version }.count > 1
        return isAmbiguous ? "\(runtime.name) (\(runtime.build))" : runtime.name
    }

    func isInstalled(_ release: XcodeRelease) -> Bool {
        xcodes.contains { $0.build == release.build }
    }

    func refreshSetup() async {
        isCheckingSetup = true
        defer { isCheckingSetup = false }
        errorMessage = nil

        await loadToken()

        xcodes = XcodeLocator.installations()
        if selectedXcode.map(xcodes.contains) != true {
            selectedXcode = await XcodeLocator.preferredSelection(in: xcodes)
        }
        await checkSelectedXcode()
    }

    func selectXcode(_ xcode: XcodeInstallation) async {
        guard xcode != selectedXcode else { return }
        selectedXcode = xcode
        XcodeLocator.remember(xcode)
        installedDevice = nil
        errorMessage = nil
        await checkSelectedXcode()
    }

    func selectRuntime(_ identifier: String?) {
        selectedRuntimeID = identifier
        deviceChoice = defaultDeviceChoice()
    }

    func loadCatalogs() async {
        catalogError = nil
        do {
            async let xcodeReleases = XcodeCatalog.fetch()
            async let runtimeReleases = RuntimeCatalog.fetch()
            (self.xcodeReleases, self.runtimeReleases) = try await (xcodeReleases, runtimeReleases)
        } catch {
            catalogError = "Couldn't load the list of versions: \(error.localizedDescription)"
        }
    }

    func getXcodeFromAppStore() {
        NSWorkspace.shared.open(Constants.xcodeAppStoreURL)
    }

    func openAppleDownloads() {
        NSWorkspace.shared.open(XcodeCatalog.moreDownloadsURL)
    }

    func download(_ release: XcodeRelease) {
        showsXcodeVersions = false
        NSWorkspace.shared.open(release.downloadURL)
        runActivity(Activity(
            title: "Waiting for \(release.fileName)",
            detail: "Sign in to Apple's developer site in your browser if asked. When the download finishes in your Downloads folder, Xcode is installed automatically."
        )) { model in
            let xip = try await XcodeInstaller.waitForDownload(of: release)
            model.activity?.title = "Installing \(release.displayName)"
            model.activity?.detail = "Unpacking takes 10 to 20 minutes. It ends up in Applications as \(release.installName)."
            let app = try await XcodeInstaller.install(xip, as: release.installName)
            model.xcodes = XcodeLocator.installations()
            if let installed = model.xcodes.first(where: { $0.url.standardizedFileURL == app.standardizedFileURL }) {
                await model.selectXcode(installed)
            }
        }
    }

    func download(_ release: RuntimeRelease) {
        guard let simulator, let xcode = selectedXcode else { return }
        showsRuntimeVersions = false
        runActivity(Activity(
            title: "Downloading \(release.displayName)",
            detail: "Using \(xcode.displayName). About \(release.fileSize.formatted(.byteCount(style: .file))).",
            progress: 0
        )) { model in
            let activityID = model.activity?.id
            try await simulator.download(release) { progress in
                Task { @MainActor in
                    guard model.activity?.id == activityID else { return }
                    model.activity?.progress = progress
                }
            }
            await model.reloadInventory()
            if let installed = model.runtimes.first(where: { $0.build == release.build || $0.version == release.version }) {
                model.selectRuntime(installed.identifier)
            }
        }
    }

    func cancelActivity() {
        activityTask?.cancel()
    }

    func signIn() {
        errorMessage = nil
        guard let clientID = Constants.gitHubClientID else {
            errorMessage = "This copy of the installer can't sign in to GitHub because it was built without a GitHub client ID."
            return
        }
        signInTask = Task {
            do {
                let code = try await GitHubAuth.requestDeviceCode(clientID: clientID)
                deviceCode = code
                let token = try await GitHubAuth.waitForToken(clientID: clientID, deviceCode: code)
                deviceCode = nil
                try await useStoredToken(token)
            } catch is CancellationError {
                deviceCode = nil
            } catch {
                deviceCode = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancelSignIn() {
        signInTask?.cancel()
        signInTask = nil
        deviceCode = nil
    }

    func copyCodeAndOpenGitHub(_ code: DeviceCode) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code.userCode, forType: .string)
        NSWorkspace.shared.open(code.verificationURI)
    }

    func useGitHubCLIAccount(_ login: String) async {
        errorMessage = nil
        guard let token = await GitHubAuth.gitHubCLIToken(for: login) else {
            errorMessage = "The GitHub CLI has no token for \(login). Run `gh auth login` again."
            return
        }
        do {
            try await adopt(token, source: .gitHubCLI(login))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func useAccessToken(_ value: String) async {
        tokenEntryError = nil
        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }
        do {
            try await useStoredToken(token)
            showsTokenEntry = false
        } catch {
            tokenEntryError = "GitHub didn't accept this token. Check that it was copied completely and hasn't expired."
        }
    }

    func openNewTokenPage() {
        NSWorkspace.shared.open(GitHubAuth.newTokenURL)
    }

    func signOut() {
        GitHubAuth.deleteStoredToken()
        GitHubAuth.savedSource = .signedOut
        credentialSource = .signedOut
        token = nil
        username = nil
    }

    func openSelectedXcode() {
        guard let selectedXcode else { return }
        NSWorkspace.shared.open(selectedXcode.url)
    }

    var currentSelection: RunSelection {
        RunSelection(
            iOSEnabled: iOSEnabled,
            iOSPullRequest: usePullRequest ? BuildSource.pullRequestNumber(from: pullRequestText) : nil,
            coreEnabled: server.coreEnabled,
            coreChannelValue: server.coreChannel.rawValue,
            corePullRequest: server.coreChannel == .pullRequest ? server.corePullRequest : nil,
            frontendEnabled: server.frontendEnabled,
            frontendChannelValue: server.frontendChannel.rawValue,
            frontendPullRequest: server.frontendChannel == .pullRequest ? server.frontendPullRequest : nil
        )
    }

    func apply(_ selection: RunSelection) {
        guard !isBusy else { return }
        iOSEnabled = selection.iOSEnabled
        usePullRequest = selection.iOSPullRequest != nil
        pullRequestText = selection.iOSPullRequest.map(String.init) ?? ""
        server.coreEnabled = selection.coreEnabled
        server.coreChannel = selection.coreChannel
        server.corePullRequestText = selection.corePullRequest.map(String.init) ?? ""
        server.frontendEnabled = selection.frontendEnabled
        server.frontendChannel = selection.frontendChannel
        server.frontendPullRequestText = selection.frontendPullRequest.map(String.init) ?? ""
    }

    func run() {
        guard canRun else { return }
        recentRuns.record(currentSelection)
        errorMessage = nil
        installTask = Task {
            async let serverRun: Void = startServerIfNeeded()
            async let appRun: Void = installAppIfNeeded()
            _ = await (serverRun, appRun)
            installTask = nil
        }
    }

    func stop() async {
        if isBusy {
            installTask?.cancel()
            return
        }
        await server.stop()
        guard let simulator, let installedDevice, let runningBundleID else { return }
        do {
            try await simulator.terminate(bundleID: runningBundleID, on: installedDevice)
            self.runningBundleID = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func connectAppToServer() async {
        guard let simulator, let installedDevice, let appURLScheme, let running = server.running else { return }
        let address = running.localURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        guard let invite = URL(string: "\(appURLScheme)://invite#url=\(address)") else { return }
        do {
            try await simulator.open(invite, on: installedDevice)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startServerIfNeeded() async {
        guard server.isActive else {
            await server.stop()
            return
        }
        await server.start(token: token)
    }

    private func installAppIfNeeded() async {
        guard iOSEnabled else { return }
        await installAndOpen()
    }

    private func installAndOpen() async {
        guard let simulator, let token, let runtime = selectedRuntime, let deviceChoice,
              let source = selectedSource else { return }
        appErrorMessage = nil
        let previousPhase = phase

        do {
            phase = .working("Finding the build…", progress: nil)
            let build = try await GitHubClient(token: token).resolve(source)

            if !startFresh, runningBundleID != nil, build.artifactID == installedArtifactID,
               case let .existing(device) = deviceChoice, device.udid == installedDevice?.udid {
                phase = previousPhase
                return
            }
            installedDevice = nil
            runningBundleID = nil
            installedArtifactID = nil

            let app: URL
            if let cached = BuildCache.extractedApp(for: build.artifactID) {
                app = cached
            } else {
                phase = .working("Downloading \(build.title)…", progress: 0)
                let zip = try await ArtifactDownloader.download(
                    GitHubClient(token: token).downloadRequest(artifactID: build.artifactID),
                    to: BuildCache.zipLocation(for: build.artifactID),
                    expectedSize: build.artifactSize
                ) { [weak self] progress in
                    Task { @MainActor in self?.updateDownloadProgress(progress, title: build.title) }
                }
                phase = .working("Unpacking…", progress: nil)
                app = try await BuildCache.extract(zip, artifactID: build.artifactID)
            }
            let bundleID = try BuildCache.bundleIdentifier(of: app)
            StorageCatalog.saveTitle("\(build.title) (\(build.commit))", in: app.deletingLastPathComponent())
            appURLScheme = BuildCache.urlScheme(of: app)

            phase = .working("Checking the build…", progress: nil)
            let missing = try await simulator.missingFrameworks(in: app)
            guard missing.isEmpty else {
                throw InstallerError(
                    "This build can't run in the Simulator: it was packaged without parts it needs (\(missing.joined(separator: ", "))), so it would crash as soon as it opens. Builds made before October 27, 2026 have this problem. Install the latest version instead, or, for a pull request, ask its author to push a new commit or update the branch so a new build is made."
                )
            }

            let device: SimulatorDevice
            switch deviceChoice {
            case let .existing(existing):
                device = existing
            case let .new(type):
                phase = .working("Creating \(type.name)…", progress: nil)
                device = try await simulator.createDevice(type, runtime: runtime)
            }

            phase = .working("Starting \(device.name)…", progress: nil)
            try await simulator.boot(device)

            if startFresh {
                phase = .working("Removing the old app…", progress: nil)
                try await simulator.uninstall(bundleID: bundleID, from: device)
            }

            phase = .working("Installing…", progress: nil)
            try await simulator.install(app, on: device)

            phase = .working("Opening the app…", progress: nil)
            try await simulator.launch(bundleID: bundleID, on: device)

            installedDevice = device
            runningBundleID = bundleID
            installedArtifactID = build.artifactID
            installedBuild = build
            phase = .done("\(build.title)\nCommit \(build.commit), built \(build.builtAt.formatted(.relative(presentation: .named)))")
            await reloadInventory()
            self.deviceChoice = .existing(devices.first { $0.udid == device.udid } ?? device)
        } catch {
            phase = .idle
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                activityLog.add("Stopped", for: .iOSApp)
                return
            }
            appErrorMessage = error.localizedDescription
            activityLog.add(error.localizedDescription, for: .iOSApp, isError: true)
        }
    }

    func takeScreenshot() async {
        guard let simulator, let installedDevice else { return }
        let file = desktopFile(extension: "png")
        do {
            try await simulator.screenshot(of: installedDevice, to: file)
            NSWorkspace.shared.activateFileViewerSelecting([file])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleRecording() {
        if let recordingProcess {
            recordingProcess.interrupt()
            recordingProcess.waitUntilExit()
            self.recordingProcess = nil
            if let recordingFile {
                NSWorkspace.shared.activateFileViewerSelecting([recordingFile])
            }
            return
        }

        guard let simulator, let installedDevice else { return }
        let file = desktopFile(extension: "mp4")
        do {
            recordingProcess = try simulator.startRecording(of: installedDevice, to: file)
            recordingFile = file
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkSelectedXcode() async {
        guard let simulator else {
            runtimes = []
            devices = []
            return
        }

        do {
            try await simulator.checkLicense()
            licenseMessage = nil
        } catch {
            licenseMessage = error.localizedDescription
            return
        }

        await reloadInventory()
    }

    private func runActivity(_ activity: Activity, _ work: @escaping @MainActor (InstallerModel) async throws -> Void) {
        guard self.activity == nil else { return }
        errorMessage = nil
        self.activity = activity
        activityTask = Task {
            do {
                try await work(self)
            } catch is CancellationError {
            } catch {
                errorMessage = error.localizedDescription
            }
            self.activity = nil
            activityTask = nil
        }
    }

    private func loadToken() async {
        gitHubCLIAccounts = await GitHubAuth.gitHubCLIAccounts()
        guard token == nil else { return }

        switch GitHubAuth.savedSource {
        case .signedOut:
            credentialSource = .signedOut
        case let .gitHubCLI(login):
            if let cli = await GitHubAuth.gitHubCLIToken(for: login) {
                try? await adopt(cli, source: .gitHubCLI(login))
            }
        case .stored, nil:
            if let stored = GitHubAuth.storedToken {
                do {
                    try await adopt(stored, source: .stored)
                } catch {
                    GitHubAuth.deleteStoredToken()
                }
            } else if let login = gitHubCLIAccounts.first, let cli = await GitHubAuth.gitHubCLIToken(for: login) {
                try? await adopt(cli, source: .gitHubCLI(login))
            }
        }
    }

    private func useStoredToken(_ token: String) async throws {
        try await adopt(token, source: .stored)
        GitHubAuth.store(token: token)
    }

    private func adopt(_ token: String, source: CredentialSource) async throws {
        let login = try await GitHubClient(token: token).username()
        self.token = token
        username = login
        credentialSource = source
        GitHubAuth.savedSource = source
        if case .gitHubCLI = source {
            GitHubAuth.deleteStoredToken()
        }
    }

    private func reloadInventory() async {
        guard let simulator else { return }
        do {
            (runtimes, devices) = try await simulator.inventory()
        } catch {
            runtimes = []
            devices = []
            errorMessage = error.localizedDescription
        }

        if selectedRuntime == nil {
            let booted = devices.first { device in device.isBooted && runtimes.contains { $0.identifier == device.runtimeID } }
            selectRuntime(booted?.runtimeID ?? runtimes.first?.identifier)
        } else if let deviceChoice, !deviceChoices.contains(deviceChoice) {
            self.deviceChoice = defaultDeviceChoice()
        } else if deviceChoice == nil {
            deviceChoice = defaultDeviceChoice()
        }
    }

    private func defaultDeviceChoice() -> DeviceChoice? {
        let choices = deviceChoices
        let booted = choices.first { if case let .existing(device) = $0 { device.isBooted } else { false } }
        let phone = choices.first { $0.label.hasPrefix("iPhone") }
        return booted ?? phone ?? choices.first
    }

    private func updateDownloadProgress(_ progress: Double, title: String) {
        guard phase.isWorking else { return }
        phase = .working("Downloading \(title)…", progress: progress)
    }

    private func desktopFile(extension fileExtension: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let name = "Home Assistant Simulator \(formatter.string(from: Date())).\(fileExtension)"
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
    }
}
