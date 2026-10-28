import Foundation

@MainActor
enum FrontendInstaller {
    private static let keptBuilds = 3

    static func prepare(
        _ frontend: ResolvedFrontend,
        token: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let directory = Constants.frontendBuildsDirectory.appendingPathComponent(frontend.cacheKey, isDirectory: true)
        let marker = directory.appendingPathComponent(".ready")

        if FileManager.default.fileExists(atPath: marker.path) {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: directory.path)
            return directory
        }

        try? FileManager.default.removeItem(at: directory)
        removeOldBuilds()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let archive = directory.appendingPathComponent("download.zip")
        let extractTo: URL
        switch frontend {
        case let .artifact(build):
            _ = try await ArtifactDownloader.download(
                GitHubClient(token: token, repository: .frontend).downloadRequest(artifactID: build.artifactID),
                to: archive,
                expectedSize: build.artifactSize,
                progress: progress
            )
            extractTo = directory.appendingPathComponent("hass_frontend", isDirectory: true)
        case let .release(_, wheel, size):
            _ = try await ArtifactDownloader.download(
                URLRequest(url: wheel),
                to: archive,
                expectedSize: size,
                progress: progress
            )
            extractTo = directory
        }

        let result = try await ProcessRunner.run("/usr/bin/ditto", ["-x", "-k", archive.path, extractTo.path])
        try? FileManager.default.removeItem(at: archive)
        let app = directory.appendingPathComponent("hass_frontend/frontend_latest")
        guard result.succeeded, FileManager.default.fileExists(atPath: app.path) else {
            throw InstallerError("The downloaded frontend is incomplete. Try again.")
        }

        FileManager.default.createFile(atPath: marker.path, contents: nil)
        StorageCatalog.saveTitle(frontend.title, in: directory)
        return directory
    }

    private static func removeOldBuilds() {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        let builds = ((try? FileManager.default.contentsOfDirectory(
            at: Constants.frontendBuildsDirectory,
            includingPropertiesForKeys: Array(keys),
            options: .skipsHiddenFiles
        )) ?? [])
            .sorted {
                let lhs = (try? $0.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast
                return lhs > rhs
            }
        for build in builds.dropFirst(keptBuilds - 1) {
            try? FileManager.default.removeItem(at: build)
        }
    }
}
