import Foundation

enum StorageCatalog {
    static let titleFileName = ".title"

    static func saveTitle(_ title: String, in directory: URL) {
        try? title.write(to: directory.appendingPathComponent(titleFileName), atomically: true, encoding: .utf8)
    }

    static func items(in group: StorageGroup) async -> [StoredItem] {
        let directory = group.directory
        return await Task.detached(priority: .utility) {
            if group == .tools {
                guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
                return [StoredItem(url: directory, title: "uv, Python and Java", date: modificationDate(of: directory), size: size(of: directory))]
            }
            let entries = (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: .skipsHiddenFiles
            )) ?? []
            return entries
                .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
                .map { StoredItem(url: $0, title: title(of: $0), date: modificationDate(of: $0), size: size(of: $0)) }
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        }.value
    }

    static func delete(_ item: StoredItem) async throws {
        let result = try await ProcessRunner.run("/bin/rm", ["-rf", item.url.path])
        guard result.succeeded else {
            throw InstallerError("Couldn't delete \(item.title): \(result.lastErrorLine)")
        }
    }

    private static func title(of directory: URL) -> String {
        if let saved = try? String(contentsOf: directory.appendingPathComponent(titleFileName), encoding: .utf8) {
            return saved
        }
        let name = directory.lastPathComponent
        for (prefix, label) in [("release-", "Release "), ("source-", "Source "), ("artifact-", "Build ")] where name.hasPrefix(prefix) {
            let rest = name.dropFirst(prefix.count)
            return label + (prefix == "source-" ? String(rest.prefix(7)) : String(rest))
        }
        return "Build \(name)"
    }

    private static func modificationDate(of url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private static func size(of directory: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: Array(keys)) else {
            return 0
        }
        var total: Int64 = 0
        for case let file as URL in enumerator {
            guard let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? 0)
        }
        return total
    }
}
