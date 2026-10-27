import Foundation

enum RuntimeCatalog {
    private static let indexURL = URL(
        string: "https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex"
    )!

    static func fetch() async throws -> [RuntimeRelease] {
        let (data, _) = try await URLSession.shared.data(from: indexURL)
        let index = try PropertyListDecoder().decode(Index.self, from: data)

        var releases: [String: RuntimeRelease] = [:]
        for downloadable in index.downloadables where downloadable.platform == "com.apple.platform.iphoneos" {
            guard let simulator = downloadable.simulatorVersion,
                  simulator.version.compare(Constants.minimumIOSVersion, options: .numeric) != .orderedAscending
            else { continue }
            let release = RuntimeRelease(
                name: downloadable.name,
                version: simulator.version,
                build: simulator.buildUpdate,
                fileSize: downloadable.fileSize ?? 0
            )
            if let existing = releases[release.name], existing.fileSize >= release.fileSize {
                continue
            }
            releases[release.name] = release
        }

        return releases.values.sorted {
            if $0.version != $1.version {
                return $0.version.compare($1.version, options: .numeric) == .orderedDescending
            }
            return $0.isFinal && !$1.isFinal
        }
    }

    private struct Index: Decodable {
        let downloadables: [Downloadable]
    }

    private struct Downloadable: Decodable {
        struct SimulatorVersion: Decodable {
            let version: String
            let buildUpdate: String
        }

        let name: String
        let platform: String?
        let fileSize: Int64?
        let simulatorVersion: SimulatorVersion?
    }
}
