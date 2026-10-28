import Foundation
import Observation

@MainActor
@Observable
final class LogTail {
    private static let maximumBytes: UInt64 = 64 * 1024

    private(set) var text = ""

    func follow(_ file: URL) async {
        while !Task.isCancelled {
            let latest = Self.read(file)
            if latest != text {
                text = latest
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private static func read(_ file: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: file) else { return "" }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let start = size > maximumBytes ? size - maximumBytes : 0
        try? handle.seek(toOffset: start)
        let text = String(decoding: (try? handle.readToEnd()) ?? Data(), as: UTF8.self)
        guard start > 0, let firstLineEnd = text.firstIndex(of: "\n") else { return text }
        return String(text[text.index(after: firstLineEnd)...])
    }
}
