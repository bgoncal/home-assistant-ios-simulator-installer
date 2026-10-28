import Foundation

@MainActor
enum CoreInstaller {
    private static let keptBuilds = 2

    static func prepare(_ core: ResolvedCore, step: (String) -> Void) async throws -> URL {
        let directory = Constants.coreBuildsDirectory.appendingPathComponent(core.cacheKey, isDirectory: true)
        let environment = directory.appendingPathComponent("venv", isDirectory: true)
        let hass = environment.appendingPathComponent("bin/hass")
        let marker = directory.appendingPathComponent(".ready")

        if FileManager.default.fileExists(atPath: marker.path), FileManager.default.isExecutableFile(atPath: hass.path) {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: directory.path)
            return hass
        }

        try await remove(directory)
        try await removeOldBuilds()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        step("Getting the Python tools…")
        let uv = try await UVTool.ensureInstalled().path

        let pythonRequirement: String
        let packageArguments: [String]
        var source: URL?
        switch core.package {
        case let .pyPI(version, requiresPython):
            pythonRequirement = requiresPython
            packageArguments = ["homeassistant==\(version)"]
        case let .source(archive):
            step("Downloading Home Assistant Core…")
            let sourceDirectory = directory.appendingPathComponent("src", isDirectory: true)
            try await downloadSource(archive, to: sourceDirectory)
            pythonRequirement = try CoreCatalog.pythonRequirement(inSource: sourceDirectory)
            packageArguments = ["-e", sourceDirectory.path]
            source = sourceDirectory
        }

        step("Installing Python…")
        try await require(
            ProcessRunner.run(
                uv,
                ["venv", environment.path, "--python", CoreCatalog.pythonVersion(for: pythonRequirement)],
                environment: UVTool.environment
            ),
            "Couldn't install Python"
        )

        step("Installing Home Assistant Core… This takes a minute or two.")
        try await require(
            ProcessRunner.run(
                uv,
                ["pip", "install", "--python", environment.appendingPathComponent("bin/python").path] + packageArguments,
                environment: UVTool.environment
            ),
            "Couldn't install Home Assistant Core"
        )

        if let source {
            step("Preparing translations…")
            try await require(
                ProcessRunner.run(
                    environment.appendingPathComponent("bin/python").path,
                    ["-m", "script.translations", "develop", "--all"],
                    currentDirectory: source
                ),
                "Couldn't prepare the translations"
            )
        }

        FileManager.default.createFile(atPath: marker.path, contents: nil)
        StorageCatalog.saveTitle(core.title, in: directory)
        return hass
    }

    private static func downloadSource(_ archive: URL, to directory: URL) async throws {
        let (tarball, response) = try await URLSession.shared.download(from: archive)
        defer { try? FileManager.default.removeItem(at: tarball) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw InstallerError("Couldn't download Home Assistant Core from GitHub. Check your internet connection and try again.")
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try await require(
            ProcessRunner.run(
                "/usr/bin/tar",
                ["-xzf", tarball.path, "-C", directory.path, "--strip-components", "1", "--exclude", "*/tests/*"]
            ),
            "Couldn't unpack Home Assistant Core"
        )
    }

    private static func removeOldBuilds() async throws {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        let builds = ((try? FileManager.default.contentsOfDirectory(
            at: Constants.coreBuildsDirectory,
            includingPropertiesForKeys: Array(keys),
            options: .skipsHiddenFiles
        )) ?? [])
            .sorted {
                let lhs = (try? $0.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast
                return lhs > rhs
            }
        for build in builds.dropFirst(keptBuilds - 1) {
            try await remove(build)
        }
    }

    private static func remove(_ directory: URL) async throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try await require(ProcessRunner.run("/bin/rm", ["-rf", directory.path]), "Couldn't remove an old copy of Home Assistant Core")
    }

    private static func require(_ result: ProcessResult, _ message: String) throws {
        guard result.succeeded else {
            throw InstallerError("\(message): \(result.lastErrorLine)")
        }
    }
}
