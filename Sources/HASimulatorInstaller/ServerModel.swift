import AppKit
import Observation

@MainActor
@Observable
final class ServerModel {
    var coreEnabled = UserDefaults.standard.bool(forKey: Keys.coreEnabled) {
        didSet { UserDefaults.standard.set(coreEnabled, forKey: Keys.coreEnabled) }
    }

    var coreChannel = CoreChannel(rawValue: UserDefaults.standard.string(forKey: Keys.coreChannel) ?? "") ?? .release {
        didSet { UserDefaults.standard.set(coreChannel.rawValue, forKey: Keys.coreChannel) }
    }

    var frontendEnabled = UserDefaults.standard.bool(forKey: Keys.frontendEnabled) {
        didSet { UserDefaults.standard.set(frontendEnabled, forKey: Keys.frontendEnabled) }
    }

    var frontendChannel = FrontendChannel(rawValue: UserDefaults.standard.string(forKey: Keys.frontendChannel) ?? "") ?? .dev {
        didSet { UserDefaults.standard.set(frontendChannel.rawValue, forKey: Keys.frontendChannel) }
    }

    var corePullRequestText = ""
    var frontendPullRequestText = ""
    var startFresh = false

    var preferredPort = UserDefaults.standard.object(forKey: Keys.port) as? Int ?? Constants.defaultServerPort {
        didSet { UserDefaults.standard.set(preferredPort, forKey: Keys.port) }
    }

    var phase: InstallPhase = .idle {
        didSet {
            guard case let .working(message, _) = phase else { return }
            activityLog.add(message, for: activeComponent)
        }
    }

    var running: RunningServer?
    private(set) var errorMessage: String?
    private(set) var failedComponent: Component?
    private(set) var activeComponent: Component = .core

    let activityLog: ActivityLog
    private var process: Process?
    private var isStopping = false
    private var lastStoppedAt: Date?

    init(activityLog: ActivityLog) {
        self.activityLog = activityLog
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.stopBeforeQuitting() }
        }
    }

    var isActive: Bool { coreEnabled || frontendEnabled }
    var isRunning: Bool { process != nil }
    var usesDefaultCore: Bool { frontendEnabled && !coreEnabled }

    var corePullRequest: Int? { BuildSource.pullRequestNumber(from: corePullRequestText) }
    var frontendPullRequest: Int? { BuildSource.pullRequestNumber(from: frontendPullRequestText) }

    func canStart(isSignedIn: Bool) -> Bool {
        if coreEnabled, coreChannel == .pullRequest, corePullRequest == nil { return false }
        if frontendEnabled {
            if frontendChannel == .pullRequest, frontendPullRequest == nil { return false }
            if frontendChannel.needsGitHub, !isSignedIn { return false }
        }
        return true
    }

    func status(of component: Component) -> ComponentStatus {
        switch component {
        case .iOSApp:
            return .off
        case .core:
            guard isActive else { return .off }
            if case let .working(message, _) = phase, activeComponent == .core { return .working(message) }
            if let errorMessage, failedComponent == .core { return .failed(errorMessage) }
            if let running { return .running(running.coreTitle) }
            return .ready
        case .frontend:
            guard frontendEnabled else { return .off }
            if case let .working(message, _) = phase { return .working(message) }
            if let errorMessage, failedComponent == .frontend { return .failed(errorMessage) }
            if let running, let frontendTitle = running.frontendTitle { return .running(frontendTitle) }
            return .ready
        }
    }

    func start(token: String?) async {
        errorMessage = nil
        failedComponent = nil
        var launched = false

        do {
            activeComponent = .core
            phase = .working("Finding Home Assistant Core…", progress: nil)
            let core = try await CoreCatalog.resolve(
                coreEnabled ? coreChannel : .release,
                pullRequest: corePullRequest,
                token: token
            )

            var frontend: ResolvedFrontend?
            if frontendEnabled {
                activeComponent = .frontend
                phase = .working("Finding the frontend…", progress: nil)
                frontend = try await FrontendCatalog.resolve(frontendChannel, pullRequest: frontendPullRequest, token: token)
            }

            if let running, isRunning, !startFresh,
               running.coreKey == core.cacheKey, running.frontendKey == frontend?.cacheKey {
                phase = .idle
                return
            }

            activeComponent = .core
            let hass = try await CoreInstaller.prepare(core) { [weak self] step in
                self?.phase = .working(step, progress: nil)
            }

            var frontendRepository: URL?
            if let frontend {
                activeComponent = .frontend
                phase = .working("Downloading the frontend…", progress: 0)
                frontendRepository = try await FrontendInstaller.prepare(frontend, token: token) { [weak self] progress in
                    Task { @MainActor in
                        guard self?.phase.isWorking == true else { return }
                        self?.phase = .working("Downloading the frontend…", progress: progress)
                    }
                }
            }

            activeComponent = .core
            phase = .working("Stopping the previous server…", progress: nil)
            await stop()

            let configDirectory = Constants.serverConfigDirectory
            if startFresh {
                try? FileManager.default.removeItem(at: configDirectory)
            }
            let justStopped = lastStoppedAt.map { Date().timeIntervalSince($0) < 10 } ?? false
            for _ in 0 ..< 20 where justStopped && !PortFinder.isAvailable(preferredPort) {
                try await Task.sleep(for: .milliseconds(250))
            }
            guard let port = PortFinder.availablePort(preferring: preferredPort) else {
                throw InstallerError("Every port from 8123 to 8199 is in use on this Mac. Quit other Home Assistant servers and try again.")
            }
            try ServerConfiguration.write(to: configDirectory, port: port, frontendRepository: frontendRepository)
            try ServerConfiguration.updateStoredPort(in: configDirectory, to: port)

            phase = .working("Starting Home Assistant… The first start can take a few minutes.", progress: nil)
            let process = try launch(hass, configDirectory: configDirectory)
            self.process = process
            launched = true
            let actualPort = try await waitUntilReady(port: port, process: process)

            running = RunningServer(
                port: actualPort,
                networkAddress: LocalNetwork.ipv4Address(),
                coreTitle: core.title,
                frontendTitle: frontend?.title,
                coreKey: core.cacheKey,
                frontendKey: frontend?.cacheKey,
                frontendDirectory: frontendRepository
            )
            phase = .idle
            activityLog.add("Running at \(running?.localURL.absoluteString ?? "")", for: .core)
            if let frontend {
                activityLog.add("Serving \(frontend.title)", for: .frontend)
            }
        } catch {
            phase = .idle
            if launched {
                await stop()
            }
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                activityLog.add("Stopped", for: activeComponent)
                return
            }
            fail(error.localizedDescription, component: activeComponent)
        }
    }

    func eraseData() async {
        await stop()
        try? FileManager.default.removeItem(at: Constants.serverConfigDirectory)
        errorMessage = nil
        failedComponent = nil
        activityLog.add("Erased the server's data", for: .core)
    }

    func revealConfigFolder() {
        try? FileManager.default.createDirectory(at: Constants.serverConfigDirectory, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([Constants.serverConfigDirectory])
    }

    func revealFrontendBuilds() {
        try? FileManager.default.createDirectory(at: Constants.frontendBuildsDirectory, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([running?.frontendDirectory ?? Constants.frontendBuildsDirectory])
    }

    private func fail(_ message: String, component: Component) {
        errorMessage = message
        failedComponent = component
        activityLog.add(message, for: component, isError: true)
    }

    func stop() async {
        running = nil
        guard let process else { return }
        isStopping = true
        let pid = process.processIdentifier
        process.terminate()
        await Task.detached {
            for _ in 0 ..< 150 {
                if kill(pid, 0) != 0 { return }
                usleep(100_000)
            }
            kill(pid, SIGKILL)
        }.value
        self.process = nil
        isStopping = false
        lastStoppedAt = Date()
        try? FileManager.default.removeItem(at: Constants.serverPIDFile)
        activityLog.add("Stopped the server", for: .core)
    }

    func stopLeftoverServer() async {
        guard let text = try? String(contentsOf: Constants.serverPIDFile, encoding: .utf8),
              let pid = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)), kill(pid, 0) == 0,
              let result = try? await ProcessRunner.run("/bin/ps", ["-o", "command=", "-p", "\(pid)"]),
              result.output.contains(Constants.serverConfigDirectory.path) else { return }
        kill(pid, SIGTERM)
        try? FileManager.default.removeItem(at: Constants.serverPIDFile)
    }

    func showLog() {
        NSWorkspace.shared.open(Constants.serverLogFile)
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func launch(_ hass: URL, configDirectory: URL) throws -> Process {
        try FileManager.default.createDirectory(at: Constants.serverDirectory, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: Constants.serverLogFile.path, contents: nil)
        let log = try FileHandle(forWritingTo: Constants.serverLogFile)

        let process = Process()
        process.executableURL = hass
        process.arguments = ["-c", configDirectory.path]
        process.environment = ProcessInfo.processInfo.environment.merging(UVTool.environment) { $1 }
        process.standardOutput = log
        process.standardError = log
        process.terminationHandler = { [weak self] ended in
            let pid = ended.processIdentifier
            let status = ended.terminationStatus
            Task { @MainActor in self?.processEnded(pid: pid, status: status) }
        }
        try process.run()
        try? "\(process.processIdentifier)".write(to: Constants.serverPIDFile, atomically: true, encoding: .utf8)
        return process
    }

    private func waitUntilReady(port: Int, process: Process) async throws -> Int {
        var port = port
        while true {
            guard process.isRunning else {
                throw InstallerError(
                    "Home Assistant stopped while starting (exit status \(process.terminationStatus)). Click Show Log to see why."
                )
            }
            if let listening = await ServerConfiguration.listeningPort(of: process.processIdentifier) {
                port = listening
            }
            let url = URL(string: "http://127.0.0.1:\(port)/manifest.json")!
            if let result = try? await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 2)),
               (result.1 as? HTTPURLResponse)?.statusCode == 200 {
                return port
            }
            try await Task.sleep(for: .seconds(2))
        }
    }

    private func processEnded(pid: Int32, status: Int32) {
        guard process?.processIdentifier == pid, !isStopping else { return }
        process = nil
        try? FileManager.default.removeItem(at: Constants.serverPIDFile)
        if running != nil {
            running = nil
            fail("Home Assistant stopped unexpectedly (exit status \(status)). Click Show Log to see why.", component: .core)
        }
    }

    private func stopBeforeQuitting() {
        guard let process, process.isRunning else { return }
        let pid = process.processIdentifier
        process.terminate()
        for _ in 0 ..< 100 where kill(pid, 0) == 0 {
            usleep(100_000)
        }
        if kill(pid, 0) == 0 {
            kill(pid, SIGKILL)
        }
        try? FileManager.default.removeItem(at: Constants.serverPIDFile)
    }

    private enum Keys {
        static let coreEnabled = "coreEnabled"
        static let coreChannel = "coreChannel"
        static let frontendEnabled = "frontendEnabled"
        static let frontendChannel = "frontendChannel"
        static let port = "serverPort"
    }
}
