import Foundation

enum XcodeCatalog {
    static let moreDownloadsURL = URL(string: "https://developer.apple.com/download/all/?q=Xcode")!
    private static let catalogURL = URL(string: "https://xcodereleases.com/data.json")!

    static func fetch() async throws -> [XcodeRelease] {
        let (data, _) = try await URLSession.shared.data(from: catalogURL)
        let entries = try JSONDecoder().decode([Entry].self, from: data)

        var seen = Set<String>()
        return entries.compactMap { entry -> XcodeRelease? in
            guard entry.name == "Xcode",
                  let url = entry.links?.download?.url,
                  seen.insert(entry.version.build ?? url.absoluteString).inserted else { return nil }
            return XcodeRelease(
                version: entry.version.number,
                build: entry.version.build ?? "",
                stage: stage(of: entry.version.release),
                requiredMacOS: entry.requires,
                releaseDate: entry.date.flatMap {
                    DateComponents(calendar: .current, year: $0.year, month: $0.month, day: $0.day).date
                },
                downloadURL: url
            )
        }
    }

    private static func stage(of release: [String: Flexible]) -> String? {
        guard let (kind, value) = release.first, kind != "release" else { return nil }
        let number = value.number.flatMap { $0 > 1 ? " \($0)" : nil } ?? ""
        switch kind {
        case "beta": return "beta" + number
        case "rc": return "RC" + number
        case "gm": return "GM"
        case "gmSeed": return "GM seed" + number
        case "dp": return "Preview" + number
        default: return kind + number
        }
    }

    private struct Entry: Decodable {
        struct Version: Decodable {
            let number: String
            let build: String?
            let release: [String: Flexible]
        }

        struct Day: Decodable {
            let year: Int
            let month: Int
            let day: Int
        }

        struct Links: Decodable {
            struct Download: Decodable {
                let url: URL
            }

            let download: Download?
        }

        let name: String
        let version: Version
        let date: Day?
        let requires: String?
        let links: Links?
    }

    private struct Flexible: Decodable {
        let number: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            number = try? container.decode(Int.self)
        }
    }
}
