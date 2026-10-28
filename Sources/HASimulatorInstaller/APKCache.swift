import Foundation

@MainActor
enum APKCache {
    private static let keptBuilds = 3

    static func package(for artifactID: Int, flavor: AndroidFlavor) -> AndroidPackage? {
        let directory = directory(for: artifactID)
        for isDebug in [false, true] {
            let apk = directory.appendingPathComponent(fileName(flavor, isDebug: isDebug))
            if FileManager.default.fileExists(atPath: apk.path) {
                try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: directory.path)
                return AndroidPackage(apk: apk, packageName: flavor.packageName(isDebug: isDebug))
            }
        }
        return nil
    }

    static func zipLocation(for artifactID: Int) throws -> URL {
        try FileManager.default.createDirectory(at: Constants.androidBuildsDirectory, withIntermediateDirectories: true)
        return Constants.androidBuildsDirectory.appendingPathComponent("\(artifactID).zip")
    }

    static func extract(_ zip: URL, artifactID: Int, title: String) async throws {
        removeOldBuilds()
        let directory = directory(for: artifactID)
        let unpacked = directory.appendingPathComponent("unpacked", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: unpacked, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: unpacked)
            try? FileManager.default.removeItem(at: zip)
        }

        let result = try await ProcessRunner.run(
            "/usr/bin/unzip",
            ["-q", "-o", zip.path, "app/build/outputs/apk/*", "-d", unpacked.path]
        )
        guard result.succeeded else {
            throw InstallerError("The downloaded file doesn't contain the Android app.")
        }

        var found = false
        for flavor in AndroidFlavor.allCases {
            for isDebug in [false, true] {
                let variant = isDebug ? "debug" : "release"
                let apk = unpacked.appendingPathComponent("app/build/outputs/apk/\(flavor.rawValue)/\(variant)/app-\(flavor.rawValue)-\(variant).apk")
                guard FileManager.default.fileExists(atPath: apk.path) else { continue }
                try FileManager.default.moveItem(at: apk, to: directory.appendingPathComponent(fileName(flavor, isDebug: isDebug)))
                found = true
            }
        }
        guard found else {
            throw InstallerError("The downloaded file doesn't contain the Android app.")
        }
        StorageCatalog.saveTitle(title, in: directory)
    }

    private static func fileName(_ flavor: AndroidFlavor, isDebug: Bool) -> String {
        "\(flavor.rawValue)-\(isDebug ? "debug" : "release").apk"
    }

    private static func directory(for artifactID: Int) -> URL {
        Constants.androidBuildsDirectory.appendingPathComponent("\(artifactID)", isDirectory: true)
    }

    private static func removeOldBuilds() {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        let builds = ((try? FileManager.default.contentsOfDirectory(
            at: Constants.androidBuildsDirectory,
            includingPropertiesForKeys: Array(keys),
            options: .skipsHiddenFiles
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
    }
}
