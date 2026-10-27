import Foundation

enum XcodeInstaller {
    private static let partialExtensions = ["download", "crdownload", "part"]

    static func waitForDownload(of release: XcodeRelease) async throws -> URL {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let baseName = (release.fileName as NSString).deletingPathExtension
        var lastSize: Int?

        while true {
            if let candidate = newestXIP(named: baseName, in: downloads) {
                let size = (try? candidate.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size > 0, size == lastSize, !hasPartialDownload(for: candidate) {
                    return candidate
                }
                lastSize = size
            }
            try await Task.sleep(for: .seconds(3))
        }
    }

    static func install(_ xip: URL, as installName: String) async throws -> URL {
        let destination = URL(fileURLWithPath: "/Applications", isDirectory: true).appendingPathComponent(installName)
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            throw InstallerError("\(destination.path) already exists.")
        }

        let workDirectory = Constants.cacheDirectory.appendingPathComponent("xcode-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDirectory) }

        let result = try await ProcessRunner.run("/usr/bin/xip", ["--expand", xip.path], currentDirectory: workDirectory)
        guard result.succeeded else {
            throw InstallerError("Unpacking \(xip.lastPathComponent) failed: \(result.lastErrorLine)")
        }
        guard let app = try FileManager.default.contentsOfDirectory(at: workDirectory, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "app" }) else {
            throw InstallerError("\(xip.lastPathComponent) doesn't contain Xcode.")
        }

        do {
            try FileManager.default.moveItem(at: app, to: destination)
        } catch {
            throw InstallerError("Couldn't move Xcode into Applications: \(error.localizedDescription)")
        }
        return destination
    }

    private static func newestXIP(named baseName: String, in directory: URL) -> URL? {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        return ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)) ?? [])
            .filter { $0.pathExtension == "xip" && $0.lastPathComponent.hasPrefix(baseName) }
            .max {
                let lhs = (try? $0.resourceValues(forKeys: Set(keys)).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: Set(keys)).contentModificationDate) ?? .distantPast
                return lhs < rhs
            }
    }

    private static func hasPartialDownload(for file: URL) -> Bool {
        partialExtensions.contains { FileManager.default.fileExists(atPath: file.path + "." + $0) }
    }
}
