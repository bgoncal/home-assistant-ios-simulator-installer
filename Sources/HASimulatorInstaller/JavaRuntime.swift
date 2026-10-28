import Foundation

enum JavaRuntime {
    private static var managedHome: URL {
        Constants.toolsDirectory.appendingPathComponent("java/Contents/Home")
    }

    private static var downloadURL: URL {
        #if arch(arm64)
        let architecture = "aarch64"
        #else
        let architecture = "x64"
        #endif
        return URL(string: "https://api.adoptium.net/v3/binary/latest/21/ga/mac/\(architecture)/jre/hotspot/normal/eclipse")!
    }

    static func home() async throws -> URL {
        let androidStudio = URL(fileURLWithPath: "/Applications/Android Studio.app/Contents/jbr/Contents/Home")
        for candidate in [androidStudio, managedHome] where isJava(candidate) {
            return candidate
        }

        let directory = managedHome.deletingLastPathComponent().deletingLastPathComponent()
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let (archive, response) = try await URLSession.shared.download(from: downloadURL)
        defer { try? FileManager.default.removeItem(at: archive) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw InstallerError("Couldn't download Java, which the Android tools need. Check your internet connection and try again.")
        }
        let result = try await ProcessRunner.run(
            "/usr/bin/tar",
            ["-xzf", archive.path, "-C", directory.path, "--strip-components", "1"]
        )
        guard result.succeeded, isJava(managedHome) else {
            throw InstallerError("Couldn't unpack Java: \(result.lastErrorLine)")
        }
        return managedHome
    }

    private static func isJava(_ home: URL) -> Bool {
        FileManager.default.isExecutableFile(atPath: home.appendingPathComponent("bin/java").path)
    }
}
