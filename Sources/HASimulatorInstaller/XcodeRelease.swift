import Foundation

struct XcodeRelease: Identifiable, Hashable, Sendable {
    let version: String
    let build: String
    let stage: String?
    let requiredMacOS: String?
    let releaseDate: Date?
    let downloadURL: URL

    var id: String { build }
    var isFinal: Bool { stage == nil }
    var displayName: String { ["Xcode \(version)", stage].compactMap(\.self).joined(separator: " ") }
    var fileName: String { downloadURL.lastPathComponent }

    var installName: String {
        "Xcode-\(version)\(stage.map { "-" + $0.replacingOccurrences(of: " ", with: "-") } ?? "").app"
    }

    var runsOnThisMac: Bool {
        guard let requiredMacOS else { return true }
        let host = ProcessInfo.processInfo.operatingSystemVersion
        let hostVersion = "\(host.majorVersion).\(host.minorVersion).\(host.patchVersion)"
        return requiredMacOS.compare(hostVersion, options: .numeric) != .orderedDescending
    }
}
