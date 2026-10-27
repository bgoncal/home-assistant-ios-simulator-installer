import Foundation

struct RuntimeRelease: Identifiable, Hashable, Sendable {
    let name: String
    let version: String
    let build: String
    let fileSize: Int64

    var id: String { name }
    var isFinal: Bool { !name.localizedCaseInsensitiveContains("beta") && !name.contains("Release Candidate") }
    var displayName: String { name.replacingOccurrences(of: " Simulator Runtime", with: "") }
    var downloadVersion: String { isFinal ? version : build }

    func isInstalled(in runtimes: [SimulatorRuntime]) -> Bool {
        runtimes.contains { $0.build == build || (isFinal && $0.version == version) }
    }
}
