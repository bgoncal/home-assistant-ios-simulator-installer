import Foundation

enum UVTool {
    static var executable: URL {
        Constants.toolsDirectory.appendingPathComponent("uv/uv")
    }

    static var environment: [String: String] {
        [
            "UV_PYTHON_INSTALL_DIR": Constants.toolsDirectory.appendingPathComponent("python").path,
            "UV_CACHE_DIR": Constants.toolsDirectory.appendingPathComponent("uv-cache").path,
            "UV_PYTHON_PREFERENCE": "only-managed",
            "UV_NO_PROGRESS": "1",
        ]
    }

    private static var downloadURL: URL {
        #if arch(arm64)
        let platform = "aarch64-apple-darwin"
        #else
        let platform = "x86_64-apple-darwin"
        #endif
        return URL(string: "https://github.com/astral-sh/uv/releases/latest/download/uv-\(platform).tar.gz")!
    }

    static func ensureInstalled() async throws -> URL {
        if FileManager.default.isExecutableFile(atPath: executable.path) {
            return executable
        }

        let directory = executable.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let (archive, response) = try await URLSession.shared.download(from: downloadURL)
        defer { try? FileManager.default.removeItem(at: archive) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw InstallerError("Couldn't download the Python tools Home Assistant Core needs. Check your internet connection and try again.")
        }
        let result = try await ProcessRunner.run(
            "/usr/bin/tar",
            ["-xzf", archive.path, "-C", directory.path, "--strip-components", "1"]
        )
        guard result.succeeded, FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw InstallerError("Couldn't unpack the Python tools: \(result.lastErrorLine)")
        }
        return executable
    }
}
