import Foundation

enum ServerConfiguration {
    static var serverName: String {
        "Simulator Test Server (\(Host.current().localizedName ?? "Mac"))"
    }

    static func write(to directory: URL, port: Int, frontendRepository: URL?) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var lines = [
            "default_config:",
            "",
            "homeassistant:",
            "  name: \(quoted(serverName))",
            "",
            "http:",
            "  server_port: \(port)",
        ]
        if let frontendRepository {
            lines += [
                "",
                "frontend:",
                "  development_repo: \(quoted(frontendRepository.path))",
            ]
        }
        try (lines.joined(separator: "\n") + "\n").write(
            to: directory.appendingPathComponent("configuration.yaml"),
            atomically: true,
            encoding: .utf8
        )
    }

    static func updateStoredPort(in directory: URL, to port: Int) throws {
        let file = directory.appendingPathComponent(".storage/http")
        guard let data = try? Data(contentsOf: file),
              var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var settings = root["data"] as? [String: Any] else { return }
        for key in ["stable", "pending"] {
            guard var entry = settings[key] as? [String: Any] else { continue }
            entry["server_port"] = port
            settings[key] = entry
        }
        root["data"] = settings
        try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            .write(to: file, options: .atomic)
    }

    static func listeningPort(of pid: Int32) async -> Int? {
        guard let result = try? await ProcessRunner.run(
            "/usr/sbin/lsof",
            ["-a", "-p", "\(pid)", "-iTCP", "-sTCP:LISTEN", "-nP", "-Fn"]
        ) else { return nil }
        return result.output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> Int? in
                guard line.hasPrefix("n"), let colon = line.lastIndex(of: ":") else { return nil }
                return Int(line[line.index(after: colon)...])
            }
            .first
    }

    private static func quoted(_ value: String) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return (try? encoder.encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "\"\""
    }
}
