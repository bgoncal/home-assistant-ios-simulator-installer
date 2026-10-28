import Foundation

enum BuildCache {
    private static let keptBuilds = 3

    static func extractedApp(for artifactID: Int) -> URL? {
        let directory = directory(for: artifactID)
        guard let app = appBundle(in: directory) else { return nil }
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: directory.path)
        return app
    }

    static func zipLocation(for artifactID: Int) throws -> URL {
        try FileManager.default.createDirectory(at: Constants.iOSBuildsDirectory, withIntermediateDirectories: true)
        return Constants.iOSBuildsDirectory.appendingPathComponent("\(artifactID).zip")
    }

    static func extract(_ zip: URL, artifactID: Int) async throws -> URL {
        removeOldBuilds()
        let destination = directory(for: artifactID)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let result = try await ProcessRunner.run("/usr/bin/ditto", ["-x", "-k", zip.path, destination.path])
        try? FileManager.default.removeItem(at: zip)
        guard result.succeeded, let app = appBundle(in: destination) else {
            throw InstallerError("The downloaded file doesn't contain the app.")
        }
        removeTestBundles(from: app)
        return app
    }

    static func removeTestBundles(from app: URL) {
        let plugIns = app.appendingPathComponent("PlugIns", isDirectory: true)
        let contents = (try? FileManager.default.contentsOfDirectory(at: plugIns, includingPropertiesForKeys: nil)) ?? []
        for bundle in contents where bundle.pathExtension == "xctest" {
            try? FileManager.default.removeItem(at: bundle)
        }
    }

    static func urlScheme(of app: URL) -> String? {
        let types = Bundle(url: app)?.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        return types.lazy.compactMap { ($0["CFBundleURLSchemes"] as? [String])?.first }.first
    }

    static func bundleIdentifier(of app: URL) throws -> String {
        guard let identifier = Bundle(url: app)?.bundleIdentifier else {
            throw InstallerError("The downloaded app is damaged. Try again.")
        }
        return identifier
    }

    private static func directory(for artifactID: Int) -> URL {
        Constants.iOSBuildsDirectory.appendingPathComponent("\(artifactID)", isDirectory: true)
    }

    private static func appBundle(in directory: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return nil }
        for case let url as URL in enumerator where url.pathExtension == "app" {
            return url
        }
        return nil
    }

    private static func removeOldBuilds() {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        let builds = ((try? FileManager.default.contentsOfDirectory(
            at: Constants.iOSBuildsDirectory,
            includingPropertiesForKeys: Array(keys)
        )) ?? [])
            .filter { $0.pathExtension != "zip" }
            .sorted {
                let lhs = (try? $0.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast
                return lhs > rhs
            }
        for build in builds.dropFirst(keptBuilds - 1) {
            try? FileManager.default.removeItem(at: build)
        }

        let legacyBuilds = (try? FileManager.default.contentsOfDirectory(
            at: Constants.cacheDirectory,
            includingPropertiesForKeys: nil
        )) ?? []
        for build in legacyBuilds where Int(build.deletingPathExtension().lastPathComponent) != nil {
            try? FileManager.default.removeItem(at: build)
        }
    }
}
